---

title: Mac常用工具配置
date: 2020-04-16 13:40

---
Tags ： zaze cmd


# Mac常用工具配置

### Homebrew

- [官网地址][1]

- 安装
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
```
ruby -e "$(curl -fsSL /homebrew/go)
```

- 使用
```
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
```
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```


### unrar


### 文件已损坏

```
sudo xattr -d com.apple.quarantine /Applications/StarUML.app
```


  [1]: https://brew.sh
  
  [2]: https://ohmyz.sh