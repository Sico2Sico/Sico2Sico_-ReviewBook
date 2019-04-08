

```objc
-[ViewController initWithCoder:]
-[ViewController awakeFromNib]
-[ViewController loadView]
-[ViewController viewDidLoad]
-[ViewController viewWillAppear:]
-[ViewController viewWillLayoutSubviews]
-[ViewController viewDidLayoutSubviews]
-[ViewController viewDidAppear:]
-[ViewController viewWillDisappear:]
-[ViewController viewDidDisappear:]
-[ViewController dealloc]
-[ViewController didReceiveMemoryWarning]
```



#### UIViewController的生命周期及iOS程序执行顺序

1.当一个视图控制器被创建，并在屏幕上显示的时候。代码的执行顺序

```
1. alloc                  创建对象，分配空间
2. init (initWithNibName) 初始化对象，初始化数据
3. loadView               从nib载入视图通常这一步不需要去干涉。除非你没有使用xib文件创建视图
4. viewDidLoad            载入完成，可以进行自定义数据以及动态创建其他控件
5、viewWillAppear         视图将出现在屏幕之前，马上这个视图就会被展现在屏幕上了
6、viewDidAppear          视图已在屏幕上渲染完成
```

2.当一个视图被移除屏幕并且销毁的时候的执行顺序

```
1、viewWillDisappear            视图将被从屏幕上移除之前执行
2、viewDidDisappear             视图已经被从屏幕上移除，用户看不到这个视图了
3、dealloc                                 视图被销毁，此处需要对你在init和viewDidLoad中创建的对象进行释放
```

下面介绍下APP在运行时的调用顺序。

1）- (void)viewDidLoad；

```
  一个APP在载入时会先通过调用loadView方法或者载入IB中创建的初始界面的方法，将视图载入到内存中。
然后会调用viewDidLoad方法来进行进一步的设置。通常，我们对于各种初始数据的载入，初始设定等很多内容
，都会在这个方法中实现，所以这个方法是一个很常用，很重要的方法。

但是要注意，这个方法只会在APP刚开始加载的时候调用一次，以后都不会再调用它了，所以只能用来做初始设置。
```

1. - (void)viewDidUnload;

     在内存足够的情况下，软件的视图通常会一直保存在内存中，但是如果内存不够，一些没有正在显示的viewcontroller就会收到内存不够的警告，然后就会释放自己拥有的视图，以达到释放内存的目的。但是系统只会释放内存，并不会释放对象的所有权，所以通常我们需要在这里将不需要在内存中保留的对象释放所有权，也就是将其指针置为nil。

     这个方法通常并不会在视图变换的时候被调用，而只会在系统退出或者收到内存警告的时候才会被调用。但是由于我们需要保证在收到内存警告的时候能够对其作出反应，所以这个方法通常我们都需要去实现。

     另外，即使在设备上按了Home键之后，系统也不一定会调用这个方法，因为IOS4之后，系统允许将APP在后台挂起，并将其继续滞留在内存中，因此，viewcontroller并不会调用这个方法来清除内存。

3）- (void)viewWillAppear:(BOOL)animated;

```
  系统在载入所有数据后，将会在屏幕上显示视图，这时会先调用这个方法。通常我们会利用这个方法，对即将显示的视图做进一步的设置。例如，我们可以利用这个方法来设置设备不同方向时该如何显示。

  另外一方面，当APP有多个视图时，在视图间切换时，并不会再次载入viewDidLoad方法，所以如果在调入视图时，需要对数据做更新，就只能在这个方法内实现了。所以这个方法也非常常用。
```

1. - (void)viewDidAppear:(BOOL)animated；

     有时候，由于一些特殊的原因，我们不能在viewWillApper方法里，对视图进行更新。那么可以重写这个方法，在这里对正在显示的视图进行进一步的设置。

2. - (void)viewWillDisappear:(BOOL)animated；

     在视图变换时，当前视图在即将被移除、或者被覆盖时，会调用这个方法进行一些善后的处理和设置。

     由于在IOS4之后，系统允许将APP在后台挂起，所以在按了Home键之后，系统并不会调用这个方法，因为就这个APP本身而言，APP显示的view，仍是挂起时候的view，所以并不会调用这个方法。

3. - (void)viewDidDisappear:(BOOL)animated；

     我们可以重写这个方法，对已经消失，或者被覆盖，或者已经隐藏了的视图做一些其他操作。

注意点：`viewWillDisappear和viewDidDisappear方法当前视图在即将被移除、或者被覆盖时`这个地方开发的时候吃过亏。

#### 开发中需要注意的知识点

1.IOS 开发 loadView 和 viewDidLoad 的区别

