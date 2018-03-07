---
layout:     post
title:      "java 类加载器"
subtitle:   "java 类加载器"
date:       2018-03-07 12:00:00
author:     "julyerr"
header-img: "img/jvm/classloader/classloader.png"
header-mask: 0.5
catalog: 	true
tags:
    - jvm
---

>类加载器是jvm中又一核心组件，所做的工作就是将class的字节码文件转变为jvm中一个类组件。

### 类加载过程

![](/img/jvm/classloader/procedure.jpg)

整个过程划分为装载、连接和初始化（卸载在垃圾阶段处理）。

#### 装载

java中有三类类加载器：根装载器、ExtClassLoader（扩展类装载器）和AppClassLoader（系统类装载器）。根装载器使用C++编写，在java开发中不能获取到（null）,其主要负责装载JRE的核心类库，如JRE目标下的rt.jar、charsets.jar等；ExtClassLoader负责装载JRE扩展目录ext中的JAR类包；AppClassLoader负责装载Classpath路径下的类包。<br>

除根加载器之外，后两者都是ClassLoader的子类，如果自定义类加载需要继承ClassLoader类.<br>

**ClassLoader常见方法如下**

```java
Class loadClass(String name)  //name为全限定类名
Class loadClass(String name,boolean resolve) //如果JVM只需要知道该类是否存在或找出该类的超类,并不需要对class文件的内容进行解析可以设置resolve=false    
Class defineClass(String name,byte[] b,int off,int len) //将类文件的字节数组变成Class对象
Class findSystemClass(String name) //从本地文件系统载入Class文件，jVM默认的装载机机制
Class findLoadedClass(String name) //调用该方法来查看ClassLoader是否已装入某个类
ClassLoader getParent() //获取类装载器的父装载器
```

下面是一个具体的用户自定类加载的demo

```java
public class UserDefinedClassLoader extends ClassLoader {
    private String directory = "/home/julyerr/github/collections/target/classes/";
    private String extensionType = ".class";

    public UserDefinedClassLoader(){
        super(); // this set the parent as the AppClassLoader by default
    }

    public UserDefinedClassLoader( ClassLoader parent ){
        super( parent );
    }

    @Override
//    重写该方法返回自定义类信息
    public Class findClass( String name ){
        byte[] data = loadClassData( name );
        return defineClass( name, data, 0, data.length );
    }

    private byte[] loadClassData( String name ) {
        byte[] data = null;
        try{
            FileInputStream in = new FileInputStream( new File( directory + name.replace( '.', '/') + extensionType ) );
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            int ch = 0;

            while( ( ch = in.read() ) != -1 ){
                out.write( ch );
            }

            data = out.toByteArray();
        }
        catch ( IOException e ){
            e.printStackTrace();
        }
        return data;
    }

    public static void main(String[] args) throws MalformedURLException, ClassNotFoundException {
        UserDefinedClassLoader userDefinedClassLoader = new UserDefinedClassLoader();
        Class demo1 = userDefinedClassLoader.findClass("com.julyerr.interviews.jvm.classloader.Demo");
//        内置的网络资源获取类资源信息
        URL url = new URL("file:/home/julyerr/github/collections/target/classes/");
        ClassLoader classLoader = new URLClassLoader(new URL[]{url});
        Class demo2 = classLoader.loadClass("com.julyerr.interviews.jvm.classloader.Demo");

        System.out.println("demo1.classLoader "+demo1.getClassLoader());
        System.out.println("demo2.classLoader "+demo2.getClassLoader());
        System.out.println("demo1.classLoader == demo2.classLoader?"+(demo1.getClassLoader() == demo2.getClassLoader()));
    }
}
```

运行以上代码，需要首先在同目录下编译并生成一个Demo.class文件，输出

```
demo1.classLoader com.julyerr.interviews.jvm.classloader.UserDefinedClassLoader@61bbe9ba
demo2.classLoader sun.misc.Launcher$AppClassLoader@18b4aac2
demo1.classLoader == demo2.classLoader?false
```

**类加载器的父委托机制**<br>

当一个ClassLoader去装载一个类的时候，先委托父装载器寻找目标类，只有在找不到的情况下才从自己的类路径中查找并装载目标类。这样做主要是为了jvm的安全，试想如果有人编写了一个恶意的基础类（如java.lang.String）并装载到JVM中，其他的所有依赖文件将是该String文件；但是使用了委托机制之后，java.lang.String永远是由根装载器来装载的。

**命名空间**<br>

不同的类装载器装载的类将被放在虚拟机内部的不同命名空间，不同命名空间的两个类是不可见的，但只要得到类所对应的Class对象的reference，还是可以访问另一命名空间的类。


**类装载器类型**<br>

- 定义类装载器：实际装载某个类的类装载器
- 初始类装载器：通过父委托机制涉及的中间的类装载器都可以称为初始类装载器

命名空间由系列被装载的类名称组成，已经被加载进jvm的类下载在使用的时候不会再次被加载。并且如果某个类被定义类加载器加载之后，该类型在所有被标志为初始类装载器是共享的，因此我们可以方便调用`java api`.

**运行时包**<br>
由同一类装载器定义装载的属于相同包的类组成了运行时包。决定两个类是不是属于同一个运行时包，不仅要看它们的包名是否相同，还要看的定义类装载器是否相同。假设用户自己定义了一个类java.lang.Yes，并用用户自定义的类装载器装载，由于java.lang.Yes和核心类库java.lang.*由不同的装载器装载，它们属于不同的运行时包，所以java.lang.Yes不能访问核心类库java.lang中类的包可见的成员。


---
**连接过程**

- **校验**：class文件是有一定的格式的，可能部分恶意用户修改了class文件，jvm直接加载该文件会导致jvm直接崩溃,因此需要事前进行校验。
- **准备**：为静态变量分配内存空间，并没有开始赋初值
- **解析**：将对象的间接引用变成直接引用

---

### 初始化阶段

只有**以下的情况才能触发初始化**操作：

- new一个对象
- 访问类的静态成员变量或者静态方法
- 反射：Class.forName("com.julyerr.Name")  
- 初始化一个类的子类

**以下操作不会触发类的初始化**

- 子类调用父类静态变量，子类不会初始化
- 数组引用：list = Main[10];
- final变量访问（编译的时候已经确定）

下面是一个示例代码段

```java
public class LoadProcessDemo {
    public static void main(String[] args){
        System.out.println("我是main方法，我输出Super的类变量i："+Sub.i);
        Sub sub  = new Sub();
    }
}

class Super{
    {
        System.out.println("我是Super成员块");
    }
    public Super(){
        System.out.println("我是Super构造方法");
    }
    {
        int j = 123;
        System.out.println("我是Super成员块中的变量j："+j);
    }
    static{
        System.out.println("我是Super静态块");
        i = 123;
    }
    protected static int i = 1;
}

class Sub extends Super{
    static{
        System.out.println("我是Sub静态块");
    }
    public Sub(){
        System.out.println("我是Sub构造方法");
    }
    {
        System.out.println("我是Sub成员块");
    }
}
``` 

以下是输出

![](/img/jvm/classloader/static.png)


本文所使用的完整代码文件[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/jvm/classloader)

---
### 参考资料
- [类装载器ClassLoader](https://github.com/it-interview/easy-java/blob/master/details/Java%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%99%A8.md)
- [JAVA类装载器classloader和命名空间namespace](http://blog.csdn.net/sureyonder/article/details/5564181)
- [类装载器学习](https://yq.aliyun.com/articles/349258)
- [Java面试相关（一）-- Java类加载全过程](https://www.jianshu.com/p/ace2aa692f96)