---
layout:     post
title:      "java集合框架之List"
subtitle:   "java集合框架之List"
date:       2018-02-18 7:00:00
author:     "julyerr"
header-img: "img/lib/collection/list/list.jpeg"
header-mask: 0.5
catalog: 	true
tags:
    - colletions
    - list
---

>本文只是对java集合框架中List做一个整体的总结，不会对源码进行分析，如果参考源码分析，推荐[blog](http://blog.csdn.net/justloveyou_/article/details/52955619)

![](/img/lib/collection/list/list-inherit.jpg)
AbstractList是一个抽象类，提供了iterator的实现，具体的元素增加和删除等操作由具体的子类实现。

- ArrayList 是一个动态数组。它由数组实现，随机访问效率高，随机插入、随机删除效率低；
- LinkedList是一个双向链表（顺序表）。随机访问效率低，但随机插入、随机删除效率高。可以被当作堆栈、队列或双端队列进行操作；
- Vector是矢量队列。数组实现，线程安全的，但是由于效率的问题基本上不会使用
- Stack 栈。继承于Vector，FIFO结构，线程安全，基本上也不会使用。

### List提供的接口
```java
//返回列表中指定位置的元素
E get(int index) 
//用指定元素替换列表中指定位置的元素
E set(int index, E element)
//在列表的指定位置插入指定元素
void add(int index, E element)
//将指定 collection 中的所有元素都插入到列表中的指定位置
boolean addAll(int index, Collection<? extends E> c)
//移除列表中指定位置的元素
E remove(int index)	
//返回此列表中第一次出现的指定元素的索引；如果此列表不包含该元素，则返回 -1
int indexOf(Object o)
//返回此列表中最后出现的指定元素的索引；如果列表不包含此元素，则返回 -1
int lastIndexOf(Object o)
//返回此列表元素的列表迭代器（按适当顺序）
ListIterator<E> listIterator()
//返回列表中元素的列表迭代器（按适当顺序），从列表的指定位置开始	
ListIterator<E> listIterator(int index)
//返回列表中指定的 fromIndex（包括 ）和 toIndex（不包括）之间的视图
List<E> subList(int fromIndex, int toIndex)
```
**notes**<br>
**subList**<br>
	非结构性修改(不涉及到list的大小改变的修改)，都会影响到彼此;若发生结构性修改的是子list，那么原list的大小也会发生变化;若发生结构性修改的是原list,触发`fast-fail`。

---
### ArrayList
```java
public class ArrayList<E> extends AbstractList<E>
    implements List<E>, RandomAccess, Cloneable, java.io.Serializable
```    

- 实现Serializable接口，虽然使用transient关键字修饰，但是还是会序列化的
	调用 ArrayList 的 writeObject()/readObject() 方法将元素写入流或者从流中读出。
- 实现RandomAcess接口，实际上就是通过下标序号进行快速访问。访问速度相对于iterator更快一些，因此遍历List之前，可以用 if( list instanceof RamdomAccess )来判断一下，选择用哪种遍历方式
- 实现Cloneable接口，能被克隆。Cloneable接口里面没有任何方法，只是起一个标记作用

构造ArrayList实例时，可以指定其容量，以避免数组扩容的发生，因为数组复制和移动效率很低。
ArrayList 的实现中大量地调用了Arrays.copyof() 和 System.arraycopy()方法 ；但是copyOf还是调用了System.arraycopy()方法，并且System.arraycopy() 是native方法。<br>

**特点**<br>
	随机访问效率高，随机插入、随机删除效率低。
	
---
### LinkedList
```java
public class LinkedList<E>
    extends AbstractSequentialList<E>
    implements List<E>, Deque<E>, Cloneable, java.io.Serializable
```

和ArrayList类似，可以被clone,序列化；实现 Deque 接口，可以当做双端队列使用；
没有实现RandomAccess接口，不支持随机访问。<br>

**实现数据结构**
![](/img/lib/collection/list/list-node.png)
可以被当作堆栈、队列或双端队列进行操作<br>

**特点**<br>
	增删效率高，随机访问效率低。

---
### 集合线程安全
集合API中Vector和Hashtable是多线程安全的，但是如果只被一个线程使用的话，同步会降低效率；Collections中提供通过同步方法封装非同步集合得到的多线程安全操作的集合
```java
public static Collection synchronizedCollention(Collection c)
public static List synchronizedList(list l)
public static Map synchronizedMap(Map m)
public static Set synchronizedSet(Set s)
public static SortedMap synchronizedSortedMap(SortedMap sm)
public static SortedSet synchronizedSortedSet(SortedSet ss)
```

以下是一个示例代码
```java
import java.util.*;  

public class SafeCollectionIteration extends Object {  
    public static void main(String[] args) {  
        //为了安全起见，仅使用同步列表的一个引用，这样可以确保控制了所有访问  
        //集合必须同步化，这里是一个List  
        List wordList = Collections.synchronizedList(new ArrayList());  

        //wordList中的add方法是同步方法，会获取wordList实例的对象锁  
        wordList.add("Iterators");  
        wordList.add("require");  
        wordList.add("special");  
        wordList.add("handling");  

        //获取wordList实例的对象锁，  
        //迭代时，阻塞其他线程调用add或remove等方法修改元素  
        synchronized ( wordList ) {  
            Iterator iter = wordList.iterator();  
            while ( iter.hasNext() ) {  
                String s = (String) iter.next();  
                System.out.println("found string: " + s + ", length=" + s.length());  
            }  
        }  
    }  
}  
```

对于ArrayList，`java.util.concurrent`包还提供`CopyOnWriteArrayList`保证多线程安全。CopyOnWrite的意思是在写时拷贝，也就是如果需要对CopyOnWriteArrayList的内容进行改变，首先会拷贝一份新的List并且在新的List上进行修改，最后将原List的引用指向新的List。对于map等集合，java.util.concurrent提供了更高效率的支持，后文会进行介绍。以下是一个示例
```java
public static void main(String[] args) {
	
	// 初始化一个list，放入5个元素
	final List<Integer> list = new CopyOnWriteArrayList<>();
	for(int i = 0; i < 5; i++) {
		list.add(i);
	}

	// 线程一：通过Iterator遍历List
	new Thread(new Runnable() {
		@Override
		public void run() {
			for(int item : list) {
				System.out.println("遍历元素：" + item);
				// 由于程序跑的太快，这里sleep了1秒来调慢程序的运行速度
				try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		}
	}).start();
	
	// 线程二：remove一个元素
	new Thread(new Runnable() {
		@Override
		public void run() {
			// 由于程序跑的太快，这里sleep了1秒来调慢程序的运行速度
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			
			list.remove(4);
			System.out.println("list.remove(4)");
		}
	}).start();
}
```

---
### 参考资料
- [Java Collection Framework : List](http://blog.csdn.net/justloveyou_/article/details/52955619)
- [多线程环境下安全使用集合 API](http://wiki.jikexueyuan.com/project/java-concurrency/multithreading.html)
- [如何线程安全地遍历List：Vector、CopyOnWriteArrayList](http://xxgblog.com/2016/04/02/traverse-list-thread-safe/)