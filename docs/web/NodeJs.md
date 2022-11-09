# NodeJs

[Node.js 中文网 (nodejs.cn)](http://nodejs.cn/)



## node版本管理工具 nvm

### 安装nvm

```shell
brew install nvm
```

按照提示配置修改``.zshrc``环境变量

```
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
```

### nvm常用命令

- 查看版本

  ```
  nvm v
  ```

- node安装

  ```
  // 安装最新版本
  nvm install node
  
  // 安装指定版本
  nvm install 16.15.0
  
  // 指定64位操作系统
  nvm install 16.15.0 64
  ```

- 使用指定node版本

  ```
  nvm use 16.15.0
  ```

- 查看已安装版本

  ```
  nvm ls
  ```

- 项目依赖下载

```shell
# 下载项目所需依赖
npm install
```



## node-sass对于node版本

[Releases · sass/node-sass (github.com)](https://github.com/sass/node-sass/releases?page=1)

