---
layout:     post
title:      "面试编程题 array"
subtitle:   "面试编程题 array"
date:       2018-02-13 6:00:00
author:     "julyerr"
header-img: "img/ds/array/array.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - array
---

单纯属于array编程的试题并不是很常见，反而结合动态规划、树、排序等试题比较多。本文尽量剥离涉及到其他知识点的试题，关注数组操作方面。

### Sum系列

[Two Sum 使用hash解题](http://julyerr.club/2018/02/13/interview-hash/#two-sum)

---
#### [3-Sum](https://leetcode.com/problems/3sum/description/)
**解题思路**<br>

- 先将数组进行排序，设置start,mid,end三个游标
- start=i,mid=start+1,end = nums.length -1
- mid和end不断逼近，将三者和为0的elem添加进result
- 提升效率，注意去重,不去重直接使用set集合会超时。

**实现代码**<br>
```java
public List<List<Integer>> threeSum(int[] nums) {
    List<List<Integer>> rt = new ArrayList<>();
    if (nums == null || nums.length == 0) {
        return rt;
    }
//        sort the num
    Arrays.sort(nums);
    int length = nums.length;
    for (int start = 0; start < length - 2; start++) {
//            去重
        while (start != 0 && nums[start] == nums[start - 1]) {
            start++;
        }
        int mid = start + 1;
        int end = length - 1;
//            后面元素同样进行迭代循环
        while (mid < end) {
            int sum = nums[start] + nums[mid] + nums[end];
            if (sum == 0) {
                List<Integer> tmp = new ArrayList<>();
                tmp.add(nums[start]);
                tmp.add(nums[mid++]);
                tmp.add(nums[end--]);
                rt.add(tmp);
//                    去重
                while (mid < end && nums[mid] == nums[mid - 1]) {
                    mid++;
                }
                while (end > mid && nums[end] == nums[end + 1]) {
                    end--;
                }
            } else if (sum < 0) {
                mid++;
            } else {
                end--;
            }
        }
    }
    return rt;
}
```
[完整代码](https://github.com/julyerr/algo/tree/master/src/com/julyerr/leetcode/array/ThreeSum.java)

---
#### [3Sum Closest](https://leetcode.com/problems/3sum-closest/description/)
**解题思路**<br>
    和`3 sum`解题思路一致;这道题，判断target delta的值是否变小，然后进行更新即可。注意如果sum ==  target可以直接返回，并且不需要进行去重处理。<br>
    
[完整代码](https://github.com/julyerr/algo/tree/master/src/com/julyerr/leetcode/array/ThreeClosest.java)

---
#### [4sum](https://leetcode.com/problems/4sum/description/)
**解题思路**<br>
    和`3 sum`解题思路一致;只是需要多增加一层循环<br>
    
[完整代码](https://github.com/julyerr/algo/tree/master/src/com/julyerr/leetcode/array/FourSum.java)

---
### Sell stocks系列
#### [Best Time to Buy and Sell Stock](https://leetcode.com/problems/best-time-to-buy-and-sell-stock/description/)    
**解题思路**<br>
stock获利就是买入和卖出的一次差值，在最低的时候买入，在最高的时候卖出.<br>

**实现代码**<br>
```java
public int maxProfit(int[] prices) {
//  check validation
    if (prices == null || prices.length < 2) {
        return 0;
    }

    int lowest = Integer.MAX_VALUE;
    int maxProfit = 0;
    for (Integer integer :
            prices) {
        lowest = Math.min(lowest, integer);
//            是否更新获取利益
        maxProfit = Math.max(maxProfit, integer - lowest);
    }
    return maxProfit;
}
```
---
#### [Best Time to Buy and Sell Stock II](https://leetcode.com/problems/best-time-to-buy-and-sell-stock-ii/description/)
**解题思路**<br>
只需要每次交易有利润可赚就行<br>
**实现代码**
```java
public int maxProfit(int[] prices) {
//  check validation
    if (prices == null || prices.length < 2) {
        return 0;
    }
    int maxProfit = 0;
    for (int i = 1; i < prices.length; i++) {
//            每次均能获利
        if (prices[i] > prices[i - 1]) {
            maxProfit += prices[i] - prices[i - 1];
        }
    }
    return maxProfit;
}
```

---
#### [Game of Life](https://leetcode.com/problems/game-of-life/description/)
解题思路
题目关键是实现原地的同时更新，因此，只能在原来的空间记录变化值，同时该变化值不会对其他元素的记录产生影响。
考虑+10 和 %10 的关系，前者+10把原来的值发生了变化，但是对后者的%10没有产生影响，利用该特性，具体参看实现代码。
实现代码
```java
static int n, m;

public void gameOfLife(int[][] board) {
//        check validation
    if (board == null || board.length == 0 || board[0] == null || board[0].length == 0) {
        return;
    }
    n = board.length - 1;
    m = board[0].length - 1;

    for (int i = 0; i <= n; i++) {
        for (int j = 0; j <= m; j++) {
            int nums = calc(board, i, j);
            //dead -> live
            if (board[i][j] == 0) {
                if (nums == 3) {
                    board[i][j] += 10;
                }
            } else {
            //live -> live
                if (nums == 2 || nums == 3) {
                    board[i][j] += 10;
                }
            }
        }
    }
//        更新+10
    for (int i = 0; i <= n; i++) {
        for (int j = 0; j <= m; j++) {
            board[i][j] /= 10;
        }
    }
}

//    返回(x,y)四周的存活的cell个数
private static int calc(int[][] board, int x, int y) {
    int ret = 0;
    for (int i = x - 1; i <= x + 1; i++) {
        for (int j = y - 1; j <= y + 1; j++) {
//                check boundary & not be itself
            if (i < 0 || j < 0 || i > n || j > m || (i == x && j == y)) {
                continue;
            }
            if (board[i][j] % 10 == 1) {
                ret++;
            }
        }
    }
    return ret;
}
```

---
#### [Jump Game](https://leetcode.com/problems/jump-game/description/)
解题思路
在跳及范围之内，尽量选择最大的step，如果maxStep大于数组的长度，说明一定存在一种方式跳出。
不断更新step的值，maxStep = Math.max(maxStep,nums[i]+i) 
实现代码
```java
public boolean canJump(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return false;
    }
    int maxStep = 0;
    int length = nums.length;
    for (int i = 0; i < length; i++) {
//            选择最大的step
        maxStep = Math.max(maxStep, nums[i] + i);
        if (maxStep >= nums.length - 1) {
            return true;
        }
//            不能前进
        if (nums[i] ==0 && maxStep == i) {
            return false;
        }
    }
    return false;
}
```

---
#### [Majority Element](https://leetcode.com/problems/majority-element/description/)
解题思路
此题通过肯定是没有问题的，关键是利用O(n)空间复杂度和O(1)时间复杂度，也是一个比较典型面试试题。
实现代码
```java
public int majorityElement(int[] nums) {
//        check validation,should not happen here
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int count = 1;
    int m = nums[0];
    for (int i = 1; i < nums.length; i++) {
        if (m == nums[i]) {
            count++;
        } else if (count > 1) {
            count--;
        } else {
            m = nums[i];
        }
    }
    return m;
}
```

---
#### [Major Element II](https://leetcode.com/problems/majority-element-ii/description/)
解题思路
解题思路和上题有点类似，超过[n/3]次数的元素最多2个
实现代码
```java
public List<Integer> majorityElement(int[] nums) {
    List<Integer> rt = new ArrayList<>();
//        check validation
    if (nums == null || nums.length == 0) {
        return rt;
    }
    int length = nums.length;

    int count1 = 1;
    int count2 = 0;
    int m1 = nums[0];
    int m2 = 0;
    for (int i = 1; i < length; i++) {
        if (nums[i] == m1) {
            count1++;
        } else if (nums[i] == m2) {
            count2++;
//                更新元素值
        } else if (count1 == 0) {
            count1 = 1;
            m1 = nums[i];
        } else if (count2 == 0) {
            count2 = 1;
            m2 = nums[i];
        } else {
            count1--;
            count2--;
        }
    }

    count1 = count2 = 0;
//        统计出现次数
    for (int i = 0; i < length; i++) {
        if (nums[i] == m1) {
            count1++;
        } else if (nums[i] == m2) {
            count2++;
        }
    }

    if (count1 > length / 3) {
        rt.add(m1);
    }
    if (count2 > length / 3) {
        rt.add(m2);
    }
    return rt;
}
```

---


---
#### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
