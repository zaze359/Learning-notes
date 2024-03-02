# NodeJs

[Node.js 中文网 (nodejs.cn)](http://nodejs.cn/)



## Node版本管理工具

### nvm

基于shell 适用于 macOS 和 Linux。

#### 安装和配置

```shell
# 使用 brew 安装
brew install nvm
```

按照提示配置修改``.zshrc``环境变量

```shell
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
```

#### 常用命令

> 查看版本

```shell
# 查看 nvm 版本
nvm v

# 查看已安装 node 版本
nvm ls

# 查看远程node版本
nvm ls-remote
```

> node安装

```shell
# 安装最新版本
nvm install node

# 安装指定版本
nvm install 16.20.2

# 指定64位操作系统
nvm install 16.20.2 64
```

> 使用指定node版本

```shell
nvm use 16.20.2
nvm use 18.18.2
```

> 项目依赖下载

```shell
# 下载项目所需依赖, package.json 中指定
npm install
```

### fnm

类似nvm， 跨平台（macOS、Linux、Windows）。

#### 安装和配置

[下载地址：Releases · Schniz/fnm (github.com)](https://github.com/Schniz/fnm/releases)

```shell
brew install fnm
```

配置

```shell
eval "$(fnm env --use-on-cd)"
```

#### 常用命令

```shell
# 安装 node 最新的 TLS 版本。
fnm install --lts
```



---

## npm

```shell
# 查看版本
npm -v
# 更新
npm install -g npm
```

镜像地址

```shell
# 查看当前镜像
npm config get registry
# 官方镜像
npm config set registry "https://registry.npmjs.org"

# 淘宝
npm config set registry "https://registry.npmmirror.com"
```





---

## node-sass对应node版本

[Releases · sass/node-sass (github.com)](https://github.com/sass/node-sass/releases?page=1)





