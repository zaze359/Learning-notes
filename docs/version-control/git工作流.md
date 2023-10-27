# git工作流

## 中心式协同工作流
同一个分支开发

- `git pull origin master` 把代码同步下来
- 改完后，`git commit` 到本地仓库中
- `git push origin master` 到远程仓库中
- 若失败则通过 `git pull --rebase` ,将远程的提交合并到本地
![git合并流程](./git%E5%B7%A5%E4%BD%9C%E6%B5%81.assets/5974a4026acca1000cd21772c4c52a6b.png)
- 若有冲突，处理后通过`git rebase --continue` 继续
![git处理冲突流程](./git%E5%B7%A5%E4%BD%9C%E6%B5%81.assets/75b3fea18fa91b837f4f3ae6db6ab6e7.png)

## 功能分支协同工作流
开辟分支开发功能(此分支上采用中心式协同工作流)，完成后再合并到主干

- `git checkout -b new-feature` 创建 `“new-feature”`分支
- 在`“new-feature”`分支上开发
- `git push -u origin new-feature` 把分支代码 push 到服务器
- 通过`git pull --rebase` 来拿到最新的这个分支的代码
- 最后提交合并到master



## 常见操作

### 1. 创建分支

按功能或bugfix创建分支（基于master分支）

```shell
git checkout -b feature-xxx master
```

### 2. 合并分支内容

开发完成后，合并功能到master分支

```shell
git checkout master
git merge --no-ff feature-xxx
```

### 3. 冲突处理

`git pull` 拉取后 可能会发生冲突。

#### 较少修改

直接强制还原变更，然后拉取最新，并进行手动修改再提交

```shell
# 还原
git reset --hard origin/master
# 拉取最新
git pull
# 手动修改提交
```

#### 较多修改

撤销本地的提交，然后暂存。拉取最新代码，还原暂存的修改，本地处理冲突后再提交。

```shell
git reset origin
# 暂存
git stash
#
git pull
# 还原修改
git stash apply stash@{0}
# 处理冲突后重新add标记所有冲突已处理
git add .
#
git push
# 删除已应用的暂存信息
git stash drop stash@{0}
```

### 4. 处理冲突后提交

```shell
git add -A
git commit -m "描述"
# git push origin master
git push
```

### 5. 删除分支

```shell
git branch -d feature-xxx
```



