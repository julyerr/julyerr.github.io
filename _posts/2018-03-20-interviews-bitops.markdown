---
layout:     post
title:      "面试编程题 位操作"
subtitle:   "面试编程题 位操作"
date:       2018-03-20 6:00:00
author:     "julyerr"
header-img: "img/ds/bit/bitops.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - bit
---

按位操作的题目不是很常见，如果合理使用位操作，能够提高执行效率同时节省所需内存空间。

---
#### [Power of Two](https://leetcode.com/problems/power-of-two/description/)
**解题思路**
如果n为2次数幂，当与n-1进行与操作的时候返回的为0.<br>
**实现代码**

```java
public boolean isPowerOfTwo(int n) {
//        所有的非正数均不是2的次数幂
    if (n <= 0) {
        return false;
    }
    return (n & (n - 1)) == 0;
}
```

---
#### [Number of 1 Bits](https://leetcode.com/problems/number-of-1-bits/description/)

**解题思路**
对int的每一位进行与操作，统计非零的次数<br>
**实现代码**

```java
public int hammingWeight(int n) {
    int bit = 1;
    int count = 0;
//        0-31的位置针对每一位进行与操作
    for (int i = 0; i < 32; i++) {
        if ((n & bit) != 0) {
            count++;
        }
        bit <<= 1;
    }
    return count;
}
```

---
#### [Single Number](https://leetcode.com/problems/single-number/description/)
**解题思路**
巧妙利用了数字异或运算的性质，N^M^M=N,然后只需要针对数组中每一位进行异或操作即可。<br>
**实现代码**

```java
public int singleNumber(int[] nums) {
    if(nums==null||nums.length ==0){
        return -1;
    }
    int n = 0;
//        每一位^操作
    for (int i :
            nums) {
        n ^= i;
    }
    return n;
}
```

---
#### [Single Number II](https://leetcode.com/problems/single-number-ii/description/)
**解题思路**
要求线性时间复杂度和O(1)的空间复杂度，比较好的方法就是位操作。每个数均出现了三次，除了一个之外。那么针对每一位统计1出现的次数count，count%3表示的就是所求的数在该位的值。（题目没有明确说明该数是否只出现一次，不过从结果来看，应该是只出现了一次）。<br>
**实现代码**

```java
public int singleNumber(int[] nums) {
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int ret = 0;
    int bit = 1;
    for (int i = 0; i < 32; i++) {
        int count = 0;

//            统计每一位1的num的个数
        for (int j = 0; j < nums.length; j++) {
            if ((nums[j] & bit) != 0) {
                count++;
            }
        }
        bit <<= 1;
//            重新构造单个数
        ret |= (count % 3) << i;
    }
    return ret;
}
```

---
#### [Single Number III](https://leetcode.com/problems/single-number-iii/description/)
**解题思路**
类似Single Number的解题思路，巧妙之处在于将整个数组划分为两部分，一部分包含单个数A,一部分包含单个数B。
具体是，通过数之间的异或操作之后，重复的数被消除，然后保留A和B异或的结果C；再次遍历数组，将数对应到C中某位为1的划分一类，该位不为1的划分为另一类，具体参见实现代码。<br>
**实现代码**

```java
public int[] singleNumber(int[] nums) {
    if (nums == null || nums.length == 0) {
        return nums;
    }
    int[] ret = new int[2];
    int n = 0;
//        先计算出各个数的^的结果
    for (int i = 0; i < nums.length; i++) {
        n ^= nums[i];
    }
//        确定最后一位1的数，用以划分数组
    n = n & (~(n - 1));
    for (int i = 0; i < nums.length; i++) {
        if ((nums[i] & n) == 0) {
            ret[0] ^= nums[i];
        } else {
            ret[1] ^= nums[i];
        }
    }
    return ret;
}
```

---
#### [Missing Number](https://leetcode.com/problems/missing-number/description/)
**解题思路**<br>
由于n+1中取出n个数，显然缺少的数使得相邻两个数之间的差值为2,直接返回该数即可。
参考别人实现思路，非常巧妙，利用m^n^n=m的特性，迭代一次就可以求出结果，具体参见实现代码。
**实现代码**<br>
```java
public int missingNumber(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int ret = nums.length;
    for (int i = 0; i < nums.length; i++) {
        ret ^= nums[i] ^ i;
    }
    return ret;
}
```

---
#### [Bitwise AND of Numbers Range](https://leetcode.com/problems/bitwise-and-of-numbers-range/description/)

**解题思路**
比较巧妙的是，直接根据边界范围m,n两个元素，进行移位操作，同时统计移动的次数。移动到m和n相等的时候，然后返回直接调整m返回即可。<br>
**实现代码**

```java
public int rangeBitwiseAnd(int m, int n) {
    int count = 0;
    while (m != n) {
        m >>= 1;
        n >>= 1;
//            统计移动的次数
        count++;
    }
    return m << count;
}
```

---
#### [Repeated DNA Sequences](https://leetcode.com/problems/repeated-dna-sequences/description/)

**解题思路**
如果直接使用hash的话，空间复杂度为O(n)。还有一种比较巧妙的方式是，将ACGT分别编码为0123然后只需要20bit就能表示一个长为10的字符串，这时候使用hash判断，提高时间和空间利用率。<br>
**实现代码**

```java
public List<String> findRepeatedDnaSequences(String s) {
    List<String> rt = new ArrayList<>();
    if (s == null || s.length() < 10) {
        return rt;
    }
//        字符编码转换
    Map<Character, Integer> map = new HashMap<>();
    map.put('A', 0);
    map.put('G', 1);
    map.put('C', 2);
    map.put('T', 3);

    int hash = 0;
    Set<Integer> set = new HashSet<>();
    for (int i = 0; i < s.length(); i++) {
//            10字符长子串转换成hash编码
        hash = (hash << 2) | map.get(s.charAt(i));
        hash = ((1 << 20) - 1) & hash;
        if (i >= 9) {
            String string = s.substring(i - 9, i + 1);
//                不能出现重复添加的情况
            if (set.contains(hash)&&!rt.contains(string)) {
                rt.add(string);
            } else {
                set.add(hash);
            }
        }
    }
    return rt;
}
```

---
#### [Reverse Bits](https://leetcode.com/problems/reverse-bits/description/)

**解题思路**
比较直观的想法是，从左右向中间逼近，如果对称的按位得到的值不相同说明需要交换。更为简洁的方式是，将n上第i位元素值移动到31-i上。<br>
**实现代码**

```java
public int reverseBits(int n) {
//        针对每一位进行判断
//        for (int i = 0; i < 16; i++) {
//            boolean firstBit = ((1 << i)&n)==0;
//            boolean secondBit = ((1 << (31-i))&n)==0;
//            if(firstBit!=secondBit){
//                if(firstBit){
//                    n |= (1<<i);
//                    n ^= (1<<(31-i));
//                }else{
//                    n ^= (1<<i);
//                    n |= (1<<(31-i));
//                }
//            }
//        }
//        return n;

//        将n上第i的值移动到31-i上
    int ret = 0;
    for (int i = 0; i < 32; i++) {
        ret |= ((n >> i) & 1) << (31 - i);
    }
    return ret;
}
```

---
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
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)