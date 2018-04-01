---
layout:     post
title:      "面试编程题 stack 篇"
subtitle:   "面试编程题 stack 篇"
date:       2018-03-07 6:00:00
author:     "julyerr"
header-img: "img/ds/stack/stack.png"
header-mask: 0.5
catalog: 	true
tags:
    - interview
    - targetOffer
    - leetcode
    - 牛客网
    - stack
---

#### [Implement Queue using Stacks](https://leetcode.com/problems/implement-queue-using-stacks/description/)
**解题思路**
使用两个队列实现栈<br>
**实现代码**
```java
public class MyQueue {

    private Stack<Integer> stack1;
    private Stack<Integer> stack2;
    private int length;

    /**
     * Initialize your data structure here.
     */
    public MyQueue() {
        stack1 = new Stack<>();
        stack2 = new Stack<>();
    }

    /**
     * Push element x to the back of queue.
     */
    public void push(int x) {
        stack1.push(x);
        length++;
    }

    /**
     * Removes the element from in front of queue and returns that element.
     */
    public int pop() {
        if (length == 0) {
            return -1;
        }
        length--;
        if (!stack2.isEmpty()) {
            return stack2.pop();
        } else {
            while (!stack1.isEmpty()) {
                stack2.add(stack1.pop());
            }
        }
        return stack2.pop();
    }

    /**
     * Get the front element.
     */
    public int peek() {
        if (length == 0) {
            return -1;
        }
        if (!stack2.isEmpty()) {
            return stack2.peek();
        } else {
            while (!stack1.isEmpty()) {
                stack2.add(stack1.pop());
            }
        }
        return stack2.peek();
    }

    /**
     * Returns whether the queue is empty.
     */
    public boolean empty() {
        return length == 0;
    }
}
```

#### [Implement Stack using Queues](https://leetcode.com/problems/implement-stack-using-queues/description/)
**解题思路**
java中的LinkedList是一个双向链表，可以实现stack的功能<br>
**实现代码**
```java
public class MyStack {
    private LinkedList<Integer> queue ;
    /** Initialize your data structure here. */
    public MyStack() {
        queue = new LinkedList<>();
    }

    /** Push element x onto stack. */
    public void push(int x) {
        queue.add(x);
    }

    /** Removes the element on top of the stack and returns that element. */
    public int pop() {
        if(queue.isEmpty()){
            return -1;
        }
        return queue.removeLast();
    }

    /** Get the top element. */
    public int top() {
        return queue.peekLast();
    }

    /** Returns whether the stack is empty. */
    public boolean empty() {
        return queue.isEmpty();
    }
}
```

---
#### [Min Stack](https://leetcode.com/problems/min-stack/description/)
**解题思路**
在O(1)的时间复杂度得到栈中的最小值，空间换时间，可以设置一个包含最小值的栈，pop的时候注意更新。<br>
**实现代码**
```java
public class MinStack {
    private Stack<Integer> stack;
    private Stack<Integer> minStack;

    public MinStack() {
        stack = new Stack<>();
        minStack = new Stack<>();
    }

    public void push(int x) {
        stack.push(x);
//        只有非空或者更小值或者重复的值出现情况才压入
        if (minStack.isEmpty() || x <= minStack.peek()) {
            minStack.push(x);
        }
    }

    public void pop() {
        if (stack.isEmpty()) {
            return;
        }
        int tmp = stack.pop();
//        pop的是当前栈顶才pop
        if (tmp == minStack.peek()) {
            minStack.pop();
        }
    }

    public int top() {
        if (stack.isEmpty()) {
            return -1;
        }
        return stack.peek();
    }

    public int getMin() {
        if (minStack.isEmpty()) {
            return -1;
        }
        return minStack.peek();
    }
}
```

---
#### [Valid Parentheses](https://leetcode.com/problems/valid-parentheses/description/)
**解题思路**
使用栈结构，出现']'或者')'便判断栈顶元素是否是'['或者'('，不是则返回错误；是则进行弹出操作。<br>
**实现代码**
```java
public boolean isValid(String s) {
    if (s == null || s.length() < 2) {
        return false;
    }

    Stack<Character> stack = new Stack<>();
    for (int i = 0; i < s.length(); i++) {
        char c = s.charAt(i);
        if (c == '(' || c == '[' || c == '{') {
            stack.push(c);
        } else {
            if (stack.isEmpty()) {
                return false;
            }
            if (c == ']') {
                if (stack.pop() != '[') {
                    return false;
                }
            } else if (c == ')') {
                if (stack.pop() != '(') {
                    return false;
                }
            } else {
                if (c == '}') {
                    if (stack.pop() != '{') {
                        return false;
                    }
                }
            }
        }
    }
    return stack.isEmpty();
}
```

