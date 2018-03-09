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
#### [Balanced Binary Tree](https://leetcode.com/problems/balanced-binary-tree/description/)
**解题思路**
判断所有左右子树的高度相差不超过1，可以利用计算高度的方式解题。但是每次都需要调用高度计算方法，而且子树高度已经知道的情况下，父亲节点的高度也可以求解出来，直接使用高度判断性能较低。<br>可以考虑使用递归，但是保留左右子树的高度，并返回给父节点进行判断，效率相对高一点。<br>
**实现代码**
```java
public boolean isBalanced(TreeNode root) {
    if (root == null) {
        return true;
    }
    return balancedHelp(root,new int[1]);
}

//    判断该节点是否平衡，并且返回node的高度
private boolean balancedHelp(TreeNode node, int[] height) {
    if (node == null) {
        height[0] = 0;
        return true;
    }

    int[] left = new int[1];
    int[] right = new int[1];
    if (!balancedHelp(node.left, left) || !balancedHelp(node.right, right) || Math.abs(left[0] - right[0]) > 1) {
        return false;
    }
    height[0] = Math.max(left[0], right[0]) + 1;
    return true;
}
```

### 二叉树的遍历

如果使用递归的方式遍历还是比较简单的，当然提高一点要求，下面的实现均是非递归的形式。
#### [Binary Tree Inorder Traversal](https://leetcode.com/problems/binary-tree-inorder-traversal/description/)

**解题思路**
设置stack结构保留左孩子节点，只有`left==null`这种情况才进行输出，进行下次迭代。<br>
**实现代码**
```java
//    递归形式
//    public List<Integer> inorderTraversal(TreeNode node) {
//        List<Integer> rt = new ArrayList<>();
//        if(node == null){
//            return rt;
//        }
//        //called by multi times,clear it first
//        inorder(node,rt);
//        return rt;
//    }
//
//    private void inorder(TreeNode node,List<Integer> rt) {
//        if (node == null) {
//            return;
//        }
//
////        递归left
//        inorder(node.left,rt);
////        添加元素
//        rt.add(node.val);
////        递归right
//        inorder(node.right,rt);
//    }

//    非递归形式
public List<Integer> inorderTraversal(TreeNode root) {
    List<Integer> rt = new ArrayList<>();

    if (root == null) {
        return rt;
    }

    Stack<TreeNode> stack = new Stack<>();
    TreeNode p = root;
    while (p != null || !stack.isEmpty()) {
//            递归left
        while (p != null) {
            stack.push(p);
            p = p.left;
        }
        if (!stack.isEmpty()) {
//                弹出元素并进行添加
            p = stack.pop();
            rt.add(p.val);
//                迭代right
            p = p.right;
        }
    }
    return rt;
}
```

#### [Binary Tree Preorder Traversal](https://leetcode.com/problems/binary-tree-preorder-traversal/description/)
**解题思路**
实现思路和上题一致，只不过元素的添加顺序提前了。
<br>
**实现代码**
```java
//    递归形式
//    public List<Integer> preorderTraversal(TreeNode node) {
//        List<Integer> rt = new ArrayList<>();
//        if(node == null){
//            return rt;
//        }
//        //called by multi times,clear it first
//        preorder(node,rt);
//        return rt;
//    }
//
//    private void preorder(TreeNode node,List<Integer> rt) {
//        if (node == null) {
//            return;
//        }
//
////        添加元素
//        rt.add(node.val);
////        递归left
//        preorder(node.left,rt);
////        递归right
//        preorder(node.right,rt);
//    }

    //    非递归形式
public List<Integer> preorderTraversal(TreeNode root) {
    List<Integer> rt = new ArrayList<>();

    if (root == null) {
        return rt;
    }

    Stack<TreeNode> stack = new Stack<>();
    TreeNode p = root;
    while (p != null || !stack.isEmpty()) {
//            递归left
        while (p != null) {
//                添加元素
            rt.add(p.val);
            stack.push(p);
            p = p.left;
        }
        if (!stack.isEmpty()) {
//                弹出元素
            p = stack.pop();
//                迭代right
            p = p.right;
        }
    }
    return rt;
}
```

#### [Binary Tree Postorder Traversal](https://leetcode.com/problems/binary-tree-postorder-traversal/description/)

