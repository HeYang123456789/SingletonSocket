
//
//  SingletonSocket.m
//  SingletonSocket
//
//  Created by HEYANG on 16/4/17.
//  Copyright © 2016年 HeYang. All rights reserved.
//

#import "SingletonSocket.h"

#import "Reachability.h"

#define CurrentReachabilityStatus [Reachability reachabilityForInternetConnection].currentReachabilityStatus

#import "SimpleNSLog.h"



//enum{
//    SocketOfflineByServer = 0,// 服务器掉线，默认为0
//    SocketOfflineByUser,  // 用户主动cut
//};


@interface SingletonSocket () <GCDAsyncSocketDelegate>

@property (nonatomic,strong) GCDAsyncSocket  *clientSocket;     // socket

@property (nonatomic,retain) NSTimer         *connectTimer;    // 计时器

@property (nonatomic,strong) NSData          *longConnectData; // 长连接发送心跳包的数据

@property (nonatomic,strong) successBlock    successDataBlock;     // 成功的时候回返回的NSData
@property (nonatomic,strong) failureBlock    failureDataBlock;     // 成功的时候回返回的NSError

/** Reachability */
@property (nonatomic,strong)Reachability *reach;

@end

@implementation SingletonSocket

// 设置为单例类
implementationSingleton(SingletonSocket)

#pragma mark - 建立Socket连接的方法
-(void)socketConnectHostSuccess:(successBlock)success failure:(failureBlock)failure{
    // 如果没有给_socketPort和_socketHost赋值，这个程序自动崩溃报错
    NSParameterAssert(_socketPort);
    NSParameterAssert(_socketHost);
    
    // 先设置了属性，然后直接请求
    if (_socketHost && _socketPort) {
        [self socketConnectHost:self.socketHost
                         onProt:self.socketPort
                        success:success
                        failure:failure];
    }else{
        
    }
}
-(void)socketConnectHost:(NSString*)host onProt:(UInt16)prot success:(successBlock)success failure:(failureBlock)failure{
    // 在默认的延迟时间上请求
    [self socketConnectHost:host
                     onProt:prot
               withTimerout:3
                    success:success
                    failure:failure];
}
-(void)socketConnectHost:(NSString*)host onProt:(UInt16)prot withTimerout:(NSTimeInterval)time success:(successBlock)success failure:(failureBlock)failure{
    [self socketConnectHost:host
                     onProt:prot
               withTimerout:time
                  withQueue:dispatch_get_global_queue(0, 0)
                    success:success
                    failure:failure];
}

-(void)socketConnectHost:(NSString*)host onProt:(UInt16)prot withTimerout:(NSTimeInterval)time withQueue:(dispatch_queue_t)queue success:(successBlock)success failure:(failureBlock)failure{
    
    self.successDataBlock = success;
    self.failureDataBlock = failure;
    
    // 因为没有通过属性传值，这里需要补充，避免属性在被用的时候却是nil的
    self.socketHost = host;
    self.socketPort = prot;
    self.connetIntervalTime = time;
    
    
    // 创建Socket对象
    self.clientSocket    = \
    [[GCDAsyncSocket alloc] initWithDelegate:self
                               delegateQueue:queue];
    
    // 开始连接
    [self connetToHost:host onPort:prot withTieout:time];
}

#pragma mark - Socket连接
-(void)connetToHost:(NSString*)host onPort:(UInt16)prot withTieout:(NSTimeInterval)time{
    NSError *error = nil;
    [self.clientSocket connectToHost:host  onPort:prot withTimeout:time error:&error];
    if (!error) {
        DLog(@"连接成功");
    }
}
#pragma mark - 断开Socket连接
-(void)cutOffSocket{
    
    // 因为手动断开Socket连接，就要告诉该Socket对象，是自己手动断开的，并非网络断开
    
    // 这个方法是让计时器暂停，还是可以恢复启动的。
    [self.connectTimer setFireDate:[NSDate distantFuture]];
    // 断开Socket连接
    [self.clientSocket disconnect];
}

