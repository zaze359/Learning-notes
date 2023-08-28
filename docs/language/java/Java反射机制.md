# Java反射机制



## 什么是反射

Java反射就是Java程序能够在运行中获取类内部信息，并进行修改。这种动态获取的信息以及动态调用对象的方法的功能也是Java被视为动态语言的一个关键特性。

* 对于任意一个类，都能够知道这个类的所有属性和方法；

* 对于任意一个对象，都能够调用它的任意一个方法和属性

## 反射的作用

反射机制允许Java程序在运行时取得任何一个已知名称的class（仅需要名称，可以是动态加载进来的类）的内部信息，包括包括其modifiers(修饰符)，fields(属性)，methods(方法)等，并可于运行时改变fields内容或调用methods。

* 动态代理。
* 不需要直接链接源代码，降低代码的耦合度（注解、EventBus、Gson）。

## 反射存在的问题

* 性能问题：由于反射涉及动态解析的类型，会导致**虚拟机无法对代码进行优化**。且每次执行反射(invoke)都会进行**检查访问权限，参数校验、参数的封装和解封**等，使用不当会造成很高的资源消耗。（即使对反射对象做缓存优化、关闭访问检查，频繁使用依然造成较高的性能损耗）。
* 兼容性问题：反射可以访问私有方法和变量，这些往往在后续迭代中会发生改变，每次改动相关反射代码都需要进行适配调整。
* 代码混淆：涉及到反射调用的代码都无法进行混淆。

## 反射的使用

> 通过源码可知返回的Method和Field都是一份拷贝，所以对他们的属性修改仅会影响到当前获得的备份。例如`setAccessible(true)`，重新获取时需要重新设置。

* 反射调用函数：获取Class实例对象，然后获取需要反射的Method，调用`Method.invoke()`方法。

* 反射修改属性：获取Class实例对象，然后获取需要修改的属性Field, 调用`Field.set()`方法修改属性值。 

### 获取Class类的实例

> 一个类被JVM加载后，有且仅有一个class对象实例。我们通过它来获取类相关西信息。

使用`.class`获取Class实例：

```java
Class<?> boolClass = Boolean.class;
```

使用`obj.getClass()`函数获取Class实例：

```java
AssetManager assetManager = AssetManager.class.newInstance();
Class<?> assetManagerClass = assetManager.getClass();
```

使用`Class.forName(classPath)`获取Class实例：

```java
// 必须是完整的类路径
Class<?> clazz = Class.forName("com.android.okhttp.HttpHandler");
```

### Class常用函数

> 方法名中带有`Declared`的函数：获取所有，包括了**private、protected、public， 但是不会获取父类的方法**。
>
> 不带有`Declared`的函数：**仅能获取public声明的，会递归查找父类或接口中的方法**。
>
> 两类方法内部最终调用相同的函数`privateGetDeclaredMthods`和`privateGetDeclaredFields`,不过在`getMthods`和`getFields`流程中多了递归操作。

| Class常用函数                                                | 说明                                                     |      |
| :----------------------------------------------------------- | -------------------------------------------------------- | ---- |
| `getName()`                                                  | 获取完整的类名                                           |      |
| `newInstance()`                                              | 使用无参构造函数构建对象                                 |      |
|                                                              |                                                          |      |
| `getFields()`                                                | 获取类的public成员变量                                   |      |
| `getDeclaredFields()`                                        | 获取类的所有属性成员变量。                               |      |
| `getDeclaredField(String name)`                              | 获取指定名称为name的成员变量                             |      |
|                                                              |                                                          |      |
| `getMethods()`                                               | 获取所有public的方法。                                   |      |
| `getMethod(String name, Class<?>... parameterTypes)`         | 获取函数名为name，参数类型为parameterTypes的public方法。 |      |
| `getDeclaredMethods()`                                       | 类或接口的所有方法。                                     |      |
| `getDeclaredMethod(String name, Class<?>... parameterTypes)` | 获取函数名为name，参数类型为parameterTypes的方法。       |      |
|                                                              |                                                          |      |
| `getConstructors()`                                          | 获取public声明的构造函数。                               |      |
| `getDeclaredConstructors()`                                  | 获取所有声明的构造函数。                                 |      |
| `getDeclaredConstructor(Class<?>... parameterTypes)`         | 获取特定构造方法。parameterTypes指定参数类型             |      |

### Method常用函数

