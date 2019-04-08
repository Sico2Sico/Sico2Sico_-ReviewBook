# constructor  &  destructor 构造 析构器

## objc_subclassing_restricted

使用这个属性可以定义一个 `Final Class`，也就是说，一个不可被继承的类，假设我们有个名叫 `Eunuch（太监）` 的类，但并不希望有人可以继承自它：

```
@interface Eunuch : NSObject
@end
@interface Child : Eunuch // 太监不能够有孩砸
@end
```

只要在 @interface 前面加上 `objc_subclassing_restricted` 这个属性即可：

```
__attribute__((objc_subclassing_restricted))
@interface Eunuch : NSObject
@end
@interface Child : Eunuch // <--- Compile Error
@end
```

## objc_requires_super

aka: `NS_REQUIRES_SUPER`，标志子类继承这个方法时需要调用 `super`，否则给出编译警告：

```
@interface Father : NSObject
- (void)hailHydra __attribute__((objc_requires_super));
@end
@implementation Father
- (void)hailHydra {
    NSLog(@"hail hydra!");
}
@end
@interface Son : Father
@end
@implementation Son
- (void)hailHydra {
} // <--- Warning missing [super hailHydra]
@end
```

## objc_boxable

Objective-C 中的 `@(...)` 语法糖可以将基本数据类型 box 成 `NSNumber` 对象，假如想 box 一个 `struct` 类型或是 `union` 类型成 `NSValue` 对象，可以使用这个属性：

```
typedef struct __attribute__((objc_boxable)) {
    CGFloat x, y, width, height;
} XXRect;
```

这样一来，`XXRect` 就具备被 box 的能力：

```
CGRect rect1 = {1, 2, 3, 4};
NSValue *value1 = @(rect1); // <--- Compile Error
XXRect rect2 = {1, 2, 3, 4};
NSValue *value2 = @(rect2); // √
```

## constructor / destructor

顾名思义，构造器和析构器，加上这两个属性的函数会在分别在可执行文件（或 shared library）**load**和 **unload** 时被调用，可以理解为在 `main()` 函数调用前和 return 后执行：

```
__attribute__((constructor))
static void beforeMain(void) {
    NSLog(@"beforeMain");
}
__attribute__((destructor))
static void afterMain(void) {
    NSLog(@"afterMain");
}
int main(int argc, const char * argv[]) {
    NSLog(@"main");
    return 0;
}

// Console:
// "beforeMain" -> "main" -> "afterMain"
```

constructor 和 `+load` 都是在 main 函数执行前调用，但 `+load` 比 constructor 更加早一丢丢，因为 dyld（动态链接器，程序的最初起点）在加载 image（可以理解成 Mach-O 文件）时会先通知 `objc runtime` 去加载其中所有的类，每加载一个类时，它的 `+load` 随之调用，全部加载完成后，dyld 才会调用这个 image 中所有的 constructor 方法。

所以 constructor 是一个干坏事的绝佳时机：

1. 所有 Class 都已经加载完成
2. main 函数还未执行
3. 无需像 +load 还得挂载在一个 Class 中