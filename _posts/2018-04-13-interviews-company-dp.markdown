---
layout:     post
title:      "面试中常见动态规划题目题解"
subtitle:   "面试中常见动态规划题目题解"
date:       2018-04-13 1:00:00
author:     "julyerr"
header-img: "img/ds/dp/dp.jpg"
header-mask: 0.5
catalog:    true
tags:
    - interview
---

### 前导

>本人不是acmer,牛客网上题目对于acmer而言基本属于easy-mid类型的。问了好几个搞acmer然后拿到亚洲奖杯的大神，基本上只要参加了的公司的在线编程都能AK。幸好国内很多bat级别的公司不像Google、微软（现在景驰等）只考察算法，其他基本不问。<br>

>经过一两个月坚持刷题，感觉绝大部分公司的编程题目难度是逐年增加，数据结构和算法不会涉及到特别复杂的（如果存在的话，最多一道题目的样子）。因此好好刷完《剑指offer》题目之后，每天刷几道牛客网上题目，到秋招问题也不会太大。<br>

>动态规划几乎是所有试卷中都会出现的题目，非常灵活，也是本文开始总结的第一块专题。本文不会涉及到比较怪的题目，虽然花很长时间弄明白了，但是编程时间限制，还是慢慢来吧。动态规划比较典型的题目是求解最值问题以及方法总数等，关键是状态方程关系式的确定，一般代码量都非常少，考察的计算思维。

#### [不等式数列](https://www.nowcoder.com/questionTerminal/621e433919214a9ba46087dd50f09879)

