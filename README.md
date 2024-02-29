# tcp-log-with-body

#### 介绍
Kong的tcp-log-with-body插件是一个高效的工具，它能够记录Kong处理的请求和响应，同时可以选择性地包含请求体（body）。这个插件非常适用于需要详细记录API请求和响应信息的情景，尤其是在调试和排查问题时。

#### 软件环境说明
- kong version 2.1.4
- CentOS version  7.3.1611
```
kong version --vv
2024/02/29 00:17:48 [verbose] Kong: 2.1.4
2024/02/29 00:17:48 [debug] ngx_lua: 10015
2024/02/29 00:17:48 [debug] nginx: 1015008
2024/02/29 00:17:48 [debug] Lua: LuaJIT 2.1.0-beta3
2.1.4


cat /etc/centos-release
CentOS Linux release 7.3.1611 (Core) 
```


#### 插件安装教程
1. 找到 kong 插件存放位置
```bash
─[root@bwg] - [/usr/local/share/lua/5.1/kong/plugins] - [2024-02-28 11:52:33]
└─[0] ls
acl              basic-auth      file-log      http-log-with-body  key-auth         post-function  request-size-limiting  session            udp-log
acme             bot-detection   grpc-gateway  http-mirror         ldap-auth        pre-function   request-termination    statsd             zipkin
aws-lambda       correlation-id  grpc-web      ip-restriction      loggly           prometheus     request-transformer    syslog
azure-functions  cors            hmac-auth     jwt                 log-serializers  proxy-cache    response-ratelimiting  tcp-log
base_plugin.lua  datadog         http-log      kafka-log           oauth2           rate-limiting  response-transformer   tcp-log-with-body

```
2. git 克隆项目到plugins目录下
```bash
git clone https://gitee.com/XiongMingcai/tcp-log-with-body.git
```

3. 修改kong配置文件 加入启用`tcp-log-with-body` 插件


```
vim /etc/kong/kong.conf
```
修改位置
```conf
plugins = bundled,tcp-log-with-body 
```



4.  重启kong

监听启动错误日志
```
tail -f /usr/local/kong/logs/error.log 
```
重启kong
```bash
sudo systemctl restart kong
```

#### 使用说明

1.  配置tcp-log-with-body插件

![输入图片说明](https://www.uibe-mba.com/upfile/image/20240229/2024022913071611921.png "tcp-log-with-body")
2.  接收日志tcp请求 `node.js 模拟tcp-log-server`

```
const net = require('net');
const {inspect} = require("util");

// Create a server instance
const server = net.createServer((socket) => {


    socket.on('data', (data) => {
 // 将数据转换为字符串，并以JSON格式输出

        const dataString = data.toString('utf8');
        console.log("Received data:", inspect(JSON.parse(dataString), false, null, true));

});


    socket.on('end', () => {

    });
});

// Error callback
server.on('error', (err) => {
    console.error('Server error:', err);
});

// Listening callback
server.listen(9999, '127.0.0.1', () => {
    console.log('Server is listening on 127.0.0.1:9999');
});

```


3.  效果

```js
.....
  request: {
    querystring: {},
    size: '563',
    uri: '/ok',
    url: 'https://ssl.hunangl.com:443/ok',
    headers: {
      host: 'ssl.hunangl.com',
      authorization: 'REDACTED',
      'postman-token': 'a0cf800e-06ac-41b0-8a4d-d849c945cee1',
      accept: '*/*',
      digest: 'SHA-256=eji/gfOD9pQzrW6QDTWz4jhVk/dqe3q11DVbi6Qe4ks=',
      'request-id': '5c54a71f-9bdb-445c-8549-f4af181ad49c',
      'cache-control': 'no-cache',
      'content-length': '13',
      'accept-encoding': 'gzip, deflate, br',
      'user-agent': 'PostmanRuntime/7.36.3',
      'x-date': 'Thu, 29 Feb 2024 05:14:21 GMT',
      connection: 'keep-alive',
      'content-type': 'application/json'
    },
    body: '{"foo":"bar"}',
    method: 'POST'
  },
  client_ip: '54.86.50.139',
.....
response: {
    body: '{"host":"0.0.0.0:8300","connection":"keep-alive","x-forwarded-for":"54.86.50.139","x-forwarded-proto":"https","x-forwarded-host":"ssl.hunangl.com","x-forwarded-port":"443","x-real-ip":"54.86.50.139","content-length":"13","x-date":"Thu, 29 Feb 2024 05:14:21 GMT","authorization":"hmac username=\\"hmac_username\\", algorithm=\\"hmac-sha256\\", headers=\\"x-date request-line digest\\", signature=\\"Kh+sGhrL3NbFNa9dsLdTs/q6hMBublOEPYUw4j8rLGM=\\"","digest":"SHA-256=eji/gfOD9pQzrW6QDTWz4jhVk/dqe3q11DVbi6Qe4ks=","content-type":"application/json","user-agent":"PostmanRuntime/7.36.3","accept":"*/*","cache-control":"no-cache","postman-token":"a0cf800e-06ac-41b0-8a4d-d849c945cee1","accept-encoding":"gzip, deflate, br","request-id":"5c54a71f-9bdb-445c-8549-f4af181ad49c"}',
    headers: {
      'content-type': 'application/json; charset=utf-8',
      date: 'Thu, 29 Feb 2024 05:14:15 GMT',
      connection: 'close',
      'server-port': '8300',
      'request-ip': '54.86.50.139',
      'content-length': '761',
      via: 'kong/2.1.4',
      'x-kong-proxy-latency': '6',
      'x-kong-upstream-latency': '12',
      'request-id': '5c54a71f-9bdb-445c-8549-f4af181ad49c'
    },
    status: 200,
    size: '1075'
  },
.....
```



