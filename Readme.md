# 使用提示

必须要遵循<SingletonSocketProtocol>协议，并实现协议里的方法。这个方法是用来获取当前网络状态的方法。

获取当前网络状态有两种方案：1、使用第三方框架，比如AFN 2、使用Reachability。







##iOS-Socket

即时通讯最大的特点就是实时性，基本感觉不到延时或是掉线，所以必须对socket的连接进行监视与检测，在断线时进行重新连接，如果用户退出登录，要将socket手动关闭，否则对服务器会造成一定的负荷。

#### 需求：在封装的Socket工具类中需要提供网络状态的监听和手动关闭socket连接的接口。

一般来说，一个用户（对于ios来说也就是我们的项目中）只能有一个正在连接的socket，所以这个socket变量必须是全局的，这里可以考虑使用单例或是AppDelegate进行数据共享，本文使用单例。如果对一个已经连接的socket对象再次进行连接操作，会抛出异常（不可对已经连接的socket进行连接）程序崩溃，所以在连接socket之前要对socket对象的连接状态进行判断

#### 需求：使用单例模式设计Socket。

使用socket进行即时通讯还有一个必须的操作，即对服务器发送心跳包，每隔一段时间对服务器发送长连接指令（指令不唯一，由服务器端指定，包括使用socket发送消息，发送的数据和格式都是由服务器指定），如果没有收到服务器的返回消息，AsyncSocket会得到失去连接的消息，我们可以在失去连接的回调方法里进行重新连接。

#### 需求：判断断开然后重连。




