---
layout:     post
title:      "面试编程题 search & sort 篇"
subtitle:   "面试编程题 search & sort 篇"
date:       2018-02-23 6:00:00
author:     "julyerr"
header-img: "img/ds/searchSort/searchSort.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - search
    - sort
---


#### [Find Peak Element](https://leetcode.com/problems/find-peak-element/description/)
**解题思路**<br>
使用二分法，只需要找到任意nums[i],nums[i]比左右的元素都大的情况即可。<br>
**实现代码**
```java
public int findPeakElement(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int low = 0;
    int high = nums.length - 1;
    while (low < high) {
        int mid = (low + high) >> 1;
        if (nums[mid] > nums[mid + 1]) {
            high = mid;
        } else {
            low = mid + 1;
        }
    }
    return low;
}
```
---

#### [Find Minimum in Rotated Sorted Array](https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/description/)
**解题思路**<br>
针对O(n)时间复杂度进行改进，考虑使用二分查找法。low、mid、high三个游标，考虑三种可能情况:

1. array[mid] > array[high]:此时的最小值一定在mid的右边；
2. array[mid] == array[high]:无法直接确定，只能一个一个尝试 high = high - 1;
3. array[mid] < array[high]:最小值一定在mid的左边或者就是mid

**实现代码**
```java
public int findMin(int[] nums) {
//        should not happend
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int low = 0;
    int high = nums.length - 1;
    while (low <= high) {
        int mid = (low + high) >> 1;
        if (nums[mid] < nums[high]) {
//                如果只有两个元素，high = mid - 1, mid = 0 ,发生越界访问
            high = mid;
        } else if (nums[mid] > nums[high]) {
            low = mid + 1;
        } else {
            high = high - 1;
        }
    }
    return nums[low];
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)