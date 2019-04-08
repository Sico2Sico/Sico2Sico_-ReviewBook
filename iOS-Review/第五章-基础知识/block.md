# iOS代码块Block

### 概述

代码块Block是苹果在iOS4开始引入的对C语言的扩展,用来实现匿名函数的特性,Block是一种特殊的数据类型,其可以正常定义变量、作为参数、作为返回值,特殊地,Block还可以保存一段代码,在需要的时候调用,目前Block已经广泛应用于iOS开发中,常用于GCD、动画、排序及各类回调

> 注: Block的声明与赋值只是保存了一段代码段,必须调用才能执行内部代码

### Block变量的声明、赋值与调用

##### Block变量的声明

```
Block变量的声明格式为: 返回值类型(^Block名字)(参数列表);

// 声明一个无返回值,参数为两个字符串对象,叫做aBlock的Block
void(^aBlock)(NSString *x, NSString *y);

// 形参变量名称可以省略,只留有变量类型即可
void(^aBlock)(NSString *, NSString *);
```

> 注: ^被称作"脱字符"

##### Block变量的赋值

```
Block变量的赋值格式为: Block变量 = ^(参数列表){函数体};

aBlock = ^(NSString *x, NSString *y){
    NSLog(@"%@ love %@", x, y);
};
```

> 注: Block变量的赋值格式可以是: Block变量 = ^返回值类型(参数列表){函数体};,不过通常情况下都将返回值类型省略,因为编译器可以从存储代码块的变量中确定返回值的类型

##### 声明Block变量的同时进行赋值

```
int(^myBlock)(int) = ^(int num){
    return num * 7;
};

// 如果没有参数列表,在赋值时参数列表可以省略
void(^aVoidBlock)() = ^{
    NSLog(@"I am a aVoidBlock");
};
```

##### Block变量的调用

```
// 调用后控制台输出"Li Lei love Han Meimei"
aBlock(@"Li Lei",@"Han Meimei");

// 调用后控制台输出"result = 63"
NSLog(@"result = %d", myBlock(9));

// 调用后控制台输出"I am a aVoidBlock"
aVoidBlock();
```

### 使用typedef定义Block类型

在实际使用Block的过程中,我们可能需要重复地声明多个相同返回值相同参数列表的Block变量,如果总是重复地编写一长串代码来声明变量会非常繁琐,所以我们可以使用typedef来定义Block类型

```
// 定义一种无返回值无参数列表的Block类型
typedef void(^SayHello)();

// 我们可以像OC中声明变量一样使用Block类型SayHello来声明变量
SayHello hello = ^(){
    NSLog(@"hello");
};

// 调用后控制台输出"hello"
hello();
```

### Block作为函数参数

##### Block作为C函数参数

```
// 1.定义一个形参为Block的C函数
void useBlockForC(int(^aBlock)(int, int))
{
    NSLog(@"result = %d", aBlock(300,200));
}

// 2.声明并赋值定义一个Block变量
int(^addBlock)(int, int) = ^(int x, int y){
    return x+y;
};

// 3.以Block作为函数参数,把Block像对象一样传递
useBlockForC(addBlock);

// 将第2点和第3点合并一起,以内联定义的Block作为函数参数
useBlockForC(^(int x, int y) {
    return x+y;
});
```

##### Block作为OC函数参数

```
// 1.定义一个形参为Block的OC函数
- (void)useBlockForOC:(int(^)(int, int))aBlock
{
    NSLog(@"result = %d", aBlock(300,200));
}

// 2.声明并赋值定义一个Block变量
int(^addBlock)(int, int) = ^(int x, int y){
    return x+y;
};

// 3.以Block作为函数参数,把Block像对象一样传递
[self useBlockForOC:addBlock];

// 将第2点和第3点合并一起,以内联定义的Block作为函数参数
[self useBlockForOC:^(int x, int y){
    return x+y;
}];
```

##### 使用typedef简化Block

```
// 1.使用typedef定义Block类型
typedef int(^MyBlock)(int, int);

// 2.定义一个形参为Block的OC函数
- (void)useBlockForOC:(MyBlock)aBlock
{
    NSLog(@"result = %d", aBlock(300,200));
}

// 3.声明并赋值定义一个Block变量
MyBlock addBlock = ^(int x, int y){
    return x+y;
};

// 4.以Block作为函数参数,把Block像对象一样传递
[self useBlockForOC:addBlock];

// 将第3点和第4点合并一起,以内联定义的Block作为函数参数
[self useBlockForOC:^(int x, int y){
    return x+y;
}];
```

