## RunLoop

reference:[深入理解Runloop](https://blog.ibireme.com/2015/05/18/runloop/)

### Runloop 基本原理

一般来讲，一个线程一次只能执行一个任务，执行完成后线程就会退出。如果我们需要一个机制，让线程能随时处理事件但并不退出，通常的代码逻辑是这样的：

```
function loop() {
    initialize();
    do {
        var message = get_next_message();
        process_message(message);
    } while (message != quit);
}
```

在`iOS`中，`Runloop`与线程是一一对应的关系，这种关系存在一张全局字典里：

```
/// 全局的Dictionary，key 是 pthread_t， value 是 CFRunLoopRef
static CFMutableDictionaryRef loopsDic;
/// 访问 loopsDic 时的锁
static CFSpinLock_t loopsLock;
 
/// 获取一个 pthread 对应的 RunLoop。
CFRunLoopRef _CFRunLoopGet(pthread_t thread) {
    OSSpinLockLock(&loopsLock);
    
    if (!loopsDic) {
        // 第一次进入时，初始化全局Dic，并先为主线程创建一个 RunLoop。
        loopsDic = CFDictionaryCreateMutable();
        CFRunLoopRef mainLoop = _CFRunLoopCreate();
        CFDictionarySetValue(loopsDic, pthread_main_thread_np(), mainLoop);
    }
    
    /// 直接从 Dictionary 里获取。
    CFRunLoopRef loop = CFDictionaryGetValue(loopsDic, thread));
    
    if (!loop) {
        /// 取不到时，创建一个
        loop = _CFRunLoopCreate();
        CFDictionarySetValue(loopsDic, thread, loop);
        /// 注册一个回调，当线程销毁时，顺便也销毁其对应的 RunLoop。
        _CFSetTSD(..., thread, loop, __CFFinalizeRunLoop);
    }
    
    OSSpinLockUnLock(&loopsLock);
    return loop;
}
 
CFRunLoopRef CFRunLoopGetMain() {
    return _CFRunLoopGet(pthread_main_thread_np());
}
 
CFRunLoopRef CFRunLoopGetCurrent() {
    return _CFRunLoopGet(pthread_self());
}
```

苹果是不允许直接创建`Runloop`的，只能通过:

```
CFRunLoopRef CFRunLoopGetMain() {
    return _CFRunLoopGet(pthread_main_thread_np());
}
 
CFRunLoopRef CFRunLoopGetCurrent() {
    return _CFRunLoopGet(pthread_self());
}
```

这两个函数来获得当前或者某个线程的`Runloop`。根据上面的源码可以得出结论：

> `Runloop`创建是发生在第一次获取之前，若从未获取，则永远不会创建。 `Runloop`销毁是在线程结束前，除主线程外，所有`Runloop`只能在当前线程中获取，主线程的`Runloop`可以在任意线程中获取。

### Models in Runloop

[![runloop](https://github.com/Rabbbbbbit/iOSReview/raw/master/imgs/RunLoop_0.png?raw=true)](https://github.com/Rabbbbbbit/iOSReview/blob/master/imgs/RunLoop_0.png?raw=true)

一个`RunLoop `包含若干个 `Mode`，每个 `Mode` 又包含若干个 `Source/Timer/Observer`。每次调用 `RunLoop` 的主函数时，只能指定其中一个 `Mode`，这个`Mode`被称作 `CurrentMode`。如果需要切换 `Mode`，只能退出 `Loop`，再重新指定一个`Mode`进入。这样做主要是为了分隔开不同组的 `Source/Timer/Observer`，让其互不影响。

1. Source:

   - `Souce`是事件发生的地方。
   - `Souce`分为`Source0`与`Source1`，`Source0`只包含一个函数指针做为回调，且不能主动唤醒`Runloop`，使用时需要先手动将其标为待处理，然后手动唤醒`Runloop`；`Source1`也包含函数指针，同时还包含一个`mach_por`。它可以主动唤醒`Runloop`，用于内核与其他线程发送消息。

2. Timer

   - `Timer`是基于时间的触发器，它和 `NSTimer` 是`toll-free bridged` 的，可以混用。其包含一个时间长度和一个回调（函数指针）。当其加入到 `RunLoop` 时，`RunLoop`会注册对应的时间点，当时间点到时，`RunLoop`会被唤醒以执行那个回调。

3. Observer

   - `Obserer`是观察者，用于观察`Runloop`各种状态。它也包含函数指针，用于状态改变时回调通知外部。

   ```
   typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
       kCFRunLoopEntry         = (1UL << 0), // 即将进入Loop
       kCFRunLoopBeforeTimers  = (1UL << 1), // 即将处理 Timer
       kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source
       kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
       kCFRunLoopAfterWaiting  = (1UL << 6), // 刚从休眠中唤醒
       kCFRunLoopExit          = (1UL << 7), // 即将退出Loop
   };
   ```

上面的 `Source/Timer/Observer` 被统称为 `mode item`，一个 `item` 可以被同时加入多个 `mode`。但一个 `item` 被重复加入同一个 `mode` 时是不会有效果的。如果一个 `mode` 中一个 `item` 都没有，则 `RunLoop` 会直接退出，不进入循环。

`CFRunLoopMode` 和` CFRunLoop` 的结构大致如下：

```
struct __CFRunLoopMode {
    CFStringRef _name;            // Mode Name, 例如 @"kCFRunLoopDefaultMode"
    CFMutableSetRef _sources0;    // Set
    CFMutableSetRef _sources1;    // Set
    CFMutableArrayRef _observers; // Array
    CFMutableArrayRef _timers;    // Array
    ...
};
 
struct __CFRunLoop {
    CFMutableSetRef _commonModes;     // Set
    CFMutableSetRef _commonModeItems; // Set<Source/Observer/Timer>
    CFRunLoopModeRef _currentMode;    // Current Runloop Mode
    CFMutableSetRef _modes;           // Set
    ...
};
```

这里有个概念叫 “CommonModes”：一个` Mode` 可以将自己标记为”Common”属性（通过将其 `ModeName` 添加到` RunLoop`的 “commonModes” 中）。每当` RunLoop` 的内容发生变化时，`RunLoop` 都会自动将 `_commonModeItems` 里的 `Source/Observer/Timer` 同步到具有 “Common” 标记的所有Mode里。

应用场景举例：主线程的 `RunLoop` 里有两个预置的 `Mode：kCFRunLoopDefaultMode` 和 `UITrackingRunLoopMode`。这两个 `Mode` 都已经被标记为”Common”属性。`DefaultMode` 是 App 平时所处的状态，`TrackingRunLoopMode` 是追踪 `ScrollView` 滑动时的状态。当你创建一个 `Timer` 并加到 `DefaultMode` 时，`Timer` 会得到重复回调，但此时滑动一个`TableView`时，`RunLoop `会将 `mode` 切换为 `TrackingRunLoopMode`，这时 `Timer` 就不会被回调，并且也不会影响到滑动操作。

有时你需要一个 `Timer`，在两个 `Mode` 中都能得到回调，一种办法就是将这个 `Timer` 分别加入这两个 `Mode`。还有一种方式，就是将 `Timer` 加入到顶层的` RunLoop` 的 “commonModeItems” 中。”commonModeItems” 被 `RunLoop` 自动更新到所有具有”Common”属性的 `Mode` 里去

### Runloop 处理事件的逻辑

[![Runloop逻辑](https://github.com/Rabbbbbbit/iOSReview/raw/master/imgs/RunLoop_1.png?raw=true)](https://github.com/Rabbbbbbit/iOSReview/blob/master/imgs/RunLoop_1.png?raw=true)

```
/// 用DefaultMode启动
void CFRunLoopRun(void) {
    CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
}
 
/// 用指定的Mode启动，允许设置RunLoop超时时间
int CFRunLoopRunInMode(CFStringRef modeName, CFTimeInterval seconds, Boolean stopAfterHandle) {
    return CFRunLoopRunSpecific(CFRunLoopGetCurrent(), modeName, seconds, returnAfterSourceHandled);
}
 
/// RunLoop的实现
int CFRunLoopRunSpecific(runloop, modeName, seconds, stopAfterHandle) {
    
    /// 首先根据modeName找到对应mode
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(runloop, modeName, false);
    /// 如果mode里没有source/timer/observer, 直接返回。
    if (__CFRunLoopModeIsEmpty(currentMode)) return;
    
    /// 1. 通知 Observers: RunLoop 即将进入 loop。
    __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopEntry);
    
    /// 内部函数，进入loop
    __CFRunLoopRun(runloop, currentMode, seconds, returnAfterSourceHandled) {
        
        Boolean sourceHandledThisLoop = NO;
        int retVal = 0;
        do {
 
            /// 2. 通知 Observers: RunLoop 即将触发 Timer 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeTimers);
            /// 3. 通知 Observers: RunLoop 即将触发 Source0 (非port) 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeSources);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
            /// 4. RunLoop 触发 Source0 (非port) 回调。
            sourceHandledThisLoop = __CFRunLoopDoSources0(runloop, currentMode, stopAfterHandle);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
 
            /// 5. 如果有 Source1 (基于port) 处于 ready 状态，直接处理这个 Source1 然后跳转去处理消息。
            if (__Source0DidDispatchPortLastTime) {
                Boolean hasMsg = __CFRunLoopServiceMachPort(dispatchPort, &msg)
                if (hasMsg) goto handle_msg;
            }
            
            /// 通知 Observers: RunLoop 的线程即将进入休眠(sleep)。
            if (!sourceHandledThisLoop) {
                __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeWaiting);
            }
            
            /// 7. 调用 mach_msg 等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。
            /// • 一个基于 port 的Source 的事件。
            /// • 一个 Timer 到时间了
            /// • RunLoop 自身的超时时间到了
            /// • 被其他什么调用者手动唤醒
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort) {
                mach_msg(msg, MACH_RCV_MSG, port); // thread wait for receive msg
            }
 
            /// 8. 通知 Observers: RunLoop 的线程刚刚被唤醒了。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopAfterWaiting);
            
            /// 收到消息，处理消息。
            handle_msg:
 
            /// 9.1 如果一个 Timer 到时间了，触发这个Timer的回调。
            if (msg_is_timer) {
                __CFRunLoopDoTimers(runloop, currentMode, mach_absolute_time())
            } 
 
            /// 9.2 如果有dispatch到main_queue的block，执行block。
            else if (msg_is_dispatch) {
                __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            } 
 
            /// 9.3 如果一个 Source1 (基于port) 发出事件了，处理这个事件
            else {
                CFRunLoopSourceRef source1 = __CFRunLoopModeFindSourceForMachPort(runloop, currentMode, livePort);
                sourceHandledThisLoop = __CFRunLoopDoSource1(runloop, currentMode, source1, msg);
                if (sourceHandledThisLoop) {
                    mach_msg(reply, MACH_SEND_MSG, reply);
                }
            }
            
            /// 执行加入到Loop的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
 
            if (sourceHandledThisLoop && stopAfterHandle) {
                /// 进入loop时参数说处理完事件就返回。
                retVal = kCFRunLoopRunHandledSource;
            } else if (timeout) {
                /// 超出传入参数标记的超时时间了
                retVal = kCFRunLoopRunTimedOut;
            } else if (__CFRunLoopIsStopped(runloop)) {
                /// 被外部调用者强制停止了
                retVal = kCFRunLoopRunStopped;
            } else if (__CFRunLoopModeIsEmpty(runloop, currentMode)) {
                /// source/timer/observer一个都没有了
                retVal = kCFRunLoopRunFinished;
            }
            
            /// 如果没超时，mode里没空，loop也没被停止，那继续loop。
        } while (retVal == 0);
    }
    
    /// 10. 通知 Observers: RunLoop 即将退出。
    __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);
}
```

### Runloop 常见用法

#### Autorelease Pool

App启动后，苹果在主线程 `RunLoop` 里注册了两个 `Observer`，其回调都是 `_wrapRunLoopWithAutoreleasePoolHandler()`。

第一个 `Observer` 监视的事件是 `Entry(即将进入Loop)`，其回调内会调用 `_objc_autoreleasePoolPush()` 创建自动释放池。其 order 是-2147483647，优先级最高，保证创建释放池发生在其他所有回调之前。

第二个 `Observer` 监视了两个事件： `BeforeWaiting(准备进入休眠) 时调用_objc_autoreleasePoolPop()` 和 `_objc_autoreleasePoolPush()` 释放旧的池并创建新池；`Exit(即将退出Loop)` 时调用 `_objc_autoreleasePoolPop()` 来释放自动释放池。这个 Observer 的 order 是 2147483647，优先级最低，保证其释放池子发生在其他所有回调之后。

在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 `RunLoop` 创建好的 `AutoreleasePool` 环绕着，所以不会出现内存泄漏，开发者也不必显示创建 `Pool` 了

#### 事件响应

苹果注册了一个 `Source1` (基于 `mach port` 的) 用来接收系统事件，其回调函数为 `__IOHIDEventSystemClientQueueCallback()`。

当一个硬件事件(触摸/锁屏/摇晃等)发生后，首先由 `IOKit.framework` 生成一个 `IOHIDEvent` 事件并由 `SpringBoard` 接收。`SpringBoard `只接收按键(锁屏/静音等)，触摸，加速，接近传感器等几种` Event`，随后用 `mach port` 转发给需要的App进程。随后苹果注册的那个 `Source1` 就会触发回调，并调用 `_UIApplicationHandleEventQueue()` 进行应用内部的分发。

`_UIApplicationHandleEventQueue()` 会把 `IOHIDEvent` 处理并包装成 `UIEvent` 进行处理或分发，其中包括识别 `UIGesture`/处理屏幕旋转/发送给` UIWindow` 等。通常事件比如 `UIButton` 点击、`touchesBegin/Move/End/Cancel `事件都是在这个回调中完成的。

#### 界面更新

当在操作 UI 时，比如改变了 `Frame`、更新了 `UIView/CALayer` 的层次时，或者手动调用了 `UIView/CALayer 的 setNeedsLayout/setNeedsDisplay`方法后，这个 `UIView/CALayer` 就被标记为待处理，并被提交到一个全局的容器去。

苹果注册了一个` Observer` 监听` BeforeWaiting`(即将进入休眠) 和`Exit`(即将退出Loop) 事件，回调去执行一个很长的函数： `_ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()`。这个函数里会遍历所有待处理的`UIView/CAlayer` 以执行实际的绘制和调整，并更新 `UI` 界面。

#### 定时器

`NSTimer` 其实就是 `CFRunLoopTimerRef`，他们之间是 `toll-free bridged` 的。一个 `NSTimer` 注册到 `RunLoop` 后，`RunLoop` 会为其重复的时间点注册好事件。例如 10:00, 10:10, 10:20 这几个时间点。`RunLoop`为了节省资源，并不会在非常准确的时间点回调这个`Timer`。`Timer` 有个属性叫做 `Tolerance` (宽容度)，标示了当时间点到后，容许有多少最大误差。

如果某个时间点被错过了，例如执行了一个很长的任务，则那个时间点的回调也会跳过去，不会延后执行。就比如等公交，如果 10:10 时我忙着玩手机错过了那个点的公交，那我只能等 10:20 这一趟了。

`CADisplayLink` 是一个和屏幕刷新率一致的定时器（但实际实现原理更复杂，和 `NSTimer` 并不一样，其内部实际是操作了一个 `Source`）。如果在两次屏幕刷新之间执行了一个长任务，那其中就会有一帧被跳过去（和 `NSTimer` 相似），造成界面卡顿的感觉。在快速滑动`TableView`时，即使一帧的卡顿也会让用户有所察觉。

#### PerformSelecter

当调用` NSObject` 的 `performSelecter:afterDelay: `后，实际上其内部会创建一个 `Timer` 并添加到当前线程的 `RunLoop`中。所以如果当前线程没有 `RunLoop`，则这个方法会失效。

当调用 `performSelector:onThread:` 时，实际上其会创建一个 `Timer` 加到对应的线程去，同样的，如果对应线程没有 `RunLoop` 该方法也会失效。