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

---
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

---
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


---
#### [Validate Binary Search Tree](https://leetcode.com/problems/validate-binary-search-tree/description/)
**解题思路**
只需要验证树的中序遍历是否递增<br>
**实现代码**

```java
public boolean isValidBST(TreeNode root) {
    if (root == null) {
        return true;
    }

    Stack<TreeNode> stack = new Stack<>();
    TreeNode p = root;
    int preVal = 0;
    boolean first = true;
    while (p != null || !stack.isEmpty()) {
//            递归left
        while (p != null) {
            stack.push(p);
            p = p.left;
        }
        if (!stack.isEmpty()) {
//                弹出元素并进行添加
            p = stack.pop();
            if(first){
                preVal = p.val;
                first = false;
            }else{
                if (p.val <= preVal) {
                    return false;
                } else {
                    preVal = p.val;
                }
            }
//                迭代right
            p = p.right;
        }
    }
    return true;
}
```

---
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
#### [Sum Root to Leaf Numbers](https://leetcode.com/problems/sum-root-to-leaf-numbers/description/)
**解题思路**
在上题所有root到叶子节点的基础上添加了求和的功能。求和还有一种更加简洁的写法，将父亲节点的值一路传入到
叶子节点，然后计算返回。<br>
**实现代码**

```java
//路径法求解
private int sum =0;
public int sumNumbers(TreeNode root) {
    dfs(root,new ArrayList<>());
    return sum;
}

private void dfs(TreeNode node,List<Integer> cur){
    if(node == null){
        return;
    }
    cur.add(node.val);
    if(node.left==null&&node.right==null){
        int tmp = 0;
        for (int i = 0; i < cur.size(); i++) {
            tmp = 10*tmp+cur.get(i);
        }
        sum += tmp;
    }
    dfs(node.left,cur);
    dfs(node.right,cur);
    cur.remove(cur.size()-1);
}

//    将根节点一路的值传递到叶子节点
public int sumNumbers(TreeNode root) {
    return dfs(root, 0);
}

private int dfs(TreeNode node, int parantVal) {
//        部分子节点为空
    if (node == null) {
        return 0;
    }
    int val = parantVal * 10 + node.val;
//        已经是叶子节点，直接返回值
    if (node.left == null && node.right == null) {
        return val;
    }
    return dfs(node.left, val) + dfs(node.right, val);
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
### Path Sum系列
#### [Path Sum](https://leetcode.com/problems/path-sum/description/)
**解题思路**
sum减去当下的值，然后递归；只有在叶子节点才能进行true和false判断。<br>
**实现代码**

```java
public boolean hasPathSum(TreeNode root, int sum) {
    if (root == null) {
        return false;
    }
    sum -= root.val;
//        只有在当前节点没有左右孩子节点的时候才可能进行返回判断
    if (root.left == null && root.right == null) {
        return sum == 0 ? true : false;
    }
    return hasPathSum(root.left, sum) || hasPathSum(root.right, sum);
}
```

#### [Path Sum II](https://leetcode.com/problems/path-sum-ii/description/)
**解题思路**
在上题的基础上，需要保留每条路径经过的元素值。为了节省空间，递归该节点的时候将元素添加进来；递归完毕，将该元素值删除。<br>
**实现代码**

```java
List<List<Integer>> rt = new ArrayList<>();

public List<List<Integer>> pathSum(TreeNode root, int sum) {
    if (root == null) {
        return rt;
    }
    dfs(root, new ArrayList<Integer>(), sum);
    return rt;
}

private void dfs(TreeNode node, List<Integer> cur, int target) {
    if (node == null) {
        return;
    }

    target -= node.val;
//        添加进当前节点
    cur.add(node.val);
//        只有在叶子节点的时候再进行判断
    if (node.left == null && node.right == null) {
        if (target == 0) {
            rt.add(new ArrayList<>(cur));
        }
    }
    dfs(node.left, cur, target);
    dfs(node.right, cur, target);
//        删除当下节点，不影响后面操作
    cur.remove(cur.size() - 1);
}
```


---
#### [Populating Next Right Pointers in Each Node](https://leetcode.com/problems/populating-next-right-pointers-in-each-node/description/)
**解题思路**
比较容易的想法是在层次遍历的基础上，调整同一层上next指针的方向；当然也可以使用递归的方式调整指针，具体参见实现代码。<br>
**实现代码**

```java
//层次遍历基础上调整
public void connect(TreeLinkNode root) {
    if (root == null) {
        return;
    }

    LinkedList<TreeLinkNode> cur, next;
    cur = new LinkedList<>();
    cur.add(root);

    while (!cur.isEmpty()) {
        next = new LinkedList<>();
        int size = cur.size();
        for (int i = 0; i < size; i++) {
            TreeLinkNode first = cur.get(i);
            if (first.left != null) {
                next.add(first.left);
            }
            if (first.right != null) {
                next.add(first.right);
            }
            if (i == size - 1) {
                break;
            }
            first.next = cur.get(i + 1);
        }
        cur.get(size - 1).next = null;

        cur = next;
    }
}