### Block内访问局部变量

- 在Block中可以访问局部变量

```
// 声明局部变量global
int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 100"
myBlock();
```

- 在声明Block之后、调用Block之前对局部变量进行修改,在调用Block时局部变量值是修改之前的旧值

```
// 声明局部变量global
int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
global = 101;
// 调用后控制台输出"global = 100"
myBlock();
```

- 在Block中不可以直接修改局部变量

```
// 声明局部变量global
int global = 100;

void(^myBlock)() = ^{
    global ++; // 这句报错
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 100"
myBlock();
```

> 注: 原理解析,通过clang命令将OC转为C++代码来查看一下Block底层实现,clang命令使用方式为终端使用cd定位到main.m文件所在文件夹,然后利用clang -rewrite-objc main.m将OC转为C++,成功后在main.m同目录下会生成一个main.cpp文件

```
// OC代码如下
void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};

// 转为C++代码如下
void(*myBlock)() = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, global));

// 将变量类型精简之后C++代码如下,我们发现Block变量实际上就是一个指向结构体__main_block_impl_0的指针,而结构体的第三个元素是局部变量global的值
void(*myBlock)() = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, global);

// 我们看一下结构体__main_block_impl_0的代码
struct __main_block_impl_0 {
struct __block_impl impl;
struct __main_block_desc_0* Desc;
int global;
__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _global, int flags=0) : global(_global) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 在OC中调用Block的方法转为C++代码如下,实际上是指向结构体的指针myBlock访问其FuncPtr元素,在定义Block时为FuncPtr元素传进去的__main_block_func_0方法
((void (*)(__block_impl *))((__block_impl *)myBlock)->FuncPtr)((__block_impl *)myBlock);

// __main_block_func_0方法代码如下,由此可见NSLog的global正是定义Block时为结构体传进去的局部变量global的值
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    int global = __cself->global; // bound by copy
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6y_vkd9wnv13pz6lc_h8phss0jw0000gn_T_main_d5d9eb_mi_0, global);
}

// 由此可知,在Block定义时便是将局部变量的值传给Block变量所指向的结构体,因此在调用Block之前对局部变量进行修改并不会影响Block内部的值,同时内部的值也是不可修改的
```

### Block内访问__block修饰的局部变量

- 在局部变量前使用下划线下划线block修饰,在声明Block之后、调用Block之前对局部变量进行修改,在调用Block时局部变量值是修改之后的新值

```
// 声明局部变量global
__block int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
global = 101;
// 调用后控制台输出"global = 101"
myBlock();
```

- 在局部变量前使用下划线下划线block修饰,在Block中可以直接修改局部变量

```
// 声明局部变量global
__block int global = 100;

void(^myBlock)() = ^{
    global ++; // 这句正确
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 101"
myBlock();
```

> 注: 原理解析,通过clang命令将OC转为C++代码来查看一下Block底层实现

```
// OC代码如下
void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};

// 转为C++代码如下
void(*myBlock)() = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_global_0 *)&global, 570425344));

// 将变量类型精简之后C++代码如下,我们发现Block变量实际上就是一个指向结构体__main_block_impl_0的指针,而结构体的第三个元素是局部变量global的指针
void(*myBlock)() = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, &global, 570425344);

// 由此可知,在局部变量前使用__block修饰,在Block定义时便是将局部变量的指针传给Block变量所指向的结构体,因此在调用Block之前对局部变量进行修改会影响Block内部的值,同时内部的值也是可以修改的
```

### Block内访问全局变量

- 在Block中可以访问全局变量

```
// 声明全局变量global
int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 100"
myBlock();
```

- 在声明Block之后、调用Block之前对全局变量进行修改,在调用Block时全局变量值是修改之后的新值

```
// 声明全局变量global
int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
global = 101;
// 调用后控制台输出"global = 101"
myBlock();
```

- 在Block中可以直接修改全局变量

```
// 声明全局变量global
int global = 100;

void(^myBlock)() = ^{
    global ++;
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 101"
myBlock();
```

