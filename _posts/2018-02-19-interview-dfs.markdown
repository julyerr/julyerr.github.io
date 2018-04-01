---
layout:     post
title:      "面试编程题 dfs"
subtitle:   "面试编程题 dfs"
date:       2018-02-19 6:00:00
author:     "julyerr"
header-img: "img/ds/dfs/dfs.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - dfs
---

### Combination Sum系列
#### [Combination Sum](https://leetcode.com/problems/combination-sum/description/)
**解题思路**<br>
深度遍历元素的所有可能组合方式<br>
**实现代码**<br>
```java
static List<List<Integer>> rt;
static int[] candidate;

public List<List<Integer>> combinationSum(int[] candidates, int target) {
    rt = new ArrayList<>();
    if (candidates == null || candidates.length == 0) {
        return rt;
    }
//        sort the arrays
    Arrays.sort(candidates);
    candidate = candidates;
    dfs(0, target, new ArrayList<>());
    return rt;
}

private static void dfs(int start, int target, List<Integer> cur) {
    if (target == 0) {
        rt.add(new ArrayList<>(cur));
        return;
    }
    for (int i = start; i < candidate.length; i++) {
//            large than remaining elems
        if (target < candidate[i]) {
            return;
        }
        cur.add(candidate[i]);
        dfs(start,target-candidate[i],cur);
        cur.remove(cur.size()-1);
    }
}
```

