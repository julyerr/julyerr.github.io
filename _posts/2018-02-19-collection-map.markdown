---
layout:     post
title:      "java集合框架之Map"
subtitle:   "java集合框架之Map"
date:       2018-02-19 7:00:00
author:     "julyerr"
header-img: "img/lib/collection/map/map.jpg"
header-mask: 0.5
catalog: 	true
tags:
    - collections
    - map
---

>本文对java集合框架中的`Map`,`HashMap`,`LinkedHashMap`,`HashTable`以及`ConcurrentHashMap`的使用和底层数据结构进行总结，但并不会详细涉及源码分析，如果需要，推荐本文后面的参考资料。

![](/img/lib/collection/map/map-inherit.png)
Map其实就是多个Entry(key-value结构)容器，`AbstractMap`抽象类提供了Map接口的骨干实现，以最大限度地减少实现Map接口所需的工作。

---
### HashMap
```java
public class HashMap<K,V>
    extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable{
}
```
根据hash算法计算key-value存储的位置并进行快速存取。<br>

**实现数据结构**<br>
![](/img/lib/collection/map/hashmap-structure.png)

- JDK1.6实现hashmap的方式是采用位桶（数组）+链表的方式，即散列链表方式
- JDK1.8则是采用位桶+链表/红黑树的方式，即当某个位桶的链表长度达到某个阈值（8）的时候，这个链表就转化成红黑树，对于冲突比较多的情况下，大大减少了查找时间。