//    递归方式
public void connect(TreeLinkNode root) {
    if (root == null) {
        return;
    }
//        调整当前节点
    if (root.left != null && root.right != null) {
        root.left.next = root.right;
    }
    if (root.right != null &&root.next !=null && root.next.left != null) {
        root.right.next = root.next.left;
    }
//        递归调整left,right
    connect(root.left);
    connect(root.right);
}
```



---
#### [Maximum Depth of Binary Tree](https://leetcode.com/problems/maximum-depth-of-binary-tree/description/)
**解题思路**
递归返回左右节点中更大高度的节点即可。<br>
**实现代码**

```java
public int maxDepth(TreeNode root) {
    if (root == null) {
        return 0;
    }
    int left = maxDepth(root.left);
    int right = maxDepth(root.right);

    return Math.max(left, right) + 1;
}
```

---
#### [Minimum Depth of Binary Tree](https://leetcode.com/problems/minimum-depth-of-binary-tree/description/)
**解题思路**
这道题关键是理解二叉树最小高度的含义，有以下情况：<br>

```
node == null -> 0
node.left == null && node.right == null -> 1
node.left != null && node.right == null -> minDepth(node.left)+1
node.left == null && node.right != null -> minDepth(node.right)+1
node.left != null && node.right != null -> min(minDepth(node.left),minDepth(node.right))+1
```

<br>
**实现代码**

```java
public int minDepth(TreeNode root) {
    if (root == null) {
        return 0;
    }
//        对应各种情况处理
    if (root.left == null && root.right == null) {
        return 1;
    } else if (root.left != null && root.right == null) {
        return 1 + minDepth(root.left);
    } else if (root.left == null && root.right != null) {
        return 1 + minDepth(root.right);
    }

    return Math.min(minDepth(root.left), minDepth(root.right)) + 1;
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
#### [Invert Binary Tree](https://leetcode.com/problems/invert-binary-tree/description/)
**解题思路**
递归方式，先交换左右节点然后递归对左右节点进行处理<br>
**实现代码**

```java
public TreeNode invertTree(TreeNode root) {
    if (root == null) {
        return null;
    }
//        先交换左右节点
    TreeNode tmp = root.left;
    root.left = root.right;
    root.right = tmp;
//        递归调用左右节点处理
    invertTree(root.left);
    invertTree(root.right);
    return root;
}
```

---
#### [Same Tree](https://leetcode.com/problems/same-tree/description/)
**解题思路**
使用递归方式判断left，right是否相等。<br>
**实现代码**

```java
public boolean isSameTree(TreeNode p, TreeNode q) {
//        直接如此判断，判断的是同一个对象，显然不行
//        if (p != q) {
//            return false;
//        }
    if (p == null && q == null) {
        return true;
    } else if (p == null || q == null) {
        return false;
    } else if (p.val != q.val) {
        return false;
    }
    return isSameTree(p.left, q.left) && isSameTree(p.right, q.right);
}
```

---
#### [Symmetric Tree](https://leetcode.com/problems/symmetric-tree/description/)
**解题思路**
类似的，可以使用层次遍历判断同一层的元素是否对程；此题也可以使用递归的方式进行，在上题的基础上添加一些技巧。<br>
**实现代码**

```java
public boolean isSymmetric(TreeNode root) {
    if (root == null) {
        return true;
    }
    return issymmetric(root.left, root.right);
}

private boolean issymmetric(TreeNode p, TreeNode q) {
    if (p == null && q == null) {
        return true;
    } else if (p == null || q == null) {
        return false;
    } else if (p.val != q.val) {
        return false;
    }
    return issymmetric(p.left, q.right) && issymmetric(p.right, q.left);
}
```

---
#### [Kth Smallest Element in a BST](https://leetcode.com/problems/kth-smallest-element-in-a-bst/description/)
**解题思路**
BST的中序遍历是有序的，只需要遍历到第k个节点就可以返回该值。<br>
**实现代码**

```java
public int kthSmallest(TreeNode root, int k) {
    Stack<TreeNode> stack = new Stack<>();
    TreeNode p = root;
    while (p != null || !stack.isEmpty()) {
//            递归left
        while (p != null) {
//                添加元素
            stack.push(p);
            p = p.left;
        }
        if (!stack.isEmpty()) {
//                弹出元素
            p = stack.pop();
            k--;
            if (k == 0) {
                return p.val;
            }
//                迭代right
            p = p.right;
        }
    }
    return -1;
}
```

---
#### [Lowest Common Ancestor of a Binary Search Tree](https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/description/)
**解题思路**
笔者开始想到的思路是，分别记录根节点到p、q的节点信息，然后比较最后一个相同的节点（有点类似求解List的最后一个公共节点）。但是这道题有还更优的解题方法，BST已经排好序，最低公共节点其实就是两节点之间的点。<br>
**实现代码**

```java
public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
    if (root == null || p == null || q == null) {
        return null;
    }

    int min = p.val > q.val ? q.val : p.val;
    int max = p.val + q.val - min;

    while (root != null) {
//            在root的右边
        if (root.val < min) {
            root = root.right;
//            在root的左边
        } else if (root.val > max) {
            root = root.left;
//             处于两者之间
        } else {
            return root;
        }
    }
    return null;
}
```

---
#### [Lowest Common Ancestor of a Binary Tree](https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-tree/description/)
**解题思路**
可以按照上题所说的传统记录路径的方式解题。下面有一种更加高效的解题思路：<br>
从根节点开始向下搜索，对每个节点进行判断：

- l：node的左子树是否出现过p或q
- r：node的右子树是否出现过p或q
如果l和r都不是null，则该结点即为lca<br>
**实现代码**

```java
public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
//        root等于p或者q可以直接返回
    if (root == null || root == p || root == q) {
        return root;
    }

    TreeNode left = lowestCommonAncestor(root.left, p, q);
    TreeNode right = lowestCommonAncestor(root.right, p, q);

//        左右节点分别包含p,q
    if (left != null && right != null) {
        return root;
    }

    return left == null ? right : left;
}
```

---
#### [Unique Binary Search Trees II](https://leetcode.com/problems/unique-binary-search-trees-ii/description/)
**解题思路**
与[上题](http://julyerr.club/018/02/25/interview-dp/#unique-binary-search-trees)使用dp求解情况数不同，需要求解出具体的树并返回。此题非常巧妙地使用递归，先将左右子树构建完成，然后针对不同的元素为root节点，添加进结果即可，具体参见实现代码。<br>
**实现代码**

```java
public List<TreeNode> generateTrees(int n) {
    if (n < 1) {
        return new ArrayList<>();
    }
    int[] nums = new int[n];
    for (int i = 0; i < n; i++) {
        nums[i] = i + 1;
    }
//       共用一个数组
    return dfs(nums, 0, n);
}

public List<TreeNode> dfs(int[] nums, int start, int end) {
    List<TreeNode> rt = new ArrayList<>();
    if (start >= end) {
//            null也需要添加进来遍历
        rt.add(null);
        return rt;
    }

//        以不同元素为root，构建tree数组
    for (int i = start; i < end; i++) {
        for (TreeNode left :
                dfs(nums, start, i)) {
            for (TreeNode right :
                    dfs(nums, i + 1, end)) {
                TreeNode node = new TreeNode(nums[i]);
                node.left = left;
                node.right = right;
                rt.add(node);
            }
        }
    }
    return rt;
}
```

---
#### [Serialize and Deserialize Binary Tree](https://leetcode.com/problems/serialize-and-deserialize-binary-tree/description/)
**解题思路**
说白了，题目要求就是现将一棵树自定义格式转换成字符串，然后能够从该字符串中还原出原来这棵树。
提示给出了一种实现，给定节点nums[i],在不超过范围前提之下，nums[2*i+1]为left,nums[2*i+2]=right。
技巧在于节点不论是否为null,一起添加进队列。<br>
**实现代码**

```java
// Encodes a tree to a single string.
public String serialize(TreeNode root) {
    if (root == null) {
        return "";
    }
    Queue<TreeNode> queue = new LinkedList<>();
    queue.add(root);
    StringBuilder stringBuilder = new StringBuilder();
    while (!queue.isEmpty()) {
        TreeNode tmp = queue.poll();
        if (tmp == null) {
            stringBuilder.append(",").append("null");
        } else {
            stringBuilder.append(",").append(tmp.val);
//                不论是否null，直接添加进来
            queue.add(tmp.left);
            queue.add(tmp.right);
        }
    }
//        去除第一个,
    return stringBuilder.toString().substring(1);
}

// Decodes your encoded data to tree.
public TreeNode deserialize(String data) {
//        比较坑的一点是，"".split()之后返回的还是""
    if (data == null || data.length() == 0) {
        return null;
    }
    String[] strings = data.split(",");

//        先建立node数组
    int length = strings.length;
    TreeNode[] nodes = new TreeNode[length];
    for (int i = 0; i < length; i++) {
        if (!strings[i].equals("#")) {
            nodes[i] = new TreeNode(Integer.parseInt(strings[i]));
        }
    }
//        记录有效的parent
    int parent = 0;
    for (int i = 0; parent * 2 + 2 < length; i++) {
//            调整左右关系
        if (nodes[i] != null) {
            nodes[i].left = nodes[2 * parent + 1];
            nodes[i].right = nodes[2 * parent + 2];
            parent++;
        }
    }
    return nodes[0];
}
```

---
#### []()
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
