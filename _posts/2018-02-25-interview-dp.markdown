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
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)