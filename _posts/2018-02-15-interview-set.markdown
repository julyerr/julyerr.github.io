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
#### [Subsets](https://leetcode.com/problems/subsets/description/)
**解题思路**<br>
集合的幂次数判断，具体参见实现代码。<br>
**实现代码**
```java
public List<List<Integer>> subsets(int[] nums) {
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
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)