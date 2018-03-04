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
**解题思路**
<br>
**实现代码**
```java

```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
