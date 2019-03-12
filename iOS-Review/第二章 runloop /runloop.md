# 2.1 runloop



1. runloop 伪代码  https://opensource.apple.com/tarballs/CF/

使程序一直运行 并接收用户输入 将事件加入消息队列 （Message queue）
决定程序在何时应该处理哪些Event 
调用解偶 (从 Message queue) 取出事件 处理

```object
int main(int argc, char * argv[]) {
   while (AppIsRunning) {
   		///1 终端等待事件唤醒
        id whoWakesMe = SleepForWakingUp();
        ///2 唤醒 获取事件
        id event = GetEvent(whoWakesMe);
        
        ///3 处理事件
        HandleEvent(event);
    }
    return 0;
}
```



2.  RunLoop is Cocoa --> Fundation--> NSRunLoop-->  CoreFundation--> CFunLoop 
  - GCD  
  - mach kernel 
  - block 
  - pthread 
  - 

3. 如何启动的
  * dydl -->start
  * main -- > main.m
  * UIApplicationMain
  * GSEeventLoopRunSepcific ---> Graphics Services
  * CFRunLoopRunSpecific  
  * __CFRunLoopRun
  * _CFRunLoopDoSources0



4. RunLoop 构建
![](./image/1.0.png)


5. RunLoopMode 
  - CFRunLoopSource 
      	 - Source0  处理App内部事件、App自己负责管理（触发），如UIEvent、CFSocket
      	 - Source1  由RunLoop和内核管理，Mach port驱动，如CFMachPort、CFMessagePort


  - CFRunLoopTimer

    ```object
     + (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo;
    
    + (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo;
    
    - (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray *)modes;
    
    + (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;
    - (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode;
    
    
    ```

  - CFRunLoopObserver

    ```objective-c
    typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
        kCFRunLoopEntry = (1UL << 0),
        kCFRunLoopBeforeTimers = (1UL << 1),
        kCFRunLoopBeforeSources = (1UL << 2),
        kCFRunLoopBeforeWaiting = (1UL << 5),
        kCFRunLoopAfterWaiting = (1UL << 6),
        kCFRunLoopExit = (1UL << 7),
        kCFRunLoopAllActivities = 0x0FFFFFFFU
    };
    
    /// 向外部报告RunLoop当前状态的更改
    /// 框架中很多机制都由RunLoopObserver触发，如CAAnimation
    ```



    UIKit通过RunLoopObserver在RunLoop两次Sleep间
    对AutoreleasePool进行Pop和Push
    将这次Loop中产生的Autorelease对象释放


​    
​    * CFRunLoopMode
​    	 - NSDefaultRunLoopMode 默认状态、空闲状态
​    	 - UITrackingRunLoopMode 滑动ScrollView时
​    	 - UIInitializationRunLoopMode 私有，App启动时
​    	 - NSRunLoopCommonModes Mode集合




* 下面的方法Timer被添加到NSDefaultRunLoopMode
	 ```obj
	 [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(timerTick:)
                                   userInfo:nil
                                    repeats:YES];
	```

	若不希望Timer被ScrollView影响，需添加到NSRunLoopCommonModes
	```obj
	NSTimer *timer = [NSTimer timerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(timerTick:)
                                           userInfo:nil
                                            repeats:YES];
[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	```


6. RunLoop的挂起与唤醒
   - 指定用于唤醒的mach_port端口

    - 调用mach_msg监听唤醒端口，被唤醒前，系统内核将这个线程挂起，停留在mach_msg_trap状态

    - 由另一个线程（或另一个进程中的某个线程）向内核发送这个端口的msg后，trap状态被唤醒，RunLoop继续开始干活

7. AFNetworking中RunLoop的创建

   ```objective-c
   + (void)networkRequestThreadEntryPoint:(id)__unused object {
       @autoreleasepool {
           [[NSThread currentThread] setName:@"AFNetworking"];
           
           NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
           [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
           [runLoop run];
       }
   }
   
   + (NSThread *)networkRequestThread {
       static NSThread *_networkRequestThread = nil;
       static dispatch_once_t oncePredicate;
       dispatch_once(&oncePredicate, ^{
           _networkRequestThread =
           [[NSThread alloc] initWithTarget:self
                                   selector:@selector(networkRequestThreadEntryPoint:)
                                     object:nil];
           [_networkRequestThread start];
       });
       
       return _networkRequestThread;
   }
   ```

8. 一个TableView延迟加载图片的新思路

   ```objective-c
   UIImage *downloadedImage = ...;
       [self.avatarImageView performSelector:@selector(setImage:)
                                  withObject:downloadedImage
                                  afterDelay:0
                                     inModes:@[NSDefaultRunLoopMode]];
   ```

9. 让Crash的App回光返照

     ```objective-c
      CFRunLoopRef runLoop = CFRunLoopGetCurrent();
         NSArray *allModes = CFBridgingRelease(CFRunLoopCopyAllModes(runLoop));
         while (1) {
             for (NSString *mode in allModes) {
                 CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
             }
         }
     
     /// 接到Crash的Signal后手动重启RunLoop
     ```

