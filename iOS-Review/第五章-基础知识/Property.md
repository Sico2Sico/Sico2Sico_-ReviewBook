

## 一、对象内存模型

- isa指针的作用

- 对象的isa指向类对象，类对象的isa指向元类，元类的isa指向根元类，根元类的isa指向自己。

- 类对象的`superClass`指针指向父类对象，直到指向根类对象，根类对象的`superClass`指向`nil`，元类也如此，直到根元类，根元类的`superClass`指向根类对象

- 对象的内存分布

  - 对象的变量表

  - 对象大小

  - 对象方法表

  - cache?

  - 协议

  - char *name?

    ```
     struct objc_class { 
         Class isa  OBJC_ISA_AVAILABILITY;
     
     #if !__OBJC2__
         Class super_class                                        OBJC2_UNAVAILABLE;
         const char *name                                         OBJC2_UNAVAILABLE;
         long version                                             OBJC2_UNAVAILABLE;
         long info                                                OBJC2_UNAVAILABLE;
         long instance_size                                       OBJC2_UNAVAILABLE;
         struct objc_ivar_list *ivars                             OBJC2_UNAVAILABLE;
         struct objc_method_list **methodLists                    OBJC2_UNAVAILABLE;
         struct objc_cache *cache                                 OBJC2_UNAVAILABLE;
         struct objc_protocol_list *protocols                     OBJC2_UNAVAILABLE;
     #endif
     
     } OBJC2_UNAVAILABLE;
     /* Use `Class` instead of `struct objc_class *` */
    ```





属性知识:

Property关键字 ： property =  _ivar + get + set

	 * atomic 原子  nonatomic
	 * strong  weak 
	 * readwrite readonly 
	 * assign unsafe_unretained 
	 * copy
	 * retain 
	 * release
	 * nonnul 非空
	 * null_resettable
	 * unllable 可空


@ synthesize  

```objective-c
该关键字会在编译期间自动生成set和get方法。当自定义了set或get方法时，会自动覆盖编译器生产的方法。
```

@dynamic

```objective-c
该关键字不会自动生成set和get方法，同时避免了编译警告，但是需要我们自己去实现set和get方法，一般在动态绑定或某些需要特别定义读写方法时使用该关键字。
```





##### 属性是怎么实现的,反编译相关的代码,大致生成了五个东西

```
1. OBJC_IVAR_$类名$属性名称 ：该属性的“偏移量” (offset)，这个偏移量是“硬编码” (hardcode)，表示该变量距离存放对象的内存区域的起始地址有多远。
2. setter 与 getter 方法对应的实现函数
3. ivar_list ：成员变量列表
4. method_list ：方法列表
5. prop_list ：属性列表
也就是说我们每次在增加一个属性,系统都会在 ivar_list 中添加一个成员变量的描述,
在 method_list 中增加 setter 与 getter 方法的描述,
在属性列表中增加一个属性的描述,
然后计算该属性在对象中的偏移量,
然后给出 setter 与 getter 方法对应的实现,
在 setter 方法中从偏移量的位置开始赋值,
在 getter 方法中从偏移量开始取值,
为了能够读取正确字节数,
系统对象偏移量的指针类型进行了类型强转.
```





## 04-@property

> @property 的本质是什么？ivar、getter、setter 是如何生成并添加到这个类中的

@property 的本质.

```objc
@property = ivar + getter + setter;
```

下面解释下：

> “属性” (property)有两大概念：ivar（实例变量）、存取方法（access method ＝ getter + setter）。

> “属性” (property)作为 Objective-C 的一项特性，主要的作用就在于封装对象中的数据。 Objective-C 对象通常会把其所需要的数据保存为各种实例变量。实例变量一般通过“存取方法”(access method)来访问。其中，“获取方法” (getter)用于读取变量值，而“设置方法” (setter)用于写入变量值。这个概念已经定型，并且经由“属性”这一特性而成为 Objective-C 2.0 的一部分。 而在正规的 Objective-C 编码风格中，存取方法有着严格的命名规范。 正因为有了这种严格的命名规范，所以 Objective-C 这门语言才能根据名称自动创建出存取方法。其实也可以把属性当做一种关键字，其表示:

编译器会自动写出一套存取方法，用以访问给定类型中具有给定名称的变量。 所以你也可以这么说：

```objc
@property = getter + setter;
```

例如下面这个类：

```objc
@interface Person : NSObject
@property NSString *firstName;
@property NSString *lastName;
@end
```

上述代码写出来的类与下面这种写法等效：

```objc
@interface Person : NSObject
- (NSString *)firstName;
- (void)setFirstName:(NSString *)firstName;
- (NSString *)lastName;
- (void)setLastName:(NSString *)lastName;
@end
```

`property`在`runtime`中是`objc_property_t`定义如下:

```objc
typedef struct objc_property *objc_property_t;
```

而`objc_property`是一个结构体，包括`name`和`attributes`，定义如下：

```objc
struct property_t {
    const char *name;
    const char *attributes;
};
```

而`attributes`本质是`objc_property_attribute_t`，定义了`property`的一些属性，定义如下：

```objc
/// Defines a property attribute
typedef struct {
    const char *name;           /**< The name of the attribute */
    const char *value;          /**< The value of the attribute (usually empty) */
} objc_property_attribute_t;
```

> 而attributes的具体内容是什么呢？其实，包括：类型，原子性，内存语义和对应的实例变量。