度度熊最近对全排列特别感兴趣,对于1到n的一个排列,度度熊发现可以在中间根据大小关系插入合适的大于和小于符号(即 '>' 和 '<' )使其成为一个合法的不等式数列。但是现在度度熊手中只有k个小于符号即('<'')和n-k-1个大于符号(即'>'),度度熊想知道对于1至n任意的排列中有多少个排列可以使用这些符号使其为合法的不等式数列。<br>

输入描述:
输入包括一行,包含两个整数n和k(k < n ≤ 1000)

输出描述:
输出满足条件的排列数,答案对2017取模。

示例1

输入
5 2

输出
66

如果尝试使用递归或者枚举的方式去解题肯定是非常耗时，想到使用动态规划，dp[i][j]表示i个序列有j个'<'所能组成的数量。

- 直接添加到最开始，此时多添加一个>,种类数+dp[i-1][j];
- 直接添加到最后面，此时多添加一个<,种类数+dp[i-1][j-1];
- 添加到中间任意一个<,例如1<2，变成1<3>2,多添加了一个>，种类数+dp[i-1][j]*j;
- 添加到中间任意一个>，例如2>1,变成2<3>1,多添加了一个<,种类数+dp[i-1][j-1]*(i-j-1)
整理可得到：dp[i][j] = dp[i-1][j]*(j+1)+dp[i-1][j-1]*(i-j)

```java
public class Inequation {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            int n = scanner.nextInt();
            int k = scanner.nextInt();
            int[][] dp = new int[n + 1][k + 1];
            for (int i = 1; i <= n; i++) {
                dp[i][0] = 1;
            }
            for (int i = 2; i <= n; i++) {
                for (int j = 1; j <= k; j++) {
                    dp[i][j] = (dp[i - 1][j](j + 1) + dp[i - 1][j - 1](i - j)) % 2017;
                }
            }
            System.out.println(dp[n][k]);
        }
    }
}
```

---
#### [双核处理](https://www.nowcoder.com/questionTerminal/9ba85699e2824bc29166c92561da77fa)

一种双核CPU的两个核能够同时的处理任务，现在有n个已知数据量的任务需要交给CPU处理，假设已知CPU的每个核1秒可以处理1kb，每个核同时只能处理一项任务。n个任务可以按照任意顺序放入CPU进行处理，现在需要设计一个方案让CPU处理完这批任务所需的时间最少，求这个最小的时间。


输入描述:
输入包括两行： 第一行为整数n(1 ≤ n ≤ 50) 第二行为n个整数length[i](1024 ≤ length[i] ≤ 4194304)，表示每个任务的长度为length[i]kb，每个数均为1024的倍数。

输出描述:
输出一个整数，表示最少需要处理的时间

示例1


输入
5 3072 3072 7168 3072 1024

输出
9216

要使两个CPU工作量相差最小，可以想到使某一CPU工作量最接近总工作量的一半，转换成sum/2大小01背包问题，还是比较tricky的。
工作量为1024的倍数，可以先缩小变换范围，
dp[j]表示背包的容量为j，对于num[i]的货物，dp[j] = max(dp[j],dp[j-nums[i]]+nums[i])

```java
public class CPUTask {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            int n = scanner.nextInt();
            int[] nums = new int[n];
            int sum = 0;
            for (int i = 0; i < n; i++) {
//                缩小容量空间
                nums[i] = scanner.nextInt() >> 10;
                sum += nums[i];
            }
            int[] dp = new int[sum / 2 + 1];
            for (int i = 0; i < n; i++) {
                for (int j = sum / 2; j >= nums[i]; j--) {
//                    对每件货物，更新背包容量能够获取的最大值
                    dp[j] = Math.max(dp[j], dp[j - nums[i]] + nums[i]);
                }
            }
            int tmp = dp[sum / 2];
            System.out.println((tmp > sum - tmp ? tmp : sum - tmp) << 10);
        }
    }
}
```
---
#### [分饼干](https://www.nowcoder.com/questionTerminal/44d0ee89b51b4725b403d1df2381d2b2)

易老师购买了一盒饼干，盒子中一共有k块饼干，但是数字k有些数位变得模糊了，看不清楚数字具体是多少了。易老师需要你帮忙把这k块饼干平分给n个小朋友，易老师保证这盒饼干能平分给n个小朋友。现在你需要计算出k有多少种可能的数值


输入描述:

输入包括两行：
 第一行为盒子上的数值k，模糊的数位用X表示，长度小于18(可能有多个模糊的数位)
 第二行为小朋友的人数n


输出描述:
输出k可能的数值种数，保证至少为1

示例1

输入
9999999999999X 3

输出
4

如果动态规划题目做多的话，容易发现此题应该是dp才能解决的。但是状态转移方程比较难想，dp[i][j]表示前i个字符串对应整数mod n之后余数为j的情况数，对应有两种情况：
1. 当下字符为X，则可以遍历k从0-9重新进行计算dp[i][(j10 + k) % n] += dp[i - 1][j];
2. 当下字符为具体的数字，dp[i][(j10 + c - '0') % n] += dp[i - 1][j];

```java
public class ShareBiscuit {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            String line = scanner.next();
            int n = scanner.nextInt();
            int len = line.length();
            long[][] dp = new long[len + 1][n];
            dp[0][0] = 1;
            for (int i = 1; i <= len; i++) {
                for (int j = 0; j < n; j++) {
                    char c = line.charAt(i - 1);
                    if (c == 'X') {
//                        0-9进行遍历
                        for (int k = 0; k < 10; k++) {
                            dp[i][(j10 + k) % n] += dp[i - 1][j];
                        }
                    } else {
//                        直接计算
                        dp[i][(j10 + c - '0') % n] += dp[i - 1][j];
                    }
                }
            }
            System.out.println(dp[len][0]);
        }
    }
}
```

---
#### [小易喜欢的数列](https://www.nowcoder.com/questionTerminal/49375dd6a42d4230b0dc4ea5a2597a9b)

小易非常喜欢拥有以下性质的数列:
1. 数列的长度为n
2. 数列中的每个数都在1到k之间(包括1和k)
3. 对于位置相邻的两个数A和B(A在B前),都满足(A <= B)或(A mod B != 0)(满足其一即可)

例如,当n = 4, k = 7
那么{1,7,7,2},它的长度是4,所有数字也在1到7范围内,并且满足第三条性质,所以小易是喜欢这个数列的
但是小易不喜欢{4,4,4,2}这个数列。小易给出n和k,希望你能帮他求出有多少个是他会喜欢的数列。 

输入描述:
输入包括两个整数n和k(1 ≤ n ≤ 10, 1 ≤ k ≤ 10^5)

输出描述:
输出一个整数,即满足要求的数列个数,因为答案可能很大,输出对1,000,000,007取模的结果。

示例1

输入
2 2

输出
3

题目有点提示，位置相邻，一前一后，基本上可以考虑使用动态规划。dp[i][j] 表示长度为i的序列以j为结束数字。
dp[i][j] = dp[i-1][m] (1<=m<=k)并且（m,j)是一个有效的序列，也即m<=j或者m%j!=0(计算可以考虑使用类似素数筛选的过程)。

