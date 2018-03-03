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
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)