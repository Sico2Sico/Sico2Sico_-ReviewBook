# __attribute__cleanup_defer


* ###__attribut__(cleanup(...))

  ## 基本用法

  `__attribute__((cleanup(...)))`，用于修饰一个变量，**在它的作用域结束时可以自动执行一个指定的方法**，如：

  ```
  // 指定一个cleanup方法，注意入参是所修饰变量的地址，类型要一样
  // 对于指向objc对象的指针(id *)，如果不强制声明__strong默认是__autoreleasing，造成类型不匹配
  static void stringCleanUp(__strong NSString **string) {
      NSLog(@"%@", *string);
  }
  // 在某个方法中：
  {
      __strong NSString *string __attribute__((cleanup(stringCleanUp))) = @"sunnyxx";
  } // 当运行到这个作用域结束时，自动调用stringCleanUp
  ```

  所谓作用域结束，包括大括号结束、return、goto、break、exception等各种情况。
  当然，可以修饰的变量不止NSString，`自定义Class`或`基本类型`都是可以的：

  ```
  // 自定义的Class
  static void sarkCleanUp(__strong Sark **sark) {
      NSLog(@"%@", *sark);
  }
  __strong Sark *sark __attribute__((cleanup(sarkCleanUp))) = [Sark new];
  // 基本类型
  static void intCleanUp(NSInteger *integer) {
      NSLog(@"%d", *integer);
  }
  NSInteger integer __attribute__((cleanup(intCleanUp))) = 1;
  ```

  假如一个作用域内有若干个cleanup的变量，他们的调用顺序是`先入后出`的栈式顺序；
  而且，cleanup是先于这个对象的`dealloc`调用的。

  ## 进阶用法

  既然`__attribute__((cleanup(...)))`可以用来修饰变量，`block`当然也是其中之一，写一个block的cleanup函数非常有趣：

  ```
  // void(^block)(void)的指针是void(^*block)(void)
  static void blockCleanUp(__strong void(^*block)(void)) {
      (*block)();
  }
  ```

  于是在一个作用域里声明一个block：

  ```
  {
     // 加了个`unused`的attribute用来消除`unused variable`的warning
      __strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^{
          NSLog(@"I'm dying...");
      };
  } // 这里输出"I'm dying..."
  ```

  这里不得不提万能的`Reactive Cocoa`中神奇的`@onExit`方法，其实正是上面的写法，简单定义个宏：

  ```
  #define onExit\
      __strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^
  ```

  用这个宏就能将一段写在前面的代码最后执行： 

  ```
  {
      onExit {
          NSLog(@"yo");
      };
  } // Log "yo"
  ```

  这样的写法可以将成对出现的代码写在一起，比如说一个lock：

  ```
  NSRecursiveLock *aLock = [[NSRecursiveLock alloc] init];
  [aLock lock];
  // 这里
  //     有
  //        100多万行
  [aLock unlock]; // 看到这儿的时候早忘了和哪个lock对应着了
  ```

  用了`onExit`之后，代码更集中了：

  ```
  NSRecursiveLock *aLock = [[NSRecursiveLock alloc] init];
  [aLock lock];
  onExit {
      [aLock unlock]; // 妈妈再也不用担心我忘写后半段了
  };
  // 这里
  //    爱多少行
  //           就多少行
  ```

* ## defer  (Swift)

在swift中也有类似的用法
其实swift中也类似的用法 [错误处理（Error Handling）](https://link.jianshu.com/?t=http://wiki.jikexueyuan.com/project/swift/chapter2/18_Error_Handling.html)

> 指定清理操作
> 可以使用defer语句在即将离开当前代码块时执行一系列语句。该语句让你能执行一些必要的清理工作，不管是以何种方式离开当前代码块的——无论是由于抛出错误而离开，还是由于诸如return或者break的语句。例如，你可以用defer语句来确保文件描述符得以关闭，以及手动分配的内存得以释放。

> defer语句将代码的执行延迟到当前的作用域退出之前。该语句由defer关键字和要被延迟执行的语句组成。延迟执行的语句不能包含任何控制转移语句，例如break或是return语句，或是抛出一个错误。延迟执行的操作会按照它们被指定时的顺序的相反顺序执行——也就是说，第一条defer语句中的代码会在第二条defer语句中的代码被执行之后才执行，以此类推。

> ```
> func processFile(filename: String) throws {
>     if exists(filename) {
>         let file = open(filename)
>         defer {
>             close(file)
>         }
>         while let line = try file.readline() {
>             // 处理文件。
>         }
>         // close(file) 会在这里被调用，即作用域的最后。
>     }
> }
> ```

