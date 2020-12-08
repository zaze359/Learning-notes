---

title: Mac常用工具配置
date: 2020-04-16 13:40

---
Tags ： zaze cmd


# Mac常用工具配置

### Homebrew

- [官网地址][https://brew.sh ]

- 安装
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
```bash
ruby -e "$(curl -fsSL /homebrew/go)
```

- 使用
```bash
brew deps xx	# 列出软件包的依赖关系
brew info xx	# 查看软件包信息
brew list		# 列出已安装的软件包
brew search xx
brew install xx
brew uninstall xx
brew update	xx		# 更新 Homebrew 的信息
brew outdated		# 看一下哪些软件可以升级
brew upgrade; brew cleanup    # 如果都要升级，直接升级完然后清理干净
brew upgrade <xxx>	# 如果不是所有的都要升级，那就这样升级指定的

brew cast install xx
```


### ohmyzsh

- [官网地址][2]

- 安装
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```


### unrar


### 文件已损坏

```bash
sudo xattr -d com.apple.quarantine /Applications/StarUML.app
```

### 处理html 无法直接打开问题
```bash
这个 @ 属性是用户在 Finder中对文件进行任意操作后就会被附带上，这可能导致在 OS X 下打包后放到 Linux 系统分享文件的时候，会出现莫名其妙的错误，兼因 tar 命令本身并不能区分 extend attributes。
这样的文件如果把扩展属性（Extend Attributes）去掉，就可以打开了。
一次性清除一个文件的所有扩展属性 extend attributes：
$ xattr -c filename 
对一个目录及其下的所有文件做清除操作：
$ xattr -rc directory 
```

[https://brew.sh]: https://brew.sh

[2]: https://ohmyz.sh