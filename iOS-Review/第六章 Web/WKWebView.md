1. js 注入

   ```objective-c
   //注入一个Cookie
   WKUserScript *newCookieScript = [[WKUserScript alloc] initWithSource:@"document.cookie = 'DarkAngelCookie=DarkAngel;'" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
   [controller addUserScript:newCookieScript];
   ```

   ```objective-c
   //创建脚本
   WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:@"alert(document.cookie);" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
   //添加脚本
   [controller addUserScript:script];
   ```


# 1  oc 调用 js

```objective-c
[self.webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
        NSLog(@"调用evaluateJavaScript异步获取title：%@", title);
}];
```









# 2 JS 调用 OC

1. #### URL拦截

```objective-c
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    //可以通过navigationAction.navigationType获取跳转类型，如新链接、后退等
    NSURL *URL = navigationAction.request.URL;
    //判断URL是否符合自定义的URL Scheme
    if ([URL.scheme isEqualToString:@"darkangel"]) {
        //根据不同的业务，来执行对应的操作，且获取参数
        if ([URL.host isEqualToString:@"smsLogin"]) {
            NSString *param = URL.query;
            NSLog(@"短信验证码登录, 参数为%@", param);
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
    NSLog(@"%@", NSStringFromSelector(_cmd));
}
```



2. #### scriptMessageHandler  消息注册

```objective-c
//那么当我在OC中通过如下的方法添加了一个handler，如
[controller addScriptMessageHandler:self name:@"currentCookies"]; //这里self要遵循协 WKScriptMessageHandler

///则当我在js中调用下面的方法时
window.webkit.messageHandlers.currentCookies.postMessage(document.cookie);

///我在OC中将会收到WKScriptMessageHandler的回调
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"currentCookies"]) {
        NSString *cookiesStr = message.body;    //message.body返回的是一个id类型的对象，所以可以支持很多种js的参数类型(js的function除外)
        NSLog(@"当前的cookie为： %@", cookiesStr);
    }
}
```