> 注: 原理解析,通过clang命令将OC转为C++代码来查看一下Block底层实现

```
// OC代码如下
void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};

// 转为C++代码如下
void(*myBlock)() = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));

// 将变量类型精简之后C++代码如下,我们发现Block变量实际上就是一个指向结构体__main_block_impl_0的指针,而结构体中并未保存全局变量global的值或者指针
void(*myBlock)() = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);

// 我们看一下结构体__main_block_impl_0的代码
struct __main_block_impl_0 {
struct __block_impl impl;
struct __main_block_desc_0* Desc;
__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 在OC中调用Block的方法转为C++代码如下,实际上是指向结构体的指针myBlock访问其FuncPtr元素,在定义Block时为FuncPtr元素传进去的__main_block_func_0方法
((void (*)(__block_impl *))((__block_impl *)myBlock)->FuncPtr)((__block_impl *)myBlock);

// __main_block_func_0方法代码如下,由此可见NSLog的global还是全局变量global的值
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6y_vkd9wnv13pz6lc_h8phss0jw0000gn_T_main_f35954_mi_0, global);
}

// 由此可知,全局变量所占用的内存只有一份,供所有函数共同调用,在Block定义时并未将全局变量的值或者指针传给Block变量所指向的结构体,因此在调用Block之前对局部变量进行修改会影响Block内部的值,同时内部的值也是可以修改的
```

### Block内访问静态变量

- 在Block中可以访问静态变量

```
// 声明静态变量global
static int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 100"
myBlock();
```

- 在声明Block之后、调用Block之前对静态变量进行修改,在调用Block时静态变量值是修改之后的新值

```
// 声明静态变量global
static int global = 100;

void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};
global = 101;
// 调用后控制台输出"global = 101"
myBlock();
```

- 在Block中可以直接修改静态变量

```
// 声明静态变量global
static int global = 100;

void(^myBlock)() = ^{
    global ++;
    NSLog(@"global = %d", global);
};
// 调用后控制台输出"global = 101"
myBlock();
```

> 注: 原理解析,通过clang命令将OC转为C++代码来查看一下Block底层实现

```
// OC代码如下
void(^myBlock)() = ^{
    NSLog(@"global = %d", global);
};

// 转为C++代码如下
void(*myBlock)() = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, &global));

// 将变量类型精简之后C++代码如下,我们发现Block变量实际上就是一个指向结构体__main_block_impl_0的指针,而结构体的第三个元素是静态变量global的指针
void(*myBlock)() = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, &global);

// 我们看一下结构体__main_block_impl_0的代码
struct __main_block_impl_0 {
struct __block_impl impl;
struct __main_block_desc_0* Desc;
int *global;
__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int *_global, int flags=0) : global(_global) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 在OC中调用Block的方法转为C++代码如下,实际上是指向结构体的指针myBlock访问其FuncPtr元素,在定义Block时为FuncPtr元素传进去的__main_block_func_0方法
((void (*)(__block_impl *))((__block_impl *)myBlock)->FuncPtr)((__block_impl *)myBlock);

// __main_block_func_0方法代码如下,由此可见NSLog的global正是定义Block时为结构体传进去的静态变量global的指针
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    int *global = __cself->global; // bound by copy
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6y_vkd9wnv13pz6lc_h8phss0jw0000gn_T_main_4d124d_mi_0, (*global));
}

// 由此可知,在Block定义时便是将静态变量的指针传给Block变量所指向的结构体,因此在调用Block之前对静态变量进行修改会影响Block内部的值,同时内部的值也是可以修改的
```

### Block在MRC及ARC下的内存管理

##### Block在MRC下的内存管理

- 默认情况下,Block的内存存储在栈中,不需要开发人员对其进行内存管理

```
// 当Block变量出了作用域,Block的内存会被自动释放
void(^myBlock)() = ^{
    NSLog(@"------");
};
myBlock();
```

- 在Block的内存存储在栈中时,如果在Block中引用了外面的对象,不会对所引用的对象进行任何操作

```
Person *p = [[Person alloc] init];
        
void(^myBlock)() = ^{
    NSLog(@"------%@", p);
};
myBlock();
        
[p release]; // Person对象在这里可以正常被释放
```

