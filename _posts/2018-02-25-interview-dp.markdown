---
layout:     post
title:      "面试编程题 dp"
subtitle:   "面试编程题 dp"
date:       2018-02-25 6:00:00
author:     "julyerr"
header-img: "img/ds/dp/dp.jpg"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - dp
---


#### [Unique Binary Search Trees](https://leetcode.com/problems/unique-binary-search-trees/description/)
**解题思路**
树的种类数等于左边孩子种类数*右边孩子种类数，使用动态规划方式。
dp[i]代表以i为root的种类数，针对左右dp[j]进行统计计算，具体参见实现代码。<br>
**实现代码**

```java
public int numTrees(int n) {
    if (n < 3) {
        return n;
    }

    int[] dp = new int[n + 1];
    dp[0] = dp[1] = 1;
    dp[2] = 2;
    for (int i = 3; i <= n; i++) {
        int tmp = 0;
//            统计以不同元素为root的情况数
        for (int j = 0; j < i; j++) {
            tmp += dp[j] * dp[i - 1 - j];
        }
        dp[i] = tmp;
    }
    return dp[n];
}
```

---
#### [Decode Ways](https://leetcode.com/problems/decode-ways/description/)
**解题思路**
典型的动态规划问题，当下的解析方式dp[i]种类数需要根据strs[i]进行判断：<br>

- 如果等于'0',判断strs[i-1]+strs[i]是否在1-26之间，在的话，dp[i]=dp[i-2]，否则不存在解析方式；
- 如果不等于'0'，dp[i]=dp[i-1]，如果strs[i-1]+strs[i]是否在10-26之间，dp[i]+=dp[i-2],具体参见实现代码。<br>
**实现代码**

```java
public int numDecodings(String s) {
    if (s == null || s.length() == 0 || s.startsWith("0")) {
        return 0;
    }
    int length = s.length();
    int[] dp = new int[length + 1];
//        初始化参数
    dp[0] = dp[1] = 1;
    for (int i = 2; i <= length; i++) {
        char c = s.charAt(i-1);
//            前面两个字符的数字表示大小
        int tmp = (s.charAt(i - 2) - '0') * 10 + c - '0';
        if (c == '0') {
//                不在1-26之间
            if (tmp<=0 || tmp > 26) {
                return 0;
            }
            dp[i] = dp[i - 2];
        } else {
            dp[i] = dp[i - 1];
//                在10-26之间
            if (tmp <= 26 && tmp >10) {
                dp[i] += dp[i - 2];
            }
        }
    }
    return dp[length];
}
```

---
#### [Climbing Stairs](https://leetcode.com/problems/climbing-stairs/description/)

**解题思路**
dp[i] = dp[i-1]+dp[i-2],但是这道题可以不使用数组直接使用变量的方式节省使用空间，具体参见实现代码。<br>
**实现代码**

```java
public int climbStairs(int n) {
    if(n<2){
        return n;
    }
    int step0 = 1;
    int step1 = 1;
    int step2 =0;
//        三个变量，循环计算结果
    for (int i = 2; i <= n; i++) {
        step2 = step0+step1;
        step0 = step1;
        step1 = step2;
    }
    return step2;
}
```

---
#### [House Robber](https://leetcode.com/problems/house-robber/description/)

**解题思路**
设置动态数组dp[n],dp[i]表示当下最大可偷的金额数,则有dp[i] = max(dp[i-2]+nums[i],dp[i-1]).<br>
**实现代码**

```java
public int rob(int[] nums) {
    if (nums == null || nums.length == 0) {
        return 0;
    }
    int length = nums.length;
    if (length < 2) {
        return nums[0];
    }
    int[] dp = new int[nums.length];
    dp[0] = nums[0];
    dp[1] = Math.max(nums[0], nums[1]);
    for (int i = 2; i < length; i++) {
//            递归的判断的关键
        dp[i] = Math.max(dp[i - 2] + nums[i], dp[i - 1]);
    }
    return dp[length - 1];
}
```

