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
**实现代码**<br>
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
#### [Count and Say](https://leetcode.com/problems/count-and-say/description/)
**解题思路**
根据字符串各个元素的值，统计次数然后相加，合成下一个字符串。<br>
**实现代码**

```java
public String countAndSay(int n) {
    if (n < 1) {
        return "";
    }
    String init = "1";
//        迭代上次计算的结果
    for (int i = 0; i < n-1; i++) {
        init = dfs(init);
    }
    return init;
}

private String dfs(String string) {
    int length = string.length();
    int count;
    int index = 0;
    StringBuilder stringBuilder = new StringBuilder();
    while (index < length) {
//            统计每个不相等字符的个数
        count = 1;
        char tmp = string.charAt(index);
        while (index + 1 < length && string.charAt(index) == string.charAt(index + 1)) {
            index++;
            count++;
        }
        index++;
        stringBuilder.append(count).append(tmp);
    }
    return stringBuilder.toString();
}
```

---
#### [Implement strStr()](https://leetcode.com/problems/implement-strstr/description/)
**解题思路**
查找子串出现的位置，显然不能直接调用库函数，自己实现的话，可以两次循环条件判断（水平高的话，实现kmp等模式匹配算法）。<br>
**实现代码**

```java
public int strStr(String haystack, String needle) {
//        有效性判断
    if (haystack == null || needle == null || haystack.length() < needle.length()) {
        return -1;
    }
    int lenA = haystack.length();
    int lenB = needle.length();
    if (lenA == 0) {
        return 0;
    }
    for (int i = 0; i < lenA; i++) {
        int count = 0;
//            针对每个字符循环判断
        for (int j = 0; j < lenB; j++) {
//                如果超过haystack的范围，return -1
            if (i + count >= lenA) {
                return -1;
            }
            if (haystack.charAt(i + count) != needle.charAt(j)) {
                break;
            }
            count++;
        }
        if (count == lenB) {
            return i;
        }
    }
    return -1;
}
```

---
#### [Length of Last Word](https://leetcode.com/problems/length-of-last-word/description/)

**解题思路**
可以从字符串末端向前进行扫描，返回长度，注意需要过滤掉空白字符串。<br>
**实现代码**

```java
public int lengthOfLastWord(String s) {
    if (s == null || s.length() == 0) {
        return 0;
    }
    int length = s.length();
    int ret = 0;
    for (int i = length - 1; i >= 0; i--) {
//            如果是空格，跳过或者是结束循环
        if (s.charAt(i) == ' ') {
            if (ret == 0) {
                continue;
            } else {
                break;
            }
        }
        ret++;
    }
    return ret;
}
```

---
#### [Letter Combinations of a Phone Number](https://leetcode.com/problems/letter-combinations-of-a-phone-number/description/)

**解题思路**
类似求解排列组合情况，通常使用递归的形式解题，具体参见实现代码。<br>
**实现代码**

```java
public class Solution{
    static final char[][] CHAR_MAP = {
        {' '},// 0
        {},// 1
        {'a', 'b', 'c'},// 2
        {'d', 'e', 'f'},// 3
        {'g', 'h', 'i'},// 4
        {'j', 'k', 'l'},// 5
        {'m', 'n', 'o'},// 6
        {'p', 'q', 'r', 's'},// 7
        {'t', 'u', 'v'},// 8
        {'w', 'x', 'y', 'z'} // 9
    };

    public List<String> letterCombinations(String digits) {
        List<String> rt = new ArrayList<>();
        if (digits == null || digits.length() == 0) {
            return rt;
        }
        dfs(rt, "", 0, digits);
        return rt;
    }

    private void dfs(List<String> rt, String cur, int level, String digits) {
        int length = digits.length();
    //        递归到结束位置，添加字符串
        if (level >= length) {
            rt.add(cur);
            return;
        }
        int offset = digits.charAt(level) - '0';
    //        当前各种情况判断
        for (int i = 0; i < CHAR_MAP[offset].length; i++) {
            dfs(rt, cur + CHAR_MAP[offset][i], level + 1, digits);
        }
    }
}
```