- 如果对Block进行一次copy操作,那么Block的内存会被移动到堆中,这时需要开发人员对其进行release操作来管理内存

```
void(^myBlock)() = ^{
    NSLog(@"------");
};
myBlock();
        
Block_copy(myBlock);
        
// do something ...
        
Block_release(myBlock);
```

- 如果对Block进行一次copy操作,那么Block的内存会被移动到堆中,在Block的内存存储在堆中时,如果在Block中引用了外面的对象,会对所引用的对象进行一次retain操作,即使在Block自身调用了release操作之后,Block也不会对所引用的对象进行一次release操作,这时会造成内存泄漏

```
Person *p = [[Person alloc] init];
        
void(^myBlock)() = ^{
    NSLog(@"------%@", p);
};
myBlock();
        
Block_copy(myBlock);
        
// do something ...
        
Block_release(myBlock);
        
[p release]; // Person对象在这里无法正常被释放,因为其在Block中被进行了一次retain操作
```

- 如果对Block进行一次copy操作,那么Block的内存会被移动到堆中,在Block的内存存储在堆中时,如果在Block中引用了外面的对象,会对所引用的对象进行一次retain操作,为了不对所引用的对象进行一次retain操作,可以在对象的前面使用下划线下划线block来修饰

```
__block Person *p = [[Person alloc] init];
        
void(^myBlock)() = ^{
    NSLog(@"------%@", p);
};
myBlock();
        
Block_copy(myBlock);
        
// do something ...
        
Block_release(myBlock);
        
[p release]; // Person对象在这里可以正常被释放
```

- 如果对象内部有一个Block属性,而在Block内部又访问了该对象,那么会造成循环引用

情况一

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

@end


@implementation Person

- (void)dealloc
{
    NSLog(@"Person dealloc");
    
    Block_release(_myBlock);
    [super dealloc];
}

@end


Person *p = [[Person alloc] init];
        
p.myBlock = ^{
    NSLog(@"------%@", p);
};
p.myBlock();
        
[p release]; // 因为myBlock作为Person的属性,采用copy修饰符修饰(这样才能保证Block在堆里面,以免Block在栈中被系统释放),所以Block会对Person对象进行一次retain操作,导致循环引用无法释放
```

情况二

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

- (void)resetBlock;

@end


@implementation Person

- (void)resetBlock
{
    self.myBlock = ^{
        NSLog(@"------%@", self);
    };
}

- (void)dealloc
{
    NSLog(@"Person dealloc");
    
    Block_release(_myBlock);
    
    [super dealloc];
}

@end


Person *p = [[Person alloc] init];
[p resetBlock];
[p release]; // Person对象在这里无法正常释放,虽然表面看起来一个alloc对应一个release符合内存管理规则,但是实际在resetBlock方法实现中,Block内部对self进行了一次retain操作,导致循环引用无法释放
```

- 如果对象内部有一个Block属性,而在Block内部又访问了该对象,那么会造成循环引用,解决循环引用的办法是在对象的前面使用下划线下划线block来修饰,以避免Block对对象进行retain操作

情况一

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

@end


@implementation Person

- (void)dealloc
{
    NSLog(@"Person dealloc");
    
    Block_release(_myBlock);
    [super dealloc];
}

@end


__block Person *p = [[Person alloc] init];
        
p.myBlock = ^{
    NSLog(@"------%@", p);
};
p.myBlock();
        
[p release]; // Person对象在这里可以正常被释放
```

情况二

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

- (void)resetBlock;

@end


@implementation Person

- (void)resetBlock
{
    // 这里为了通用一点,可以使用__block typeof(self) p = self;
    __block Person *p = self;
    self.myBlock = ^{
        NSLog(@"------%@", p);
    };
}

- (void)dealloc
{
    NSLog(@"Person dealloc");
    
    Block_release(_myBlock);
    
    [super dealloc];
}

@end


Person *p = [[Person alloc] init];
[p resetBlock];
[p release]; // Person对象在这里可以正常被释放
```

##### Block在ARC下的内存管理

- 在ARC默认情况下,Block的内存存储在堆中,ARC会自动进行内存管理,程序员只需要避免循环引用即可

```
// 当Block变量出了作用域,Block的内存会被自动释放
void(^myBlock)() = ^{
    NSLog(@"------");
};
myBlock();
```

