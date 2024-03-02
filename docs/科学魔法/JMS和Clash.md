# Just My Socks + Clash

## 服务购买

- [Just My Socks](https://justmysocks2.net/)(即买即用)
- [Just My Socks中文网](https://www.jichang.us/)

## 客户端下载地址

> Clash-core 已删库跑路，替代品有Clash meta、 V2ray、Xray 等。

- [ClashX Mac](https://github.com/yichengchen/clashX/releases)
- [Clash For Linux](https://github.com/Dreamacro/clash/releases)
- [Clash For Windows](https://github.com/Fndroid/clash_for_windows_pkg/releases)

- [Clash For Android](https://github.com/Kr328/ClashForAndroid/releases)


## 简单配置

```
#---------------------------------------------------#
## 配置文件需要放置在 $HOME/.config/clash/*.yaml

## 这份文件是clashX的基础配置文件，请尽量新建配置文件进行修改。
## ！！！只有这份文件的端口设置会随ClashX启动生效

## 如果您不知道如何操作，请参阅 SS-Rule-Snippet：https://github.com/Hackl0us/SS-Rule-Snippet/blob/master/LAZY_RULES/clash.yaml
## 或者官方Github文档 https://github.com/Dreamacro/clash/blob/master/README.md
#---------------------------------------------------#

#---------------------------------------------------#

port: 7890
socks-port: 7891
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

proxies:
  - name: "proxyName"
    type: ss
    server: 服务地址
    port: 服务端口
    cipher: 加密方式
    password: "密码"

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - proxyName

rules:
## Google
  - DOMAIN,developer.android.google.cn,DIRECT
  - DOMAIN,cs.android.com,Proxy
  - DOMAIN-SUFFIX,google.com,Proxy
  - DOMAIN-KEYWORD,google,Proxy
  - DOMAIN,google.com,Proxy
  - DOMAIN,source.android.com,Proxy
  - DOMAIN,medium.com,Proxy
## xxx
  - DOMAIN-SUFFIX,github.com,Proxy
  
##  Default
  - DOMAIN-SUFFIX,ad.com,REJECT
  - GEOIP,CN,DIRECT
  - MATCH,DIRECT
```



## Linux上的使用Clash

### 1.下载完成后解压, 然后修改文件权限

```shell
sudo chmod +x ./clash-linux-XXXX
```

### 2. 执行文件

```shell
clash-linux-XXXX
```

### 3. 修改配置

```
cd ~/.confing/clash
vim config.yaml
```

### 4. 网页上查看启动的clash

[Clash UI](http://clash.razord.top/#/proxies)

### 5. 启动代理

![image-20220305132257560](./JMS和Clash.assets/image-20220305132257560-16464577809101.png)



## Windows
