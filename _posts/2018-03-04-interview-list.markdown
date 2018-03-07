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

### Reverse List
使用递归的方式较为简单，直接反转容易出错

#### [Reverse Linked List](https://leetcode.com/problems/reverse-linked-list/description/)
**解题思路**
直接递归反转，node.next反转好之后，调整node和反转好的节点的关系即可<br>
**实现代码**
```java
public ListNode reverseList(ListNode head) {
    if(head == null || head.next == null){
        return head;
    }
    
//        保留head.next用于调整关系
    ListNode tmp = head.next;
    ListNode newHead = reverseList(head.next);
    
//        修改指针
    tmp.next = head;
    head.next = null;
    
    return newHead;
}
```

#### [Reverse Linked List II](https://leetcode.com/problems/reverse-linked-list-ii/description/)
**解题思路**
限制在某个范围之内的反转操作，记录起始和结束node,结束node的null需要设置为null；
反转该部分之后，重新拼接出新的linked list<br>
**实现代码**
```java
public ListNode reverseBetween(ListNode head, int m, int n) {
    if (head == null || head.next == null || m == n ) {
        return head;
    }

//        为了方便操作，设置临时头结点
    ListNode tmpHead = new ListNode(0);
    tmpHead.next = head;


//        保留pre
    ListNode pre = null;
    //        记录起始和结束node
    ListNode start = tmpHead;
    ListNode end = tmpHead;
    while (m-- > 0) {
        pre = start;
        start = start.next;
        end = end.next;
        n--;
    }
    while (n-- > 0) {
        end = end.next;
    }

//        保留tail
    ListNode tail = end.next;
    end.next = null;

//        反转并拼接
    pre.next = reverseListComm(start);
    start.next = tail;

    return tmpHead.next;
}

public static ListNode reverseListComm(ListNode head) {
    if (head == null || head.next == null) {
        return head;
    }

    ListNode tmp = head.next;
    ListNode newHead = reverseListComm(head.next);
    tmp.next = head;
    head.next = null;
    return newHead;
}
```

---
#### [Palindrome Linked List](https://leetcode.com/problems/palindrome-linked-list/description/)
**解题思路**
先使用快慢指针找到中点，然后反转后半段；返回的新节点和开始节点迭代比较即可<br>
**实现代码**
```java
public boolean isPalindrome(ListNode head) {
//        check validation
    if (head == null || head.next == null) {
        return true;
    }

    ListNode fast = head;
    ListNode slow = head;

//        找到中间节点
    while (fast != null && fast.next != null) {
        fast = fast.next.next;
        slow = slow.next;
    }

//        翻转后部分
    ListNode tail = reverseList(slow);

//        迭代比较
//        notes:如果设置成head!=tail，会发生空指针引用的异常，中间的tail = null
    while (head != slow) {
        if (head.val != tail.val) {
            return false;
        }
        head = head.next;
        tail = tail.next;
    }
    return true;
}

private ListNode reverseList(ListNode head) {
    if (head == null || head.next == null) {
        return head;
    }

    ListNode tmp = head.next;
    ListNode newHead = reverseList(head.next);
    tmp.next = head;
    head.next = null;
    return newHead;
}
```

---
### remove duplicates

和数组去重类似，只不过改成了链表

##### [Remove Duplicates from Sorted List](https://leetcode.com/problems/remove-duplicates-from-sorted-list/description/)

**解题思路**
next只有当新的元素出现的时候才添加进来<br>
**实现代码**
```java
public ListNode deleteDuplicates(ListNode head) {
    if(head == null || head.next==null){
        return head;
    }

    ListNode p = head;
    while(p.next!=null){
       if(p.next.val==p.val){
           ListNode tmp = p.next;
//               下一个不相等的节点或者null
           while(tmp!=null && tmp.val == p.val){
               tmp = tmp.next;
           }
           p.next = tmp;
       }else{
           p = p.next;
       }
    }
    return head;
}
```

#### [Remove Duplicates from Sorted List II](https://leetcode.com/problems/remove-duplicates-from-sorted-list-ii/description/)
**解题思路**
设置一个临时头结点，只有将未出现过重复的节点添加进来。<br>
**实现代码**
```java
public ListNode deleteDuplicates(ListNode head) {
    if (head == null || head.next == null) {
        return head;
    }

    ListNode tmpHead = new ListNode(0);
    tmpHead.next = head;

    ListNode p = tmpHead;
//        两级next比较
    while (p.next != null && p.next.next != null) {
        if (p.next.val == p.next.next.val) {
            ListNode tmp = p.next.next;
//                寻找新值，或者出现null
            while (tmp != null && tmp.val == p.next.val) {
                tmp = tmp.next;
            }
            p.next = tmp;
        } else {
            p = p.next;
        }
    }

    return tmpHead.next;
}
```

