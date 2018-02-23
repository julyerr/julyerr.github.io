---
layout:     post
title:      "面试编程题 string"
subtitle:   "面试编程题 string"
date:       2018-02-20 6:00:00
author:     "julyerr"
header-img: "img/ds/ds/string.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - string
---

#### [Longest Substring Without Repeating Characters](https://leetcode.com/problems/longest-substring-without-repeating-characters/description/)
**解题思路**<br>
通过hash方法维护一个滑动窗口，窗口中保存的是当下最长的无重复字符串，每次比较更新即可。<br>
**实现代码**
```java
public int lengthOfLongestSubstring(String s) {
//        check validation
    if (s == null || s.length() == 0) {
        return 0;
    }
    Map<Character, Integer> map = new HashMap<>();
    int max = 0;
    int start = 0;
    for (int i = 0; i < s.length(); i++) {
        char c = s.charAt(i);
        if (map.get(c) != null) {
            start = Math.max(start, map.get(c) + 1);
        }
        map.put(c, i);
        max = Math.max(max, i + 1 - start);
    }
    return max;
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