---
### 表达式计算系列
#### [Basic Calculator](https://leetcode.com/problems/basic-calculator/description/)
**解题思路**
典型的使用stack解题，可以设置符号、操作数两个栈，但是维护起来较为麻烦。
参考大神的解题思路只需要维持一个操作数栈即可，遇到'('将先前计算结果压入，遇到')'则将操作数弹出并计算。
<br>
**实现代码**
```java
public int calculate(String s) {
//        check validation
    if (s == null || s.length() == 0) {
        return 0;
    }

//        计算结果
    int ret = 0;
//        后面的操作数是否是有符号
    int signed = 1;
//        操作数栈
    Stack<Integer> ops = new Stack<>();

    int length = s.length();
    //        迭代整个字符串
    for (int i = 0; i < length; i++) {
        char c = s.charAt(i);
        if (c == '+') {
            signed = 1;
        } else if (c == '-') {
            signed = -1;
        } else if (Character.isDigit(c)) {
            int tmp = c - '0';
            while (i + 1 < length && Character.isDigit(s.charAt(i + 1))) {
                tmp *= 10 + s.charAt(++i) - '0';
            }
            ret += signed * tmp;

//               压栈操作
        } else if (c == '(') {
            ops.push(ret);
            ops.push(signed);
//                重新进行下轮计算
            ret = 0;
            signed = 1;
//                合并计算结果
        } else if (c == ')') {
            ret = ret * ops.pop() + ops.pop();
            signed = 1;
        }
    }
    return ret;
}
```

#### [Basic Calculator II](https://leetcode.com/problems/basic-calculator-ii/description/)
**解题思路**
相对于第一道题目而言，没有括号的限制，但是有操作符的优先级。
可以将乘除操作和加减操作分隔，第一遍的时候计算出乘除，后面计算加减即可。
计算加减的时候，由于栈的入栈和出栈的顺序相反，符号操作有正负，因此需要反转整个stack.<br>
**实现代码**
```java
public int calculate(String s) {
    if (s == null || s.length() == 0) {
        return 0;
    }


    int length = s.length();
//        使用一个stack的时候，需要将符号表示为数字存储
    Stack<Integer> stack = new Stack<>();
    for (int i = 0; i < length; i++) {
        char c = s.charAt(i);
        if (Character.isDigit(c)) {
            int tmp = c - '0';
            while (i + 1 < length && Character.isDigit(s.charAt(i + 1))) {
//                    tmp *= 10+s.charAt(++i)-'0' 出错，先计算10+s.char(++i)-'0'后才是相乘操作
                tmp = tmp * 10 + s.charAt(++i) - '0';
            }
//                进行乘除运算
            if (!stack.isEmpty() && (stack.peek() == 2 || stack.peek() == 3)) {
                int sign = stack.pop();
                int val = stack.pop();

                if (sign == 2) {
                    val = val * tmp;
                } else {
                    val = val / tmp;
                }
                stack.push(val);
            } else {
                stack.push(tmp);
            }
        } else {
            switch (c) {
                case '+':
                    stack.push(0);
                    break;
                case '-':
                    stack.push(1);
                    break;
                case '*':
                    stack.push(2);
                    break;
                case '/':
                    stack.push(3);
                    break;
            }
        }
    }

//        进行加减运算,出栈和入栈顺序相反
    Collections.reverse(stack);

    if (stack.isEmpty()) {
        return 0;
    }

//        重复利用已经计算好的结果
    int ret = stack.pop();
    while (!stack.isEmpty()) {
        int signed = stack.pop();
        int b = stack.pop();
        if (signed == 0) {
            ret += b;
        } else {
            ret -=b;
        }
    }
    return ret;
}
```

---
#### [Evaluate Reverse Polish Notation](https://leetcode.com/problems/evaluate-reverse-polish-notation/description/)
**解题思路**
逆波兰表达式，只需要设置一个栈。如果是数字直接入栈，符号数出栈进行操作，后压栈。<br>
**实现代码**
```java
public int evalRPN(String[] tokens) {
    if (tokens == null || tokens.length == 0) {
        return 0;
    }

    Stack<Integer> stack = new Stack<>();
    for (int i = 0; i < tokens.length; i++) {
        String s = tokens[i];
        if (s.equals("+")) {
            int a = stack.pop();
            int b = stack.pop();
            stack.push(a + b);
        } else if (s.equals("-")) {
            int a = stack.pop();
            int b = stack.pop();
            stack.push(b - a);
        } else if (s.equals("*")) {
            int a = stack.pop();
            int b = stack.pop();
            stack.push(a * b);
        } else if (s.equals("/")) {
            int a = stack.pop();
            int b = stack.pop();
            stack.push(b / a);
        } else {
            stack.push(Integer.parseInt(s));
        }
    }
    return stack.pop();
}
```

---
#### [Simplify Path](https://leetcode.com/problems/simplify-path/description/)
**解题思路**
现将输入的字符串通过'/'进行划分，划分之后针对字符串数组进行判断；
'.'不作处理，'..'需要进行pop操作。<br>
**实现代码**
```java
public String simplifyPath(String path) {
    if (path == null || path.length() == 0) {
        return "";
    }

    String[] strings = path.split("/");
    Stack<String> stack = new Stack<>();
    for (int i = 0; i < strings.length; i++) {
        String s = strings[i];
//            不进行处理
        if (s.equals("") || s.equals(".")) {
            continue;
        } else if (s.equals("..")) {
            if (!stack.isEmpty()) {
                stack.pop();
            }
        } else {
            stack.push(s);
        }
    }

//        如果出现空的情况
    if (stack.isEmpty()) {
        return "/";
    }

//        栈和正常的顺序相反
    Collections.reverse(stack);
    StringBuilder stringBuilder = new StringBuilder();
    while (!stack.isEmpty()) {
        stringBuilder.append("/");
        stringBuilder.append(stack.pop());
    }
    return stringBuilder.toString();
}
```

---
### 参考资料
- [剑指offer（第二版）java实现导航帖](https://www.jianshu.com/p/010410a4d419)
- [LeetCode题解](https://www.zybuluo.com/Yano/note/253649)
- [牛客网](https://www.nowcoder.com/5312575)