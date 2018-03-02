---
layout:     post
title:      "面试编程题 set"
subtitle:   "面试编程题 set"
date:       2018-02-13 6:00:00
author:     "julyerr"
header-img: "img/ds/set/set.jpg"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - set
---

#### [Contains-Duplicate-III](https://leetcode.com/problems/contains-duplicate-iii/description/)
**解题思路**<br>
nums[i]和nums[j]之间的差距最大为t,i和j最大差距为k；通过维持最小和最大差距为2t的集合，必要时将下标差距大于k的元素移除，具体参见实现代码<br>
**实现代码**<br>
```java
public boolean containsNearbyAlmostDuplicate(int[] nums, int k, int t) {
//        check validation
    if (nums == null || nums.length < 2 || k < 1 || t < 0) {
        return false;
    }
    SortedSet<Long> set = new TreeSet<>();
    for (int i = 0; i < nums.length; i++) {
//            截取一定范围内的subSet,左闭右开
        SortedSet<Long> subSet = set.subSet((long) nums[i] - t, (long) nums[i] + t + 1);
        if (!subSet.isEmpty()) {
            return true;
        }
//            下一次迭代的时候需要移除的元素
        if (i >= k) {
            set.remove((long) nums[i - k]);
        }
        set.add((long) nums[i]);
    }
    return false;
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)