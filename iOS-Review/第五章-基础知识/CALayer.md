## 1.  contents属性

你真正要赋值的类型应该是CGImageRef，它是一个指向CGImage结构的指针。UIImage有一个CGImage属性，它返回一个"CGImageRef",如果你想把这个值直接赋值给CALayer的`contents`，那你将会得到一个编译错误。因为CGImageRef并不是一个真正的Cocoa对象，而是一个Core Foundation类型。

尽管Core Foundation类型跟Cocoa对象在运行时貌似很像（被称作toll-free bridging），他们并不是类型兼容的，不过你可以通过bridged关键字转换。如果要给图层的寄宿图赋值，你可以按照以下这个方法：

```objective-c
layer.contents = (__bridge id)image.CGImage;
```





## 2. **contentGravity**

```objective-c
view.contentMode = UIViewContentModeScaleAspectFit;
```

这个方法基本和我们遇到的情况的解决方法已经接近了（你可以试一下 :) ），不过UIView大多数视觉相关的属性比如`contentMode`，对这些属性的操作其实是对对应图层的操作。

CALayer与`contentMode`对应的属性叫做`contentsGravity`，但是它是一个NSString类型，而不是像对应的UIKit部分，那里面的值是枚举。`contentsGravity`可选的常量值有以下一些：

- kCAGravityCenter
- kCAGravityTop
- kCAGravityBottom
- kCAGravityLeft
- kCAGravityRight
- kCAGravityTopLeft
- kCAGravityTopRight
- kCAGravityBottomLeft
- kCAGravityBottomRight
- kCAGravityResize
- kCAGravityResizeAspect
- kCAGravityResizeAspectFill

和`cotentMode`一样，`contentsGravity`的目的是为了决定内容在图层的边界中怎么对齐，我们将使用kCAGravityResizeAspect，它的效果等同于UIViewContentModeScaleAspectFit， 同时它还能在图层中等比例拉伸以适应图层的边界。

```objective-c
self.layerView.layer.contentsGravity = kCAGravityResizeAspect;
```