- 在Block的内存存储在堆中时,如果在Block中引用了外面的对象,会对所引用的对象进行强引用,但是在Block被释放时会自动去掉对该对象的强引用,所以不会造成内存泄漏

```
Person *p = [[Person alloc] init];
        
void(^myBlock)() = ^{
    NSLog(@"------%@", p);
};
myBlock();
        
// Person对象在这里可以正常被释放
```

- 如果对象内部有一个Block属性,而在Block内部又访问了该对象,那么会造成循环引用

情况一

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

@end


@implementation Person

- (void)dealloc
{
    NSLog(@"Person dealloc");
}

@end


Person *p = [[Person alloc] init];
        
p.myBlock = ^{
    NSLog(@"------%@", p);
};
p.myBlock();
        
// 因为myBlock作为Person的属性,采用copy修饰符修饰(这样才能保证Block在堆里面,以免Block在栈中被系统释放),所以Block会对Person对象进行一次强引用,导致循环引用无法释放
```

情况二

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

- (void)resetBlock;

@end


@implementation Person

- (void)resetBlock
{
    self.myBlock = ^{
        NSLog(@"------%@", self);
    };
}

- (void)dealloc
{
    NSLog(@"Person dealloc");
}

@end


Person *p = [[Person alloc] init];
[p resetBlock];

// Person对象在这里无法正常释放,在resetBlock方法实现中,Block内部对self进行了一次强引用,导致循环引用无法释放
```

- 如果对象内部有一个Block属性,而在Block内部又访问了该对象,那么会造成循环引用,解决循环引用的办法是使用一个弱引用的指针指向该对象,然后在Block内部使用该弱引用指针来进行操作,这样避免了Block对对象进行强引用

情况一

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

@end


@implementation Person

- (void)dealloc
{
    NSLog(@"Person dealloc");
}

@end


Person *p = [[Person alloc] init];
__weak typeof(p) weakP = p;

p.myBlock = ^{
    NSLog(@"------%@", weakP);
};
p.myBlock();
        
// Person对象在这里可以正常被释放
```

情况二

```
@interface Person : NSObject

@property (nonatomic, copy) void(^myBlock)();

- (void)resetBlock;

@end


@implementation Person

- (void)resetBlock
{
    // 这里为了通用一点,可以使用__weak typeof(self) weakP = self;
    __weak Person *weakP = self;
    self.myBlock = ^{
        NSLog(@"------%@", weakP);
    };
}

- (void)dealloc
{
    NSLog(@"Person dealloc");
}

@end


Person *p = [[Person alloc] init];
[p resetBlock];

