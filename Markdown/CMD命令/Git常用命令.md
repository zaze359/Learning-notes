Tags : zaze cmd

[TOC]

# Git常用命令

## 基础

```
git clone xxxx.git
git status -s
git log
git diff
git rm -r xxx
git config --add core.filemode false   

// 撤销本地最近一次commit
git reset HEAD~
```

## 参数配置
```
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890
git config --global --unset http.proxy
git config --global --unset https.proxy
git remote set-url origin http://xxxx
```

## 分支处理

### 2.1 分支操作

```
git checkout xxx # 切换
git branch branch_222 #创建分支
```

- 删除本地多余分支(远程仓库中已不存在的)
```
git remote prune origin
```

- 合并
```
git merge xxx
```

### 2.3 分支查看

```
git branch
git branch -r
git branch -a
git remote show origin   // 查看远程分支
```
### 2.4 更换分支地址
```
git remote set-url origin "xxxxxx"
```

## SubTree


``git subtree add --prefix dependence http://xxx/xx/x.git master``
``git subtree pull --prefix dependence http://xxx/xx/x.git master``


## tag

```
 # 在控制台打印出当前仓库的所有标签
 -l 'v0.1.*' # 搜索符合模式的标签
git show v0.1.2 #查看标签信息
git tag v0.1.2 #创建量标签
git tag -a v0.1.2 -m "0.1.2版本" #创建附注标签
git tag -d v0.1.2
```

- 标签发布

```
$ git push origin v0.1.2 # 将v0.1.2标签提交到git服务器
$ git push origin –tags # 将本地所有标签一次性提交到git服务器
```

## 补丁

```
sha1开始最近一次的补丁
git patch sha1  -1
```

```
git diff sha1 sha2 > init.diff
```


## 流程


- 按功能或bugfix创建分支（基于master分支）
```
git checkout -b feature-xxx master
```

- 开发完成后，合并功能分支到master：
```
git checkout master
git merge --no-ff feature-xxx
git push origin master
```
- 删除分支
```
git branch -d feature-xxx
```

## git - stash

```
git stash 
git stash save "aaa"
git stash pop
git stash pop stash@{0}
git stash apply stash@{0}
git stash show stash@{0}
git stash drop stash@{0}
```

## git ignore

```bash
# 查看哪个忽略规则把它忽略掉了:
git check-ignore -v 被忽略的文件或文件夹
```

