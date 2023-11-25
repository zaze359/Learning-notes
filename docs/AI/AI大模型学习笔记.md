# AI大模型学习笔记

NLP：自然语言处理任务

LLM：第一代大语言模型



语言 >> 使用工具 >> 制造工具 >> 自我思考

## 语言模型

**语言模式的本质就是信息编码和解码的通道**。语言模型的进化历程：

1. 起源于图灵测试。
2. 基于规则的语言模型。定义一套文法规则例如 主谓宾，符合规则就认为是一个句子。
3. 基于统计的语言模型。利用一个大型的语料库训练，根据词与词直接的上下文关系建立一个概率数据模型。更好的泛化功能，更好的容错性。
   * 条件概率（N-gram Model）：P(W1,W2,Wn) = P(W1) * P(W2|W1) * (W3|W1,W2) ... P(Wn|W1,W2 ..., Wn-1)
   * 马尔科夫假设简化为二元模型（Bi-gram）：任意一个词出现的概率只同它前面那个词有关。
     * P(W1,W2,Wn) = P(W1) * P(W2|W1) * (W3|W2) ... P(Wn|Wn-1)

### 重要的里程碑

| 模型                                                        |      |                                                              |
| ----------------------------------------------------------- | ---- | ------------------------------------------------------------ |
| **N-gram**                                                  | 1948 | 基于前 n - 1个词 预测下一个词。Bi-gram：基于前一个（或前2个等）词预测下一个词。 |
| **Bag-of-word（词袋模型）**                                 | 1954 | 将一个句子或文档表示其单词的集合。                           |
| Distributed Representation                                  | 1986 | 以分布式激活的形式表示词。                                   |
| **Neural Probabilistic Language Model**（神经概率语言模型） | 2003 | 神经概率语言模型来建模。通过神经网络来学习单词之间的复杂关系。CNN、RNN、LSTM。 |
| **Word2vec（词向量）**                                      | 2013 | 一种简单高效的分布式单词表示方法。                           |
| **Pre-trained Language Model（预训练语言模型）**            | 2018 | 采用上下文表示，通过更大的语料库和更深的神经网络结构来进行预训练。如BERT、GPT等。核心技术就是Transformer架构。 |



## Transformer架构

Transformer 是一种用于自然语言处理 和 其他序列到序列任务的神经网络模型文本。

针对整个序列进行编解码，可以堆叠多个层来构成深度模型。



|       |                                                              |      |
| ----- | ------------------------------------------------------------ | ---- |
| Token | 文本分词之后的产物，训练数据。                               |      |
| 参数  | 神经网络函数的参数,用于处理token，是模型的一部分。           |      |
|       |                                                              |      |
| [CLS] | classification，BERT 中的每一个输入都需要先添加一个 CLS Token。 |      |
| [SEP] | separator，BERT中一个句子结束末尾必然存在这个分隔token       |      |

Transformer 的input结构：

* Token Embeddings：将输入文本分词，一个词形成一个token。例如`my`、`dog`就是2个token。
* Segment Embeddings：输入可以是多个句子，分词后标记这些token属于哪个句子。
* Position Embeddings：这个token的位置，是第几个token，这样多个token间就形成了关联。



### 编码器

transformer 串联了多个具有相同结构的编码器形成了深度神经网络。输入Embedding 序列 （词嵌入）X 经过这些编码器处理后就形成了已经习得全局上下文信息的一个新的Embedding序列 Z。

1. 将输入映射成 一个 embedding向量

2. 加入序列位置信息。
3. 进入编码器的主处理单元，包括2个子模块
   * 对输入序列做多头自注意力的处理。让模型学习序列的整体信息。
   * 按照位置来进行的全连接前馈网络。
4. 将编码器处理后生成的新的Embedding序列 Z 传递给解码器。

### 解码器

> 编码器整体采用的**自回归机制**：每次都会将上次的处理结果重新传给自己，辅助处理下一个数据，这样循环往复。

包括3个子模块

1. 输出预处理模块：获取解码器上一次输出的向量Y，使用带掩码的多头自注意力机制处理。
2. 读入编码器生成的序列Z，结合上一个子模块处理过的输出信息Y，整体再做多头自注意力。
3. 按位置的全连接前馈网络。



