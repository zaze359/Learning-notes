# Git学习笔记

## 草稿

```bash
git clone xxxx.git
git status -s
git log
git diff
git rm -r xxx
git config --add core.filemode false   

// 撤销本地最近一次commit
git reset HEAD~

// 在所有的提交中找代码
git grep $regexp $(git rev-list --all)

// 避免自动merge
git pull --rebase
```

## 0. git工作流

### 中心式协同工作流
同一个分支开发

- git pull origin master把代码同步下来
- 改完后，git commit到本地仓库中
- git push origin master到远程仓库中
- 若失败则通过 git pull --rebase,将远程的提交合并到本地
![git合并流程](https://static001.geekbang.org/resource/image/59/6b/5974a4026acca1000cd21772c4c52a6b.png)
- 若有冲突，处理后通过git rebase --continue继续
![git处理冲突流程](https://static001.geekbang.org/resource/image/75/e7/75b3fea18fa91b837f4f3ae6db6ab6e7.png)

### 功能分支协同工作流
开辟分支开发功能(此分支上采用中心式协同工作流)，完成后再合并到主干

- git checkout -b new-feature 创建 “new-feature”分支
- 在“new-feature”分支上开发
- git push -u origin new-feature 把分支代码 push 到服务器
- 通过git pull --rebase来拿到最新的这个分支的代码
- 最后,提交合并到master

## 1. Config参数配置
```
git config --list

git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890
git config --global --unset http.proxy
git config --global --unset https.proxy
```


## 2. 关联远程仓库
1. 初始化git 仓库
```
git init
```

2. 查看仓库远程地址配置
```
git remote -v 
```

3. 建立/移除远程关联
```
git remote add origin xxxxx.git
git remote rm origin
```

4. 根据提示进行操作
```
git pull origin master
git branch --set-upstream-to=origin/<branch> master
git push --set-upstream origin master
```


## 3. 分支操作

### 查看分支
```
git branch
git branch -r
git branch -a
git remote show origin   // 查看远程分支
```
### 创建分支
```
git branch branch1
```

### 切换分支
```
git checkout branch1
```

### 删除分支

删除指定分支
```
git branch -D branch1
```

删除本地多余分支(远程仓库中已不存在的)
```
git remote prune origin
```

### 合并分支变更

**merge**: 合并branch2中的所有变更当当前分支

```bash
git merge branch2
```

**cherry-pick**: 挑选指定的功能合并到当前分支

```bash
git cherry-pick
```

### 分支地址操作

查看远程地址

```bash
git remote get-url origin
```

修改远程地址

```bash
git remote set-url origin "xxxx"
```

## SubTree

```bash
git subtree add --prefix dependence http://xxx/xx/x.git master
git subtree pull --prefix dependence http://xxx/xx/x.git master
```

## tag

```bash
## 在控制台打印出当前仓库的所有标签-l 'v0.1.*' # 搜索符合模式的标签
git show v0.1.2 #查看标签信息
git tag v0.1.2 #创建量标签
git tag -a v0.1.2 -m "0.1.2版本" #创建附注标签
git tag -d v0.1.2
```

- 标签发布

```bash
git push origin v0.1.2 # 将v0.1.2标签提交到git服务器
git push origin –tags # 将本地所有标签一次性提交到git服务器
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

1. 按功能或bugfix创建分支（基于master分支）

```
git checkout -b feature-xxx master
```

2. 开发完成后，合并功能到master分支

```
git checkout master
git merge --no-ff feature-xxx
git push origin master
```

3. 删除分支

```
git branch -d feature-xxx
```

## git  stash

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
查看哪个忽略规则把它忽略掉了
```bash
git check-ignore -v [被忽略的文件或文件夹]
```