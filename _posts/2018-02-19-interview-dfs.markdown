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

### Combination 系列
#### [Combinations](https://leetcode.com/problems/combinations/description/)
**解题思路**
递归，选择数字k次，每次选择的数字都比前一个大。<br>
**实现代码**
```java
//    存储的次数
static int times;
//    全局数组
static Integer[] nums;
static Integer[] cur;
List<List<Integer>> rt;

public List<List<Integer>> combine(int n, int k) {
    rt = new ArrayList<>();
//        check validation
    if (n < 1 || k < 1) {
        return rt;
    }
//        赋新值
    nums = new Integer[n];
    cur = new Integer[k];
    for (int i = 0; i < n; i++) {
        nums[i] = i + 1;
    }
    times = k;
    dfs(0);
    return rt;
}

private void dfs(int start) {
    if (start == times) {
        rt.add(new ArrayList<>(Arrays.asList(cur)));
        return;
    }

    for (int i = 0; i < nums.length; i++) {
//            比最后一个元素大的值
        if (start > 0 && nums[i] <= cur[start - 1]) {
            continue;
        }

        cur[start] = nums[i];
        dfs(start + 1);
    }
}
```

#### [Subsets](https://leetcode.com/problems/subsets/description/)
**解题思路**<br>
解题思路和上题基本类似，只是需要针对不同的长度递归<br>
**实现代码**
```java
static List<List<Integer>> rt;
static int times;
static Integer[] cur;

public List<List<Integer>> subsets(int[] nums) {
    rt = new ArrayList<>();
    //        check validation
    if (nums == null || nums.length == 0) {
        return rt;
    }
//        sort the array
    Arrays.sort(nums);

    for (int i = 0; i < nums.length; i++) {
//            针对不同的长度进行更新
        times = i;
        cur = new Integer[i];
        dfs(nums, 0);
    }
    return rt;
}

private void dfs(int[] nums, int start) {
    if (start == times) {
        rt.add(new ArrayList<>(Arrays.asList(cur)));
        return;
    }
    for (int i = 0; i < nums.length; i++) {
        if (start > 0 && nums[i] <= cur[start - 1]) {
            continue;
        }
        cur[start] = nums[i];
        dfs(nums, start + 1);
    }
}

```

#### [Subsets II](https://leetcode.com/problems/subsets-ii/description/)
**解题思路**
可以不使用递归的方式解决，针对pow(2,nums.length)的方法数，然后加进对应的nums[i],具体参见实现代码。<br>
这种实现方式也适用于Subset 结题。<br>
**实现代码**
```java
public List<List<Integer>> subsetsWithDup(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return new ArrayList<>();
    }

    Set<List<Integer>> rt = new HashSet<>();

    int length = nums.length;
    Arrays.sort(nums);
    for (int i = 0; i < Math.pow(2, length); i++) {
        int tmp = i;
        List<Integer> list = new ArrayList<>();

        for (int j = 0; j < length; j++) {
            int bit = tmp & 0x01;
            tmp = tmp >> 1;
            if (bit == 1) {
                list.add(nums[j]);
            }
        }
        rt.add(list);
    }
    return new ArrayList<>(rt);
}
```

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