```
viewDidLoad 此方法只有当view从nib文件初始化的时候才被调用。

loadView 此方法在控制器的view为nil的时候被调用。此方法用于以编程的方式创建view的时候用到。 如：
- ( void ) loadView {
    UIView *view = [ [ UIView alloc] initWithFrame:[ UIScreen
mainScreen] .applicationFrame] ;
    [ view setBackgroundColor:_color] ;
    self.view = view;
    [ view release] ;
}
```

你在控制器中实现了loadView方法，那么你可能会在应用运行的某个时候被内存管理控制调用。 如果设备内存不足的时候， view 控制器会收到didReceiveMemoryWarning的消息。 默认的实现是检查当前控制器的view是否在使用。如果它的view不在当前正在使用的view hierarchy里面，且你的控制器实现了loadView方法，那么这个view将被release, loadView方法将被再次调用来创建一个新的view。

#### 就是各个子控制器在切换过程中他们的生命周期会发什么变化，

1.其实我们在前面一篇文章中已经介绍了控制器的生命周期方法了：

```
1> view初始化完毕后，就会调用控制器的viewDidLoad方法
2> view初始化完毕后，就会把这个根控制器的view添加到窗口中
3> 当view即将被添加到窗口中时，就会调用控制器的viewWillAppear:方法
4> 当view已经被添加到窗口中时，就会调用控制器的viewDidAppear:方法
5> 如果控制器的view即将从窗口中移除时，就会调用控制器的viewWillDisappear:方法
6> 如果控制器的view已经从窗口中移除时，就会调用控制器的viewDidDisappear:方法
7> 如果控制器接收到内存警告的时候，就会调用控制器的didReceiveMemoryWarning方法
```

didReceiveMemoryWarning方法的默认实现是：如果控制器的view没有显示在窗口中，也就是说controller.view.superview为nil时，系统就会销毁控制器的view.

```
8> 销毁完毕后会调用控制器的viewDidUnload方法
9> 如果控制器的view以前因为内存警告被销毁过，现在需要再次访问控制器的view时，会重复前面的步骤初始化view
```

2.从生命周期上可以看到，和上面的切换控制器一样，各个子控制器都是采用懒加载机制，用到展示的采取进行加载，以后只会调用`viewDidDisappear`和`viewDidAppear`等方法了。

#### 视图控制器总结

第一个：切换控制器UITabBarController

这个控制器一般用于首页的切换tab功能，在使用的过程中，需要使用一个子控制器数组存放所有的子控制器。然后每个子控制器之间的`切换操作有对应的回调代理方法`：

```
1.监听到切换到哪个子控制器
2.可以指定返回值来设置哪个子控制器不可切换选择
```

在这个过程中每个子控制器的生命周期方法是：

```
1.所有子控制器都是采用懒加载机制，需要展示的时候才去加载
2.如果已经加载过得子控制器下次再次切换的时候只会调用viewDidAppear和viewDidDisapper等方法
```

最后就是有重要属性：

```
对于每个子控制器都有一个属性：tabBarController 可以获取到当前的切换控制器对象。
```

第二个：导航控制器UINavigationController

这个控制器用的比较多，一般用于程序的多个子控制器之间跳转，这个控制器有一个特殊的地方就是他采用的是栈结构来管理子控制器。那么对于跳转就是入栈操作，返回就是出栈操作。操作也是非常简单的。同样的这里我们在操作的时候也是有两个件事需要知道:
 `一个是各个子控制器在跳转的时候的回调代理方法：`

```
1. 监听当前栈顶变化的回调代理方法
还有一个就是需要知道每个子控制器的生命周期方法变化：
1.所有子控制器都是采用懒加载机制，需要展示的时候才去加载。
//重点：
2.如果已经加载过得子控制器下次再次切换的时候只会调用
viewDidAppear和viewDidDisapper等方法
```



作者：晓飞76

链接：https://www.jianshu.com/p/484d8f69c7ab

来源：简书

简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。







## LoadView 作用以及使用LoadView的注意点?

- 控制器调用loadView方法创建控制器的view.它的默认做法是:
- 先去判断当前控制器是不是从StoryBoard当中加载的,如果是,那么它就会从StoryBoard当中加载控制器的View.
- 如果不是从StoryBoard当中加载的, 那么它还会判断是不是从Xib当中创建的控制器.如果是,那么它就会从xib加载控制器的View.
- 如果也不是从Xib加载的控制器.那么它就会创建一个空的UIView.设为当前控制器的View.
  - 注意点:
    - 一旦重写了loadView,表示需要自己创建控制器的View.
    - 如果控制器的View还没有赋值,就不能调用控制器View的get方法.会造成死循环. 因为控制器View的get方法底层会调用loadView方法.







