# Cocos2dx


## 新建项目


## 资源管理器

![资源管理器](/Users/zaze/Desktop/markdown/res_cocos2dx/资源管理器.png)

* BF(Bitmap Font) 位图字体, 游戏开发中常用的字体资源


## 创建游戏场景


### Scene
在 Cocos Creator 中，游戏场景（Scene）是开发时组织游戏内容的中心，也是呈现给玩家所有游戏内容的载体。游戏场景中一般会包括以下内容:

* 场景图像和文字（Sprite，Label）
* 角色
* 以组件形式附加在场景节点上的游戏逻辑脚本


### Canvas

打开场景后，层级管理器中会显示当前场景中的所有节点和他们的层级关系。我们刚刚新建的场景中只有一个名叫Canvas的节点，Canvas可以被称为画布节点或渲染根节点，点击选中Canvas，可以在属性检查器中看到他的属性。
![层级管理器](/Users/zaze/Desktop/markdown/res_cocos2dx/层级管理器.png)
![属性检查器](/Users/zaze/Desktop/markdown/res_cocos2dx/属性检查器.png)

这里的Design Resolution属性规定了游戏的设计分辨率，Fit Height和Fit Width规定了在不同尺寸的屏幕上运行时，我们将如何缩放Canvas以适配不同的分辨率。

由于提供了多分辨率适配的功能，我们一般会将场景中的所有负责图像显示的节点都放在Canvas下面。这样当Canvas的scale（缩放）属性改变时，所有作为其子节点的图像也会跟着一起缩放以适应不同屏幕的大小。

### 场景布置

- 一系列的拖拽 修改属性


## 代码登场

### 创建脚本


1. 在**资源管理器**中右键点击``assets``文件夹，选择``新建->文件夹``
2. 右键点击``New Folder``，选择``重命名``，将其改名为``scripts``，之后我们所有的脚本都会存放在这里。
3. 右键点击``scripts``文件夹，选择``新建->JavaScript``，创建一个JavaScript脚本
4. 将新建脚本的名字改为``Player``。双击这个脚本，打开代码编辑器。

**注意：** Cocos Creator 中脚本名称就是组件的名称，这个命名是大小写敏感的！如果组件名称的大小写不正确，将无法正确通过名称使用组件！


### 方法解释

``onLoad``方法会在场景加载后立刻执行，所以我们会把初始化相关的操作和逻辑都放在这里面。

