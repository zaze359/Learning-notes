# git工作流

## 中心式协同工作流
同一个分支开发

- `git pull origin master` 把代码同步下来
- 改完后，`git commit` 到本地仓库中
- `git push origin master` 到远程仓库中
- 若失败则通过 `git pull --rebase` ,将远程的提交合并到本地
![git合并流程](https://static001.geekbang.org/resource/image/59/6b/5974a4026acca1000cd21772c4c52a6b.png)
- 若有冲突，处理后通过`git rebase --continue` 继续
![git处理冲突流程](https://static001.geekbang.org/resource/image/75/e7/75b3fea18fa91b837f4f3ae6db6ab6e7.png)

## 功能分支协同工作流
开辟分支开发功能(此分支上采用中心式协同工作流)，完成后再合并到主干

- `git checkout -b new-feature` 创建 `“new-feature”`分支
- 在`“new-feature”`分支上开发
- `git push -u origin new-feature` 把分支代码 push 到服务器
- 通过`git pull --rebase` 来拿到最新的这个分支的代码
- 最后提交合并到master



## 常用流程

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

### 3. 处理冲突后提交

```shell
git push origin master
```

### 4. 删除分支

```shell
git branch -d feature-xxx
```