**解题思路**
先访问左右节点，然后才访问父节点。访问当前节点仅当该节点无右节点或者右节点已经被访问过了，具体参见实现代码。<br>
**实现代码**
```java
    //    递归形式
//    public List<Integer> postorderTraversal(TreeNode node) {
//        List<Integer> rt = new ArrayList<>();
//        if(node == null){
//            return rt;
//        }
//        postorder(node,rt);
//        return rt;
//    }
//
//    private void postorder(TreeNode node,List<Integer> rt) {
//        if (node == null) {
//            return;
//        }
//
////        递归left
//        postorder(node.left,rt);
////        递归right
//        postorder(node.right,rt);
////        添加元素
//        rt.add(node.val);
//    }


    //    非递归形式
public List<Integer> postorderTraversal(TreeNode root) {
    List<Integer> rt = new ArrayList<>();
    if (root == null) {
        return rt;
    }

    Stack<TreeNode> stack = new Stack<>();
    TreeNode p = root, visited = null;
    while (p != null || !stack.isEmpty()) {
        while (p != null) {
            stack.add(p);
            p = p.left;
        }

        if (!stack.isEmpty()) {
            p = stack.peek().right;
//                访问当前节点，仅当right=null或者right已经访问过了
            if (p != null && p != visited) {
                stack.add(p);
//                    进行下一次迭代
                p = p.left;
            } else {
                p = stack.pop();
//                    访问
                visited = p;
                rt.add(p.val);
                p = null;
            }
        }
    }
    return rt;
}
```

---
#### [Binary Tree Level Order Traversal](https://leetcode.com/problems/binary-tree-level-order-traversal/description/)
**解题思路**
设置cur,next两个List<TreeNode>保存迭代顺序，针对每一次遍历，将当前层的所有元素的值添加即可。<br>
**实现代码**
```java
public List<List<Integer>> levelOrder(TreeNode root) {
    List<List<Integer>> rt = new ArrayList<>();
    if (root == null) {
        return rt;
    }

    List<TreeNode> cur = new ArrayList<>();
    cur.add(root);
    while (!cur.isEmpty()) {
        List<TreeNode> next = new ArrayList<>();
        List<Integer> tmp = new ArrayList<>();
//            下一层元素添加
        for (TreeNode node :
                cur) {
            tmp.add(node.val);
            if (node.left != null) {
                next.add(node.left);
            }
            if (node.right != null) {
                next.add(node.right);
            }
        }
//            交换，下一次迭代
        rt.add(tmp);
        cur = next;
    }
    return rt;
}
```

---
#### [Binary Tree Level Order Traversal II](https://leetcode.com/problems/binary-tree-level-order-traversal-ii/description/)

**解题思路**
在上题的基础上对返回的结果reverse一下即可。<br>
**实现代码**
```java
public List<List<Integer>> levelOrder(TreeNode root) {
    List<List<Integer>> rt = new ArrayList<>();
    if (root == null) {
        return rt;
    }

    List<TreeNode> cur = new ArrayList<>();
    cur.add(root);
    while (!cur.isEmpty()) {
        List<TreeNode> next = new ArrayList<>();
        List<Integer> tmp = new ArrayList<>();
//            下一层元素添加
        for (TreeNode node :
                cur) {
            tmp.add(node.val);
            if (node.left != null) {
                next.add(node.left);
            }
            if (node.right != null) {
                next.add(node.right);
            }
        }
//            交换，下一次迭代
        rt.add(tmp);
        cur = next;
    }
    Collections.reverse(rt);
    return rt;
}
```

---
#### [Binary Tree Paths](https://leetcode.com/problems/binary-tree-paths/description/)

**解题思路**
使用递归的方式，将节点的父节点数组作为参数传入，到达叶子节点的时候添加路径。<br>
**实现代码**
```java
private List<String> rt = new ArrayList<>();

public List<String> binaryTreePaths(TreeNode root) {
    dfs(root,new ArrayList<>());
    return rt;
}

private void dfs(TreeNode node, List<TreeNode> cur) {
    if (node == null) {
        return;
    }

    cur.add(node);
    if (node.left == null && node.right == null) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append(cur.get(0).val);
        for (int i = 1; i < cur.size(); i++) {
            stringBuilder.append("->").append(cur.get(i).val);
        }
        rt.add(stringBuilder.toString());
    }
//        迭代left,right
    dfs(node.left, cur);
    dfs(node.right, cur);
//        移除当前元素，便于下次迭代
    cur.remove(cur.size() - 1);
}
```

---
#### [Binary Tree Right Side View](https://leetcode.com/problems/binary-tree-right-side-view/description/)
**解题思路**
层次遍历的变种，返回结果并不是将整层元素添加进来，而是将整层元素的最后一个添加进来。<br>
**实现代码**
```java
public List<Integer> rightSideView(TreeNode root) {
    List<Integer> rt = new ArrayList<>();
    if (root == null) {
        return rt;
    }

    List<TreeNode> cur = new ArrayList<>();
    cur.add(root);
    while (!cur.isEmpty()) {
        List<TreeNode> next = new ArrayList<>();
//            下一层元素添加
        for (TreeNode node :
                cur) {
            if (node.left != null) {
                next.add(node.left);
            }
            if (node.right != null) {
                next.add(node.right);
            }
        }
        rt.add(cur.get(cur.size() - 1).val);
        //            交换，下一次迭代
        cur = next;
    }
    return rt;
}
```