#pragma mark - GCDAsyncSocketDelegate 代理方法
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    DLog(@"连接成功调用的代理方法");
    
    // 因为当前的方法在子线程执行，需要在主线程执行的操作就需要手动处理
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_connectTimer == nil) {
            // 连接成功之后，就需要用每隔   时间向服务器发送心跳包
            self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:self.connetIntervalTime
                                                                 target:self
                                                               selector:@selector(longConnectToSocket)
                                                               userInfo:nil
                                                                repeats:YES];
            // 需要定时确定执行了这个定时器方法
            [[NSRunLoop mainRunLoop] addTimer:self.connectTimer
                                      forMode:NSRunLoopCommonModes];
        }
        // 启动心跳包
        [self.connectTimer setFireDate:[NSDate distantPast]];
    });
    
    // 连接成功就需要为读取数据做准备
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    DLog(@"连接失败调用的代理方法");
    
    // 失败的话，就需要关闭计时器
    dispatch_async(dispatch_get_main_queue(), ^{
        // 这个方法是让计时器暂停，还是可以恢复启动的。
        [self.connectTimer setFireDate:[NSDate distantFuture]];
    });
    
    
    if (CurrentReachabilityStatus == NotReachable) {
        DLog(@"没有网络");
        return;
    }
    
    // 如果是服务器那边进行自动断开，那么就需要30秒(根据需求设置，30是我自己随便设置的)间隔请求
    NSDictionary* dic = [err valueForKey:@"userInfo"];
    if ([dic[@"NSLocalizedDescription"] isEqualToString:@"Socket closed by remote peer"]) {
        // 延迟30秒在请求
        dispatch_async(dispatch_get_main_queue(), ^{
            sleep(30);
            DLog(@"Socket closed by remote peer：异步函数中重新连接网络");
            // 重新连接网络
            [self connetToHost:self.socketHost onPort:self.socketPort withTieout:self.connetIntervalTime];
        });
        return;
    }
    // 补充，在实际开发中，其实可以将这个重新连接网的方法公开出去，让刷新框架调用
    
    // 重新连接网络
    [self connetToHost:self.socketHost onPort:self.socketPort withTieout:self.connetIntervalTime];
    
    // 因为失败了，所以把错误通过block传递出去
    self.failureDataBlock(err);
}
// 如果返回得到数据就会调用的方法
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    // 成功的话就会返回data数据
    if (data) {
        self.successDataBlock(data);
    }
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - 心跳包
#pragma mark 心跳包调用的方法
-(void)longConnectToSocket{
    
    // 如果没有数据，自然要崩溃提示
    NSParameterAssert(_longConnectData);
    
    // 写入数据
    [self.clientSocket writeData:self.longConnectData withTimeout:-1 tag:1];
    
    DLog(@"心跳一次，发送一次数据,%@",[NSThread currentThread]);
}

#pragma mark - Reachability
- (void)setUpReachabilityConnect{
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChange) name:kReachabilityChangedNotification object:nil];
    self.reach = [Reachability reachabilityForInternetConnection];
    // 开始监听网络
    [self.reach startNotifier];
}
- (void)reachabilityChange{
    /*
     NotReachable = 0; // 没有网络
     ReachableViaWiFi, // WIFI
     ReachableViaWWAN  // 蜂窝网络
     */
    // 首先获得一个Reachability有状态的
    if (CurrentReachabilityStatus == ReachableViaWWAN) {
        DLog(@"蜂窝网络");
        
        return;
    }
    if (CurrentReachabilityStatus == ReachableViaWiFi) {
        DLog(@"WIFI状态");
        // 需要重新连上Socket连接
        [self connetToHost:self.socketHost
                    onPort:self.socketPort
                withTieout:self.connetIntervalTime];
        return;
    }
    if (CurrentReachabilityStatus == NotReachable) {
        DLog(@"没有网络");
        return;
    }
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.reach stopNotifier];
}

#pragma mark - set和get方法 包括懒加载的方法
-(void)setLongConnectData:(NSData *)longConnectData{
    _longConnectData = longConnectData;
}

-(NSTimeInterval)connetIntervalTime{
    if (!_connetIntervalTime) {
        // 默认设置心跳包的时间间隔为3秒
        _connetIntervalTime = 3;
    }
    return _connetIntervalTime;
}


@end
