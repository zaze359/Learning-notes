---
Tags : zaze

---

[TOC]

---

# Git 

```
git clone xxxx.git

git status -s

git log

git diff

git rm -r xxx
```

## 分支处理

- 切换分支
```
git checkout xxx
```

- 创建分支

```
git branch branch_222
```

- 查看远程分支
```
git remote show origin 
```

- 查看本地分支
```
git branch
git branch -r
git branch -a
```

- 删除本地分支(远程仓库中已不存在的)
```
git remote prune origin
```

- 合并
```
git merge xxx
```


## SubTree



``git subtree add --prefix dependence http://xxx/xx/x.git master``

``git subtree pull --prefix dependence http://xxx/xx/x.git master``


## tag

- 列出标签

```
$ git tag # 在控制台打印出当前仓库的所有标签
$ git tag -l ‘v0.1.*’ # 搜索符合模式的标签
```

- 查看标签信息

``$ git show v0.1.2``

- 创建轻量标签

``$ git tag v0.1.2-light``

- 创建附注标签

``$ git tag -a v0.1.2 -m “0.1.2版本”``

- 删除标签

``$ git tag -d v0.1.2``

- 标签发布

```
$ git push origin v0.1.2 # 将v0.1.2标签提交到git服务器
$ git push origin –tags # 将本地所有标签一次性提交到git服务器
```