```java
public class LikedSeq {
    private static final int MOD = 1000000007;

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            int n = scanner.nextInt();
            int k = scanner.nextInt();

            int[][] dp = new int[n + 1][k + 1];
            dp[0][1] = 1;
            for (int i = 1; i <= n; i++) {
                int sum = 0;
//                所有可能组合
                for (int j = 1; j <= k; j++) {
                    sum = (sum + dp[i - 1][j]) % MOD;
                }

                for (int j = 1; j <= k; j++) {
//                    删除所有不满足条件的情况，类似素数筛选的过程
                    int invalid = 0;
                    int p = 2;
                    while (pj <= k) {
                        invalid = (invalid + dp[i - 1][pj]) % MOD;
                        p++;
                    }
//                    为初始化添加增量
                    dp[i][j] = (sum - invalid + MOD) % MOD;
                }
            }
            int sum = 0;
            for (int i = 1; i <= k; i++) {
                sum = (sum + dp[n][i]) % MOD;
            }
            System.out.println(sum);
        }
    }
}
```

---
#### [跳石板](https://www.nowcoder.com/questionTerminal/4284c8f466814870bae7799a07d49ec8)

小易来到了一条石板路前，每块石板上从1挨着编号为：1、2、3.......
这条石板路要根据特殊的规则才能前进：对于小易当前所在的编号为K的石板，小易单次只能往前跳K的一个约数(不含1和K)步，即跳到K+X(X为K的一个非1和本身的约数)的位置。 小易当前处在编号为N的石板，他想跳到编号恰好为M的石板去，小易想知道最少需要跳跃几次可以到达。
例如：
N = 4，M = 24：
4->6->8->12->18->24
于是小易最少需要跳跃5次，就可以从4号石板跳到24号石板 

输入描述:
输入为一行，有两个整数N，M，以空格隔开。 (4 ≤ N ≤ 100000) (N ≤ M ≤ 100000)

输出描述:
输出小易最少需要跳跃的步数,如果不能到达输出-1

示例1

输入
4 24

输出
5

dp[i]表示到达i的步数，dp[i+j] = min(dp[i+j],dp[i]+j),j为i的约数。

```java
public class BengShiban {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            int N = scanner.nextInt();
            int M = scanner.nextInt();
            int[] dp = new int[M + 1];
            Arrays.fill(dp, Integer.MAX_VALUE);
            dp[N] = 0;
            for (int i = N; i <= M; i++) {
//                该位置可达
                if (dp[i] != Integer.MAX_VALUE) {
                    for (int j = 2; jj <= i; j++) {
//                        有公共的因子
                        if (i % j == 0) {
//                            两种情况都可能进行更新
                            if (i + j <= M) {
                                dp[i + j] = Math.min(dp[i + j], dp[i] + 1);
                            }
                            if (i + i / j <= M) {
                                dp[i + i / j] = Math.min(dp[i + i / j], dp[i] + 1);
                            }
                        }
                    }
                }
            }
            System.out.println(dp[M] == Integer.MAX_VALUE ? -1 : dp[M]);
        }
    }
}
```

---
#### [暗黑字符串](https://www.nowcoder.com/questionTerminal/7e7ccd30004347e89490fefeb2190ad2)

一个只包含'A'、'B'和'C'的字符串，如果存在某一段长度为3的连续子串中恰好'A'、'B'和'C'各有一个，那么这个字符串就是纯净的，否则这个字符串就是暗黑的。例如：
BAACAACCBAAA 连续子串"CBA"中包含了'A','B','C'各一个，所以是纯净的字符串
AABBCCAABB 不存在一个长度为3的连续子串包含'A','B','C',所以是暗黑的字符串
你的任务就是计算出长度为n的字符串(只包含'A'、'B'和'C')，有多少个是暗黑的字符串。 

