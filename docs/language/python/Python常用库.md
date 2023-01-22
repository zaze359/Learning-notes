# Python常用库

## 标准库

### collections

> OrderedDict
>
> 记录了添加顺序的字典

```python
from collections import OrderedDict

dicts = OrderedDict()

dicts["key1"] = "value1"
dicts["key2"] = "value2"
dicts["key3"] = "value3"

for key, value in dicts.items():
    print(key + "=" + value)
```

---

### json

* `json.dump()` : 存储数据。
* `json.load()` : 加载数据。

```kotlin
import json

filename = "./res/numbers.json"

numbers = [1, 3, 5, 7, 9]
with open(filename, "w") as f_obj:
    json.dump(numbers, f_obj)


with open(filename, "r") as f_obj:
    read_nums = json.load(f_obj)

print(read_nums)

```

---

## Pygame

### 安装

[GettingStarted - pygame wiki](https://www.pygame.org/wiki/GettingStarted)

```shell
python3 -m pip install -U pygame --user

# brew install hg sdl sdl_image sdl_ttf
# brew install sdl_mixer portmidi
```

### 验证

```shell
python3 -m pygame.examples.aliens
```

