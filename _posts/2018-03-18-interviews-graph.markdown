---
layout:     post
title:      "面试编程题 graph"
subtitle:   "面试编程题 graph"
date:       2018-03-18 6:00:00
author:     "julyerr"
header-img: "img/ds/graph/graph.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - dfs
---

《剑指offer》和其他在线编程平台上关于图的试题还是不太常见，图的算法性较强，难度较大。如果不是专门练过的话(acmer)或者算法岗位的面试，一般不会专门涉及到图在线编程（知道常见的图的算法还是很有[必要的](http://julyerr.club/2018/01/13/dsGraph/)）。<br>

---
#### [Course Schedule](https://leetcode.com/problems/course-schedule/description/)
**解题思路**
典型拓扑排序的试题，现将没有先修课程入队列，队列弹出一门课程；然后将以该课程为先修课程的先修课程引用数减一，
先修课程引用数为0的课程加入队列，不断迭代下去，具体参见实现代码。<br>
**实现代码**

```java
public boolean canFinish(int courseNum, int[][] prequisition) {
    if (prequisition == null || prequisition.length == 0 || prequisition[0] == null || prequisition[0].length < 2) {
        return true;
    }
    int[] count = new int[courseNum];
//        统计课程的先修数
    for (int i = 0; i < prequisition.length; i++) {
        count[prequisition[i][0]]++;
    }
    Queue<Integer> queue = new LinkedList<>();
//        没有先修课程的课程加入队列
    for (int i = 0; i < courseNum; i++) {
        if (count[i] == 0) {
            queue.add(i);
        }
    }
    int finishedCourse = queue.size();
    while (!queue.isEmpty()) {
        int finished = queue.poll();
        for (int i = 0; i < prequisition.length; i++) {
            if (prequisition[i][1] == finished) {
                count[prequisition[i][0]]--;
                if (count[prequisition[i][0]] == 0) {
//                        没有先修课程的课程加入队列
                    finishedCourse++;
                    queue.add(prequisition[i][0]);
                }
            }
        }
    }
    return finishedCourse == courseNum;
}
```

---
#### [Course Schedule II](https://leetcode.com/problems/course-schedule-ii/description/)
**解题思路**
在上题的基础上添加了，先修课程完成顺序，完成之时添加进返回List即可。<br>
**实现代码**

```java
public int[] findOrder(int courseNum, int[][] prequisition) {
    int[] count = new int[courseNum];
//        没有任何先修课程，直接返回（有点坑）
    if (prequisition == null || prequisition.length == 0) {
        for (int i = 0; i < courseNum; i++) {
            count[i] = courseNum - 1 - i;
        }
        return count;
    }
    //        统计课程的先修数
    for (int i = 0; i < prequisition.length; i++) {
        count[prequisition[i][0]]++;
    }
    int[] ret = new int[courseNum];
    int index = 0;
    Queue<Integer> queue = new LinkedList<>();
//        没有先修课程的课程加入队列
    for (int i = 0; i < courseNum; i++) {
        if (count[i] == 0) {
            queue.add(i);
            ret[index++] = i;
        }
    }
    while (!queue.isEmpty()) {
        int finished = queue.poll();
        for (int i = 0; i < prequisition.length; i++) {
            if (prequisition[i][1] == finished) {
                count[prequisition[i][0]]--;
                if (count[prequisition[i][0]] == 0) {
//                        没有先修课程的课程加入队列
                    ret[index++] = prequisition[i][0];
                    queue.add(prequisition[i][0]);
                }
            }
        }
    }
    if (index != courseNum) {
        return new int[]{};
    }
    return ret;
}
```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)