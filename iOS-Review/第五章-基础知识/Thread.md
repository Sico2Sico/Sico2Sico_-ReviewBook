### 12.进程和线程的区别？同步异步的区别？并行和并发的区别？

##### 1.进程和线程的区别？

> 进程:进程是指在系统中正在运行的一个应用程序。每个进程之间是独立的，每个进程均运行在其专用且受保护的内存空间内。
>
> 线程：线程是进程的基本执行单元，一个进程的所有任务都在线程中执行。1个进程要想执行任务，必须得有线程，例如默认就是主线程。

##### 2.同步异步的区别？

> 同步函数：不具备开线程的能力，只能串行按顺序执行任务
>
> 异步函数：具备开线程的能力，但并不是只要是异步函数就会开线程。

##### 3.并行和并发的区别？

> 并行：并行即同时执行。比如同时开启3条线程分别执行三个不同人物，这些任务执行时同时进行的。
>
> 并发：并发指在同一时间里，CPU只能处理1条线程，只有1条线程在工作（执行）。多线程并发（同时）执行，其实是CPU快速地在多条线程之间调度（切换），如果CPU调度线程的时间足够快，就造成了多线程并发执行的假象。

### 13.线程间通信？

##### 1.NSThread

```
    // 第一种方式。
    [self performSelectorOnMainThread:@selector(showImage:) withObject:image waitUntilDone:YES];
    
    // 第二种方式
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
```

##### 2.GCD

```
   //0.获取一个全局的队列
   dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
   
   //1.先开启一个线程，把下载图片的操作放在子线程中处理
   dispatch_async(queue, ^{
      //2.下载图片
       NSURL *url = [NSURL URLWithString:@"http://h.hiphotos.baidu.com/zhidao/pic/item/6a63f6246b600c3320b14bb3184c510fd8f9a185.jpg"];
       NSData *data = [NSData dataWithContentsOfURL:url];
       UIImage *image = [UIImage imageWithData:data];
       NSLog(@"下载操作所在的线程--%@",[NSThread currentThread]);
       //3.回到主线程刷新UI
       dispatch_async(dispatch_get_main_queue(), ^{
          self.imageView.image = image;
          //打印查看当前线程
           NSLog(@"刷新UI---%@",[NSThread currentThread]);
       });
   });
   
   // GCD通过嵌套就可以实现线程间的通信。
```

##### 3.NSOperationQueue

```
    //1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];

    //2.使用简便方法封装操作并添加到队列中
    [queue addOperationWithBlock:^{

        //3.在该block中下载图片
        NSURL *url = [NSURL URLWithString:@"http://news.51sheyuan.com/uploads/allimg/111001/133442IB-2.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        NSLog(@"下载图片操作--%@",[NSThread currentThread]);

        //4.回到主线程刷新UI
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.imageView.image = image;
            NSLog(@"刷新UI操作---%@",[NSThread currentThread]);
        }];
    }];
```

### 14.GCD的一些常用的函数？

##### 1.栅栏函数（控制任务的执行顺序）

```
    dispatch_barrier_async(queue, ^{
    
        NSLog(@"barrier");
    });
```

##### 2.延迟执行（延迟·控制在哪个线程执行）

```
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"---%@",[NSThread currentThread]);
    });
```

##### 3.一次性代码

```
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{

       NSLog(@"-----");
   });
```

##### 4.快速迭代（开多个线程并发完成迭代操作）

```
    dispatch_apply(subpaths.count, queue, ^(size_t index) {
    });
```

##### 5.队列组（同栅栏函数）

```
    dispatch_group_t group = dispatch_group_create();
    // 队列组中的任务执行完毕之后，执行该函数
    dispatch_group_notify(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);

    // 进入群组和离开群组
    dispatch_group_enter(group);//执行该函数后，后面异步执行的block会被gruop监听
    dispatch_group_leave(group);//异步block中，所有的任务都执行完毕，最后离开群组
    //注意：dispatch_group_enter|dispatch_group_leave必须成对使用
```

##### 6.信号量（并发编程中很有用）







## 多线程的 `并行` 和 `并发` 有什么区别？

并行：充分利用计算机的多核，在多个线程上同步进行 并发：在一条线程上通过快速切换，让人感觉在同步进行