---
#### [Remove Nth Node From End of List](https://leetcode.com/problems/remove-nth-node-from-end-of-list/description/)
**解题思路**
借鉴快慢指针的思路，可以先让fast走n步，然后迭代至fast到末端，直接修改next即可<br>
**实现代码**
```java
//    题目明确n是有效的，因此不需要判断n的范围
public ListNode removeNthFromEnd(ListNode head, int n) {
//        check n if necessary
    if (head == null) {
        return head;
    }

//        设置临时头结点
    ListNode tmpHead = new ListNode(0);
    tmpHead.next = head;

    ListNode fast = tmpHead;
//        先走N步
    while (n-- > 0) {
        fast = fast.next;
    }
    ListNode pre = tmpHead;

//        迭代到fast到末端
    while (fast.next != null) {
        fast = fast.next;
        pre = pre.next;
    }
//        移除对应节点
    pre.next = pre.next.next;

    return tmpHead.next;
}
```

---
#### [Rotate List](https://leetcode.com/problems/rotate-list/description/)
**解题思路**
先调整成一个环，然后选择合适的位置截断<br>
**实现代码**
```java
public ListNode rotateRight(ListNode head, int k) {
    if (head == null) {
        return head;
    }

//        记录链表的长度，p为末端
    int length = 1;
    ListNode p = head;
    while (p.next != null) {
        p = p.next;
        length++;
    }

//        k可能超过链表的长度，需要取余数
    k = k % length;

//        未发生变化
    if (k == 0) {
        return head;
    }

//        找到新的末端节点
    ListNode tail = head;
    for (int i = 0; i < length - k - 1; i++) {
        tail = tail.next;
    }

//        构成环
    p.next = head;
    ListNode ret = tail.next;

//        截断环
    tail.next = null;

    return ret;

}
```

---
#### [Sort List](https://leetcode.com/problems/sort-list/description/)
**解题思路**
在O(nlogn)的时间复杂度进行排序，常见有快排、堆排和归并排序；前两者对元素的下标操作要求较为灵活，
选择归并排序。先不断split,后调用merge归并<br>
**实现代码**
```java
public ListNode sortList(ListNode head){
    if(head == null || head.next == null){
        return head;
    }
    ListNode mid = split(head);
    ListNode node1 = sortList(head);
    ListNode node2 = sortList(mid);
   return mergeTwoLists(node1,node2);
}

private ListNode split(ListNode head){
    if(head == null || head.next==null){
        return head;
    }
    
//        设置快慢指针
    ListNode fast = head;
    ListNode slow = head;
    ListNode slowPre = null;
    while(fast!=null && fast.next!=null){
        fast = fast.next.next;
        slowPre = slow;
        slow = slow.next;
    }
    
    slowPre.next = null;
    return slow;
}

public static ListNode mergeTwoLists(ListNode l1, ListNode l2) {
//        check validation
    if (l1 == null && l2 == null) {
        return null;
    } else if (l1 == null) {
        return l2;
    } else if (l2 == null) {
        return l1;
    }

//        设置临时节点
    ListNode tmpHead = new ListNode(0);
    ListNode cur = tmpHead;

    ListNode p = l1;
    ListNode q = l2;
    while (p != null && q != null) {
        if (p.val <= q.val) {
            cur.next = p;
            p = p.next;
        } else {
            cur.next = q;
            q = q.next;
        }
        cur = cur.next;
    }
//        剩余部分合并
    if (p != null) {
        cur.next = p;
    }
    if (q != null) {
        cur.next = q;
    }
    return tmpHead.next;
}
```

#### [Swap Nodes in Pairs](https://leetcode.com/problems/swap-nodes-in-pairs/description/)
**解题思路**
题目明确要求，不能直接交换相邻node之间的val，只能调整node。
迭代list的时候，两两做一个部分进行交换即可，注意next<br>
**实现代码**
```java
public ListNode swapPairs(ListNode head) {
    if(head == null || head.next== null){
        return head;
    }

//        设置临时头结点，方便操作
    ListNode tmpHead = new ListNode(0);
    tmpHead.next = head;

    ListNode p = tmpHead;
    ListNode nextStep = null;
    while(p!=null && p.next!=null && p.next.next!=null){
        nextStep = p.next.next.next;
        
        ListNode tmp = p.next;
        p.next = p.next.next;
        p.next.next = tmp;
        tmp.next = nextStep;
//            下一次跌地
        p = tmp;
    }

    return tmpHead.next;
}
```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
