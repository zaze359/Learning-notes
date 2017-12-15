# Git

``git subtree add --prefix dependence http://xxx/xx/x.git master``

``git subtree pull --prefix dependence http://xxx/xx/x.git master``


## 切换

``git checkout [name] ``

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

