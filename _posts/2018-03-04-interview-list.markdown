---
layout:     post
title:      "面试编程题 list"
subtitle:   "面试编程题 list"
date:       2018-03-04 6:00:00
author:     "julyerr"
header-img: "img/ds/list/list.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - list
---

#### [Delete Node in a Linked List](https://leetcode.com/problems/delete-node-in-a-linked-list/description/)
**解题思路**
此题比较灵活，将数值直接覆盖就相当于删除了该节点。<br>
**实现代码**
```java
public void deleteNode(ListNode node) {
//        check validation
    if (node == null) {
        return;
    }
    node.val = node.next.val;
    node.next = node.next.next;
}
```

---
#### [Add Two Numbers](https://leetcode.com/problems/add-two-numbers/description/)
**解题思路**
循环判断两个链表，设置一个进位标志位，然后将两个链表的元素相加判断即可。<br>
**实现代码**
```java
public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
    if (l1 == null && l2 == null) {
        return null;
    } else if (l1 == null) {
        return l2;
    } else if (l2 == null) {
        return l1;
    }

//        设置临时ListNode
    ListNode head = new ListNode(0);
    ListNode p = head;
    int carry = 0;
    while (l1 != null || l2 != null) {
//            fetch the first elem from l1
        int val1 = 0;
        if (l1 != null) {
            val1 = l1.val;
            l1 = l1.next;
        }

//            fetch the first elem from l2
        int val2 = 0;
        if (l2 != null) {
            val2 = l2.val;
            l2 = l2.next;
        }

//            更新zhi
        int tmp = val1 + val2 + carry;
        carry = tmp / 10;
        p.next = new ListNode(tmp % 10);
        p = p.next;
    }
    if (carry != 0) {
        p.next = new ListNode(carry);
    }
    return head.next;
}
```

---
#### [Linked List Cycle](https://leetcode.com/problems/linked-list-cycle/description/)
**解题思路**
判断一个链表中是否存在环，可以设置快慢两个指针，如果存在环的话，必然在某次出现fast = slow的情况；反之，则不存在环。<br>
**实现代码**
```java
public boolean hasCycle(ListNode head) {
//        check validation
    if(head == null || head.next == null){
        return false;
    }
    
    ListNode fast = head;
    ListNode slow = head;
    while(fast!=null&& fast.next!=null){
        fast = fast.next.next;
        slow = slow.next;
        if(fast==slow){
            return true;
        }
    }
    return false;
}
```

--- 
#### [Linked List Cycle II](https://leetcode.com/problems/linked-list-cycle-ii/description/)
**解题思路**
此题解题思路比较巧妙，设头结点Head到环入口的长度为X,环的长度为Y,相遇时从环入口到相遇节点的长度为K,相遇节点为kNode；
则快慢指针满足的关系2*(X+n*Y+K) = X+m*Y+K,其中n,m分别代表慢快指针在环中循环的次数；
化简得到：X+K = (m-2*n)*Y ,说明Head和kNode一起走X步，能够在环入口相遇。
[具体流程参见](http://fisherlei.blogspot.kr/2013/11/leetcode-linked-list-cycle-ii-solution.html)<br>
**实现代码**
```java
public ListNode detectCycle(ListNode head) {
//        check validation
    if (head == null) {
        return null;
    }

    ListNode fast = head;
    ListNode slow = head;
//        查找相遇节点
    while (fast != null && fast.next != null) {
        fast = fast.next.next;
        slow = slow.next;
        if (fast == slow) {
            break;
        }
    }
//        不存在环的情况
    if (fast == null || fast.next == null) {
        return null;
    }

//        共同走X步
    ListNode p = head;
    while (p != fast) {
        p = p.next;
        fast = fast.next;
    }
    return fast;
}
```

---
#### [Insertion Sort List](https://leetcode.com/problems/insertion-sort-list/description/)
**解题思路**
可以选择从后往前插入，或者从前往后插入。此题显然比较适合从前往后插入<br>
**实现代码**
```java
public ListNode insertionSortList(ListNode head) {
//        check validation
    if(head == null || head.next == null){
        return head;
    }

//        临时头结点
    ListNode tmpHead = new ListNode(0);
    tmpHead.next = head;

    ListNode pre = head;
    ListNode cur = head.next;
    while(cur!=null){
//            需要调整指针
        if(cur.val<pre.val){
            ListNode p = cur;
            cur = cur.next;
            pre.next = cur;

//                找到插入位置
            ListNode tmp = tmpHead;
            while(tmp.next!=pre && p.val > tmp.next.val ){
                tmp = tmp.next;
            }
            p.next = tmp.next;
            tmp.next = p;
        }else{
//            next while loop
            pre = pre.next;
            cur = cur.next;
        }
    }
    return tmpHead.next;
}
```

---
#### [Intersection of Two Linked Lists](https://leetcode.com/problems/intersection-of-two-linked-lists/description/)
**解题思路**
可以预先求出两个链表的长度，较长链表头可以先走|lenA-lenB|步，然后返回第一个公共节点即可。
由于原题中可能出现两个链表不相交的情况，求解长度的时候保留最后一个节点判断是否相同。<br>
**实现代码**
```java
public ListNode getIntersectionNode(ListNode headA, ListNode headB) {
//        check validation
    if (headA == null || headB == null) {
        return null;
    }

//        计算各自的长度
    ListNode pA = headA;
    int aLen = 0;
    while (pA != null) {
        pA = pA.next;
        aLen++;
    }

    ListNode pB = headB;
    int bLen = 0;
    while (pB != null) {
        pB = pB.next;
        bLen++;
    }

//        各自最后一个节点不相同
    if (pA != pB) {
        return null;
    }

    ListNode p = headA;
    ListNode q = headB;
    while (aLen > bLen) {
        aLen--;
        p = p.next;
    }
    while (aLen < bLen) {
        bLen--;
        q = q.next;
    }

    while (p != q) {
        p = p.next;
        q = q.next;
    }

    return p;
}
```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
