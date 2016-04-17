//
//  ViewController.m
//  SingletonSocket
//
//  Created by HEYANG on 16/4/17.
//  Copyright © 2016年 HeYang. All rights reserved.
//

#pragma mark - 常量定义区
// 测试用的  IP和端口号
#define Host @"123.59.66.225"
#define Port 9000


#import "ViewController.h"

#import "SingletonSocket.h"
#import "SimpleNSLog.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self socketConnet];
}

- (void)reachability{
    
}

- (void)socketConnet{
    SingletonSocket* socket = [SingletonSocket shareSingletonSocket];
    // 设置属性
    socket.socketHost = Host;
    socket.socketPort = Port;
    
    // 传入数据
    socket.longConnectData = [self getData];
    
    // 设置心跳包的间隔时间
    socket.connetIntervalTime = 30;
    
    // 开启连接，并发送数据
    [socket socketConnectHostSuccess:^(NSData* data) {
        DLog(@"因为返回了数据，所以就会调用这个方法");
        DLog(@"%@",data);
        Byte *dataByte = (Byte*)data.bytes;
        DLog(@"");
        for (int i = 0; i<data.length; i++) {
            printf("%hhu ",dataByte[i]);
        }
        DLog(@"");
    } failure:^(NSError* error) {
        DLog(@"失败了：%@",error);
    }];
    
    
    //    [socket cutOffSocket];
}

// 拼接数据的方法
- (NSData*)getData{
    // 拼接数据
    Byte byte1[] = {0,0,0,6};
    Byte byte2[] = {-22,96};
    NSMutableData* data = [[NSMutableData alloc] init];
    [data appendBytes:byte1 length:4];
    [data appendBytes:byte2 length:2];
    return data;
}

// 发送固定的指令，长连接发送数据
/*
 message Cs_60000{
 null Code = 1;
 }
 message Sc_60000{
 array ServerList {
 unit8 Line = 1;  分线
 string Ip = 2;   IP
 uint16 Port = 3;    端口
 uint8 State = 4;    状态1顺畅2正常3繁忙
 uint16 UserNum = 5; 人数
 }
 }
 */

@end

