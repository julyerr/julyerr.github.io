---
layout:     post
title:      "java Collections框架总概"
subtitle:   "java Collections框架总概"
date:       2018-02-15 10:00:00
author:     "julyerr"
header-img: "img/lib/collection/collection.jpg"
header-mask: 0.5
catalog: 	true
tags:
    - collections
    - iterator
---


下图显示了java集合框架中各个接口和类之间的依赖和继承关系
![](/img/lib/collection/collections.jpeg)

>本文主要对iterator接口和Collection接口进行总结，后续文章会陆续介绍List,Map等框架。

### iterator接口
```java
public interface Iterator<E> {
    boolean hasNext();
    E next();
    void remove();
}
```
java集合框架中可以使用iterator迭代访问各种结构，使用iterator的**优点**

- 访问内部元素不需要暴露内部
- 支持元素多种遍历
- 为便利不同元素提供统一的接口（多态迭代）

**notes**<br>
	java中的集合，如List或者Set实现了Iterable接口而不是Iterator接口，原因如下：

- Iterator接口的核心方法 next() 或者 hasNext() 是依赖于迭代器的当前迭代位置的，需要进行下标的记录，多个迭代器之间容易产生干扰
- 调用Iterable接口每次都会返回一个从头开始计数的迭代器（Iterator），彼此之间没有干扰
- Map没有实现Iterable接口。
<br>
<br>
#### Iterator的快速失败机制

快速失败(fail-fast)是java集合框架中一种`错误检测机制`，当多钱程对集合进行结构上的改变或者集合在迭代元素时直接调用自身方法改变集合结构而没有通知迭代器时，有可能会触发fast-fail机制并抛出异常`ConcurrentModificationException`。
```java
final void checkForComodification() {
    if (modCount != expectedModCount)
        throw new ConcurrentModificationException();
}
```

集合内部维护的modCount记录改变的元素的个数，expectedModCount在迭代开始等于modCount，如果操作过程中使用子类的remove()修改了modCount但是expectedModCount并没有被修改，两者不相等,于是抛出异常。但是如果调用iterator自身remove()则不会抛出异常。
```java
ArrayList<String> arrayList=new ArrayList<>();
arrayList.add("hello");
arrayList.add("how are you");
arrayList.add("I'm ok");
Iterator<String> iterator=arrayList.iterator();
boolean shouldDelete=true;
while (iterator.hasNext()){
    String string=iterator.next();
   if(shouldDelete){
       shouldDelete=!shouldDelete;
       //arrayList.remove(2); 则会抛出异常
       iterator.remove();
   }
}
```

#### ListIterator接口
![](/img/lib/collection/listIterator.png)
ListIterator 没有当前元素；它的光标位置始终位于调用 previous() 所返回的元素和调用 next() 所返回的元素之间。
相对于Iterator而言，提供了诸多更为强大的功能。

- add()向List中添加对象
- hasPrevious()和previous()可以实现逆序遍历
- nextIndex()和previousIndex()可以定位当前的索引位置

---

### collection接口
>提供更加具体并且具有普遍性的子接口(如Set和List等)

- 构造方法
	两个标准的构造方法：
	- void（无参数）构造方法，用于创建空 collection
	- 带有 Collection类型单参数的构造方法，用于创建一个具有与其参数相同元素新的 collection

- 提供方法
	- 增
		add() addAll()
	- 删
		- remove() removeAll()
		- retain()
		- clear()
	- 查
		- iterator()
		- contains()
		- containsAll()
	- 转
		- toArray()
		- T[] toArray(T[] a): Array与Collection之间的桥梁，在 AbstractCollection 中提供默认实现，子类可以对它重写
	
 - 原生方法
    	- size()
    	- isEmpty()

**AbstractCollection**<br>
	提供Collection接口的骨干实现，最大程度减少实现此接口的工作量。

- **可选操作**<br>
	声明调用某些方法不会执行有意义的行为，反而会抛出异常`UnsupportedOperationException`。主要为了减少容器中接口爆炸的情形，同时为了容器的简单易用,UnsupportedOperationException必须是罕见事件。

---

### 参考资料
- [java集合系列——java集合概述（一）](http://blog.csdn.net/u010648555/article/details/56049460)
- [Java 迭代器综述](http://blog.csdn.net/justloveyou_/article/details/53487707)
- [Iterator与fast-fail机制](https://www.jianshu.com/p/1c2d31b1f69e)