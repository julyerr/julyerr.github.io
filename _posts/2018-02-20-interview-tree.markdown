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
**实现代码**
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
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