// Person对象在这里可以正常被释放
```

##### Block在ARC下的内存管理的官方案例

在MRC中,我们从当前控制器采用模态视图方式present进入MyViewController控制器,在Block中会对myViewController进行一次retain操作,造成循环引用

```
MyViewController *myController = [[MyViewController alloc] init];
// ...
myController.completionHandler =  ^(NSInteger result) {
   [myController dismissViewControllerAnimated:YES completion:nil];
};
[self presentViewController:myController animated:YES completion:^{
   [myController release];
}];
```

在MRC中解决循环引用的办法即在变量前使用下划线下划线block修饰,禁止Block对所引用的对象进行retain操作

```
__block MyViewController *myController = [[MyViewController alloc] init];
// ...
myController.completionHandler =  ^(NSInteger result) {
    [myController dismissViewControllerAnimated:YES completion:nil];
};
[self presentViewController:myController animated:YES completion:^{
   [myController release];
}];
```

但是上述方法在ARC下行不通,因为下划线下划线block在ARC中并不能禁止Block对所引用的对象进行强引用,解决办法可以是在Block中将myController置空(为了可以修改myController,还是需要使用下划线下划线block对变量进行修饰)

```
__block MyViewController *myController = [[MyViewController alloc] init];
// ...
myController.completionHandler =  ^(NSInteger result) {
    [myController dismissViewControllerAnimated:YES completion:nil];
    myController = nil;
};
[self presentViewController:myController animated:YES completion:^{}];
```

上述方法确实可以解决循环引用,但是在ARC中还有更优雅的解决办法,新创建一个弱指针来指向该对象,并将该弱指针放在Block中使用,这样Block便不会造成循环引用

```
MyViewController *myController = [[MyViewController alloc] init];
// ...
__weak MyViewController *weakMyController = myController;
myController.completionHandler =  ^(NSInteger result) {
    [weakMyController dismissViewControllerAnimated:YES completion:nil];
};
[self presentViewController:myController animated:YES completion:^{}];
```

虽然解决了循环引用,但是也容易涉及到另一个问题,因为Block是通过弱引用指向了myController对象,那么有可能在调用Block之前myController对象便已经被释放了,所以我们需要在Block内部再定义一个强指针来指向myController对象

```
MyViewController *myController = [[MyViewController alloc] init];
// ...
__weak MyViewController *weakMyController = myController;
myController.completionHandler =  ^(NSInteger result) {
    MyViewController *strongMyController = weakMyController;
    if (strongMyController)
    {
        [strongMyController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        // Probably nothing...
    }
};
[self presentViewController:myController animated:YES completion:^{}];
```

这里需要补充一下,在Block内部定义的变量,会在作用域结束时自动释放,Block对其并没有强引用关系,且在ARC中只需要避免循环引用即可,如果只是Block单方面地对外部变量进行强引用,并不会造成内存泄漏

> 注: 关于下划线下划线block关键字在MRC和ARC下的不同

```
__block在MRC下有两个作用
1. 允许在Block中访问和修改局部变量 
2. 禁止Block对所引用的对象进行隐式retain操作

__block在ARC下只有一个作用
1. 允许在Block中访问和修改局部变量
```

### 使用Block进行排序

在开发中,我们一般使用数组的如下两个方法来进行排序

- 不可变数组的方法: - (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr
- 可变数组的方法 : - (void)sortUsingComparator:(NSComparator)cmptr

其中,NSComparator是利用typedef定义的Block类型

```
typedef NSComparisonResult (^NSComparator)(id obj1, id obj2);
```

其中,这个返回值为NSComparisonResult枚举,这个返回值用来决定Block的两个参数顺序,我们只需在Block中指明不同条件下Block的两个参数的顺序即可,方法内部会将数组中的元素分别利用Block来进行比较并排序

```
typedef NS_ENUM(NSInteger, NSComparisonResult)
{
    NSOrderedAscending = -1L, // 升序,表示左侧的字符在右侧的字符前边
    NSOrderedSame, // 相等
    NSOrderedDescending // 降序,表示左侧的字符在右侧的字符后边
};
```

我们以Person类为例,对Person对象以年龄升序进行排序,具体方法如下

```
@interface Student : NSObject

@property (nonatomic, assign) int age;

@end


@implementation Student

@end


Student *stu1 = [[Student alloc] init];
stu1.age = 18;
Student *stu2 = [[Student alloc] init];
stu2.age = 28;
Student *stu3 = [[Student alloc] init];
stu3.age = 11;
        
NSArray *array = @[stu1,stu2,stu3];
        
array = [array sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    Student *stu1 = obj1;
    Student *stu2 = obj2;
            
    if (stu1.age > stu2.age)
    {
        return NSOrderedDescending; // 在这里返回降序,说明在该种条件下,obj1排在obj2的后边
    }
    else if (stu1.age < stu2.age)
    {
        return NSOrderedAscending;
    }
    else
    {
        return NSOrderedSame;
    }
}];
```

### 

作者：蚊香酱

链接：https://www.jianshu.com/p/14efa33b3562

来源：简书

简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。









# 2 

## Block

### Block 基本原理

```
int main() {
    void (^blk)(void) = ^{
        (printf("hello world!"));
    };
    blk();
    return 0;
}
```

如上，通过`clang`转换为`cpp`源码，截取关键部分:

```
// block 的真面目
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};

// ..... 一大坨无关代码

