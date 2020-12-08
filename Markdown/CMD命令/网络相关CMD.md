---

title: 网络相关CMD
date: 2020-04-16 13:03

---
Tags : zaze cmd

[TOC]

#  网络相关CMD
```
http://ping.pe/

```

---
## 查看本机ip地址

- mac
```
ifconfig en0
```
- [x] window
- linux


## 查看端口占用

- mac 
```
lsof -i:80
```

- windows 
```
netstat -anp |grep 61018
```

## 查看当前所有tcp端口

```
netstat -ntlp   
netstat -ntulp |grep 80   //查看所有80端口使用情况
netstat -an | grep 3306   //查看所有3306端口使用情况
```

## linux

查看内核版本 ``cat /proc/version``


du -m    以m为单位查看大小
df	剩余空间

mount -o remount, rw /

### 查看进程

``ps``

``ps | grep packageName``


``ls -aF``

## Dig命令

Dig是一个在类Unix命令行模式下查询DNS包括NS记录，A记录，MX记录等相关信息的工具
```
dig www.baidu.com
dig @114.114.114.114 www.baidu.com
dig baidu.com A +noall +answer
```

```txt
; <<>> DiG 9.10.6 <<>> www.baidu.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25392
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 5, ADDITIONAL: 6

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.baidu.com.			IN	A

;; ANSWER SECTION:
www.baidu.com.		679	IN	CNAME	www.a.shifen.com.
www.a.shifen.com.	3	IN	A	112.80.248.76
www.a.shifen.com.	3	IN	A	112.80.248.75

;; AUTHORITY SECTION:
a.shifen.com.		903	IN	NS	ns2.a.shifen.com.
a.shifen.com.		903	IN	NS	ns4.a.shifen.com.
a.shifen.com.		903	IN	NS	ns5.a.shifen.com.
a.shifen.com.		903	IN	NS	ns1.a.shifen.com.
a.shifen.com.		903	IN	NS	ns3.a.shifen.com.

;; ADDITIONAL SECTION:
ns3.a.shifen.com.	903	IN	A	112.80.255.253
ns4.a.shifen.com.	903	IN	A	14.215.177.229
ns5.a.shifen.com.	903	IN	A	180.76.76.95
ns1.a.shifen.com.	903	IN	A	61.135.165.224
ns2.a.shifen.com.	903	IN	A	220.181.33.32

;; Query time: 3 msec
;; SERVER: 192.168.5.50#53(192.168.5.50)
;; WHEN: Mon Apr 27 10:26:25 CST 2020
;; MSG SIZE  rcvd: 271
```

  [1]: https://developers.google.com/android/nexus/images
  [2]: http://www.supersu.com/download
  [3]: http://ghoulich.xninja.org/2015/12/08/android_logcat_manual/
