### KVO

- 原理：

  1. `isa swizzling`方法，通过`runtime`动态创建一个中间类，继承自被监听的类。
  2. 使原有类的`isa`指针指向这个中间类，同时重写改类的`Class`方法，使得该类的`Class`方法返回自己而不是`isa`的指向。
  3. 复写中间类的对应被监听属性的`setter`方法，调用添加进来的方法，然后给当前中间类的父类也就是原类的发送`setter`消息。

- 自定义KVO:

  1. 通过给`NSObject`添加分类的方法，添加新的对象方法:

  ```
      #import <Foundation/Foundation.h>
      @interface NSObject (ACoolCustom_KVO)
      /**
       *    自定义添加观察者
       *
       *    @param oberserver 观察者
       *    @param keyPath    要观察的属性
       *    @param block      自定义回调
       */
      - (void)zl_addOberver:(id)oberserver
                forKeyPath:(NSString *)keyPath
                     block:(void(^)(id oberveredObject,NSString *keyPath,id newValue,id oldValue))block;
  ```

  1. 动态创建中间类，	更改原有类的`isa`指向，同时重写中间类的`Class`方法:

  ```
   Class originalClass = object_getClass(self);
   //创建中间类 并使其继承被监听的类
   Class kvoClass = objc_allocateClassPair(originalClass, kvoClassName.UTF8String, 0);
   //向runtime动态注册类
   objc_registerClassPair(kvoClass);
   object_setClass(self, kvoClass);
   //替换被监听对象的class方法...
   //原始类的class方法的实现
   //原始类的class方法的参数等信息
   Method clazzMethod = class_getInstanceMethod(originalClass, @selector(class));
   const char *types = method_getTypeEncoding(clazzMethod);
   class_addMethod(kvoClass, @selector(class), (IMP)new_class, types);
  ```

  1. 利用`runtime`给对象动态增加关联属性保存外部传进来的回调`block`:

  ```
   objc_setAssociatedObject(self, kObjectPropertyKey ,block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  ```

  1. 利用`runtime`替换中间类的`setter`方法，在新的方法中，调用`block`后再向父类发送原消息:

  ```
   // 利用函数指针强制转换
   void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
   // 给父类 发送原消息
   objc_msgSendSuperCasted(&superclass, _cmd, newValue);
   // 调用block
   ZLObservingBlock block = objc_getAssociatedObject(self, kObjectPropertyKey);
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       block(self, nil, newValue);
   });
  ```

## 