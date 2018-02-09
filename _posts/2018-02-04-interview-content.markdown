---
layout:     post
title:      "java 程序员面试基本知识点总结"
subtitle:   "java 程序员面试基本知识点总结"
date:       2018-02-04 10:00:00
author:     "julyerr"
header-img: "img/thoughts/interview.jpeg"
header-mask: 0.5
catalog: 	true
tags:
    - interview
---

![](/img/bat.jpeg)

>以前零星对java程序员面试需要了解的内容和常见问题进行了总结，这次稍微整理成一篇blog。整体上来说，不论是国内还是国外大公司都对计算机基础知识要求比较扎实，当然其他大神就勿喷了。


学习和复习方式因人而异，自己比较推崇的方式是

- **学习**<br>
		通过blog或者官方的文档快速入门，然后找评分比较高的书籍系统学习，学习一阶段之后整理整理，看看几个小型的demos并实现，然后就可以开始尽情地玩耍了。
- **复习**<br>
		对以前学习的书籍、做的笔记之类的浏览一遍，然后结合实践经验更加有条理的整理一下，看看其他比较有深度而且系统的blog。如果准备面试的话，刷刷leetcode、牛客网上以及前辈面试的题目.

![](/img/variety/time-learn.jpeg)


---
#### 语言本身特性和高级使用
>大神精通个三四门语言不成问题，我们这些菜鸟还是先熟练一门语言，再去学习其他的语言，毕竟人的精力是有限的嘛。本文就java而言
	
- **基础语法**<br>
- **java中各类库**<br>
	- **集合类库**<br>
	除了知道如何使用之外，还需要了解内部实现机制，最好能够看看源码，比如
ArrayList,LinkedList,HahsMap等，推荐[blog](http://blog.csdn.net/column/details/15584.html)
	- **高并发类库**<br>
	java对多线程和高并发提供了比较强大的支持，内容比较多
		- java thread类，推荐[blog](http://blog.csdn.net/shb_derek1/article/details/26929249)
		- 多线程同步、锁等,推荐[blog](http://wangkuiwu.github.io/categories/)
		- 支持多线程的集合类库ConcurrentHashMap等
		- nio,推荐[blog](http://ifeve.com/java-nio-path/)
- **网络库**<br>
	如果从事网络编程方面，还需要了解常见的Socket编程类库

- **jvm**<br>
    - 内存分布
	- gc算法以及常见的垃圾回收器
	- 类加载机制
	推荐[blog](http://www.hollischuang.com/archives/1001)

---
#### 计算机基础知识
>大学认真学习的话，这部分复习起来相对简单一点，但是要注意不能遗漏某些问题。比如数据库中乐观锁、悲观锁，LRU算法之类，如果提前没有复习到的话（或者根本不知道）被问及，真的是蒙逼，但是这些内容理解起来并不是很复杂。

- **数据结构和算法**<br>
	acmer勿喷，并不强调一味的刷题，刷题只是考察基本的解决问题和coding的能力，还有部分数据结构和算法内容其实通过刷题是没有被复习到。推荐`《算法第四版》`，然后加上`《剑指offer》`，`leetcode`和`牛客网`上其他的大公司的真面试题。
- **操作系统**<br>
	关注进程、线程、内存分配和管理、磁盘以及文件系统等内容。网上比较多的人做了很好的[系列总结](https://www.jianshu.com/u/ccb6e3e26ec3)

- **计算机网络**<br>
		关注tcp,ip报文格式，tcp建立和断开等内容，应用层dhcp,dns以及http等协议
- **数据库系统**<br>
	数据库基本操作之外，事物之间如何保证acid等内容

>个人觉得，如果时间允许的话，自己可以在github上分门别类的建立几个repo，然后自己将这些理论知识实践，慢慢构建成一个工具集或者库。数据结构和算法，实现的图、树等算法;操作系统，实现LRU,进程调度，内存管理等;计算机网络，自定义通信格式，小型的web服务器之类的;数据库，各种关系结构，一对多、多对多等。关注一些总结比较好的博主，他们写的文章通常含金量很高。

---
#### 框架
>java涉及的方面比较多，从常见的web开发，后台开发到大数据、hadoop生态等。个人对web比较感兴趣，其他的也可以自行google.

ssm或者ssh,框架不求多，比较熟悉常见的即可。

- **spring**<br>
	推荐[blog](http://blog.csdn.net/column/details/15933.html)
- **spring mvc**<br>
	- 推荐[blog1](http://www.cnblogs.com/best/tag/Spring%20MVC/)
	- 推荐[blog2](http://blog.csdn.net/u012562943/article/category/6037159)	
- **spring boot**<br>
	推荐[blog](http://www.ityouknow.com/spring-boot.html)
- **mybatis**<br>
	推荐[blog](http://blog.csdn.net/luanlouis/article/details/40422941)

- **netty**<br>
	在学习或者复习nio、多线程等的时候，学习netty可以看成是自然过渡，也是一个加分项吧。了解netty基本使用，基于netty的一些开源项目，或者可以看看[netty的源码](https://github.com/code4craft/netty-learning)。	

---

#### 自己做的项目
>项目很难速成，如果没有自己的项目，可以分析一下比较优秀的开源框架的代码，比如netty之类的。

#### 其他加分项
	
- maven 
- junit 能够自我进行集成测试的程序员很少
- linux 基本的linux命令行以及常见服务器配置
- git 常见命令
- 个人blog 顺便也自己做一个总结
- docker 基本命令，能够将自己的运用打包分发等
- hadoop 了解架构、运用场景之类

---
#### 参考资料
- [如何准备阿里的社招Java技术面试？](https://www.jianshu.com/p/edec2ca6fe29)
- [2018秋招找工作总结](http://blog.zzkun.com/archives/623)
- [2018年三年工作经验的Java程序员该掌握哪些技能。？](https://www.zhihu.com/question/266078326)