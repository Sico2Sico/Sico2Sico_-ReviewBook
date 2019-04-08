## WKWebView 那些坑https://mp.weixin.qq.com/s/rhYKLIbXOsUJC_n6dt9UfA

## https://www.jianshu.com/p/870dba42ec15





# 1   OC 调 JS

1.  **stringByEvaluatingJavaScriptFromString**

	  self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];

2. ####    JavaScriptCore

```objective-c
JSContext *jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
//这也是一种获取标题的方法。
JSValue *value = [self.jsContext evaluateScript:@"document.title"];
//更新标题
self.navigationItem.title = value.toString;
```

3. 异常处理 

```objective-c
//在调用前，设置异常回调
[self.jsContext setExceptionHandler:^(JSContext *context, JSValue *exception){
        NSLog(@"%@", exception);
}];
```



# 2 JS 调 OC



1.  URL截取

```objective-c
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //标准的URL包含scheme、host、port、path、query、fragment等
    NSURL *URL = request.URL;    
    if ([URL.scheme isEqualToString:@"darkangel"]) {
        if ([URL.host isEqualToString:@"smsLogin"]) {
            NSLog(@"短信验证码登录，参数为 %@", URL.query);
            return NO;
        }
    }
    return YES;
}
```



2.  javaScriptCore

```objective-c
/// html 里的
function share(title, imgUrl, link) {
     //这里需要OC实现
}

/// OC里的
//获取该UIWebview的javascript上下文
    //self持有jsContext
    //@property (nonatomic, strong) JSContext *jsContext;
    self.jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    //js调用oc
    //其中share就是js的方法名称，赋给是一个block 里面是oc代码
    //此方法最终将打印出所有接收到的参数，js参数是不固定的
    self.jsContext[@"share"] = ^() {
        NSArray *args = [JSContext currentArguments];//获取到share里的所有参数
        //args中的元素是JSValue，需要转成OC的对象
        NSMutableArray *messages = [NSMutableArray array];
        for (JSValue *obj in args) {
            [messages addObject:[obj toObject]];
        }
        NSLog(@"点击分享js传回的参数：\n%@", messages);
    };
}

```

```objective-c

//该方法传入两个整数，求和，并返回结果
function testAddMethod(a, b) {
    //需要OC实现a+b，并返回
    return a + b;
}


self.jsContext[@"testAddMethod"] = ^NSInteger(NSInteger a, NSInteger b) {
      return a * b;
};
```

