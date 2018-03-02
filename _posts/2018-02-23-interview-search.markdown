---
layout:     post
title:      "面试编程题 search & sort 篇"
subtitle:   "面试编程题 search & sort 篇"
date:       2018-02-23 6:00:00
author:     "julyerr"
header-img: "img/ds/searchSort/searchSort.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - search
    - sort
---


#### [Search Insert Position](https://leetcode.com/problems/search-insert-position/description/)
**解题思路**
简单的插入排序<br>
**实现代码**<br>
```java
public int searchInsert(int[] nums, int target) {
//        check validation
    if(nums == null || nums.length ==0){
        return 0;
    }
    int i = 0;
    for (i = nums.length-1; i >= 0 ; i--) {
        if(target > nums[i]){
            break;
        }
    }
    return i+1;
}
```

---
#### [Find Peak Element](https://leetcode.com/problems/find-peak-element/description/)
**解题思路**<br>
使用二分法，只需要找到任意nums[i],nums[i]比左右的元素都大的情况即可。<br>
**实现代码**<br>
```java
public int findPeakElement(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int low = 0;
    int high = nums.length - 1;
    while (low < high) {
        int mid = (low + high) >> 1;
//        找到下降点
        if (nums[mid] > nums[mid + 1]) {
            high = mid;
        } else {
            low = mid + 1;
        }
    }
    return low;
}
```
---

### Rotated Array系列
#### [Find Minimum in Rotated Sorted Array](https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/description/)
**解题思路**<br>
针对O(n)时间复杂度进行改进，考虑使用二分查找法。low、mid、high三个游标，考虑三种可能情况:

1. array[mid] > array[high]:此时的最小值一定在mid的右边；
2. array[mid] == array[high]:无法直接确定，只能一个一个尝试 high = high - 1;
3. array[mid] < array[high]:最小值一定在mid的左边或者就是mid

**实现代码**<br>
```java
public int findMin(int[] nums) {
//        should not happend
    if (nums == null || nums.length == 0) {
        return -1;
    }
    int low = 0;
    int high = nums.length - 1;
    while (low <= high) {
        int mid = (low + high) >> 1;
        if (nums[mid] < nums[high]) {
            high = mid;
        } else if (nums[mid] > nums[high]) {
            low = mid + 1;
        } else {
            high = high - 1;
        }
    }
    return nums[low];
}
```

