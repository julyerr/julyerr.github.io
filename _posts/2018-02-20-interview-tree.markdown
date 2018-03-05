---
layout:     post
title:      "面试编程题 tree"
subtitle:   "面试编程题 tree"
date:       2018-02-20 6:00:00
author:     "julyerr"
header-img: "img/ds/tree/tree.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - tree
---

### Construct Tree
通过二叉树前序和中序或者后序和中序构建新的二叉树返回
#### [Construct Binary Tree from Preorder and Inorder Traversal](https://leetcode.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/description/)
**解题思路**<br>
leetcode上说明了`You may assume that duplicates do not exist in the tree.`;
如果tree中出现了duplicates，需要特殊处理。下面的这种解法适合出现[重复的现象](https://www.nowcoder.com/practice/8a19cbe657394eeaac2f6ea9b0f6fcf6)。
设置pre、in数组的start,end限制元素选取范围。<br>
**实现代码**<br>
```java
public TreeNode buildTree(int[] preorder, int[] inorder) {
//        check validation
    if (preorder == null || preorder.length == 0) {
        return null;
    }
    return constructBT(preorder, 0, preorder.length - 1, inorder, 0, inorder.length - 1);
}

private static TreeNode constructBT(int[] pre, int preStart, int preEnd, int[] in, int inStart, int inEnd) {
//        边界范围
    if (preStart > preEnd || inStart > inEnd) {
        return null;
    }
    int i = 0;
    for (i = inStart; i <= inEnd; i++) {
        if (pre[preStart] == in[i]) {
            break;
        }
    }
    TreeNode newNode = new TreeNode(pre[preStart]);
    newNode.left = constructBT(pre, preStart + 1, preStart+(i-inStart), in, inStart, i - 1);
    newNode.right = constructBT(pre, preStart+(i-inStart)+1, preEnd, in, i + 1, inEnd);
    return newNode;
}
```

---
#### [Construct Binary Tree from Inorder and Postorder Traversal](https://leetcode.com/problems/construct-binary-tree-from-inorder-and-postorder-traversal/description/)
**解题思路**<br>
和上题解题思路基本上一致<br>
[实现代码](https://github.com/julyerr/algo/tree/master/src/com/julyerr/leetcode/tree/BSTFIP.java)

---
#### [Convert Sorted List to Binary Search Tree](https://leetcode.com/problems/convert-sorted-list-to-binary-search-tree/description/)
**解题思路**
需要保持BST的平衡性，可以取链表的中间节点作为root节点，然后递归左右部分。取中间节点的时候可以通过快慢指针。<br>
**实现代码**
```java
public TreeNode sortedListToBST(ListNode head) {
//        check validation
    if (head == null) {
        return null;
    } else if (head.next == null) {
        return new TreeNode(head.val);
    }
    ListNode mid = cutMid(head);

//        查询中间节点，构建平衡树
    TreeNode node = new TreeNode(mid.val);
    node.left = sortedListToBST(head);
    node.right = sortedListToBST(mid.next);
    return node;
}

private ListNode cutMid(ListNode head) {
    if (head == null) {
        return null;
    }
    //        single node
    if (head.next == null) {
        return head;
    }
    ListNode fast = head;
    ListNode slow = head;

    ListNode slowPre = null;
//        查询设置slow为中间位置
    while (fast != null && fast.next != null) {
        slowPre = slow;
        slow = slow.next;
        fast = fast.next.next;
    }
//        分成不相链的两部分
    slowPre.next = null;
    return slow;
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
