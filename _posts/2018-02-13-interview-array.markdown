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
**实现代码**<br>
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
**解题思路**<br>
题目关键是实现原地的同时更新，因此，只能在原来的空间记录变化值，同时该变化值不会对其他元素的记录产生影响。
考虑+10 和 %10 的关系，前者+10把原来的值发生了变化，但是对后者的%10没有产生影响，利用该特性，具体参看实现代码。
**实现代码**<br>
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
**解题思路**<br>
在跳及范围之内，尽量选择最大的step，如果maxStep大于数组的长度，说明一定存在一种方式跳出。
不断更新step的值，maxStep = Math.max(maxStep,nums[i]+i) 
**实现代码**<br>
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
**解题思路**<br>
此题通过肯定是没有问题的，关键是利用O(n)空间复杂度和O(1)时间复杂度，也是一个比较典型面试试题。
**实现代码**<br>
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
**解题思路**<br>
解题思路和上题有点类似，超过[n/3]次数的元素最多2个
**实现代码**<br>
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
#### [Move Zeroes](https://leetcode.com/problems/move-zeroes/description/)
**解题思路**<br>
原地进行操作，需要将非0的元素向前进行移动，后面元素全部置为0
**实现代码**<br>
```java
public void moveZeroes(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return;
    }
    int index = 0;
    for (int i = 0; i < nums.length; i++) {
        if (nums[i] != 0) {
            nums[index++] = nums[i];
        }
    }
    for (int i = index; i < nums.length; i++) {
        nums[i] = 0;
    }
}
```

