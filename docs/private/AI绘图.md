# AI绘图

> stable-diffusion-webui

## 前置准备

> 遇到问题可以参考下方的 问题处理。记录一些我在部署是碰到的问题和解决方式。

### 安装python和git

> windows直接下载安装

[python配置](../env/Python配置.md)

[git安装](https://git-scm.com/download/win)

> Linux安装方式

```shell
# git
sudo apt-get install git
# Debian-based:
sudo apt install wget git python3 python3-venv
# Red Hat-based:
sudo dnf install wget git python3
# Arch-based:
sudo pacman -S wget git python3
```

### 配置stable-diffusion-webui

[AUTOMATIC1111/stable-diffusion-webui: Stable Diffusion web UI (github.com)](https://github.com/AUTOMATIC1111/stable-diffusion-webui)

```shell
git clone git@github.com:AUTOMATIC1111/stable-diffusion-webui.git
```

### 下载`model.ckpt`

模型决定的就是生成图片的画风，它是基础

[Dependencies · AUTOMATIC1111/stable-diffusion-webui Wiki (github.com)](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Dependencies)

```tex
magnet:?xt=urn:btih:3a4a612d75ed088ea542acac52f9f45987488d1c&dn=sd-v1-4.ckpt&tr=udp%3a%2f%2ftracker.openbittorrent.com%3a6969%2fannounce&tr=udp%3a%2f%2ftracker.opentrackr.org%3a1337
```

放到`..\stable-diffusion-webui\models\Stable-diffusion`目录下并重命名为`model.ckpt`。

### pip镜像设置

> 遇到无法下载是时修改使用国内镜像

```shell
# 清华镜像
python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip
# 豆瓣镜像
pip install -i http://pypi.douban.com/simple --trusted-host  pypi.douban.com -r requirements.txt
```



## 尝试运行

![image-20221030124705379](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030124705379.png)

> 运行失败在考虑进行对应环境的配置，配置完成后续都可使用次命令之间运行。

```shell
# 使用webui-user运行
./webui-user.bat
```

> 配置好环境能正常运行后，我们可以添加一些配置参数。
>
> 编辑webui-user 添加COMMANDLINE_ARGS`

```shell
# major speed increase for select cards
--xformers
```



## Linux环境配置

```shell

git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui

cd stable-diffusion-webui
# 创建python虚拟环境
python3 -m venv venv
# 激活环境
source venv/bin/activate
python -m pip install --upgrade pip wheel

# It's possible that you don't need "--precision full", dropping "--no-half" however crashes my drivers
TORCH_COMMAND='pip install torch torchvision --extra-index-url https://download.pytorch.org/whl/rocm5.1.1' 

# 启动
python launch.py --precision full --no-half
```

---

## windows环境配置

```shell
# 进入到项目中
cd stable-diffusion-webui
#
python3 -m venv venv
# 激活环境
.\venv\Scripts\Activate.ps1
# 更新
python -m pip install --upgrade pip wheel

# 启动
python launch.py --precision full --no-half

# 启动时可能提示需要安装的，根据实际情况选择安装。
pip3 install torch torchvision torchaudio
python -m pip install --upgrade pip wheel
pip3 install gfpgan clip
```



## 模型

常见的模型文件格式：

* pytorch 格式：`.ckpt`、`.pt`、`pth`。存在一定安全风险。
* safetensors 格式：`.safetensors`。

模型一般可以分为两大类。

* 大模型：是一种标准模型, 需要的训练量很大。自带了TextEncoder、U-Net、VAE等模型。
* 小模型：在大模型的基础上进行调整来实现想要的效果，成本低。如Textual inversion、Hypernetwork、LoRA等

| 模型                | 目录                                              | 大小  |
| ------------------- | ------------------------------------------------- | ----- |
| CheckPoint 基础模型 | `\stable-diffusion-webui\models\Stable-diffusion` | GB    |
| embedding           | `\stable-diffusion-webui\embeddings`              | KB    |
| Hypernetwork        | `\stable-diffusion-webui\models\hypernetworks`    | MB~GB |
| LoRA                | `\stable-diffusion-webui\models\lora`             | MB    |
| VUE                 | `\stable-diffusion-webui\models\VUE`              | MB    |



## 模型训练

> 通过大量的素材图片（图片需要具由一定的关联性）训练模型，最终会生成一个`.pt`文件。
>
> 此文件就是我们的专属魔法咒语。

### 训练前准备

#### 素材处理

先对素材进行裁剪，裁剪成一致分辨率的正方形。[在线裁剪网站](https://www.birme.net)

#### 安装deepdanbooru

官方文档：

> DeepDanbooru integration, creates danbooru style tags for anime prompts (add **--deepdanbooru** to commandline args)

将将`--deepdanbooru`添加到`webui-user.bat`/`webui-user.sh`脚本中的`commandline args`中。



![image-20221028155046295](./AI%E7%BB%98%E5%9B%BE.assets/image-20221028155046295.png)





#### Settings配置

**提升训练效率**

> 将`VAE`和` CLIP`从显存中去除。不同版本文案不同

![image-20221028153433333](./AI%E7%BB%98%E5%9B%BE.assets/image-20221028153433333.png)



![image-20221028220726343](./AI%E7%BB%98%E5%9B%BE.assets/image-20221028220726343.png)



**增强训练效果**

默认为`0.5`，调高一些。它决定了 我们训练的产物的对模型的影响程度。

![image-20221030141322867](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030141322867.png)

#### 保存设置

> 别忘记保存！！

![image-20221030141438848](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030141438848.png)



### 开始训练

![image-20221030143722493](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030143722493.png)

#### Create embedding（嵌入方式）

> 生成的模型在项目目录下，例如： `D:\GitRepository\stable-diffusion-webui\embeddings\test.pt`。

* **Name**：需要英文。同txt2img时我们输入的魔法词条。
* **Initialization text**：特征值。
* **Number of vectors per token**：所占的特征数。推荐3 ~ 15。

![image-20221030143703357](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030143703357.png)



#### Preprocess images （图像预处理）

* Source directory：我们的素材目录。
* Destination directory：处理后的输出目录。
* Width/Height：图片宽高。
* Create flipped copies：素材较少时可以勾选。会创建我们素材的反转镜像，从而有更多训练素材。
* Split oversized images：大图分割，之前已处理过就不需要勾选了。

![image-20221030143145789](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030143145789.png)



## 问题处理

运行过程中会从git拉取一些仓库。采用的是`Https`方式，我们可以关闭`ssl`，防止下载超时报错。

```shell
git config http.sslVerify "false"
```

### AMD显卡可能需要的特殊处理

> 若由于不支持AMD显卡报错，可以考虑修改`launcher.py`
>
> **出现不支持AMD显卡报错相关问题再配置**。

```python
# 原始内容
commandline_args = os.environ.get('COMMANDLINE_ARGS', "")
# 添加 --skip-torch-cuda-test
commandline_args = os.environ.get('COMMANDLINE_ARGS', "--skip-torch-cuda-test")
```

### deepdanbooru等依赖安装问题

我安装deepdanbooru 时碰到 `Installing deepdanboor` 一直卡住的问题，最后保存 timeout 或者 git openssl问题。

> git openssl：主要是由于内部使用了 https clone项目。

我在`stable-diffusion-webui`项目下的`repositories`目录中 `clone deepdanbooru`。

```shell
git clone git@github.com:KichangKim/DeepDanbooru.git deepdanbooru
```

> 然后进入 deepdanbooru 指定镜像安装依赖
>
> tensorflow timeout：是由于在国外下载太慢了。可以通过设置镜像解决

```shell
cd D:\GitRepository\stable-diffusion-webui\repositories\deepdanbooru
pip install -i http://pypi.douban.com/simple --trusted-host  pypi.douban.com -r requirements.txt
```

![image-20221030124811698](./AI%E7%BB%98%E5%9B%BE.assets/image-20221030124811698.png)



## 魔法学院

[元素法典——Novel AI 元素魔法全收录 (qq.com)](https://docs.qq.com/doc/DWHl3am5Zb05QbGVs)

[Lexica-AI白魔法图书馆](https://lexica.art/)

