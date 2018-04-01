---
layout:     post
title:      "java String和常量池"
subtitle:   "java String和常量池"
date:       2018-03-31 8:00:00
author:     "julyerr"
header-img: "img/lib/string/string.png"
header-mask: 0.5
catalog: 	true
tags:
    - string
---

String是java中较为常用的类，其简单使用之处还有部分高级特性值得我们关注。<br>

### String基础深入
**String的final特性**<br>
    String被final关键字修饰，意味着string对象不能被继承和修改，值在初始化的时候就已经确定

#### String初始化

```java
// 字面量初始化
String a = new String("abc");
// 构造方法
String a = new String("abc");
//...
```

![](/img/lib/string/string-ref.jpg)



**String、StringBuffer与StringBuilder比较**
|类型|可变性|线程安全性
|---|
|String |不可变    |线程安全
|StringBuffer   |可变 |线程安全
|StringBuilder| 可变  |非线程安全（没有同步代码块约束，效率更高）

### "+"操作

**编译时优化**

```java
String str1 = "ab" + "cd";   //编译的时候已经可以确定str1的值
String str11 = "abcd";   
System.out.println("str1 = str11 : "+ (str1 == str11));  // true
```

**局部变量表**

```java
String str2 = "ab";  
String str3 = "cd";         
/**
运行期间jvm先在堆中创建一个StringBuilder对象，并且使用str2字符内容进行初始化，“+”实际上调用StringBuilder
对象的append()方法，最后调用toString()方法将字符串内容返回给str4.
**/                                 
String str4 = str2 + str3;   
String str44 = "abcd";    
System.out.println("str4 = str5 : " + (str4 == str44)); // false  
```

**final字符串编译时优化**

```java
final String str5 = "b";  //编译的时候str8优化成常量变量
String str6 = "a" + str5;  
String str7 = "ab";  
System.out.println("str6 = str7 : "+ (str6 == str7)); // true  
```

---
### String与JVM常量池

jvm方法区内容[参见](http://julyerr.club/2018/01/27/jvm-mem-manage/#方法区),
方法区中的运行时常量池存储编译生成的字面量(文本字符串、final常量值等)、符号引用、接口的全限定名、字段的名称、描述符和方法的名称。相对于其他如Class文件常量池而言具有动态性，是指运行期间可能将新的常量放入池中，比如字符串的手动入池方法intern()。

#### String.intern()

intern()方法的作用是在常量池中查找值等于（equals）当前字符串的对象，如果找到，则直接返回这个对象的地址；如果没有找到，则将当前字符串拷贝到常量池中，然后返回拷贝后的对象地址。<br>

- jdk1.7之前，常量池包含在永久代内;
- jdk1.7字符串常量和类引用被移动到堆中;
- jdk1.8中，整个方法区被元空间替代。

不同版本常量池实现的差异，可以借助下面demo进行理解（面试中常被问及的知识点）

```java
public static void main(String[] args) {
    String s1 = new String("1") + new String("1");
    s1.intern();
    String s2 = "11";
    System.out.println(s1 == s2);

    System.out.println("---------");

    String s3 = new String("a") + new String("a");
    String s4 = "aa";
    s3.intern();
    System.out.println(s3 == s4);
}

/*
*
jdk1.7之前的版本输出
false
---------
false

jdk1.7及之后的版本输出
true
---------
false
* */
```

![](/img/lib/string/string-ref-jdk1.6.png)
上图是jdk1.7之前，各个变量的引用关系:<br>
    常量池和堆内存分开存储，"11"在堆内存中动态生成，intern()方法将"11"放进常量池中。因此两次指向地址不同，均返回false。

    
![](/img/lib/string/string-ref-jdk1.7.png)
上图是jdk1.7之后，各个变量的引用关系:<br>

- 常量池包含在堆中，"11"在堆内存中动态生成，intern()方法发现堆内存中已经存在"11"，便返回一个对"11"的引用;
- "aa"调用intern()方法，发现常量池中已经存在"aa"，不做其他处理直接返回。因此，整个输出结果为true,false。


---
### 参考资料

- [【系列】重新认识Java——字符串（String）](http://blog.csdn.net/xialei199023/article/details/63251366)
- [深入分析Java String.intern()方法](http://blog.csdn.net/u012546526/article/details/44619519)