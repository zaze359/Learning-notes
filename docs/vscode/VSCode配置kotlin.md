# VSCode配置kotlin

## 下载安装kotlin

### 1. 下载安装
> [下载地址](https://github.com/JetBrains/kotlin/releases)

- ``mac``也可直接通过brew安装
```
brew install kotlin
```

- ``windows``下载完成后需要配置环境变量
```
E:\kotlin\bin
```

### 2. 验证kotlin
```
kotlinc -version
```

## 安装插件

- Kotlin Language
- Code Runner


## 配置Setting.json
管理 >> 设置 >> 右上角的编辑按钮
```
"code-runner.runInTerminal": true,
"terminal.integrated.shell.windows": "powershell.exe"
```