---
#### [Binary Tree Zigzag Level Order Traversal](https://leetcode.com/problems/binary-tree-zigzag-level-order-traversal/description/)

**解题思路**
leetcode在tree前面部分，有很多题目考察的不是Tree的操作，越来越像数组的变换操作哈。
此题在层次遍历的基础上，通过设置flag的方式，交替将数组反转然后添加到返回结果。<br>
**实现代码**
```java
public List<List<Integer>> zigzagLevelOrder(TreeNode root) {
    List<List<Integer>> rt = new ArrayList<>();
    if (root == null) {
        return rt;
    }

    List<TreeNode> cur = new ArrayList<>();
    cur.add(root);
    boolean flag = true;
    while (!cur.isEmpty()) {
        List<TreeNode> next = new ArrayList<>();
        List<Integer> tmp = new ArrayList<>();
//            下一层元素添加
        for (TreeNode node :
                cur) {
            tmp.add(node.val);
            if (node.left != null) {
                next.add(node.left);
            }
            if (node.right != null) {
                next.add(node.right);
            }
        }
//            交换，下一次迭代
        if (!flag) {
            Collections.reverse(tmp);
        }
        flag = !flag;
        rt.add(tmp);
        cur = next;
    }
//        Collections.reverse(rt);
    return rt;
}
```

---
#### [Convert Sorted Array to Binary Search Tree](https://leetcode.com/problems/convert-sorted-array-to-binary-search-tree/description/)
**解题思路**
和[Convert Sorted List to Binary Search Tree](http://julyerr.club/2018/02/20/interview-tree/#convert-sorted-list-to-binary-search-tree)类似,每次取数组的中间元素作为root，然后
迭代左右两部分。<br>
**实现代码**
```java
public TreeNode sortedArrayToBST(int[] nums) {
    if (nums == null || nums.length == 0) {
        return null;
    }
    return dfs(nums, 0, nums.length - 1);
}

private TreeNode dfs(int[] nums, int start, int end) {
    if (start > end) {
        return null;
    }
//        每次取出中间元素作为节点
    int mid = (start + end) >> 1;
    TreeNode node = new TreeNode(nums[mid]);
    node.left = dfs(nums, start, mid - 1);
    node.right = dfs(nums, mid + 1, end);
    return node;
}
```

#### [Count Complete Tree Nodes](https://leetcode.com/problems/count-complete-tree-nodes/description/)
**解题思路**
可以使用递归的方式获取到所有节点的个数，但是对于完全二叉树而言，知道了高度和最后一层叶子节点的个数，
整个二叉树的节点个数也就知道了。因此先获取到左右子树的最大高度，如果相等，说明是完全满二叉树，节点个数计算得出；
如果不相等，可以递归左右子树获取。<br>
**实现代码**
```java
public int countNodes(TreeNode root) {
    if(root == null){
        return 0;
    }
    
//        分别获取left,right的高度
    int leftHeight = 1;
    int rightHeight = 1;
    TreeNode left = root.left;
    TreeNode right = root.right;
    while(left!=null){
        left = left.left;
        leftHeight++;
    }
    while(right!=null){
        right = right.right;
        rightHeight++;
    }
    
//        完全满二叉树
    if(leftHeight == rightHeight){
        return (1<<leftHeight)-1;
    }
    
    return 1+countNodes(root.left)+countNodes(root.right);
}
```

---
#### [Flatten Binary Tree to Linked List](https://leetcode.com/problems/flatten-binary-tree-to-linked-list/description/)

**解题思路**
转换成LnkedList之后，next指针指向BST的前序遍历的下一个节点。比较自然的想法是使用
前序遍历将所有的TreeNode添加进Queue，然后调整指针，但是浪费空间；下面这种递归调整方式很巧妙，
通过设置一个pre的指针，然后递归的时候进行调整，具体参见实现代码。<br>
**实现代码**
```java
TreeNode prev = null;
public void flatten(TreeNode root) {
    if (root == null) {
        return;
    }
//        调整前驱指针
    if (prev != null) {
        prev.right = root;
        prev.left = null;
    }

//        保存left,right节点
    TreeNode left = root.left;
    TreeNode right = root.right;

    prev = root;
    flatten(left);
    flatten(right);
}
```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
