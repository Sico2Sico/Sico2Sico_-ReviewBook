`Post`请求体有哪些格式？

#### application/x-www-form-urlencoded

这应该是最常见的 `POST` 提交数据的方式了。浏览器的原生 `form` 表单，如果不设置 `enctype` 属性，那么最终就会以 `application/x-www-form-urlencoded` 方式提交数据

```html
POST  HTTP/1.1
Host: www.demo.com
Cache-Control: no-cache
Postman-Token: 81d7b315-d4be-8ee8-1237-04f3976de032
Content-Type: application/x-www-form-urlencoded

key=value&testKey=testValue
```

#### multipart/form-data

```html
POST  HTTP/1.1
Host: www.demo.com
Cache-Control: no-cache
Postman-Token: 679d816d-8757-14fd-57f2-fbc2518dddd9
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="key"

value
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="testKey"

testValue
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="imgFile"; filename="no-file"
Content-Type: application/octet-stream


<data in here>
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

#### application/json

#### text/xml







# 2.网络请求的状态码都大致代表什么意思？

##### 1.1xx

> 1xx 代表临时响应，需要请求者继续执行操作的状态代码。

##### 2.2xx

> 2xx 代表的多是操作成功。

##### 3.3xx

> 3xx 代表重定向，表示要完成请求，需要进一步操作

##### 4.4xx

> 4xx 代表请求错误，表示请求可能出错，妨碍了服务器的处理。

##### 5.5xx

> 5xx 代表服务器错误，表示服务器在尝试处理请求时发生内部错误。 这些错误可能是服务器本身的错误，而不是请求出错