---
#### [House Robber II](https://leetcode.com/problems/house-robber-ii/description/)

**解题思路**
在上题的基础上，增加了环的处理。比较巧妙的方法是，沿着开始节点分别向左向右计算nums.length-1的长度比较。<br>
**实现代码**

```java
public int rob(int[] nums) {
    if (nums == null || nums.length == 0) {
        return 0;
    }
    if (nums.length == 1) {
        return nums[0];
    }
//        划分成两段分别进行最大值计算
    return Math.max(robCore(nums, 0, nums.length - 2), robCore(nums, 1, nums.length - 1));
}

private int robCore(int[] nums, int start, int end) {
    if (start >= end) {
        return nums[start];
    }
    if (end == start + 1) {
        return Math.max(nums[start], nums[end]);
    }
//        使用三个变量记录最大值的情况
    int step0 = nums[start];
    int step1 = Math.max(nums[start], nums[start + 1]);
    int step2 = 0;
    for (int i = start + 2; i <= end; i++) {
        step2 = Math.max(step0 + nums[i], step1);
        step0 = step1;
        step1 = step2;
    }
    return step2;
}
```


---
#### [Maximum Subarray](https://leetcode.com/problems/maximum-subarray/description/)
**解题思路**<br>
curSum存储包含当下元素的最大数值和，即curSum = Math.max(curSum+nums[i],nums[i]);
maxSum记录nums[i]更新过程中最大值作为返回值,maxSum = Math.max(maxSum,curSum).
**实现代码**<br>
```java
public int maxSubArray(int[] nums) {
//        check validation,should not happen here
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int curSum = nums[0];
    int maxSum = nums[0];
    for (int i = 1; i < nums.length; i++) {
        //更新curSum 和 maxSum的值
        curSum = Math.max(curSum + nums[i], nums[i]);
        maxSum = Math.max(maxSum, curSum);
    }
    return maxSum;
}
```

---
#### [Maximum Product Subarray](https://leetcode.com/problems/maximum-product-subarray/description/)
**解题思路**<br>
解题思路和上题类似，只是负数*负数=正数，因此需要保留最大和最小整数判断，具体参见实现代码
**实现代码**<br>
```java
public int maxProduct(int[] nums) {
//      check validation , should not happend here
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int curMax = nums[0];
    int curMin = nums[0];
    int max = curMax;
    for (int i = 1; i < nums.length; i++) {
        curMax *= nums[i];
        curMin *= nums[i];
//            大小改变需要交换
        if (curMax < curMin) {
            int t = curMax;
            curMax = curMin;
            curMin = t;
        }
        curMax = Math.max(curMax, nums[i]);
        curMin = Math.min(curMin, nums[i]);
        max = Math.max(max, curMax);
    }
    return max;
}
```

---
#### [Minimum Size Subarray Sum](https://leetcode.com/problems/minimum-size-subarray-sum/description/)
**解题思路**<br>
通过设置start,end两个游标限制大于sum的范围，对于大于sum的情况，start++;对于小于sum情况，end++。
**实现代码**<br>
```java
public int minSubArrayLen(int s, int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return 0;
    }
    int min = Integer.MAX_VALUE;
    int start = 0;
    int sum = 0;
//        end 就是 i
    for (int i = 0; i < nums.length; i++) {
        sum += nums[i];
        if (sum >= s) {
            while (sum - nums[start] >= s) {
                sum -= nums[start++];
            }
            min = Math.min(min, i + 1 - start);
        }
    }
    if (min > nums.length) {
        return 0;
    }
    return min;
}
```

---
#### [Ugly Number II](https://leetcode.com/problems/ugly-number-ii/description/)

**解题思路**
设置数组保存当前计算出的结果，然后分别为2,3,5保存对应的游标，只有当前的ugly等于自己的倍数的时候才将对应的游标增加一。<br>
**实现代码**

