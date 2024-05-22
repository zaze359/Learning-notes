# Git常用命令记录

```shell
git clone xxxx.git
# 查看哪些文件发生变化了
git status -s
# 查看文件的具体修改内容
git diff
git diff util/src/main/java/com/zaze/utils/TraceHelper.kt


# 查看提交信息
git log

git rm -r xxx
git config --add core.filemode false   

# 撤销本地最近一次commit
git reset HEAD~
# 撤销变更
git reset HEAD util/src/main/java/com/zaze/utils/TraceHelper.kt

# 在所有的提交中找代码
git grep $regexp $(git rev-list --all)

# 避免自动merge
git pull --rebase

# 还原 B ~ D
git revert B^...D
```

## Config参数配置
```shell
git config --list

git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890
git config --global --unset http.proxy
git config --global --unset https.proxy


git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### 设置文件夹大小写敏感

由于git默认为大小写不敏感。通过以下命令修改

```shell
git config core.ignorecase = false
```

重命名文件夹调整大小写后提交到远程仓库

> ✨恭喜你远程仓库存在了未调整大小写前的文件夹和修改后的文件夹。简直了！👿

所以还有最后一步，删除之前到文件夹。🤪

## 基础操作

### 创建仓库

初始化git 仓库

```shell
git init
```

### 关联远程仓库

查看仓库远程地址配置

```shell
git remote -v 
```

建立/移除远程关联

```shell
# 建立远程关联
git remote add origin xxxxx.git
# 移除远程关联
git remote rm origin
```

根据提示进行操作

```shell
git pull origin master
git branch --set-upstream-to=origin/<branch> master
git push --set-upstream origin master
```

### 拉取代码

```shell
# 拉取最新，检查后合并
git fetch
# 拉取并合并
git pull
# 避免自动merge
git pull --rebase
```

### 提交代码

```shell
# 添加单个文件
git add build.gradle
# 添加所有代码
git add -A
# 提交代码，注意此时只是提交到本地
git commit -m "提交信息"
# 修改提交信息
git commit --amend

```

### 撤销变更

```shell
# 撤销本地最近一次commit
git reset HEAD~
# 撤销 某个文件变更
git reset HEAD util/src/main/java/com/zaze/utils/TraceHelper.kt
# 撤销变更，还原到远程 origin到状态
git reset origin
# --hard，撤销变更，并强制清除变更到文件
git reset --hard origin/master
```

### 推送到远程仓库

```shell
# 提交到远程仓库
git push 
```



## branch：分支

### 查看分支
```shell
git branch
git branch -r
git branch -a
git remote show origin   // 查看远程分支
```
### 创建分支
```shell
git branch branch1
```

### 切换分支
```shell
git checkout branch1
```

### 删除分支

删除指定分支
```shell
git branch -D branch1
```

删除本地多余分支(远程仓库中已不存在的)
```shell
git remote prune origin
```

### 合并分支变更

**merge**: 合并branch2中的所有变更当当前分支

```shell
git merge branch2

# 一般用于从公共分支合并到个人分支。
git rebase master
git rebase --continue
```

### 分支地址操作

查看远程地址

```shell
git remote get-url origin
```

修改远程地址

```shell
git remote set-url origin "xxxx"
```



## tag：标签

```bash
## 在控制台打印出当前仓库的所有标签-l 'v0.1.*' # 搜索符合模式的标签
git show v0.1.2 #查看标签信息
git tag v0.1.2 #创建量标签
git tag -a v0.1.2 -m "0.1.2版本" #创建附注标签
git tag -d v0.1.2
```

- 发布tag

```bash
git push origin v0.1.2 # 将v0.1.2标签提交到git服务器
git push origin –tags # 将本地所有标签一次性提交到git服务器
```

## patch：补丁

```
# sha1开始最近一次的补丁
git patch sha1  -1
```

```
git diff sha1 sha2 > init.diff
```

## SubTree

```bash
git subtree add --prefix dependence http://xxx/xx/x.git master
git subtree pull --prefix dependence http://xxx/xx/x.git master
```



## cherry-pick

[git cherry-pick 教程](https://www.ruanyifeng.com/blog/2020/04/git-cherry-pick.html)

**挑选指定提交**应用到当前分支

```shell
git cherry-pick <commitHash>
```

选择**某分支的最后一次提交**应用到当前分支

```shell
git cherry-pick <branchName>
```

选择多个提交

```shell
git cherry-pick <HashA> <HashB>
```

选择一系列连续的提交

```shell
## 不包含A提交
git cherry-pick A..B 
## 包含A提交 添加^
git cherry-pick A^..B 

git cherry-pick b2b51d6e5a8db07a7f3025f5f5f7c3bd430d8e47^..c536c1c121d8b665d185ff174cacc7fa9a3b9cb5

git config --global user.name "zaze"
git config --global user.email 359635919@qq.com

```



## stash：暂存

- 暂存

  ```shell
  git stash
  # or
  git stash save "aaa"
  ```

- 显示暂存列表

  ```shell
  git stash list
  ```

- 显示暂存内容

  ```shell
  # 默认stash@{0}， 0表示最近一个。
  git stash show
  # or
  git stash show stash@{0}
  ```

- 恢复暂存内容

  ```shell
  # 获取依然保留在暂存列表中, 默认stash@{0}
  git stash apply
  git stash apply stash@{0}
  # 获取并从暂存列表中删除, 默认stash@{0}
  git stash pop
  git stash pop stash@{0}
  ```

- 删除暂存内容

  ```shell
  # 默认删除最上面 stash@{0}
  git stash drop
  # or
  git stash drop stash@{0}
  ```

## git ignore
查看哪个忽略规则把它忽略掉了
```bash
git check-ignore -v [被忽略的文件或文件夹]
```