---
#### [Next Permutation](https://leetcode.com/problems/next-permutation/description/)
**解题思路**<br>
题目意思就是数字字典序的全排，如果是最后一种排列则返回第一种排列方式。
计算排列方式可以从后往前递推，实现代码[参考](http://blog.csdn.net/yano_nankai/article/details/49754925)
**实现代码**<br>
```java
public void nextPermutation(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return;
    }
    int length = nums.length;
    int p = 0;
//        从右到左，找到第一个nums[i] < nums[i+1]的数
    for (int i = length - 2; i >= 0; i--) {
        if (nums[i] < nums[i + 1]) {
            p = i;
            break;
        }
    }

    int q = 0;
//        从右到左，找到第一个nums[i] > nums[p]
    for (int i = length - 1; i >= 0; i--) {
        if (nums[i] > nums[p]) {
            q = i;
            break;
        }
    }

//        如果是最后一种排列情况
    if (p == 0 && q == 0) {
        reverse(nums, 0, length - 1);
        return;
    }

//        swap p and q
    int tmp = nums[p];
    nums[p] = nums[q];
    nums[q] = tmp;

//        防止数组越界访问
    if (p < length - 1) {
        reverse(nums, p + 1, length - 1);
    }
}

public static void reverse(int[] nums, int start, int end) {
    while (start < end) {
        int tmp = nums[start];
        nums[start] = nums[end];
        nums[end] = tmp;
        start++;
        end--;
    }
}
```

---
#### [Pascal's Triangle](https://leetcode.com/problems/pascals-triangle/description/)
**解题思路**<br>
通过pre数组迭代计算出下一个数组
**实现代码**<br>
```java
public List<List<Integer>> generate(int numRows) {
    List<List<Integer>> rt = new ArrayList<>();
    //        check validation
    if (numRows < 1) {
        return rt;
    }

//        pre
    Integer[] pre = null;
    for (int i = 1; i <= numRows; i++) {
        Integer[] cur = new Integer[i];
//            计算cur数组的值
        cur[0] = 1;
        cur[i - 1] = 1;
        for (int j = 1; j < i - 1; j++) {
            cur[j] = pre[j - 1] + pre[j];
        }
        rt.add(new ArrayList<>(Arrays.asList(cur)));
//            更新pre
        pre = cur;
    }
    return rt;
}
```

---
#### [Pascal's Triangle II](https://leetcode.com/problems/pascals-triangle-ii/description/)
**解题思路**<br>
要求O(K)的空间复杂度，需要在原地迭代进行更新
**实现代码**<br>
```java
public List<Integer> getRow(int rowIndex) {
//        check validation
    Integer[] rt = new Integer[rowIndex + 1];
    if (rowIndex < 0) {
        return new ArrayList<Integer>(Arrays.asList(rt));
    }

//        fill values
    Arrays.fill(rt, 1);
    for (int i = 0; i < rowIndex - 1; i++) {
        for (int j = i + 1; j >= 1; j--) {
            rt[j] = rt[j - 1] + rt[j];
        }
    }
    return new ArrayList<>(Arrays.asList(rt));
}
```

---
#### [Product of Array Except Self](https://leetcode.com/problems/product-of-array-except-self/description/)
**解题思路**<br>
在O(n)时间复杂度和不能使用除法的情况下，通过设置right[]数组保存右边元素的乘积迭代结果，
然后从左到右开始扫描计算即可，具体参见实现代码。
**实现代码**<br>
```java
public int[] productExceptSelf(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return nums;
    }
    int length = nums.length;
    int[] right = new int[length];
//        保存从右到左的乘积结果
    right[length - 1] = 1;
    for (int i = length - 2; i >= 0; i--) {
        right[i] = right[i + 1] * nums[i + 1];
    }

//        从左到右扫描
    int left = nums[0];
    for (int i = 1; i < length; i++) {
        right[i] *= left;
//            保存从左到右的乘积迭代结果
        left *= nums[i];
    }
    return right;
}
```

### Remove Duplicate
#### [Remove Element](https://leetcode.com/problems/remove-element/description/)
**解题思路**<br>
不等于给定元素的值直接添加进来
**实现代码**<br>
```java
public int removeElement(int[] nums, int val) {
//        check validation
    if (nums == null || nums.length < 1) {
        return 0;
    }
    int index = 0;
    for (int i = 0; i < nums.length; i++) {
        if (nums[i] != val) {
            nums[index++] = nums[i];
        }
    }
    return index + 1;
}
```

---
#### [Rotate Array](https://leetcode.com/problems/rotate-array/description/)
**解题思路**<br>
在原地实现数组反转，这道题是比较经典的技巧题。通过对不同部分的分别反转，然后整个数组反转即可。
**实现代码**<br>
```java
public void rotate(int[] nums, int k) {
//    check validation
    if (nums == null || nums.length < 2 || k < 1) {
        return;
    }
    int length = nums.length;
//        提高反转效率
    k = k % length;

//   反转前一部分
    rotate(nums, 0, length - 1 - k);
//   反转后一部分    
    rotate(nums, length - k, length - 1);
//   反转整个数组
    rotate(nums, 0, length - 1);
}

private static void rotate(int[] nums, int start, int end) {
    while (start < end) {
        int t = nums[start];
        nums[start] = nums[end];
        nums[end] = t;
        start++;
        end--;
    }
}
```

---
#### [Remove Duplicates from Sorted Array](https://leetcode.com/problems/remove-duplicates-from-sorted-array/description/)
**解题思路**<br>
设置index，从左到右将相邻不相等的元素添加进来
**实现代码**<br>
```java
public int removeDuplicates(int[] nums) {
//        check validation
    if (nums == null || nums.length < 2) {
        return nums.length;
    }
    int index = 0;
    for (int i = 1; i < nums.length; i++) {
        if (nums[index] != nums[i]) {
            nums[++index] = nums[i];
        }
    }
    return index + 1;
}
```

---
#### [Remove Duplicates from Sorted Array II](https://leetcode.com/problems/remove-duplicates-from-sorted-array-ii/description/)
**解题思路**<br>
解题思路和上题基本类似，只不过需要重复间隔的两个元素是否相等
**实现代码**<br>
```java
public int removeDuplicates(int[] nums) {
//        check validation
    if (nums == null || nums.length < 3) {
        return nums.length;
    }
    int index = 0;
    for (int i = 2; i < nums.length; i++) {
//            是否超过2个元素相等
        if (!(nums[i] == nums[index] && nums[i] == nums[index-1])) {
            nums[++index] = nums[i];
        }
    }
    return index + 1;
}
```

---
#### [Roate Image](https://leetcode.com/problems/rotate-image/description/)
**解题思路**<br>
如果按照传统的循环迭代进行元素交换的话，效率比较低。
此题也是比较经典的技巧性题，通过先对角线元素交换后中线交换得到结果。
![](/img/ds/array/rotateImage.png)
**实现代码**<br>
```java
 public void rotate(int[][] matrix) {
//        check validation
    if (matrix == null || matrix.length < 2 || matrix[0] == null || matrix[0].length < 2) {
        return;
    }

    int mx = matrix.length;
    int my = matrix[0].length;
//        对角线交换
    int mY = my - 1;
    for (int i = 0; i < mx - 1; i++) {
        for (int j = 0; j < mY; j++) {
            int newX = my - 1 - j;
            int newY = mx - 1 - i;

            int t = matrix[i][j];
            matrix[i][j] = matrix[newX][newY];
            matrix[newX][newY] = t;
        }
        mY--;
    }

//        进行中线交换
    int xLen = mx / 2;
    for (int i = 0; i < xLen; i++) {
        for (int j = 0; j < my; j++) {
            int newX = mx - 1 - i;

            int t = matrix[i][j];
            matrix[i][j] = matrix[newX][j];
            matrix[newX][j] = t;
        }
    }
}
```

---
#### [Set Matrix Zeroes](https://leetcode.com/problems/set-matrix-zeroes/description/)
**解题思路**
此题要求的是原地实现矩阵置零操作，依据的原来矩阵中零的位置而不是新增的零；
因此需要设置标志位，可以将首行和首列作为标志位，同时对首行、首列设置额外进行标志位判断，[具体参考](http://fisherlei.blogspot.kr/2013/01/leetcode-set-matrix-zeroes.html)。<br>
**实现代码**
```java
public void setZeroes(int[][] matrix) {
//        check validation
    if (matrix == null || matrix.length == 0 || matrix[0] == null || matrix[0].length == 0) {
        return;
    }

    int rows = matrix.length;
    int cols = matrix[0].length;

    boolean xFlag, yFlag;
    xFlag = yFlag = false;

//        对第一行、第一列设置标志位
    for (int i = 0; i < cols; i++) {
        if (matrix[0][i] == 0) {
            yFlag = true;
            break;
        }
    }

    for (int i = 0; i < rows; i++) {
        if (matrix[i][0] == 0) {
            xFlag = true;
            break;
        }
    }


//        设置矩阵中其他元素标志位
    for (int i = 1; i < rows; i++) {
        for (int j = 1; j < cols; j++) {
            if (matrix[i][j] == 0) {
                matrix[i][0] = 0;
                matrix[0][j] = 0;
            }
        }
    }

//        除了首行、首列之外的置零操作
    for (int i = 1; i < rows; i++) {
        if (matrix[i][0] == 0) {
            for (int j = 0; j < cols; j++) {
                matrix[i][j] = 0;
            }
        }
    }

    for (int i = 0; i < cols; i++) {
        if (matrix[0][i] == 0) {
            for (int j = 0; j < rows; j++) {
                matrix[j][i] = 0;
            }
        }
    }

//        首行、首列的置零操作
    if (yFlag) {
        for (int i = 0; i < cols; i++) {
            matrix[0][i] = 0;
        }
    }

    if (xFlag) {
        for (int i = 0; i < rows; i++) {
            matrix[i][0] = 0;
        }
    }

}
```

---
### Spiral Matrix
#### [Spiral Matrix](https://leetcode.com/problems/spiral-matrix/description/)
**解题思路**
只需要按照对应的螺旋顺序添加元素，同时需要注意边界条件的判断，例如重复元素的添加<br>
**实现代码**
```java
public List<Integer> spiralOrder(int[][] matrix) {
        List<Integer> rt = new ArrayList<>();
    //        check validation
    if (matrix == null || matrix.length == 0 ||  matrix[0] == null || matrix[0].length == 0) {
        return rt;
    }

//        设置循环边界条件
    int xStart = 0;
    int xEnd = matrix.length - 1;
    int yStart = 0;
    int yEnd = matrix[0].length - 1;

    while (xStart <= xEnd && yStart <= yEnd) {
//            上面一行
        for (int i = yStart; i <= yEnd; i++) {
            rt.add(matrix[xStart][i]);
        }
//            右边一行
        for (int i = xStart + 1; i <= xEnd; i++) {
            rt.add(matrix[i][yEnd]);
        }

//            遍历完成
        if (xStart == xEnd || yStart == yEnd) {
            break;
        }
        //            下面一行
        for (int i = yEnd-1; i >= yStart; i--) {
            rt.add(matrix[xEnd][i]);
        }
//            左边一行
        for (int i = xEnd - 1; i > xStart; i--) {
            rt.add(matrix[i][xStart]);
        }

        xStart++;
        xEnd--;
        yStart++;
        yEnd--;
    }
    return rt;
}
```

#### [Spiral Matrix II](https://leetcode.com/problems/spiral-matrix-ii/description/)
**解题思路**
实现思路和上题基本类似，只不过通过nums++的方式赋值<br>
**实现代码**
```java
public int[][] generateMatrix(int n) {
//        check validation
    if (n < 1) {
        return new int[][]{};
    }

    int[][] ret = new int[n][n];
    int startX = 0;
    int startY = 0;
    int endX = n - 1;
    int endY = n - 1;
    int index = 1;
    while (startX <= endX && startY <= endY) {
//            最上面一行
        for (int i = startY; i <= endY; i++) {
            ret[startX][i] = index++;
        }
//            最右面一行
        for (int i = startX + 1; i <= endX; i++) {
            ret[i][endY] = index++;
        }
//            是否可以结束循环
        if (startX == endX || startY == endY) {
            break;
        }
//            最下面一行
        for (int i = endY - 1; i >= startY; i--) {
            ret[endX][i] = index++;
        }
//            最左面一行
        for (int i = endX - 1; i > startX; i--) {
            ret[i][startY] = index++;
        }
        startX++;
        startY++;
        endX--;
        endY--;
    }
    return ret;
}
```

---
#### [Summary Ranges](https://leetcode.com/problems/summary-ranges/description/)
**解题思路**
设置,start,end两个游标，如果是连续递增的话end++,具体参加实现代码。<br>
**实现代码**
```java
public List<String> summaryRanges(int[] nums) {
    List<String> rt = new ArrayList<>();
    //        check validation
    if (nums == null || nums.length == 0) {
        return rt;
    }

    int length = nums.length;
    for (int i = 0; i < length; i++) {
        // 设置起始和结束游标
        int start = i;
        int end = start;

        while (i + 1 < length && nums[i + 1] - 1 == nums[i]) {
            i++;
            end++;
        }

        if (start == end) {
            rt.add(nums[start] + "");
        } else {
            rt.add(nums[start] + "->" + nums[end]);
        }
    }
    return rt;
}
```


---
#### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)