---
#### [Search in Rotated Sorted Array](https://leetcode.com/problems/search-in-rotated-sorted-array/description/)
**解题思路**<br>
参考[大神的解题思路](http://blog.csdn.net/linhuanmars/article/details/20525681)<br>
假设数组是A，每次左边缘为l，右边缘为r，还有中间位置是m。在每次迭代中，分三种情况：

- 如果target==A[m]，那么m就是我们要的结果，直接返回；
- 如果A[m]<A[r]，那么说明从m到r一定是有序的（没有受到rotate的影响），那么我们只需要判断target是不是在m到r之间，如果是则把左边缘移到m+1，否则就target在另一半，即把右边缘移到m-1。
- 如果A[m]>=A[r]，那么说明从l到m一定是有序的，同样只需要判断target是否在这个范围内，相应的移动边缘即可。
根据以上方法，每次我们都可以切掉一半的数据，所以算法的时间复杂度是O(logn)，空间复杂度是O(1)。<br>
**实现代码**<br>
```java
public int search(int[] nums, int target) {
//        check validation
    if (nums == null || nums.length == 0) {
        return -1;
    }

//        二分法查找
    int left = 0;
    int right = nums.length - 1;
    while (left <= right) {
        int mid = (left + right) >> 1;
        if (nums[mid] == target) {
            return mid;
//                mid ~ right 直接有序
        } else if (nums[mid] < nums[right]) {
//                元素处于 mid ~ right之间
            if (target > nums[mid] && target <= nums[right]) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
//                left ~ mid 有序
        } else {
//                元素处于 left ~ mid之间
            if (target >= nums[left] && target < nums[mid]) {
                right = mid - 1;
            } else {
                left = mid + 1;
            }
        }
    }
    return -1;
}
```

---
#### [Search in Rotated Sorted Array II](https://leetcode.com/problems/search-in-rotated-sorted-array-ii/description/)
**解题思路**<br>
解题思路和上题基本一致，需要注意的是允许出现重复值，nums[mid] 和nums[right]的比较可能出现相等的情况，
例如：[3 1 1] 和 [1 1 3 1]，中间值等于最右值时，目标值3既可以在左边又可以在右边，只需要right--，然后重新判断即可<br>
**实现代码**
```java
public boolean search(int[] nums, int target) {
//        check validation
    if (nums == null || nums.length == 0) {
        return false;
    }

//        二分法查找
    int left = 0;
    int right = nums.length - 1;
    while (left <= right) {
        int mid = (left + right) >> 1;
        if (nums[mid] == target) {
            return true;
//                mid ~ right 直接有序
        } else if (nums[mid] < nums[right]) {
//                元素处于 mid ~ right之间
            if (target > nums[mid] && target <= nums[right]) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
//                left ~ mid 有序
        } else if (nums[mid] > nums[right]) {
//                元素处于 left ~ mid之间
            if (target >= nums[left] && target < nums[mid]) {
                right = mid - 1;
            } else {
                left = mid + 1;
            }
        } else {
            right--;
        }
    }
    return false;
}
```

---
#### [Merge Sorted Array](https://leetcode.com/problems/merge-sorted-array/description/)
**解题思路**
这道题关键是在原地实现merge sort，需要从后向前推进<br>
**实现代码**<br>
```java
public void merge(int[] nums1, int m, int[] nums2, int n) {
//        cursor
    int index = m + n - 1;
    m -= 1;
    n -= 1;
    while (m >= 0 && n >= 0) {
        if (nums1[m] <= nums2[n]) {
            nums1[index--] = nums2[n];
            n--;
        } else {
            nums1[index--] = nums1[m];
            m--;
        }
    }
    while (m >= 0) {
        nums1[index--] = nums1[m--];
    }
    while (n >= 0) {
        nums1[index--] = nums2[n--];
    }
}
```

---
#### [Search a 2D Matrix](https://leetcode.com/problems/search-a-2d-matrix/description/)
**解题思路**
将整个matrix装换成一维数组对待的话，直接使用二分查找即可。<br>
**实现代码**<br>
```java
public boolean searchMatrix(int[][] matrix, int target) {
//        check validation
    if (matrix == null || matrix.length == 0 || matrix[0] == null || matrix[0].length == 0) {
        return false;
    }
    int xLen = matrix.length;
    int yLen = matrix[0].length;
//        提高查询速度，进行边界条件检查
    if(target < matrix[0][0] || target > matrix[xLen-1][yLen-1]){
        return false;
    }

//        使用二分法查找
    int left = 0;
    int right = xLen * yLen-1;
    while (left <= right) {
        int mid = (left + right) >> 1;

//            对应的二维坐标
        int x = mid / yLen;
        int y = mid % yLen;
        if (matrix[x][y] == target) {
            return true;
        } else if (matrix[x][y] > target) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return false;
}
```

---
#### [Search for a Range](https://leetcode.com/problems/search-for-a-range/description/)
**解题思路**
在O(log n)的时间复杂度内，使用二分法查找，然后针对相同的元素左右扩展<br>
**实现代码**<br>
```java
public int[] searchRange(int[] nums, int target) {
//        check validation
    if (nums == null || nums.length == 0 || target < nums[0] || target > nums[nums.length - 1]) {
        return new int[]{-1, -1};
    }

    int length = nums.length;

//        二分查找
    int left = 0;
    int right = length - 1;
    while (left <= right) {
        int mid = (left + right) >> 1;
        if (nums[mid] == target) {
            int start, end;
            start = end = mid;
            while (start - 1 >= 0 && nums[start - 1] == target) {
                start--;
            }
            while (end + 1 <= length - 1 && nums[end + 1] == target) {
                end++;
            }
            return new int[]{start, end};
        } else if (nums[mid] > target) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return new int[]{-1, -1};
}
```

---
#### [Sort Colors](https://leetcode.com/problems/sort-colors/description/)
**解题思路**<br>
比较简单的实现思路，使用计数排序算法，需要遍历数组两次；
如果遍历一次，需要扫面并且交换元素，如果nums[cur] == 2, swap(nums[cur],nums[right]);
如果nums[cur]==0 , swap(nums[cur],nums[left]),具体参见实现代码<br>
**实现代码**
```java
    public void sortColors(int[] nums) {
//        check validation
    if (nums == null || nums.length == 0) {
        return;
    }

    int left = 0;
    int right = nums.length - 1;
    int cur = 0;
    while (cur <= right) {
        if (nums[cur] == 2) {
            swap(nums, cur, right--);
        } else {
            if (nums[cur] == 0) {
                swap(nums, cur, left++);
            }
            cur++;
        }
    }
}

private static void swap(int[] nums, int m, int n) {
    int t = nums[m];
    nums[m] = nums[n];
    nums[n] = t;
}
```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)