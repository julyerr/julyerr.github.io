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

**解题思路**
<br>
**实现代码**
```java

```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)