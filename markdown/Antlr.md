# Antlr（java编写）

Antlr是 将语法文件转换成可以识别改语法文件所描述的语言 的程序


1. ANTLR 语言识别的一个工具 (ANother Tool for Language Recognition ) 是一种语言工具，它提供了一个框架，可以通过包含 Java, C++, 或 C# 动作（action）的语法描述来构造语言识别器，编译器和解释器。 计算机语言的解析已经变成了一种非常普遍的工作，在这方面的理论和工具经过近 40 年的发展已经相当成熟，使用 Antlr 等识别工具来识别，解析，构造编译器比手工编程更加容易，同时开发的程序也更易于维护。
2. 语言识别的工具有很多种，比如大名鼎鼎的 Lex 和 YACC，Linux 中有他们的开源版本，分别是 Flex 和 Bison。在 Java 社区里，除了 Antlr 外，语言识别工具还有 JavaCC 和 SableCC 等。
3. 和大多数语言识别工具一样，Antlr 使用上下文无关文法描述语言。最新的 Antlr 是一个基于 LL(*) 的语言识别器。在 Antlr 中通过解析用户自定义的上下文无关文法，自动生成词法分析器 (Lexer)、语法分析器 (Parser) 和树分析器 (Tree Parser)。



## 1.1 ANTLR全景

当我们实现一种语言时，我们需要构建读取句子（sentence）的应用，并对输入中的元素做出反应。如果应用计算或执行句子，我们就叫它解释器（interpreter），包括计算器、配置文件读取器、Python解释器都属于解释器。如果我们将句子转换成另一种语言，我们就叫它翻译器（translator），像Java到C#的翻译器和编译器都属于翻译器。不管是解释器还是翻译器，应用首先都要识别出所有有效的句子、词组、字词组等，识别语言的程序就叫解析器（parser）或语法分析器（syntax analyzer）。我们学习的重点就是如何实现自己的解析器，去解析我们的目标语言，像DSL语言、配置文件、自定义SQL等等。

## 1.2 元编程

手动编写解析器是非常繁琐的，所以我们有了ANTLR。只需编写ANTLR的语法文件，描述我们要解析的语言的语法，之后ANTLR就会自动生成能解析这种语言的解析器。也就是说，ANTLR是一种能写出程序的程序。ANTLR语言的语法，就是元语言（meta-language）。


## base


- **词法分析（Lexical analysis或Scanning）和词法分析程序（Lexical analyzer或Scanner）** 

　　词法分析阶段是编译过程的第一个阶段。这个阶段的任务是从左到右一个字符一个字符地读入源程序，即对构成源程序的字符流进行扫描然后根据构词规则识别单词(也称单词符号或符号)。词法分析程序实现这个任务。词法分析程序可以使用lex等工具自动生成。

- **语法分析（Syntax analysis或Parsing）和语法分析程序（Parser）** 

　　语法分析是编译过程的一个逻辑阶段。语法分析的任务是在词法分析的基础上将单词序列组合成各类语法短语，如“程序”，“语句”，“表达式”等等.语法分析程序判断源程序在结构上是否正确.源程序的结构由上下文无关文法描述.

- **语义分析（Syntax analysis）** 

　　语义分析是编译过程的一个逻辑阶段. 语义分析的任务是对结构上正确的源程序进行上下文有关性质的审查, 进行类型审查.例如一个C程序片断:
　　int arr[2],b;
　　b = arr * 10; 
　　源程序的结构是正确的. 
　　语义分析将审查类型并报告错误:不能在表达式中使用一个数组变量,赋值语句的右端和左端的类型不匹配.




## 文法定义

```
/** This is a document comment */
grammarType grammar name;    // GrammarType Must be the one of the types we talked above;   name is the Name of this grammar, which should indicating its role.

<<optionsSpec>>                // Specifics about Options.

<<tokensSpec>>                // Specifics about Tokens.

<<attributeScopes>>          // Specifics about Tokens.

<<actions>>                     // Actions

/** doc comment */
rule1 : ... | ... | ... ;
rule2 : ... | ... | ... ;
...

```

上述的这个基本结构的次序（指语法类型、选项等等）不能颠倒。在这些基本细节之后，紧跟着的是规则（Rules），同一条规则之间可以用"|"来表示“或”，每条规则均以分号结尾



文件的头部是 grammar 关键字，定义文法的名字，必须与文法文件文件的名字相同
**Demo.g4**

`` grammar Demo;``


**DemoLexer**是Antlr生成的**词法分析器**，**DemoParser**是 Antlr 生成的**语法分析器**