---
layout:     post
title:      "java 多线程系列开篇"
subtitle:   "java 多线程系列开篇"
date:       2018-01-29 13:00:00
author:     "julyerr"
header-img: "img/thread/overview.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - java
    - thread
    - thread-base
    - thread-advance
    - thread-support
---

>现准备对java多线程方面的知识点做一个系列总结，本文就涉及的内容overview.<br>
谈起线程，就离不开进程、操作系统等方面的知识。例如**进程生命周期、进程调度，进程之间的互斥和同步等**（[详细参见](http://julyerr.club/2018/01/29/os-process-thread/)），线程涉及到的内容基本上也是这些。
虽然编程语言五花八门，但是离不开这些核心知识点，只是各自支持的程度有所不同。<br>

系列内容分为三大模块，`多线程基础`、`线程之间的互斥和同步等高级模块`以及`java中对线程池支持`分析。

- [多线程基础](http://julyerr.club/tags/#thread-base)
	- Thread 类使用
	- 休眠，让步，唤醒和等待
	- 线程优先级、中断，守护线程
- [多线程互斥和同步](http://julyerr.club/tags/#thread-advance)
	Lock，Semaphore,Condition,ReentrantLock以及原子操作集合等
- [线程池的分析](http://julyerr.club/tags/#thread-support)
	线程池结介绍、原理以及Callable & Future
	
### 参考资料
[博主目录](http://wangkuiwu.github.io/categories/)