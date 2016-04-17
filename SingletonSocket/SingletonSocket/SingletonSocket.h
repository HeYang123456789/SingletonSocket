//
//  SingletonSocket.h
//  SingletonSocket
//
//  Created by HEYANG on 16/4/17.
//  Copyright © 2016年 HeYang. All rights reserved.
//

/* 需要改进的地方，要重新考虑两个不同的错误：1、网络连接错误 2、服务器自动断开连接错误
 *      我下面的failureBlock只用在第2种错误。
 *
 *      计时器要处理，对象生命周期中要设置，这个可以考虑考虑，貌似单例不会被销毁
 */


#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

/***************************************************************************/
/***************************************************************************/

#ifndef Singleton_h
#define Singleton_h

/**
 *  单例模式宏抽取
 *
 *  @description
 *
 *  1、创建一个Singleton.h头文件然后输入以下所有的文件。
 *  2、使用：在需要设置为单例的类中，@interface里使用interfaceSingleton(类名)
 *                             @implementation里使用implementationSingleton(类名)
 *                      这样，即可直接就将所在的类设置为单例模式
 *
 */
// 以后就可以使用interfaceSingleton来替代后面的方法声明
// 这里宏抽取的是在interface的单例模式方法声明
#define interfaceSingleton(name)  +(instancetype)share##name



//这里宏抽取的是在implementation的单例模式
#if __has_feature(objc_arc)
// ARC
#define implementationSingleton(name)  \
+ (instancetype)share##name \
{ \
name *instance = [[self alloc] init]; \
return instance; \
} \
static name *_instance = nil; \
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[super allocWithZone:zone] init]; \
}); \
return _instance; \
} \
- (id)copyWithZone:(NSZone *)zone{ \
return _instance; \
} \
- (id)mutableCopyWithZone:(NSZone *)zone \
{ \
return _instance; \
}
#else
// MRC

#define implementationSingleton(name)  \
+ (instancetype)share##name \
{ \
name *instance = [[self alloc] init]; \
return instance; \
} \
static name *_instance = nil; \
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[super allocWithZone:zone] init]; \
}); \
return _instance; \
} \
- (id)copyWithZone:(NSZone *)zone{ \
return _instance; \
} \
- (id)mutableCopyWithZone:(NSZone *)zone \
{ \
return _instance; \
} \
- (oneway void)release \
{ \
} \
- (instancetype)retain \
{ \
return _instance; \
} \
- (NSUInteger)retainCount \
{ \
return  MAXFLOAT; \
}
#endif


#endif /* Singleton_h */

/***************************************************************************/
/***************************************************************************/

#pragma mark - 声明一个代理协议，用于返回当前设备网络状态

@protocol SingletonSocketProtocol <NSObject>

@required
- (BOOL)getCurrentNetworkStatus;

@end

/***************************************************************************/
/***************************************************************************/
#pragma mark - 类型定义两个block，并通过宏来限制

#ifndef SingletonSocket_h
#define SingletonSocket_h

typedef void (^successBlock)(NSData* data);
typedef void (^failureBlock)(NSError* error);

#endif /* SingletonSocket_h */

@interface SingletonSocket : NSObject

#pragma mark - 设置为单例类
interfaceSingleton(SingletonSocket);

#pragma mark - 公开的属性
@property (nonatomic, copy  ) NSString       *socketHost; // socket的Host
@property (nonatomic, assign) UInt16         socketPort;  // socket的prot
@property (nonatomic,assign)  NSTimeInterval connetIntervalTime; // 心跳包的间隔时间

/** SingletonSocketProtocol 协议的代理 */
@property (nonatomic,strong)id<SingletonSocketProtocol> networkListeneDelegate;


#pragma mark - 公开的方法

/** 开启Socket连接，并开启发送数据，并且需要传入代理对象 */
-(void)socketConnectHostSuccess:(successBlock)success
                        failure:(failureBlock)failure;
/** 开启Socket连接，并开启发送数据，并且需要传入代理对象 */
-(void)socketConnectHost:(NSString*)host
                  onProt:(UInt16)prot
                 success:(successBlock)success
                 failure:(failureBlock)failure;
/** 开启Socket连接，并开启发送数据，并且需要传入代理对象 */
-(void)socketConnectHost:(NSString*)host
                  onProt:(UInt16)prot
            withTimerout:(NSTimeInterval)time
                 success:(successBlock)success
                 failure:(failureBlock)failure;
/** 开启Socket连接，并开启发送数据，并且需要传入代理对象 */
-(void)socketConnectHost:(NSString*)host
                  onProt:(UInt16)prot
            withTimerout:(NSTimeInterval)time
               withQueue:(dispatch_queue_t)queue
                 success:(successBlock)success
                 failure:(failureBlock)failure;


/** 断开Socket连接 */
-(void)cutOffSocket;


/** longConnectData的set方法 */
-(void)setLongConnectData:(NSData *)longConnectData;

@end
