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
#### [Merge Two Sorted Lists](https://leetcode.com/problems/merge-two-sorted-lists/description/)
**解题思路**
实现思路和上题基本类似，只不过针对剩余的元素可以直接使用next而不需要重新复制。<br>
**实现代码**
```java
public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
//        check validation
    if (l1 == null && l2 == null) {
        return null;
    } else if (l1 == null) {
        return l2;
    } else if (l2 == null) {
        return l1;
    }

//        设置临时节点
    ListNode tmpHead = new ListNode(0);
    ListNode cur = tmpHead;

    ListNode p = l1;
    ListNode q = l2;
    while (p != null && q != null) {
        if (p.val <= q.val) {
            cur.next = p;
            p = p.next;
        } else {
            cur.next = q;
            q = q.next;
        }
        cur = cur.next;
    }
//        剩余部分合并
    if (p != null) {
        cur.next = p;
    }
    if (q != null) {
        cur.next = q;
    }
    return tmpHead.next;
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
#### [H-Index](https://leetcode.com/problems/h-index/description/)
**解题思路**
第一次题目理解比较难以理解，以[3, 0, 6, 1, 5]为例，先将该数组从大到小进行排序得到
[6,5,3,1,0]，从左到右迭代，求第一个i使得`nums[i]<i`，实现还是比较简单的，参见具体代码。<br>
**实现代码**
```java
public int hIndex(int[] citations) {
    if (citations == null || citations.length == 0) {
        return 0;
    }
    Arrays.sort(citations);
    //        针对int[]数组，从大到小不能自定义排序，因此考虑从小到大，然后做部分调整
    int ret = 0;
    int length = citations.length;
    for (int i = length - 1; i >= 0; i--) {
        if (citations[i] >= length - i) {
            ret++;
        } else {
            break;
        }
    }

    return ret;
}
```

#### [H-Index II](https://leetcode.com/problems/h-index-ii/description/)
**解题思路**
如果输入的citations已经排序好了，需要提高查找效率的话，考虑使用二分法，查找第一个满足`nums[i]<i`。<br>
**实现代码**
```java
public int hIndex(int[] citations) {
    if (citations == null || citations.length == 0) {
        return 0;
    }

    int length = citations.length;
    int left = 0;
    int right = length - 1;
    while (left <= right) {
        int mid = (left + right) >> 1;
//            即使数组中出现重复的现象，也可以直接返回，因为下一次迭代，nums[i]--,但是hIndex++
        if (citations[mid] == length - mid) {
            return length - mid;
        } else if (citations[mid] > length - mid) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return length - left;
}
```

#### [Largest Number](https://leetcode.com/problems/largest-number/description/)
**解题思路**
自定义排序规则，使用字典序排序即可。<br>
**实现代码**
```java
public String largestNumber(int[] nums) {
    if(nums == null || nums.length ==0){
        return "";
    }

    int length = nums.length;
    String[] strings = new String[length];
    for (int i = 0; i < length; i++) {
        strings[i] = ""+nums[i];
    }

//        自定义字典序排序规则
    Arrays.sort(strings, new Comparator<String>() {
//         默认系统调用比较的是 (o1+o2).compareTo(o2+o1)
        @Override
        public int compare(String o1, String o2) {
            return (o2+o1).compareTo(o1+o2);
        }
    });

//        0开头，整个数组都是0
    if(strings[0].equals("0")){
        return "0";
    }

    return String.join("",strings);
}
```

---
#### [Sort List](https://leetcode.com/problems/sort-list/description/)
**解题思路**
在O(nlogn)的时间复杂度进行排序，常见有快排、堆排和归并排序；前两者对元素的下标操作要求较为灵活，
选择归并排序。先不断split,后调用merge归并<br>
**实现代码**
```java
public ListNode sortList(ListNode head){
    if(head == null || head.next == null){
        return head;
    }
    ListNode mid = split(head);
    ListNode node1 = sortList(head);
    ListNode node2 = sortList(mid);
   return mergeTwoLists(node1,node2);
}

private ListNode split(ListNode head){
    if(head == null || head.next==null){
        return head;
    }
    
//        设置快慢指针
    ListNode fast = head;
    ListNode slow = head;
    ListNode slowPre = null;
    while(fast!=null && fast.next!=null){
        fast = fast.next.next;
        slowPre = slow;
        slow = slow.next;
    }
    
    slowPre.next = null;
    return slow;
}

public static ListNode mergeTwoLists(ListNode l1, ListNode l2) {
//        check validation
    if (l1 == null && l2 == null) {
        return null;
    } else if (l1 == null) {
        return l2;
    } else if (l2 == null) {
        return l1;
    }

//        设置临时节点
    ListNode tmpHead = new ListNode(0);
    ListNode cur = tmpHead;

    ListNode p = l1;
    ListNode q = l2;
    while (p != null && q != null) {
        if (p.val <= q.val) {
            cur.next = p;
            p = p.next;
        } else {
            cur.next = q;
            q = q.next;
        }
        cur = cur.next;
    }
//        剩余部分合并
    if (p != null) {
        cur.next = p;
    }
    if (q != null) {
        cur.next = q;
    }
    return tmpHead.next;
}
```


---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)