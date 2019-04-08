# 3.2 msg_send

* msg_send 
  向一个objc对象（或Class）发消息，实际上就是沿着它的isa指针寻找真正函数地址，所以只要一个对象满足下面的结构，就可以对它发送消息：

  ```objective-c
  struct objc_object {
      Class isa;
  } *id;
  ```
也就是熟知的id类型，objc在语言层面先天就支持了这个基本的鸭子类型，我们可以将任意一个对象强转为id类型从而向它发送消息，就算它并不能响应这个消息，编译器也无从知晓。
正如这篇文章中对objc对象的简短定义：The best definition for a Smalltalk or Objective-C "object" is "something that can respond to messages. object并非一定是某个特定类型的实例，只要它能响应需要的消息就可以了



* 发消息给一个对象

  向object发送消息时，Runtime库会根据object的isa指针找到这个实例object所属于的类，然后在类的方法列表以及父类方法列表寻找对应的方法运行。id是一个objc_object结构类型的指针，这个类型的对象能够转换成任何一种对象；

* objc_object与id

  objc_object是一个类的实例结构体，objc/objc.h中objc_object是一个类的实例结构体定义如下：

  ```
  struct objc_object {
  Class isa OBJC_ISA_AVAILABILITY;
  };
  
  typedef struct objc_object *id;
  ```



* Meta Class

    meta class是一个类对象的类，当向对象发消息，runtime会在这个对象所属类方法列表中查找发送消息对应的方法，但当向类发送消息时，runtime就会在这个类的meta class方法列表里查找。所有的meta class，包括Root class，Superclass，Subclass的isa都指向Root class的meta class，这样能够形成一个闭环。