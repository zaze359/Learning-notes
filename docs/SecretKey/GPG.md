## GPG 

- 安装

```bash
# 安装
brew install -v gpg
```

- 生成密钥

```bash
# 生成密钥
gpg --generate-key
```

- 显示所有已创建密钥

**KeyId**: 后八位 CE1A2961

**密钥指纹**: 752319xxxxxxxxxxxxxxxxxxxxxxxCE1A2961

```bash
➜ gpg -k
/Users/zhaozhen/.gnupg/pubring.kbx
----------------------------------
pub   ed25519 2021-07-20 [SC] [有效至：2023-07-20]
      752319xxxxxxxxxxxxxxxxxxxxxxxCE1A2961
uid             [ 绝对 ] zhen zhao <359635919@qq.com>
sub   cv25519 2021-07-20 [E] [有效至：2023-07-20]
```
- 生成 secretKeyRingFile
```shell
gpg --export-secret-keys [密钥指纹] > secret.gpg
```

- 上传到公钥服务器
```shell
gpg --keyserver keyserver.ubuntu.com --send-keys [密钥指纹]
```