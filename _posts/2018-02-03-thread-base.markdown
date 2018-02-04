---
layout:     post
title:      "java 多线程基础"
subtitle:   "java 多线程基础"
date:       2018-02-03 12:00:00
author:     "julyerr"
header-img: "img/thread/thread-base.jpg"
header-mask: 0.5
catalog:    true
tags:
    - java
    - thread
    - thread-base
---

>Java线程在JDK 1.2之前是基于用户线程实现([详细参见](http://julyerr.club/2018/01/29/os-process-thread/#线程的实现))的，而JDK1.2中，线程模型替换为基于操作系统原生线程来实现。

创建线程的两种方式
	实现Runnable接口
		
	扩展Thread类