| Method常用函数                       |                                                              |      |
| ------------------------------------ | ------------------------------------------------------------ | ---- |
| `getName() `                         | 获取方法名。                                                 |      |
| `setAccessible(boolean flag)`        | 访问权限检查的开关：值为 true，则表示反射的对象在使用时应该取消 java 语言的访问检查；反之不取消。通常使用时设置为true。 |      |
| `invoke(Object obj, Object... args)` | 执行方法。obj：指定对象实例，静态方法忽略该值。args：指定方法参数。 |      |
|                                      |                                                              |      |

### Field常用函数

| Field常用函数                   |                                                              |      |
| ------------------------------- | ------------------------------------------------------------ | ---- |
| `getName() `                    | 获取属性名。                                                 |      |
| `setAccessible(boolean flag)`   | 同Method，访问权限检查的开关。                               |      |
| `get(Object obj)`               | 获取属性的值。obj：对象实例，静态属性时忽略该值。            |      |
| `set(Object obj, Object value)` | 修改属性的值。obj：对象实例，静态属性时忽略该值。value：修改的值。 |      |
|                                 |                                                              |      |

### final属性值的修改问题

对于final修饰的属性，需要修改Field 的 modifiers属性，去除它的final修饰。

因为**final修饰的常量（静态、非静态相同）**，本身将被编译器优化，内联到使用处，所以**反射修改无效**，依然还是原来的值。

```java
// 此处以静态常量、变量为例子，非静态相同。
public class TestJava {
    // 普通的静态变量，可以正常反射修改。
    // private static String name = "张三";
    // 静态常量，反射修改无效，会被内联到使用处
    private static final String name = "张三";
    // 区别于上方静态常量，此处为对象，反射修改可以生效
    // private static final String name = new String("张三"); 
    public static String getName() {
        return name;
    }
    public static void main(String args[]) {
        System.out.println("before: " + name);
        try {
            Field nameField = TestJava.class.getDeclaredField("name");
            // 若name为final修饰，则需要修改nameField中的modifiers，去除final
            // 否则此时即使设置了nameField.setAccessible(true)，也会抛出IllegalAccessException。
            Field modifiersField = Field.class.getDeclaredField("modifiers");
            modifiersField.setAccessible(true);
            modifiersField.setInt(nameField, nameField.getModifiers() & ~Modifier.FINAL);
            //
            nameField.setAccessible(true);
            nameField.set(null, "李四");
            System.out.println("field: " + nameField.get(null)); // 输出李四
            System.out.println("name: " + TestJava.name); // 张三
            System.out.println("getName: " + TestJava.getName()); // 张三
        } catch (Exception e) {
            e.printStackTrace();
        }
        // Node node = new Node(16);
        // System.out.println("node: " + node.forwards[0]);
    }

    public static class Node {
        private int data = -1;
        private Node forwards[];
        private int maxLevel = 0;

        public Node(int level) {
            forwards = new Node[level];
        }

        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("{ data: ");
            builder.append(data);
            builder.append("; levels: ");
            builder.append(maxLevel);
            builder.append(" }");
            return builder.toString();
        }
    }
}

```

### 泛型处理

|                       |                                            |                            |
| --------------------- | ------------------------------------------ | -------------------------- |
| Generic type          | ParameterizedType                          | 泛型。`List<E>`            |
| Parameterized type    | ParameterizedType                          | 参数化类型，`List<String>` |
| Raw type              | `ParameterizedType#getRawType : Class<?>`  | 原始类型。`List`           |
| Actual type parameter | `ParameterizedType#getActualTypeArguments` | 实际类型参数。`String`     |

```java
public static <T> List<T> parseJsonToList(String json, final Class<T> clazz) {
    // 例如 clazz = String.class
    // 这里的 new ParameterizedType() 生成了 List<String> 类型
    return parseJsonToList(json, new ParameterizedType() {
        @NotNull
        @Override
        public Type[] getActualTypeArguments() {
            // 实际类型参数：这里指泛型 T 的真实类型。
            return new Class[]{clazz};
        }

        @NotNull
        @Override
        public Type getRawType() {
            // 原始类型，
            return List.class;
        }

        @Override
        public Type getOwnerType() {
            return null;
        }
    });
}
```

匿名内部类方式 获取泛型类型。`Base<T>`

```kotlin
// 获取子类
val superclass = this::class.java.genericSuperclass
// 获取泛型参数类型
val parameterized = superclass as ParameterizedType
// 获取 参数类型
val type = parameterized.actualTypeArguments[0]
// 可以直接转为 class
val clazz : Class<*> = type as Class<*>
```







## 代码案例

### 案例一：反射的简单使用