---
#### [Longest Common Prefix](https://leetcode.com/problems/longest-common-prefix/description/)
**解题思路**
在两个字符串最大前缀的基础上添加了循环判断，实现思路一致。<br>
**实现代码**

```java
public String longestCommonPrefix(String[] strs) {
    if (strs == null || strs.length == 0) {
        return "";
    }
    int length = strs.length;
//        如果只存在一个字符串直接返回
    if (length == 1) {
        return strs[0];
    }
    int ret = 0;
    for (int i = 0; i < strs[0].length(); i++) {
        char c = strs[0].charAt(i);
        boolean valid = true;
//            针对字符串组的当下字符进行判断
        for (int j = 1; j < length; j++) {
            if (i >= strs[j].length() || strs[j].charAt(i) != c) {
                valid = false;
                break;
            }
        }
        if (!valid) {
            break;
        }
        ret++;
    }
    return strs[0].substring(0, ret);
}
```

---
#### [Longest Palindromic Substring](https://leetcode.com/problems/longest-palindromic-substring/description/)
**解题思路**
针对字符串中每个字符，计算向左向右两方面扩展的回文长度，进行比较更新。此题可以优化的部分是如果当前扩展的长度不可能比先前长就可以直接返回。<br>
**实现代码**

```java
public String longestPalindrome(String s) {
    if(s==null||s.length() < 2){
        return s;
    }
    int start = 0,len = 0;
    int length = s.length();
    for (int i = 0; i < length; i++) {
//            不可能出现更长的回文
        if(i+len/2 >= length){
            break;
        }
//            当前字符的回文长度计算
        int len1 = lenPalindromeOfThisChar(s,i,i);
        int len2 = lenPalindromeOfThisChar(s,i,i+1);
        int tmp = Math.max(len1,len2);
        if(len < tmp){
            len = tmp;
            start = i - (len-1) / 2;
        }
    }
    return s.substring(start,start+len);
}

private int lenPalindromeOfThisChar(String s,int left,int right){
    while(left >= 0 && right < s.length() && s.charAt(left) == s.charAt(right)){
        left--;
        right++;
    }
    return right-left-1;
}
```

---
#### [Reverse Words in a String](https://leetcode.com/problems/reverse-words-in-a-string/description/)
**解题思路**
此题可以使用java提供的api相对简单一点，不过需要注意去除字符串的左右空格和中间多余空格。<br>
**实现代码**

```java
public String reverseWords(String s) {
    if (s == null || s.length() == 0) {
        return s;
    }
//        左右空格去除，然后中建多个空格使用正则进行分隔
    List<String> strings = Arrays.asList(s.trim().split(" +"));
    Collections.reverse(strings);
    return String.join(" ", strings);
}
```

---
#### [Valid Palindrome](https://leetcode.com/problems/valid-palindrome/description/)
**解题思路**
设置左右两个游标，然后不断比较，中间需要过滤掉不是数字和字母的字符，而且忽略大小。<br>
**实现代码**

```java
public boolean isPalindrome(String s) {
    if (s == null || s.length() < 2) {
        return true;
    }
    int left = 0;
    int right = s.length() - 1;
    while (left < right) {
//            找到数字或者字母位置
        while (left < right && !(Character.isAlphabetic(s.charAt(left)) || Character.isDigit(s.charAt(left)))) {
            left++;
        }

        while (left < right && !(Character.isAlphabetic(s.charAt(right)) || Character.isDigit(s.charAt(right)))) {
            right--;
        }

//            大小转换之后比较
        if (left < right && Character.toLowerCase(s.charAt(left)) != Character.toLowerCase(s.charAt(right))) {
            return false;
        }
        left++;
        right--;
    }
    return true;
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
