# APK手动签名参考

## 主要流程

### 1. 使用keytool生成签名文件:

> keystore文件: android_demo.keystore
>
> password: 123456
>
> alias:android

```shell
keytool -genkey -v -keystore android.keystore -alias android -keyalg RSA -validity 20000 -keystore android_demo.keystore
```
![image-20230211145911053](./APK%E6%89%8B%E5%8A%A8%E7%AD%BE%E5%90%8D%E5%8F%82%E8%80%83.assets/image-20230211145911053.png)

### 2. apk进行签名

#### ~~2.1. jarsigner(v1签名)~~

```shell
jarsigner -verbose -digestalg SHA1 -sigalg MD5withRSA -keystore android_zaze.keystore -storepass 123456 -signedjar your_signed.apk source.apk android
```

#### 2.2. apksigner(✨推荐)
以下以v1,v2方式对应用进行签名:

```shell
apksigner sign -verbose --ks android_demo.keystore --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --ks-key-alias android --ks-pass pass:123456 --key-pass pass:123456 --out /Users/zhaozhen/Downloads/signed.apk source.apk
```

### 3. 封装脚本文件

#### 3.1. **signer.sh**

对apksigner进行了简单的封装, 执行签名操作。

```shell
#!/bin/bash

#signedApk=${4#*/}
#signedApk=${4##*/}
signedApk=${4##*/}
signedApkName=${signedApk%.*}
echo "-------------------- sign $signedApkName start"
echo "脚本 : $0 ";
echo "apk file  : $4 ";
echo "keystore : $1 ";
echo "keystore pwd : $2 ";
echo "keystore alias : $3 ";
echo "signedApk  : $signedApk ";
echo "signedApkName : $signedApkName ";
outPath="/Users/zhaozhen/Downloads/signed/${signedApkName}_signed.apk"

# 仅开启了v1,v2
# --v1-signer-name cert
/Users/zhaozhen/Library/Android/sdk/build-tools/29.0.2/apksigner sign -verbose --ks $1 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --ks-key-alias $3 --ks-pass pass:$2 --key-pass pass:$2 --out $outPath $4 

# jarsigner -verbose -digestalg SHA1 -sigalg MD5withRSA -keystore $1 -storepass $2 -signedjar $outPath $4 $3
echo "-------------------- sign $signedApkName end"

```

#### 3.2. **do_sign.sh**

需要执行签名的apk的配置文件, 内部调用了signer.sh。

```shell
##!/bin/bash

mkdir /Users/zhaozhen/Downloads/signed/

signer.sh /Users/zhaozhen/Downloads/android_demo.keystore 123456 android /Users/zhaozhen/Downloads/unsigned.apk

open /Users/zhaozhen/Downloads/signed/
```



## 相关命令摘录

### keytool

#### 查看keystore文件

```shell
keytool -list -v -keystore android_zaze.keystore
```

#### 查看CERT.RSA文件

RSA文件可通过解压apk文件后在META-INF中获取

```shell
keytool -printcert -file CERT.RSA
```

### apksigner

#### 查看apk签名信息

```shell
/Users/zhaozhen/Library/Android/sdk/build-tools/29.0.2/apksigner verify -v xxx.apk
# 签名信息
apksigner verify --print-certs xxx.apk
# 签名版本
apksigner verify -v xxx.apk
#
apksigner verify --min-sdk-version

```

#### other

```shell
# -f : 输出文件覆盖源文件
# -v : 详细的输出log
# -p : outfile.zip should use the same page alignment for all shared object files within infile.zip
# -c : 检查当前APK是否已经执行过Align优化。另外上面的数字4是代表按照4字节（32位）边界对齐。
java -jar apksigner.jar sign    //执行签名操作
# --ks ***                        //签名证书路径
# --ks-key-alias ***              //生成jks/keystore时指定的alias
# --ks-pass pass:***              //KeyStore密码
# --key-pass pass:***             //签署者的密码，即生成jks时指定alias对应的密码
# --out output.apk                //输出路径
# input.apk                       //被签名的apk

apksigner sign -verbose --ks android_zaze.keystore --ks-key-alias android --out app-release-signed.apk app-release_protected.apk 

java -jar apksigner.jar sign  --ks ***  --ks-key-alias ***  --ks-pass pass:***  --key-pass pass:***  --out output.apk  input.apk  
```