```java
public int nthUglyNumber(int n) {
    if (n < 2) {
        return n;
    }
//        其中dp[i]表示下标为i+1对应的ugly number
    int[] dp = new int[n];
    dp[0] = 1;
    int step0 = 0;
    int step1 = 0;
    int step2 = 0;
    for (int i = 1; i < n; i++) {
        int min = Math.min(dp[step0] * 2, Math.min(dp[step1] * 3, dp[step2] * 5));
        dp[i] = min;
        if (min == dp[step0] * 2) {
            step0++;
        }
        if (min == dp[step1] * 3) {
            step1++;
        }
        if (min == dp[step2] * 5) {
            step2++;
        }
    }
    return dp[n - 1];
}
```

---
### Unique Path系列
#### [Unique Paths](https://leetcode.com/problems/unique-paths/description/)
**解题思路**
dp[i][j] = dp[i-1][j]+dp[i][j-1]，同样需要对0行和0列进行初始化<br>
**实现代码**
```java
public int uniquePaths(int m, int n) {
//        check validation
    if (m < 1 || n < 1) {
        return 0;
    }
    int[][] dp = new int[m][n];
//        对0行0列进行初始化
    for (int i = 0; i < n; i++) {
        dp[0][i] = 1;
    }

    for (int i = 0; i < m; i++) {
        dp[i][0] = 1;
    }

//        进行数据更新
    for (int i = 1; i < m; i++) {
        for (int j = 1; j < n; j++) {
            dp[i][j] = dp[i - 1][j] + dp[i][j - 1];
        }
    }
    return dp[m - 1][n - 1];
}
```

---
#### [Unique Paths II](https://leetcode.com/problems/unique-paths-ii/description/)
**解题思路**
实现思路和上题差不多，对于出现的障碍需要重新设置dp[i][j]=0<br>
**实现代码**
```java
public int uniquePathsWithObstacles(int[][] obstacleGrid) {
//        check validation
    if (obstacleGrid == null || obstacleGrid.length == 0 || obstacleGrid[0] == null || obstacleGrid[0].length == 0) {
        return 0;
    }

    int m = obstacleGrid.length;
    int n = obstacleGrid[0].length;

    int[][] dp = new int[m][n];

//        初始化0行和0列
    for (int i = 0; i < n; i++) {
        if (obstacleGrid[0][i] == 0) {
            dp[0][i] = 1;
        } else {
            break;
        }
    }

    for (int i = 0; i < m; i++) {
        if (obstacleGrid[i][0] == 0) {
            dp[i][0] = 1;
        } else {
            break;
        }
    }

//        进行数据更新
    for (int i = 1; i < m; i++) {
        for (int j = 1; j < n; j++) {
            if (obstacleGrid[i][j] == 1) {
                dp[i][j] = 0;
            } else {
                dp[i][j] = dp[i - 1][j] + dp[i][j - 1];
            }
        }
    }
    return dp[m - 1][n - 1];
}
```

---
#### [Minimum Path Sum](https://leetcode.com/problems/minimum-path-sum/description/)
**解题思路**<br>
dp[n][m] = Math.min(dp[n-1][m],dp[n][m-1])+nums[n][m],需要对0行和0列合理初始化
**实现代码**<br>
```java
public int minPathSum(int[][] grid) {
//        check validation,should not happen here
    if (grid == null || grid.length == 0 || grid[0] == null || grid[0].length == 0) {
        return -1;
    }
    int n = grid.length;
    int m = grid[0].length;
    int[][] dp = new int[n][m];
//        初始化操作
    int sum = 0;
    for (int i = 0; i < m; i++) {
        sum += grid[0][i];
        dp[0][i] = sum;
    }

    sum = 0;
    for (int i = 0; i < n; i++) {
        sum += grid[i][0];
        dp[i][0] = sum;
    }

    for (int i = 1; i < n; i++) {
        for (int j = 1; j < m; j++) {
            dp[i][j] = Math.min(dp[i - 1][j], dp[i][j - 1]) + grid[i][j];
        }
    }
    return dp[n-1][m-1];
}
```