输入描述:
输入一个整数n，表示字符串长度(1 ≤ n ≤ 30)

输出描述:
输出一个整数表示有多少个暗黑字符串

示例1

输入
2 3

输出
9 21

same[i]表示i长的字符串后面两个字母相同情况数，diff[i]表示i长的字符串后面两个字母不相同情况数。
容易得到状态转移关系式 same[i] = same[i - 1] + diff[i - 1]，diff[i] = 2same[i - 1] + diff[i - 1]

```java
public class DarkStr {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            int n = scanner.nextInt();
            long[] same = new long[n + 1];
            long[] diff = new long[n + 1];
            same[2] = 3;
            diff[2] = 6;
            for (int i = 3; i <= n; i++) {
                same[i] = same[i - 1] + diff[i - 1];
                diff[i] = 2same[i - 1] + diff[i - 1];
            }
            //不同情况总数之和
            System.out.println(same[n] + diff[n]);
        }
    }
}
```

---
#### [合唱](https://www.nowcoder.com/questionTerminal/fddf64d5757e41ec93f3ef0c0a10b891)

小Q和牛博士合唱一首歌曲,这首歌曲由n个音调组成,每个音调由一个正整数表示。
对于每个音调要么由小Q演唱要么由牛博士演唱,对于一系列音调演唱的难度等于所有相邻音调变化幅度之和, 例如一个音调序列是8, 8, 13, 12, 那么它的难度等于|8 - 8| + |13 - 8| + |12 - 13| = 6(其中||表示绝对值)。
现在要对把这n个音调分配给小Q或牛博士,让他们演唱的难度之和最小,请你算算最小的难度和是多少。
如样例所示: 小Q选择演唱{5, 6}难度为1, 牛博士选择演唱{1, 2, 1}难度为2,难度之和为3,这一个是最小难度和的方案了。 

输入描述:
输入包括两行,第一行一个正整数n(1 ≤ n ≤ 2000) 第二行n个整数v[i](1 ≤ v[i] ≤ 10^6), 表示每个音调。

输出描述:
输出一个整数,表示小Q和牛博士演唱最小的难度和是多少。

示例1

输入
5
1 5 6 2 1

输出
3

同样也是动态规划比较适合此题，dp[i][j]表示最近一次第一个人唱的是i，第二个人唱的是j种类数。
不妨设置i>j:

- 当j = i-1，说明发生了交换的情况，dp[i][j] = dp[i-1][k]+min(abs(nums[i]-nums[k])), 0<=k<i-1;

- 当j<i-1，说明唱i字符的时候没有发生交换的情况,dp[i][j] =dp[i-1][j]+abs(nums[i]-nums[i-1])


```java
public class Chorus {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            int n = scanner.nextInt();
            int[] nums = new int[n];
            for (int i = 0; i < n; i++) {
                nums[i] = scanner.nextInt();
            }
            int[] acc = new int[n];
            int[][] dp = new int[n][n];
            for (int i = 1; i < n; i++) {
                acc[i] = acc[i - 1] + Math.abs(nums[i] - nums[i - 1]);
//                初始化dp[i][i-1]
                dp[i][i - 1] = acc[i - 1];
                for (int j = 0; j < i - 1; j++) {
//                    第一种情况
                    dp[i][j] = dp[i - 1][j] + acc[i] - acc[i - 1];
//                    第二种情况
                    dp[i][i - 1] = Math.min(dp[i][i - 1], dp[i - 1][j] + Math.abs(nums[i] - nums[j]));
                }
            }
//            统计最小值
            int min = dp[n - 1][0];
            for (int i = 1; i < n - 1; i++) {
                min = Math.min(min, dp[n - 1][i]);
            }
            System.out.println(min);
        }
    }
}
```

---
### 参考资料
- [牛客网](https://www.nowcoder.com)
- [个人部分题解](https://www.nowcoder.com/profile/5312575/comments)