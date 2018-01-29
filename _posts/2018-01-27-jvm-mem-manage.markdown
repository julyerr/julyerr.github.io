---
layout:     post
title:      "jvm 内存管理"
subtitle:   "jvm 内存管理"
date:       2018-01-27 10:00:00
author:     "julyerr"
header-img: "img/jvm/jvm-mem.jpg"
header-mask: 0.5
catalog: 	true
tags:
    - jvm
    - java
---

![图片来源[1]](/img/jvm/jvm-mem-zone.png)
>上图为jvm几大基础组件，本文就运行时数据区进行分析，blog将不断更新，后文将会陆续分析其他组件。

## 线程私有区域
- **程序计数器(program counter register)**
	>表示线程正在执行字节码的地址，和cpu中`pc`并不是同一个概念，虽然起到的作用都是类似的。

    - 如果线程正在执行的是一个Java方法，计数器记录的是正在执行的字节码指令的地址；
    - 如果正在执行的是 Native 方法，则计数器的值为空

- **虚拟机栈(vm stack)**
	>为执行java方法服务,每执行一个方法会创建一个栈帧(stack frame);方法调用完成之后，退栈帧.

    + **栈帧组成部分**
![stack frame](/img/jvm/jvm-mem-stackFrame.png)
		1. **局部变量表**<br>
			由若干个Slot组成，长度在编译之后已经确定(long,double占用两个Slot).除了方法参数变量、局部变量之外，还包含非static方法隐含的this指针(占用第一个slot)、try-catch块中catch中的异常对象变量。
		    + **对象引用（refrence)**
					有两种实现方式，句柄和直接指针
			    + 句柄
![](/img/jvm/jvm-mem-refrence-jubing.jpeg)
				堆中划分出一块句柄池区域，句柄池中包含到实例数据和类型数据的地址信息。对象改变的时候，只需要改变句柄信息即可。
				+ 直接指针
![](/img/jvm/jvm-mem-refrence-pointer.jpeg)					
				直接指向实例对象，相对句柄方式节省了一次指针开销，访问效率较高。
		2. **操作数栈**
			FILO栈,运算时，将操作数弹出，计算后放回栈中。
		3. **动态链接**
			每个栈帧内部都包含一个指向当前方法所在类型的运行时常量池的符号引用，在类加载初始化的解析阶段将方法或者变量变成直接引用。
		4. **返回地址**
			return或者未处理异常发生之后，返回到被调用位置
		5. **其他信息	**
	
>若线程请求的栈深度大于虚拟机允许的深度，则抛出 StackOverFlowError 异常；**可以在启动运用的时候，`-Xss` 参数设置虚拟机栈大小。**
	栈无法申请到内存时，则抛出 OutofMemoryError 异常。

- **本地栈**
	为执行本地方法服务，运行机制和虚拟机栈类似。常用的SunJVM实现中，本地方法栈和JVM虚拟机栈是同一个。

---

### 线程共享区
- **堆（GC堆）**
![heap](/img/jvm/jvm-mem-heap-old.jpeg)

    >用于存放对象实例，也是垃圾回收器主要作用区域。通常被划分为新生代、老年代，新生代又被划分为`Edgen space`,`From Space`和`To Space`，它们的详细讲解，后面会添加blog进行介绍。

    + **对象内存分配**
    为新生的对象分配内存有两种策略，使用私有分配缓冲区(`TLAB`)或者直接在堆上进行分配。
        - 通常jvm优先考虑在TLAB进行分配，线程私有区不需要进行线程互斥保护操作，效率比较高；若TLAB用完并分配新的TLAB时，加同步锁定即可。
		- 如果分配内存比较大，直接在堆上分配。

	>如果堆内存不足，会抛出OutOfMemoryError异常。
	`-Xms`为JVM启动时申请的最小Heap内存，`-Xmx`为JVM可申请的最大Heap内存。		
- **方法区**
	>存储被虚拟机加载的类信息、常量、静态变量、即时编译器编译后的代码等数据
	
    **运行时常量池**
  	>存储编译生成的`字面量`(文本字符串、final常量值等)、符号引用、接口的全限定名、字段的名称、描述符和方法的名称.
	相对于其他如Class文件常量池而言具有`动态性`，运行期间也可能将新的常量放入池中，比如字符串的手动入池方法intern()。
	

    **不同jdk实现版本差异**
	- jdk1.2-jdk1.6使用永久代GC管理方法区
	- jdk1.7
		- 符号表移动到native中
		- 字符串常量和类引用被移动到堆中
	- jdk1.8	
		被元空间(metaspace)替代,使用native实现
	
    ![](/img/jvm/jvm-mem-method-new.png)
    
    内存不足，同样抛出OutOfMemoryError异常，设置参数
    - jdk1.7之前
		- `-XX:PermSize` 方法区初始大小
		- `-XX:MaxPermSize` 方法区最大大小
    - jdk 8
		- `-XX:MetaspaceSize` 元空间初始大小
		- `-XX:MaxMetaspaceSize` 元空间最大大小	

		

### 参考资料
[1]:http://sparkyuan.me/2016/04/22/JVM%E8%BF%90%E8%A1%8C%E6%97%B6%E6%95%B0%E6%8D%AE%E5%8C%BA%E5%9F%9F/

- [JVM 内存模型概述](http://blog.csdn.net/justloveyou_/article/details/71189093)
- [深入理解Java虚拟机（一）](https://www.jianshu.com/p/62f9db4d1df3)
- [java jvm运行栈结构](http://blog.csdn.net/quinnnorris/article/details/76467948)
- [永久代vs元空间](https://www.jianshu.com/p/9f1c5051b44d)