---
#### [Combination Sum II](https://leetcode.com/problems/combination-sum-ii/description/)
**解题思路**<br>
和上题基本类似，只不过需要使用set进行去重处理<br>
[实现代码参见](https://github.com/julyerr/algo/tree/master/src/com/julyerr/leetcode/DFS/CombinationSumII.java)

---
#### [Combination Sum III](https://leetcode.com/problems/combination-sum-iii/description/)
**解题思路**<br>
和Combination Sum II类似，只不过现在选择元素限制在1-9之间<br>
**实现代码**<br>
```
static List<List<Integer>> rt;
public List<List<Integer>> combinationSum3(int k, int n) {
    rt = new ArrayList<>();
//        check validation
    if (k < 1 || n < 1) {
        return rt;
    }
    dfs(1, n, k, new ArrayList<>());
    return rt;
}

private static void dfs(int start, int n, int k, List<Integer> cur) {
    if (k == 0 && n == 0) {
        rt.add(new ArrayList<>(cur));
        return;
    } else if (n <= 0 || k <= 0) {
        return;
    }
    for (int i = start; i <= 9; i++) {
        if (i > n) {
            return;
        }
        cur.add(i);
        dfs(i + 1, n - i, k - 1, cur);
        cur.remove(cur.size() - 1);
    }
}
```

---
#### [Restore IP Addresses](https://leetcode.com/problems/restore-ip-addresses/description/)
**解题思路**
使用递归的方式，传入当前下标cur和已经划分好的段数；只有在划分好四段而且cur==s.length()-1的时候才返回。<br>
**实现代码**

```java
List<String> rt;
String[] strs = new String[4];

public List<String> restoreIpAddresses(String s) {
    rt = new ArrayList<>();
    if (s == null || s.length() < 4) {
        return rt;
    }
    dfs(s, 0, 0);
    return rt;
}

private void dfs(String s, int cur, int segs) {
    if (segs == 4) {
        if (cur >= s.length()) {
            rt.add(String.join(".", strs));
        }
        return;
    }
//        考虑接下来的1-3个字符划分为新的一段
    for (int i = 1; i <= 3; i++) {
        if (cur + i > s.length()) {
            return;
        }
//            如果当前字符是0,除了当前0为一段之外，其他直接返回
        if (i > 1 && s.charAt(cur) == '0') {
            return;
        }
        String number = s.substring(cur, cur + i);
        if (Integer.parseInt(number) <= 255) {
            strs[segs] = number;
            dfs(s, cur + i, segs + 1);
        }
    }
}
```

---
#### [Palindrome Partitioning](https://leetcode.com/problems/palindrome-partitioning/description/)
**解题思路**
可以使用递归的方法，将整个字符串分成两部分，前部分如果是回文的话可以添加到结果，后部分迭代使用递归生成的回文序列，具体参见实现代码。<br>
**实现代码**

```java
public List<List<String>> partition(String s) {
    List<List<String>> rt = new ArrayList<>();
    if (s == null || s.length() == 0) {
        return rt;
    }
    for (int i = 0; i < s.length(); i++) {
//            截取前半部分
        String prePart = s.substring(0, i+1);
        if (isPalindrome(prePart)) {
//                对后半部分进行递归
            List<List<String>> subList = partition(s.substring(i + 1));
            if (subList.isEmpty()) {
                rt.add(Arrays.asList(prePart));
            } else {
//                    扩展两部分
                for (List<String> list :
                        subList) {
                    List<String> tmp = new ArrayList<>();
                    tmp.add(prePart);
                    tmp.addAll(list);
                    rt.add(tmp);
                }
            }
        }
    }
    return rt;
}

//    判断是否为回文字符串
private boolean isPalindrome(String s) {
//        防止出现死循环
    if (s.length() == 0) {
        return false;
    }
    int start = 0;
    int end = s.length() - 1;
    while (start < end) {
        if (s.charAt(start) != s.charAt(end)) {
            return false;
        }
        start++;
        end--;
    }
    return true;
}

```

---
#### [Word Search](https://leetcode.com/problems/word-search/description/)
**解题思路**
先遍历board中的每个元素，递归该元素的上下左右四个方向，如果存在则直接返回，否则跳过该元素，具体参见实现代码。<br>
**实现代码**

```java
public boolean exist(char[][] board, String word) {
//        需要验证的条件较多
    if (board == null || board.length == 0 || board[0] == null || board[0].length == 0 || word == null || word.length() == 0) {
        return false;
    }
    xLen = board.length;
    yLen = board[0].length;
//        不能出现重复访问同一个位置的情况
    boolean[][] visited = new boolean[xLen][yLen];
    for (int i = 0; i < xLen; i++) {
        for (int j = 0; j < yLen; j++) {
//                每次访问从头开始
            if (finded(board, i, j, word, 0, visited)) {
                return true;
            }
        }
    }
    return false;
}

private boolean finded(char[][] board, int x, int y, String string, int index, boolean[][] visited) {
    if (index == string.length()) {
        return true;
    }
    if (x < 0 || x >= xLen || y < 0 || y >= yLen) {
        return false;
    }
//        没有被访问过，并且相等
    if (!visited[x][y] && string.charAt(index) == board[x][y]) {
        visited[x][y] = true;
//            dfs判断上下左右位置
        if (finded(board, x + 1, y, string, index + 1, visited) || finded(board, x, y + 1, string, index + 1, visited) ||
                finded(board, x - 1, y, string, index + 1, visited) || finded(board, x, y - 1, string, index + 1, visited)) {
            return true;
        }
        visited[x][y] = false;
    }
    return false;
}

private int xLen, yLen;
```

---
#### [Different Ways to Add Parentheses](https://leetcode.com/problems/different-ways-to-add-parentheses/description/)
**解题思路**
开始的想法是，不同的括号位置，可以对应到stack中针对某个运算符是直接计算，还是直接入栈后面再操作，但是后面实现的时候发现太复杂了。<br>
转而还是使用递归，针对每个运算符，将整个字符串划分为两部分，然后分别计算左右的结果（递归获取）。<br>

**实现代码**

```java
public List<Integer> diffWaysToCompute(String input) {
    List<Integer> rt = new ArrayList<>();
    if (input.length() == 0) {
        return rt;
    }
    for (int i = 0; i < input.length(); i++) {
        char c = input.charAt(i);
//            将符号的左右字符串划分为不同的两部分
        if (c == '+' || c == '-' || c == '*') {
            String firsPart = input.substring(0, i);
            String secondPart = input.substring(i + 1);
            for (Integer first :
                    diffWaysToCompute(firsPart)) {
                for (Integer second :
                        diffWaysToCompute(secondPart)) {
                    int tmp = 0;
                    switch (c) {
                        case '+':
                            tmp = first + second;
                            break;
                        case '-':
                            tmp = first - second;
                            break;
                        case '*':
                            tmp = first * second;
                            break;
                    }
                    rt.add(tmp);
                }
            }
        }
    }
//        如果没有运算符的话，只存在数字，可以作为结果返回
    if (rt.size() == 0) {
        rt.add(Integer.parseInt(input));
    }
    return rt;
}
```

---
#### [Generate Parentheses](https://leetcode.com/problems/generate-parentheses/description/)
**解题思路**
生成字符串只需要保证先有'('然后再有')',同时左右括号的次数相同即可。
可以使用递归的方式产生结果，具体参见实现代码。<br>
**实现代码**

```java
public List<String> generateParenthesis(int n) {
    List<String> rt = new ArrayList<>();
    if (n < 1) {
        return rt;
    }
    dfs(rt, "", n, n);
    return rt;
}

private void dfs(List<String> rt, String cur, int left, int right) {
//        保证left优先出现
    if (left > right) {
        return;
    }
    if (left == 0 && right == 0) {
        rt.add(cur);
        return;
    }
//        先生成（
    if (left > 0) {
        dfs(rt, cur + '(', left - 1, right);
    }

//        后生成）
    if (right > 0) {
        dfs(rt, cur + ')', left, right);
    }
}
```

---
#### [Number of Islands](https://leetcode.com/problems/number-of-islands/description/)

**解题思路**
针对整个矩阵进行遍历，只需要出现1的情况就ret++,将所有相连的1变成非1即可（递归进行）。<br>
**实现代码**

```java
public int numIslands(char[][] grid) {
    if (grid == null || grid.length == 0 || grid[0] == null || grid[0].length == 0) {
        return 0;
    }
    int ret = 0;
    for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[0].length; j++) {
//                跳过非1的情况
            if (grid[i][j] != '1') {
                continue;
            }
            ret++;
            dfs(grid, i, j);
        }
    }
    return ret;
}

private void dfs(char[][] grid, int x, int y) {
    if (x < 0 || x >= grid.length || y < 0 || y > grid[0].length) {
        return;
    }
//        将1变成非1
    if (grid[x][y] == '1') {
        grid[x][y] = '0';
        dfs(grid, x - 1, y);
        dfs(grid, x + 1, y);
        dfs(grid, x, y - 1);
        dfs(grid, x, y + 1);
    }
}
```

---
#### [Kth Largest Element in an Array](https://leetcode.com/problems/kth-largest-element-in-an-array/description/)

**解题思路**
题目没有明确说明数组中是否允许出现重复，不过从运行结果来看，可以出现重复的数，只是相同的数可能被排在不同的位置（比如，6最大，而且6出现两次，那么第一和第二大的数都是6）。可以使用堆排序，构建k个小顶堆，然后遍历后序的数，将更大的数添加进来。下面实现使用了类似快排的思路，找到左边界的元素划分后对应的下标位置，不断逼近nums.length-k(经过转换得到)然后返回。<br>
**实现代码**

```java
public int findKthLargest(int[] nums, int k) {
    if (nums == null || nums.length == 0) {
        return -1;
    }
    return findK(nums, nums.length - k, 0, nums.length - 1);
}

private int findK(int[] nums, int k, int left, int right) {
//        寻找中间分节点的位置
    int p = partition(nums, left, right);
    while (p != k) {
//            不断进行调整
        if (p > k) {
            p = partition(nums, left, p - 1);
        } else {
            p = partition(nums, p + 1, right);
        }
    }
    return nums[p];
}

//    一次快排操作
private int partition(int[] nums, int left, int right) {
    if (left > right) {
        return left;
    }
    int tmp = nums[left];
    while (left < right) {
        while (left < right && nums[right] >= nums[left]) {
            right--;
        }
        swap(nums, left, right);
        while (left < right && nums[left] <= nums[right]) {
            left++;
        }
        swap(nums, left, right);
    }
    nums[left] = tmp;
    return left;
}

private void swap(int[] nums, int left, int right) {
    int tmp = nums[left];
    nums[left] = nums[right];
    nums[right] = tmp;
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)