#### 存储查找原理
下面摘抄自[1](https://www.jianshu.com/p/b2d611c01bf3),总结得很不错<br>
**存储**<br>

- 首先获取key的hashcode，然后取模数组的长度，快速定位到要存储到数组中的坐标，然后判断数组中是否存储元素；
- 如果没有存储则新构建Node节点，把Node节点存储到数组中；
- 如果有元素，则迭代链表(红黑二叉树)，如果存在此key,默认更新value,不存在则把新构建的Node存储到链表的头部。

**查找**<br>
获取key的hashcode，通过hashcode取模数组的长度，获取要定位元素的坐标，然后迭代链表（红黑树），进行每一个元素的key的equals对比，如果相同则返回该元素。<br>

**notes**

- HashMap的底层数组长度总是2的n次方, h&(length-1)就相当于对length取模，其效率要比直接取模高得多
- HashMap允许键为NULL的键值对存在

---
### LinkedHashMap
```java
public class LinkedHashMap<K,V>
    extends HashMap<K,V>
    implements Map<K,V> {
}
```
HashMap中元素是无序的，LinkedHashMap通过`双向链表`保证了迭代的顺序；维持的顺序可以是元素`插入顺序`也可以是元素`访问顺序`(LRU的功能)，默认是元素插入顺序。<br>

**实现数据结构**
![](/img/lib/collection/map/linkedhashmap.png)
增加额外的before和after指针保持元素的有序性
![](/img/lib/collection/map/linkedhashmap-entry.png)

**存储和查找原理**<br>
存取过程基本上和HashMap类似，在插入新Entry同时，还会将其链入到双向链表中;
元素读取操作上，重写了get方法。<br>
**LinkedHashMap实现LRU算法**<br>
`accessOrder`标志位为true,`LinkedHashMap`中的当前访问的Entry（put进来的Entry或get出来的Entry）移到双向链表的尾部,在保持固定大小的前提下，可以实现LRU功能。以下是一个示例
```java
**        
 * Title: 使用LinkedHashMap实现LRU算法    
 * Description: 
 * @author rico       
 * @created 2017年5月12日 上午11:32:10    
 */      
public class LRU<K,V> extends LinkedHashMap<K, V> implements Map<K, V>{

    private static final long serialVersionUID = 1L;

    public LRU(int initialCapacity,
             float loadFactor,
                        boolean accessOrder) {
        super(initialCapacity, loadFactor, accessOrder);
    }

    /** 
     * @description 重写LinkedHashMap中的removeEldestEntry方法，当LRU中元素多余6个时，
     *              删除最不经常使用的元素
     * @author rico       
     * @created 2017年5月12日 上午11:32:51      
     * @param eldest
     * @return     
     * @see java.util.LinkedHashMap#removeEldestEntry(java.util.Map.Entry)     
     */  
    @Override
    protected boolean removeEldestEntry(java.util.Map.Entry<K, V> eldest) {
        // TODO Auto-generated method stub
        if(size() > 6){
            return true;
        }
        return false;
    }

    public static void main(String[] args) {

        LRU<Character, Integer> lru = new LRU<Character, Integer>(
                16, 0.75f, true);

        String s = "abcdefghijkl";
        for (int i = 0; i < s.length(); i++) {
            lru.put(s.charAt(i), i);
        }
        System.out.println("LRU中key为h的Entry的值为： " + lru.get('h'));
        System.out.println("LRU的大小 ：" + lru.size());
        System.out.println("LRU ：" + lru);
    }
}
```

---
### 线程安全Map
`HashMap`在多线程环境下会造成[死循环](https://coolshell.cn/articles/9606.html)可以利用集合提供的[线程安全API](http://julyerr.club/2018/02/18/collection-list/#集合线程安全),也可以使用集合提供的`HashTable`和`ConcurrentHashMap`

### HashTable
继承于`Dictionary`而不是`AbstractMap`,底层使用的数据结构是散链表。put 和get操作都使用了synchronized进行同步，效率较低，因而实际运用中通常使用`ConcurrentHashMap`。


### ConcurrentHashMap
>ConcurrentHashMap在jdk1.8之前基于分段锁实现，jdk1.8中改成基于CAS实现多线程安全，性能又得以提升。

#### 基于分段锁实现
**数据结构**
![](/img/lib/collection/map/segment-map.jpg)
ConcurrentHashMap就是一个`Segment`(继承`ReentrantLock`)数组，每个Segment实例又是一个hash表;针对hash表的不同部分,使用不同的锁控制，从而允许多个修改的线程并发进行，理论上最大并发度和Segment个数相等。<br>

读写某个Key，先获取Key的hash值，将哈希值的高N位对Segment个数取模从而得到该Key应该属于哪个Segment。

- 对于写操作，先获取Key所在的Segment的锁，然后对待普通HashMap一样操作该Segment.

```java
static final class HashEntry<K,V> {
   final K key;                       // 声明 key 为 final 的
   final int hash;                   // 声明 hash 值为 final 的
   volatile V value;                // 声明 value 被volatile所修饰
   final HashEntry<K,V> next;      // 声明 next 为 final 的
	...
}
```
- 对于读操作,由于value被声明为volatile类型，key、hash、next均为`final`类型，因此可以不用加锁直接诶进行读取操作。

**跨段操作**<br>
为了提高并发度，每个segment维持了一个count保存hashEntry的数量;调用size()方法获取的是所有的segment中元素大小总和。如果直接锁住所有的segment数组，操作效率很低。<br>因此，ConcurrentHashMap会在不上锁的前提下逐个Segment计算3次size，如果某相邻两次计算获取的所有Segment的更新次数相同，说明中间无更新操作，可直接返回结果;如果Map有更新，对所有的Segment加锁重新计算size大小。

#### 基于CAS实现
**数据结构**
![](/img/lib/collection/map/concurrent-rb-structure.png)
使用散列表的结构，为减少hash碰撞带来的效率问题，在链表长度超过一定阈值（8）时将链表转换为红黑树。

- 对于写操作，如果Key对应的数组元素为null，则通过CAS操作将其设置为当前值;
如果Key对应的数组元素（不为null，则对该元素使用synchronized关键字申请锁，然后进行操作。如果该put操作使得当前链表长度超过一定阈值，则将该链表转换为树。

```java
static class Node<K,V> implements Map.Entry<K,V> {
  final int hash;
  final K key;
  volatile V val;
  volatile Node<K,V> next;
}
```
- 对于读操作，val 被 volatile关键字修饰,对多线程可见。
只要hash不发生冲突就不会涉及锁的操作

**notes**<br>
HashTable和ConcurrentHashMap 中Key和Value都不允许为NULL。


---
### 参考资料
- [Java-容器](http://blog.csdn.net/justloveyou_/article/category/6485749)
- [HashMap 源码解析(JDK1.8)](https://www.jianshu.com/p/b2d611c01bf3)
- [Java进阶（六）从ConcurrentHashMap的演进看Java多线程核心技术](http://www.jasongj.com/java/concurrenthashmap/)