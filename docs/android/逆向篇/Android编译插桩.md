# Android编译插桩



![image-20221003181041017](./Android%E7%BC%96%E8%AF%91%E6%8F%92%E6%A1%A9.assets/image-20221003181041017.png)



## AspectJ

[9. Aspect Oriented Programming with Spring](https://docs.spring.io/spring-framework/docs/3.2.x/spring-framework-reference/html/aop.html)

| 概念          |                                              |                                          |
| ------------- | -------------------------------------------- | ---------------------------------------- |
| Aspect        | 切面                                         |                                          |
| Join Point    | 连接点，Spring AOP中代表一次方法的执行。     | 可以获取方法的信息                       |
| Advice        | 通知，在连接点执行的动作。                   | 定义在连接点之前做什么、之后做什么等的。 |
| Pointcut      | 切入点，说明如何匹配连接点。                 |                                          |
| Introduction  | 引入，为现有类型声明额外的方法和属性。       |                                          |
| Target object | AOP代理的目标对象。                          |                                          |
| AOP proxy     | AOP代理对象，JDK动态代理或者CGLIB代理        |                                          |
| Weaving       | 织入，连接切面和目标对象或类型创建代理的过程 |                                          |

| 注解            |                                              |      |
| --------------- | -------------------------------------------- | ---- |
| @Aspect         | 声明一个切面，需要同时将该类声明成一个Bean。 |      |
| @Before         | 在方法执行之前                               |      |
| @Pointcut       | 定义切入点                                   |      |
| @AfterReturning | 成功返回之后执行                             |      |
| @AfterThrowing  | 抛异常后执行                                 |      |
| @After          | 不管什么清空，在方法执行之后                 |      |
| @Around         | 包含了整个过程                               |      |
| @Order          | 指定切面的执行顺序                           |      |



```java
@Aspect 
@Component
@Slf4j
public class LoggerAdvice {

    @Before(value = "within(com.zaze..*) && @annotation(loggerManage)")
    public void addBeforeLogger(JoinPoint joinPoint, LoggerManage loggerManage) {
        log.info("开始执行【{}】", loggerManage.description());
        log.info(joinPoint.getSignature().toString());
        log.info(parseParams(joinPoint.getArgs()));
    }

    @AfterReturning(value = "within(com.zaze..*) && @annotation(loggerManage)", returning = "result")
    public void addAfterReturningLogger(JoinPoint joinPoint, LoggerManage loggerManage, Object result) {
        log.info("执行【{}】; 结果: {}", loggerManage.description(), result);
        log.info("结束执行【{}】", loggerManage.description());
    }

    @AfterThrowing(pointcut = "within(com.zaze..*) && @annotation(loggerManage)", throwing = "ex")
    public void addAfterThrowingLogger(JoinPoint joinPoint, LoggerManage loggerManage, Exception ex) {
        log.error("执行【{}】异常", loggerManage.description(), ex);
    }

    private String parseParams(Object[] params) {
        if (null == params || params.length <= 0 || params.length > 1024) {
            return "";
        }
        StringBuilder param = new StringBuilder("传入参数[{}] ");
        for (Object obj : params) {
            param.append(obj.toString()).append("  ");
        }
        return param.toString();
    }

}
```





## ASM