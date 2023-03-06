# YAML

* YAML是 Kubernetes的标准工作语言，Kubernetes 中的 API对象都是用过 YAML来定义的。

* YAML是JSON的超集，即所有合法的JSON都是YAML。

* 用空格缩进，不用tab。防止 `found a tab character that violates indentation`异常。

| 语法     | 说明                                                         |
| -------- | ------------------------------------------------------------ |
| 层次关系 | 使用**缩进对齐表示层次**，可以不使用`花括号{}`和`方括号[]`。 |
| `: `     | 表示对象。与 JSON 基本相同，但 **Key 不需要使用双引号`""`包裹**。后面**必须要有空格** |
| `- `     | 表示数组。（有点类似 MarkDown的列表）。后面**必须要有空格**  |
| `#`      | 注释                                                         |
| `---`    | 在一个文件里分隔多个 YAML 对象                               |

> `--dry-run=client -o yaml`：表示生成一份yaml样例模板

```shell
kubectl run ngx --image=nginx:alpine --dry-run=client -o yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: ngx
  name: ngx-pod
spec:
  containers:
  - image: nginx:alpine
    name: ngx
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

[转为json](https://www.bejson.com/json/json2yaml/)如下：

```json
{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "creationTimestamp": null,
        "labels": {
            "run": "ngx"
        },
        "name": "ngx-pod"
    },
    "spec": {
        "containers": [
            {
                "image": "nginx:alpine",
                "name": "ngx",
                "resources": {}
            }
        ],
        "dnsPolicy": "ClusterFirst",
        "restartPolicy": "Always"
    },
    "status": {}
}
```