例如：我们定义一个`string`的`property`

```objc
@property (nonatomic, copy) NSString *string;
```

通过 `property_getAttributes(property)`获取到`attributes`并打印出来之后的结果为

```objc
T@"NSString",C,N,V_string
```

其中`T`就代表类型，可参阅`Type Encodings`，`C`就代表`Copy`，`N`代表`nonatomic`，`V`就代表对于的实例变量。

> ivar、getter、setter 是如何生成并添加到这个类中的?

**“自动合成”( autosynthesis)**

> 完成属性定义后，编译器会自动编写访问这些属性所需的方法，此过程叫做“自动合成”(autosynthesis)。需要强调的是，这个过程由编译 器在编译期执行，所以编辑器里看不到这些“合成方法”(synthesized method)的源代码。除了生成方法代码 getter、setter 之外，编译器还要自动向类中添加适当类型的实例变量，并且在属性名前面加下划线，以此作为实例变量的名字。在前例中，会生成两个实例变量，其名称分别为 _firstName 与 _lastName。也可以在类的实现代码里通过@synthesize 语法来指定实例变量的名字.

```objc
@implementation Person
@synthesize firstName = _myFirstName;
@synthesize lastName = _myLastName;
@end
```

**我为了搞清属性是怎么实现的,曾经反编译过相关的代码,他大致生成了五个东西**

```objc
1. OBJC_IVAR_$类名$属性名称 ：该属性的“偏移量” (offset)，这个偏移量是“硬编码” (hardcode)，表示该变量距离存放对象的内存区域的起始地址有多远。
2. setter 与 getter 方法对应的实现函数
3. ivar_list ：成员变量列表
4. method_list ：方法列表
5. prop_list ：属性列表
也就是说我们每次在增加一个属性,系统都会在 ivar_list 中添加一个成员变量的描述,在 method_list 中增加 setter 与 getter 方法的描述,在属性列表中增加一个属性的描述,然后计算该属性在对象中的偏移量,然后给出 setter 与 getter 方法对应的实现,在 setter 方法中从偏移量的位置开始赋值,在 getter 方法中从偏移量开始取值,为了能够读取正确字节数,系统对象偏移量的指针类型进行了类型强转.
```



**属性可以拥有的特质分为四类:**

- 原子性--- nonatomic 特质,在默认情况下，由编译器合成的方法会通过锁定机制确保其原子性(atomicity)。如果属性具备 nonatomic 特质，则不使用自旋锁。请注意，尽管没有名为“atomic”的特质(如果某属性不具备 nonatomic 特质，那它就是“原子的” ( atomic) )，但是仍然可以在属性特质中写明这一点，编译器不会报错。若是自己定义存取方法，那么就应该遵从与属性特质相符的原子性。
- 读/写权限---readwrite(读写)、readonly (只读)
- 内存管理语义---assign、strong、 weak、unsafe_unretained、copy
- 方法名---getter=<name> 、setter=<name>

**getter=<name>的样式：**

```objc
@property (nonatomic, getter=isOn) BOOL on;
     
(`setter=`这种不常用，也不推荐使用。故不在这里给出写法。）
```

**setter=<name>一般用在特殊的情境下，比如**：

> 在数据反序列化、转模型的过程中，服务器返回的字段如果以 init 开头，所以你需要定义一个 init 开头的属性，但默认生成的 setter 与 getter 方法也会以 init 开头，而编译器会把所有以 init 开头的方法当成初始化方法，而初始化方法只能返回 self 类型，因此编译器会报错。

**这时你就可以使用下面的方式来避免编译器报错：**

```objc
@property(nonatomic, strong, getter=p_initBy, setter=setP_initBy:)NSString *initBy;
```

**另外也可以用关键字进行特殊说明，来避免编译器报错**：

```objc
@property(nonatomic, readwrite, copy, null_resettable) NSString *initBy;

- (NSString *)initBy __attribute__((objc_method_family(none)));

1. 不常用的：nonnull,null_resettable,nullable

注意：很多人会认为如果属性具备 nonatomic 特质，则不使用 “同步锁”。其实在属性设置方法中使用的是自旋锁，自旋锁相关代码如下：

static inline void reallySetProperty(id self, SEL _cmd, id newValue, ptrdiff_t offset, bool atomic, bool copy, bool mutableCopy)
{
    if (offset == 0) 
    {
        object_setClass(self, newValue);
        return;
    }

    id oldValue;
    id *slot = (id*) ((char*)self + offset);

    if (copy) 
    {
        newValue = [newValue copyWithZone:nil];
    } 
    else if (mutableCopy) 
    {
        newValue = [newValue mutableCopyWithZone:nil];
    } 
    else 
    {
        if (*slot == newValue) return;
        newValue = objc_retain(newValue);
    }

    if (!atomic) 
    {
        oldValue = *slot;
        *slot = newValue;
    } 
    else 
    {
        spinlock_t& slotlock = PropertyLocks[slot];
        slotlock.lock();
        oldValue = *slot;
        *slot = newValue;        
        slotlock.unlock();
    }

    objc_release(oldValue);
}

void objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id newValue, BOOL atomic, signed char shouldCopy) 
{
    bool copy = (shouldCopy && shouldCopy != MUTABLE_COPY);
    bool mutableCopy = (shouldCopy == MUTABLE_COPY);
    reallySetProperty(self, _cmd, newValue, offset, atomic, copy, mutableCopy);
}
```

