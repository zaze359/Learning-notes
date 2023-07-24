# Python配置

## 安装

### Linux上安装Python

```shell
# Debian-based:
sudo apt install wget git python3 python3-venv
# Red Hat-based:
sudo dnf install wget git python3
# Arch-based:
sudo pacman -S wget git python3
```



### Windows上安装Python

方式一：直接在微软应用商店下载即可。



方式二：通过官网下载：[python Download Python | Python.org](https://www.python.org/downloads/)

> 下载完后执行并安装。
>
> 勾选`Add Python 3.10 to PATH`。

![image-20220913083226129](./Python%E9%85%8D%E7%BD%AE.assets/image-20220913083226129.png)



### MAC上安装python

```shell
brew search python3
brew install python3
```



## 版本管理

### Miniconda

[Miniconda — conda documentation](https://docs.conda.io/en/latest/miniconda.html#windows-installers)

## 常用配置

语法提示

```shell
pip3 install -U flake8
```

代码格式化

```shell
pip3 install -U autopep8
```