```java
package com.zaze.utils;

import android.text.TextUtils;

import com.zaze.utils.log.ZLog;
import com.zaze.utils.log.ZTag;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * Description :
 *
 * @author : ZAZE
 * @version : 2017-07-27 - 16:44`
 */
public class ReflectUtil {
    public static boolean showLog = false;

    public static Object getField(Object self, String field) throws Exception {
        return self.getClass().getField(field).get(self);
    }

    /**
     * 反射执行方法
     */
    public static Object executeMethod(Object self, String functionName, Object... args) throws Exception {
        if (self == null) {
            return null;
        }
        return executeMethod(self.getClass(), self, functionName, args);
    }

    private static Object executeMethod(Class<?> clazz, Object receiver, String functionName, Object... args) throws Exception {
        if (showLog) {
            ZLog.d(ZTag.TAG_DEBUG, "functionName : " + functionName);
        }
        Class<?>[] classes = null;
        if (args != null && args.length > 0) {
            classes = new Class[args.length];
            for (int i = 0; i < args.length; i++) {
                classes[i] = args[i].getClass();
                classes[i] = dealPrimitive(classes[i]);
                if (classes[i].isPrimitive()) {
                    classes[i] = dealPrimitive(classes[i]);
                }
                if (showLog) {
                    ZLog.d(ZTag.TAG_DEBUG, "clazz[" + i + "] " + classes[i]);
                }
            }
        }
        Method method = clazz.getDeclaredMethod(functionName, classes);
        method.setAccessible(true);
        return method.invoke(receiver, args);
    }

    public static void setFieldValue(Object obj, String fieldName, Object value) throws Exception {
        if (showLog) {
            ZLog.d(ZTag.TAG_DEBUG, "setFieldValue fieldName: " + fieldName);
        }
        Class<?> clazz = obj.getClass();
        Field field = clazz.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
    }

    /**
     * 处理8种基础类型的反射
     */
    private static Class<?> dealPrimitive(Class<?> clazz) {
        if (Integer.class.equals(clazz)) {
            return int.class;
        } else if (Boolean.class.equals(clazz)) {
            return boolean.class;
        } else if (Long.class.equals(clazz)) {
            return long.class;
        } else if (Short.class.equals(clazz)) {
            return short.class;
        } else if (Float.class.equals(clazz)) {
            return float.class;
        } else if (Double.class.equals(clazz)) {
            return double.class;
        } else if (Byte.class.equals(clazz)) {
            return byte.class;
        } else if (Character.class.equals(clazz)) {
            return char.class;
        } else {
            return clazz;
        }
    }

}

```

### 案例二：反射代理默认的HttpURL

```java
package com.zaze.utils.http;

import android.os.Build;
import android.util.Log;

import java.io.IOException;
import java.lang.reflect.Method;
import java.net.Proxy;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;

/**
 * Description :
 *
 * @author : ZAZE
 * @version : 2019-05-22 - 15:53
 */
public class HttpURLHandler extends URLStreamHandler {
    public static final String PROTOCOL = "http";

    private URLStreamHandler handler;
    private Class httpHandlerClass;

    public HttpURLHandler() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                // 4.4及以上
                httpHandlerClass = Class.forName("com.android.okhttp.HttpHandler");
            } else {
                httpHandlerClass = Class.forName("libcore.net.http.HttpHandler");
            }
            handler = (URLStreamHandler) httpHandlerClass.newInstance();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    @Override
    protected URLConnection openConnection(URL url) throws IOException {
        try {
            Method method = handler.getClass().getDeclaredMethod("openConnection", URL.class);
            method.setAccessible(true);
            return (URLConnection) method.invoke(handler, dealURL(url));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    protected URLConnection openConnection(URL u, Proxy p) throws IOException {
        try {
            Method method = handler.getClass().getDeclaredMethod("openConnection", URL.class, Proxy.class);
            method.setAccessible(true);
            return (URLConnection) method.invoke(handler, dealURL(u), p);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private URL dealURL(URL url) {
        Log.i("zaze", "URLConnection url : " + url.toString());
        Log.i("zaze", "URLConnection thread : " + Thread.currentThread().getName());
        return url;
    }
}

```

### 案例三：ViewModel实例的构建

```kotlin
open class ViewModelFactory : ViewModelProvider.NewInstanceFactory() {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return if (AbsAndroidViewModel::class.java.isAssignableFrom(modelClass)) {
            try {
                modelClass.getConstructor(Application::class.java)
                    .newInstance(BaseApplication.getInstance())
            } catch (e: Exception) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            }
        } else super.create(modelClass)
    }
}
```



