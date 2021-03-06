---
layout:     post
title:      "面试编程题 hash篇"
subtitle:   "面试编程题 hash篇"
date:       2018-02-13 6:00:00
author:     "julyerr"
header-img: "img/ds/hash/hash.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - hash
---

#### [Two-Sum](https://leetcode.com/problems/two-sum/description/)
**解题思路**<br>
     和为定值，只有一个解;使用hash，map.put(sum-num[i],i)，然后判断是否存在num[i]的key;存在即可返回，注意不能是本身.<br>
**实现代码**<br>
```java
public int[] twoSum(int[] nums, int target) {
//        check validation
    if (nums == null || nums.length < 1) {
        return nums;
    }
    Map<Integer, Integer> map = new HashMap<>();
    for (int i = 0; i < nums.length; i++) {
        map.put(target - nums[i], i);
    }
    for (int i = 0; i < nums.length; i++) {
        Integer v = map.get(nums[i]);
//            can't be itself
        if (v != null && v != i) {
            return new int[]{i , v};
        }
    }
    return null;
}
```
[完整代码](https://github.com/julyerr/algo/tree/master/src/com/julyerr/leetcode/hash/TwoSum.java)

---
### Duplicate系列
#### [Contains Duplicate](https://leetcode.com/problems/contains-duplicate/description/)
**解题思路**<br>
使用hash判断是否已经存在相同元素即可<br>
**实现代码**<br>
```java
public boolean containsDuplicate(int[] nums) {
//         check validation
    if(nums == null || nums.length < 2){
        return false;
    }
    Map<Integer,Integer> map = new HashMap<>();
    for(int i = 0;i < nums.length;i++){
        if(map.get(nums[i])!=null){
            return true;
        }
        map.put(nums[i],0);
    }
    return false;
}
```

---
#### [Contains Duplicate II](https://leetcode.com/problems/contains-duplicate-ii/description/)
**解题思路**<br>
使用hash记录出现情况，对于出现多次的元素判断下标之差是否小于等于k<br>

**实现代码**<br>
```java
public boolean containsNearbyDuplicate(int[] nums, int k) {
//  check validation
    if (nums == null || nums.length < 2) {
        return false;
    }
    Map<Integer, Integer> map = new HashMap<>();
    for (int i = 0; i < nums.length; i++) {
        if (map.get(nums[i]) != null && (i - map.get(nums[i])) <= k) {
            return true;
        }
        map.put(nums[i], i);
    }
    return false;
}
```

---

#### [Contains duplicate III使用treeSet题解](http://julyerr.club/2018/02/13/interview-set/#contains-duplicate-iii)

---
#### [Valid Anagram](https://leetcode.com/problems/valid-anagram/description/)
**解题思路**
先一遍将char的次数统计出来，后一次遍历的时候次数减少1，最后一遍的时候判断是否全为0.<br>
**实现代码**
```java
public boolean isAnagram(String s, String t) {
    if (s == null || t == null || s.length() != t.length()) {
        return false;
    }

    Map<Character, Integer> map = new HashMap<>();
//        第一次遍历的时候统计次数
    for (int i = 0; i < s.length(); i++) {
        char c = s.charAt(i);
        int times = 0;
        if (map.get(c) != null) {
            times = map.get(c);
        }
        map.put(c, times);
    }

//        第二次遍历的时候次数--，并判断
    for (int i = 0; i < t.length(); i++) {
        char c = t.charAt(i);
        if (map.get(c) == null) {
            return false;
        }
        int times = map.get(c);
        if (times == 0) {
            return false;
        }
        map.put(c, --times);
    }

//        最后一遍判断0
    for (Integer integer :
            map.values()) {
        if (integer != 0) {
            return false;
        }
    }
    return true;
}
```



---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)