---
#### [Perfect Squares](https://leetcode.com/problems/perfect-squares/description/)

**解题思路**
此题有点像素数筛选的过程，这不过求解的是最小值。<br>
**实现代码**

```java
public int numSquares(int n) {
    if(n < 2){
        return n;
    }
    int[] dp = new int[n+1];
//        初始化为最大值
    Arrays.fill(dp,Integer.MAX_VALUE);
//        将所有的平方数均设置为1
    for (int i = 1; i*i <=n; i++) {
        dp[i*i] = 1;
    }
    for (int i = 1; i <=n; i++) {
//            迭代进行比较，类似素数筛选的过程
        for (int j = 1; i+j*j <=n ; j++) {
            dp[i+j*j] = Math.min(dp[i]+1,dp[i+j*j]);
        }
    }

    return dp[n];
}
```

---
#### [Maximal Square](https://leetcode.com/problems/maximal-square/description/)

**解题思路**
典型使用动态规划解决，dp[i][j]代表当前nums[i][j]的最大的方形的边长；
只有当前为1的时候才判断，dp[i][j] = 1+Math.min(dp[i-1][j],Math.min(dp[i][j-1],dp[i-1][j-1])),整个遍历过程设置max记录最大的边长。<br>
**实现代码**

```java
public int maximalSquare(char[][] matrix) {
    if (matrix == null || matrix.length == 0 || matrix[0] == null || matrix[0].length == 0) {
        return 0;
    }
    int xLen = matrix.length;
    int yLen = matrix[0].length;
    int[][] dp = new int[xLen][yLen];

//        设置max正确初始值
    int max = 0;
//        对第一行和第一列进行初始化
    for (int i = 0; i < xLen; i++) {
        if (matrix[i][0] == '1') {
            dp[i][0] = 1;
            max = 1;
        }
    }

    for (int i = 0; i < yLen; i++) {
        if (matrix[0][i] == '1') {
            dp[0][i] = 1;
            max = 1;
        }
    }

    for (int i = 1; i < xLen; i++) {
        for (int j = 1; j < yLen; j++) {
//                只有在1的情况下才设置值，并且更新
            if (matrix[i][j] == '1') {
                dp[i][j] = 1 + Math.min(dp[i - 1][j], Math.min(dp[i - 1][j - 1], dp[i][j - 1]));
                max = Math.max(max, dp[i][j]);
            }
        }
    }
    return max * max;
}
```

---
#### [Triangle](https://leetcode.com/problems/triangle/description/)

**解题思路**
使用上次获取到的最小值的位置，然后下一层的时候在该位置的左右取上最小值，但是这样会出现错误的解答，因为下一层该位置的左右的值可能很大。直接使用递归的时间复杂度太高，动态规划设置dp1[i]和dp[i]表示上下两层到达位置i的最小值，中间设置min表示dp[n]中最小值，具体参见实现代码。<br>
**实现代码**

```java
public int minimumTotal(List<List<Integer>> triangle) {
    if (triangle == null || triangle.size() == 0 || triangle.get(0) == null || triangle.get(0).size() == 0) {
        return 0;
    }
//        设置前后两个数组保持层次顺序
    int[] pre = new int[]{triangle.get(0).get(0)};
    int min = pre[0];

    for (int i = 1; i < triangle.size(); i++) {
        int[] cur = new int[i + 1];
        List<Integer> tmp = triangle.get(i);
        for (int j = 0; j < i + 1; j++) {
            int val = tmp.get(j);
//                边缘情况直接复制元素下来相加即可
            if (j == 0) {
                cur[j] = val + pre[j];
                min = cur[j];
            } else if (j == i) {
                cur[j] = val + pre[j-1];
//                    取上层元素的最小值
            } else {
                cur[j] = Math.min(pre[j], pre[j - 1]) + val;
            }
            if (min > cur[j]) {
                min = cur[j];
            }
        }
//            交替迭代
        pre = cur;
    }
    return min;
}
```



---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)