// 通过这个结构体包装block，用于快速构造block
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {

        (printf("hello world!"));
    }

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main() {
    void (*blk)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
    ((void (*)(__block_impl *))((__block_impl *)blk)->FuncPtr)((__block_impl *)blk);
    return 0;
}
```

比较核心的是以下内容:`__block_impl`结构体，`__main_block_impl_0`结构体，`__main_block_func_0`函数，`&_NSConcreteStackBlock`，`__main_block_desc_0`结构体。

- `__block_impl`结构体:

  该结构体定义在源文件上方，其中`isa`指针指向当前`block`对象类对象，`FuncPtr`指向`block`保存的函数指针。

- `__main_block_desc_0`结构体:

  - 用于保存`__main_block_impl_0 `结构体大小等信息。

- `__main_block_func_0`静态函数:

  - 用于存储当前`block`的代码块。

- `__main_block_impl_0`结构体:

  该结构体包装了`__block_impl`结构体，同时包含`__main_block_desc_0`结构体。对外提供一个构造函数，构造函数需要传递函数指针(`__main_block_func_0`静态函数)、`__main_block_desc_0`实例。

由此我们可知，上述一个简单的`block`定义及调用过程被转换为了：

1. 定义`block`变量相当于调用`__main_block_impl_0`构造函数，通过函数指针传递代码块进`__main_block_impl_0`实例。
2. 构造函数内部，将外部传递进来的`__main_block_func_0`函数指针，设置内部实际的`block`变量(`__block_impl`类型的结构体)的函数指针。
3. 调用`block`时，取出`__main_block_impl_0`类型结构体中的`__block_impl`类型的结构体的函数指针(`__main_block_func_0`)并调用。

至此，一个简单的`block`原理描述完毕。

### __block 捕获原理

`block`内部可以直接使用外部变量，但是在不加`__block`修饰符的情况下，是无法修改的。比如下面这段代码：

```
int main() {
    int a = 1;
    void (^blk)(void) = ^{
        printf("%d", a);
    };
    blk();
    return 0;
}
```

经过`cpp`重写后:

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int a;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _a, int flags=0) : a(_a) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int a = __cself->a; // bound by copy

        printf("%d", a);
    }

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main() {
    int a = 1;
    void (*blk)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, a));
    ((void (*)(__block_impl *))((__block_impl *)blk)->FuncPtr)((__block_impl *)blk);
    return 0;
}
```

经过[上一节的讨论](https://github.com/Alllfred/iOSReview#6-1)，我们知道代码块是由`__main_block_impl_0`构造函数传通过函数指针传递进来的。在这节的例子中，可以发现构造函数中多了一个`int _a`参数。同时`__main_block_impl_0`结构体也多了一个`int a`属性用于保存`block`内部使用的变量`a`。

由于构造函数的参数为整形，在`c++`中，函数的形参为值拷贝，也就是说`__main_block_impl_0`结构体中的属性`a`，是外部`a`变量的拷贝。在代码块内部(也就是`__main_block_func_0 `函数)我们通过`__cself`指针拿到`a`变量。故我们在代码块中是无法修改`a`变量的，同时如果外部`a`变量被修改了，那么`block`内部也是无法得知的。

如果想要在内部修改`a`变量，可以通过`__block`关键字:

```
int main() {
    __block int number = 1;
    void (^blk)(void) = ^{
        number = 3;
        printf("%d", number);
    };
    blk();
    return 0;
}
struct __Block_byref_number_0 {
  void *__isa;
__Block_byref_number_0 *__forwarding;
 int __flags;
 int __size;
 int number;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_number_0 *number; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_number_0 *_number, int flags=0) : number(_number->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_number_0 *number = __cself->number; // bound by ref

        (number->__forwarding->number) = 3;
        printf("%d", (number->__forwarding->number));
    }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->number, (void*)src->number, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->number, 8/*BLOCK_FIELD_IS_BYREF*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
int main() {
    __attribute__((__blocks__(byref))) __Block_byref_number_0 number = {(void*)0,(__Block_byref_number_0 *)&number, 0, sizeof(__Block_byref_number_0), 1};
    void (*blk)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_number_0 *)&number, 570425344));
    ((void (*)(__block_impl *))((__block_impl *)blk)->FuncPtr)((__block_impl *)blk);
    return 0;
}
```

可以看到整形`number`变量变成了`__Block_byref_number_0`结构体实例，在`__main_block_impl_0`构造函数中，将该实例的指针传递进来。`__Block_byref_number_0`结构体中，通过`__forwarding`指向自己，整形`number`存储具体的值。

上节提到，构造函数中的参数是值拷贝，故此处代码块内部拿到的指针拷贝一样可以操作外部的`__Block_byref_number_0`结构体中的值，通过这种方式实现了`block`内部修改外部值。

### block 引起的循环引用原理