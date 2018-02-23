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
#### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