### 自注意力机制（The Self Attention）

专门用于处理序列的技术，捕捉序列之间的依赖关系。**根据不同的输入部分分配不同的权重**，这样模型在处理序列数据时**更加关注序列中更重要的部分**，能更好理解输入序列的语义讯息（上下文）。而RNN这类模型在每一步中都是做等同处理，忽略了序列中不同部分的重要性属性。

* 计算出输入序列中的每一个元素（词向量）和其他元素的**关联程度**。关联程度高，权重就高。
* 多头就是多个维度，使用矩阵来记录。能表示各种各样复杂的关系。

主要由以下三个部分组成：

* Query、Key、Value向量：每一个元素都包括这三个向量，由【词向量 * (Query、Key、Value)三个矩阵】计算得到。
* Attention Scores（注意力得分）：Query向量和其他Key向量之间的相似度得分。(Dot Product)。
* Attention Weight（权重）：最终输出。将注意力得分通过 softmax进行归一化得到权重。每个 Value向量的加权平均值。

> Query 和 其他元素的Key 决定得分。各个得分 和 Value 加权平均后决定输出（权重）。

多头处理：将输入向量进行线性变换后进行上述计算，最后进行聚合成一个新的向量。



### 位置编码

是一种能将源词和上下文中每个位置的目标词相互关联的机制，用于表明单词在一个序列中的位置信息。传统的神经网络 RNN、CNN、LSTM中是使用循环记忆来捕捉单词的位置信息，但是Transformer中不存在这中循环机制，所以需要自己输入单词的位置信息。



## 预训练大模型使用方法

例如BERT、GPT等模型。

### 大模型 + 小模型

使用大量的语料库训练一个比较强大的模型，然后再使用特定领域的一个小数据集来微调模型。

### Prompt提示工程

不使用小模型微调，而是直接向强大的模型提出一个好问题，由模型直接生成答案。GPT的训练和使用就是通过Prompt来完成的



## Hugging Face

[Hugging Face – The AI community building the future.](https://huggingface.co/)

一个 AI社区。可以下载/上传模型、数据集等。

```shell
pip install tensorflow
pip install datasets
pip install transformers
```





## Datasets

问答、生成、命名实体识别、情感分类、文本总结

| 数据集 |                              |      |
| ------ | ---------------------------- | ---- |
| SQuAD  | 用于**问答任务**的标准数据集 |      |
|        |                              |      |
|        |                              |      |



## 聊天机器人

Telegram



## ChatGPT

一种 生成式预训练 Transformers。

文本预测，类似接龙，自回归



| message role |                             | content |
| ------------ | --------------------------- | ------- |
| system       | 系统消息，指定ChatGPT的人设 |         |
| user         | 用户消息，用于正常对话      |         |
| assistant    | 助手消息，辅助给定上下文    |         |



## Github相关项目

### chatgpt-web

[Chanzhaoyu/chatgpt-web: 用 Express 和 Vue3 搭建的 ChatGPT 演示网页 (github.com)](https://github.com/Chanzhaoyu/chatgpt-web)

### LangChain

[hwchase17/langchain: ⚡ Building applications with LLMs through composability ⚡ (github.com)](https://github.com/hwchase17/langchain)

这个三方开源库用于解决 OpenAI 的 API 无法联网的痛点。

1. 可以将 LLM 模型与外部数据源进行连接。
2. 允许与 LLM 模型进行交互。

[liaokongVFX/LangChain-Chinese-Getting-Started-Guide: LangChain 的中文入门教程 (github.com)](https://github.com/liaokongVFX/LangChain-Chinese-Getting-Started-Guide)

### ChatGLM2-6B

[THUDM/ChatGLM2-6B: ChatGLM2-6B: An Open Bilingual Chat LLM | 开源双语对话语言模型 (github.com)](https://github.com/THUDM/ChatGLM2-6B)

### ChatGLM-Tuning

[mymusise/ChatGLM-Tuning: 一种平价的chatgpt实现方案, 基于ChatGLM-6B + LoRA (github.com)](https://github.com/mymusise/ChatGLM-Tuning)



