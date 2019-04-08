## KVC底层实现?

- 拿字符串与当前类的属性进行匹配.如果匹配到,就给该属性赋值.

  ```
   [flagItem setValue:obj forKeyPath:key];
  ```

- 1.会找有没有跟key值相同名称的set方法,如果有，就会调用set方法,把obj传入

- 2.如果说没有set方法.那么它会去找没有相同名称,并且带有下划线的成员属性,如果有就会给该属性赋值.

- 3.如果也没有带有下划线的成员属性,就看有没有跟它相同名称的成员属性,如果有就会给该属性赋值.

- 4.如果还没有跟它相同名称的成员属性,就会调用`setValue:(id)value forUndefinedKey:`

- 5.如果没有实现setValue: forUndefinedKey: 就直接报错





## KVC

**Key-Value Coding (KVC)**

> KVC（Key-value coding）键值编码，单看这个名字可能不太好理解。其实翻译一下就很简单了，就是指iOS的开发中，可以允许开发者通过Key名直接访问对象的属性，或者给对象的属性赋值。而不需要调用明确的存取方法。这样就可以在运行时动态在访问和修改对象的属性。而不是在编译时确定，这也是iOS开发中的黑魔法之一。很多高级的iOS开发技巧都是基于KVC实现的。目前网上关于KVC的文章在非常多，有的只是简单地说了下用法，有的讲得深入但是在使用场景和最佳实践没有说明，我写下这遍文章就是给大家详解一个最完整最详细的KVC。

**KVC在iOS中的定义**

无论是`Swift`还是`Objective-C`，`KVC`的定义都是对`NSObject`的扩展来实现的(`Objective-C`中有个显式的`NSKeyValueCoding`类别名，而`Swift`没有，也不需要)所以对于所有继承了`NSObject`在类型，都能使用`KVC`(一些纯`Swift`类和结构体是不支持`KVC`的)，下面是`KVC`最为重要的四个方法

```objc
- (nullable id)valueForKey:(NSString *)key;                          //直接通过Key来取值
- (void)setValue:(nullable id)value forKey:(NSString *)key;          //通过Key来设值
- (nullable id)valueForKeyPath:(NSString *)keyPath;                  //通过KeyPath来取值
- (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath;  //通过KeyPath来设值
```

当然`NSKeyValueCoding`类别中还有其他的一些方法，下面列举一些

```objc
+ (BOOL)accessInstanceVariablesDirectly;
//默认返回YES，表示如果没有找到Set<Key>方法的话，会按照_key，_iskey，key，iskey的顺序搜索成员，设置成NO就不这样搜索
- (BOOL)validateValue:(inout id __nullable * __nonnull)ioValue forKey:(NSString *)inKey error:(out NSError **)outError;
//KVC提供属性值确认的API，它可以用来检查set的值是否正确、为不正确的值做一个替换值或者拒绝设置新值并返回错误原因。
- (NSMutableArray *)mutableArrayValueForKey:(NSString *)key;
//这是集合操作的API，里面还有一系列这样的API，如果属性是一个NSMutableArray，那么可以用这个方法来返回
- (nullable id)valueForUndefinedKey:(NSString *)key;
//如果Key不存在，且没有KVC无法搜索到任何和Key有关的字段或者属性，则会调用这个方法，默认是抛出异常
- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key;
//和上一个方法一样，只不过是设值。
- (void)setNilValueForKey:(NSString *)key;
//如果你在SetValue方法时面给Value传nil，则会调用这个方法
- (NSDictionary<NSString *, id> *)dictionaryWithValuesForKeys:(NSArray<NSString *> *)keys;
//输入一组key,返回该组key对应的Value，再转成字典返回，用于将Model转到字典。
```

上面的这些方法在碰到特殊情况或者有特殊需求还是会用到的，所以也是可以了解一下。后面的代码示例会有讲到其中的一些方法。
同时苹果对一些容器类比如NSArray或者NSSet等，KVC有着特殊的实现。建议有基础的或者英文好的开发者直接去看苹果的官方文档，相信你会对KVC的理解更上一个台阶。

**KVC是怎么寻找Key的**

KVC是怎么使用的，我相信绝大多数的开发者都很清楚，我在这里就不再写简单的使用KVC来设值和取值的代码了，首页我们来探讨KVC在内部是按什么样的顺序来寻找key的。
当调用`setValue：`属性值 `forKey：``@”name“`的代码时，底层的执行机制如下：

- 程序优先调用`set<Key>:`属性值方法，代码通过`setter`方法完成设置。注意，这里的`<key>`是指成员变量名，首字母大清写要符合`KVC`的全名规则，下同
- 如果没有找到`setName：`方法，`KVC`机制会检查`+ (BOOL)accessInstanceVariablesDirectly`方法有没有返回`YES`，默认该方法会返回`YES`，如果你重写了该方法让其返回`NO`的话，那么在这一步KVC会执行`setValue：forUNdefinedKey：`方法，不过一般开发者不会这么做。所以KVC机制会搜索该类里面有没有名为`_<key>`的成员变量，无论该变量是在类接口部分定义，还是在类实现部分定义，也无论用了什么样的访问修饰符，只在存在以`_<key>`命名的变量，`KVC`都可以对该成员变量赋值。
- 如果该类即没有`set<Key>：`方法，也没有`_<key>`成员变量，`KVC`机制会搜索`_is<Key>`的成员变量，
- 和上面一样，如果该类即没有`set<Key>：`方法，也没有`_<key>`和`_is<Key>`成员变量，`KVC`机制再会继续搜索`<key>`和`is<Key>`的成员变量。再给它们赋值。
- 如果上面列出的方法或者成员变量都不存在，系统将会执行该对象的`setValue：forUNdefinedKey：`方法，默认是抛出异常。

如果开发者想让这个类禁用`KVC`里，那么重写`+ (BOOL)accessInstanceVariablesDirectly`方法让其返回NO即可，这样的话如果`KVC`没有找到`set<Key>:`属性名时，会直接用`setValue：forUNdefinedKey：`方法。