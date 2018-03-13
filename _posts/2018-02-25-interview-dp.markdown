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
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)