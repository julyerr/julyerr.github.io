---
layout:     post
title:      "java 常见设计模式二"
subtitle:   "java 常见设计模式二"
date:       2018-03-26 12:00:00
author:     "julyerr"
header-img: "img/lib/designPattern/designPattern.png"
header-mask: 0.5
catalog: 	true
tags:
    - designPattern
---

>继续设计模式的学习，很多内容参考自[1]

### 策略模式

定义了算法族，分别封装起来，让它们之间可相互替换，此模式让算法的变化独立于使用算法的客户。<br>

下面以游戏角色为例，每个游戏角色有自己的名称、攻击、防御、展示方法。如果游戏角色很多的话，创建不同的类是不现实的，需要充分返回接口的强大之处.<br>

**三个接口**

```java
public interface IDefendBehavior{
    void defend();
}

public interface IAttackBehavior {
    void attack();
}


public interface IDisplayBehavior {
    void display();
}

```

**接口实现类**

```java
public class DefendTBS implements IDefendBehavior {
    @Override
    public void defend() {
        System.out.println("铁布衫");
    }
}

public class AttackJY implements IAttackBehavior {
    @Override
    public void attack() {
        System.out.println("九阳神功！");
    }
}

public class DisplayHMG implements IDisplayBehavior {
    @Override
    public void display() {
        System.out.println("蛤蟆功");
    }
}
```

**角色抽象类**

```java
public abstract class Role {
    protected String name;

    protected IDefendBehavior defendBehavior;
    protected IDisplayBehavior displayBehavior;
    protected IAttackBehavior attackBehavior;

    public void setName(String name) {
        this.name = name;
    }

    public void setDefendBehavior(IDefendBehavior defendBehavior) {
        this.defendBehavior = defendBehavior;
    }

    public void setDisplayBehavior(IDisplayBehavior displayBehavior) {
        this.displayBehavior = displayBehavior;
    }

    public void setAttackBehavior(IAttackBehavior attackBehavior) {
        this.attackBehavior = attackBehavior;
    }

    protected void display(){
        displayBehavior.display();
    }


    protected void attack() {
        attackBehavior.attack();
    }

    protected void defend(){
        defendBehavior.defend();
    }
}
```

**设置不同的角色并测试**

```java
public class RoleA extends Role {
    public RoleA(String name) {
        this.name = name;
    }

    public static void main(String[] args) {

        Role roleA = new RoleA("A");

        roleA.setAttackBehavior(new AttackJY());
        roleA.setDefendBehavior(new DefendTBS());
        roleA.setDisplayBehavior(new DisplayHMG());
        System.out.println(roleA.name);
        roleA.attack();
        roleA.defend();
        roleA.display();
    }
}
```

大家可能会发现，策略模式和装饰者模式有很多类似的地方。两者不同之处在于，策略模式将所有的方法、属性等限制了，不能添加任意其他的方法（例如上面的Role抽象类）；但是装饰者模式可以动态添加任意多个的方法，具体[参见](http://julyerr.club/2018/03/07/java-design-pattern/#装饰者模式)。两者都是能够处理类数量过多的情况，但是有所偏向的。

---
### 命令行模式

将请求封装成对象，将动作请求者和动作执行者解耦.下面以家电的遥控器为例，看看命令行模式的使用<br>

**家电对象**

```java
public class Light {
    public void on(){
        System.out.println("打开电灯");
    }

    public void off(){
        System.out.println("关闭电灯");
    }
}

public class Computer {
    public void on(){
        System.out.println("打开电脑");
    }

    public void off(){
        System.out.println("关闭电脑");
    }
}
```

**不同家电执行的接口以及实现**

```java
public interface Command {
    void execute();
}

public class LightOnCommond implements Command {
    private Light light;

    public LightOnCommond(Light light) {
        this.light = light;
    }

    @Override
    public void execute() {
        light.off();
    }
}

public class LightOffCommond implements Command {
    private Light light;

    public LightOffCommond(Light light) {
        this.light = light;
    }

    @Override
    public void execute() {
        light.off();
    }
}

public class ComputerOnCommond implements Command {
    private Computer computer ;

    public ComputerOnCommond( Computer computer){
        this.computer = computer;
    }

    @Override
    public void execute(){
        computer.on();
    }

}

public class ComputerOffCommond implements Command {
    private Computer computer ;

    public ComputerOffCommond(Computer computer){
        this.computer = computer;
    }

    @Override
    public void execute(){
        computer.off();
    }

}
```

**控制面板及其测试**

```java
public class NoCommond implements Command {
    @Override
    public void execute() {

    }
}

public class ControlPanel {
    private static final int CONTROL_SIZE = 9;
    private Command[] commands;

    public ControlPanel() {
        commands = new Command[CONTROL_SIZE];
        /**
         * 初始化所有按钮指向空对象
         */
        for (int i = 0; i < CONTROL_SIZE; i++) {
            commands[i] = new NoCommond();
        }
    }

    public void setCommand(int index, Command command) {
        commands[index] = command;
    }

    public void keyPressed(int index) {
        commands[index].execute();
    }

    public static void main(String[] args)
    {

        Light light = new Light();
        Computer computer = new Computer();

        ControlPanel controlPanel = new ControlPanel();
        // 为每个按钮设置功能
        controlPanel.setCommand(0, new LightOnCommond(light));
        controlPanel.setCommand(1, new LightOffCommond(light));
        controlPanel.setCommand(2, new ComputerOnCommond(computer));
        controlPanel.setCommand(3, new ComputerOffCommond(computer));

        // 模拟点击
        controlPanel.keyPressed(0);
        controlPanel.keyPressed(2);
    }
}
```

**动态添加一个按键（快捷方式）**

```java
public class QuickCommond implements Command {
    private Command[] commands;

    public QuickCommond(Command[] commands){
        this.commands = commands;
    }

    @Override
    public void execute(){
        for (int i = 0; i < commands.length; i++){
            commands[i].execute();
        }
    }

}
```

**对控制面板文件修改**

```java
QuickCommond quickCommond = new QuickCommond(new Command[]{
                new LightOffCommond(light),
                new ComputerOnCommond(computer)
});
System.out.println("一键快捷方式");
controlPanel.setCommand(4,quickCommond);
controlPanel.keyPressed(4);
```

使用命令行设计模式很方便对多个请求进行封装，将动作请求者与动作执行者完全解耦。

---
### 外观模式

提供一个统一的接口，用来访问子系统中的一群接口。这个设计模式比较简单，通过下面这张图就能理解了。

![](/img/lib/designPattern/facade.png)

---
### 组合模式

将对象组合成树形结构以表示“部分-整体”的层次结构，使得用户对单个对象和组合对象的使用具有一致性。<br>

下面以员工以及员工下属为例，demo展示<br>

**员工的统一接口**

```java
public class Employee {
    private String name;
    private String dept;
    private int salary;
    private List<Employee> subordinates;

    //构造函数
    public Employee(String name,String dept, int sal) {
        this.name = name;
        this.dept = dept;
        this.salary = sal;
        subordinates = new ArrayList<Employee>();
    }

    public void add(Employee e) {
        subordinates.add(e);
    }

    public void remove(Employee e) {
        subordinates.remove(e);
    }

    public List<Employee> getSubordinates(){
        return subordinates;
    }

    public String toString(){
        return ("Employee :[ Name : "+ name
                +", dept : "+ dept + ", salary :"
                + salary+" ]");
    }
}
```

**测试用例**

```java
public class Test {
    public static void main(String[] args) {
        Employee CEO = new Employee("John","CEO", 30000);

        Employee headSales = new Employee("Robert","Head Sales", 20000);

        Employee headMarketing = new Employee("Michel","Head Marketing", 20000);

        Employee clerk1 = new Employee("Laura","Marketing", 10000);
        Employee clerk2 = new Employee("Bob","Marketing", 10000);

        Employee salesExecutive1 = new Employee("Richard","Sales", 10000);
        Employee salesExecutive2 = new Employee("Rob","Sales", 10000);

        CEO.add(headSales);
        CEO.add(headMarketing);

        headSales.add(salesExecutive1);
        headSales.add(salesExecutive2);

        headMarketing.add(clerk1);
        headMarketing.add(clerk2);

        //打印该组织的所有员工
        System.out.println(CEO);
        for (Employee headEmployee : CEO.getSubordinates()) {
            System.out.println(headEmployee);
            for (Employee employee : headEmployee.getSubordinates()) {
                System.out.println(employee);
            }
        }
    }
}
```

---
### 模板模式

定义了一个算法的骨架，而将一些步骤延迟到子类中，模版方法使得子类可以在不改变算法结构的情况下，重新定义算法的步骤。还是挺好理解的，下面的是程序员上班的一个例子<br>

**定义好的模板**

```java
public abstract class Worker {
    protected String name;

    public Worker(String name) {
        this.name = name;
    }

    /**
     * 记录一天的工作
     */
    public final void workOneDay() {

        System.out.println("-----------------work start ---------------");
        enterCompany();
        computerOn();
        work();
        computerOff();
        exitCompany();
        System.out.println("-----------------work end ---------------");

    }

    /**
     * 工作
     */
    public abstract void work();

    /**
     * 关闭电脑
     */
    private void computerOff() {
        System.out.println(name + "关闭电脑");
    }

    /**
     * 打开电脑
     */
    private void computerOn() {
        System.out.println(name + "打开电脑");
    }

    /**
     * 进入公司
     */
    public void enterCompany() {
        System.out.println(name + "进入公司");
    }

    /**
     * 离开公司
     */
    public void exitCompany() {
        System.out.println(name + "离开公司");
    }
}
```

**不同人员执行的工作**

```java
public class ITWorker extends Worker{

    public ITWorker(String name){
        super(name);
    }

    @Override
    public void work(){
        System.out.println(name + "写程序-测bug-fix bug");
    }

}

public class QAWorker extends Worker{

    public QAWorker(String name){
        super(name);
    }

    @Override
    public void work(){
        System.out.println(name + "写测试用例-提交bug-写测试用例");
    }

}

public class ManagerWorker extends Worker{

    public ManagerWorker(String name){
        super(name);
    }

    @Override
    public void work(){
        System.out.println(name + "打dota...");
    }

}
```

**测试**

```java
public class Test {
    public static void main(String[] args) {
        Worker it1 = new ITWorker("it1");
        it1.workOneDay();
        Worker it2 = new ITWorker("it2");
        it2.workOneDay();
        Worker qa = new QAWorker("it3");
        qa.workOneDay();
        Worker pm = new ManagerWorker("it4");
        pm.workOneDay();
    }
}
```

定义好模板，不同的人员不改变原有结构，可以实现不同的动作。

---
### 责任链模式

使多个对象都有机会处理同一个请求，从而避免请求的发送者和接收者之间的耦合关系。将这些对象连成一条链，并沿着这条链传递该请求，直到有一个对象处理它为止。<br>

下面以日志信息打印为例，demo展示 <br>

**日志打印抽象类**

```java
public abstract class AbstractLogger {
    public static int INFO = 1;
    public static int DEBUG = 2;
    public static int ERROR = 3;

    protected int level;

    //责任链中的下一个元素
    protected AbstractLogger nextLogger;

    public void setNextLogger(AbstractLogger nextLogger){
        this.nextLogger = nextLogger;
    }

    public void logMessage(int level, String message){
        if(this.level <= level){
            write(message);
        }
        if(nextLogger !=null){
            nextLogger.logMessage(level, message);
        }
    }

    abstract protected void write(String message);
}
```

**实现的三个子类**

```java
public class ConsoleLogger extends AbstractLogger {

    public ConsoleLogger(int level){
        this.level = level;
    }

    @Override
    protected void write(String message) {
        System.out.println("Standard Console::Logger: " + message);
    }
}

public class FileLogger extends AbstractLogger {

    public FileLogger(int level){
        this.level = level;
    }

    @Override
    protected void write(String message) {
        System.out.println("File::Logger: " + message);
    }
}

public class ErrorLogger extends AbstractLogger {

    public ErrorLogger(int level){
        this.level = level;
    }

    @Override
    protected void write(String message) {
        System.out.println("Error Console::Logger: " + message);
    }
}
```

**测试**

```java
public class Test {
    private static AbstractLogger getChainOfLoggers(){

        AbstractLogger errorLogger = new ErrorLogger(AbstractLogger.ERROR);
        AbstractLogger fileLogger = new FileLogger(AbstractLogger.DEBUG);
        AbstractLogger consoleLogger = new ConsoleLogger(AbstractLogger.INFO);

        errorLogger.setNextLogger(fileLogger);
        fileLogger.setNextLogger(consoleLogger);

        return errorLogger;
    }

    public static void main(String[] args) {
        AbstractLogger loggerChain = getChainOfLoggers();

        loggerChain.logMessage(AbstractLogger.INFO,
                "This is an information.");

        loggerChain.logMessage(AbstractLogger.DEBUG,
                "This is an debug level information.");

        loggerChain.logMessage(AbstractLogger.ERROR,
                "This is an error information.");
    }
}
```

通过责任链的模式，一级一级的传递下去

---
### 状态模式

当对象的内部状态改变时，它的行为跟随状态的改变而改变了，看起来好像重新初始化了一个类似的。<br>

下面以售货机的几种状态转换为例，demo展示<br>


**状态转换图**

![](/img/lib/designPattern/state-change.jpeg)

**状态接口**

```java
public interface State {
    /**
     * 放钱
     */
    void insertMoney();
    /**
     * 退钱
     */
    void backMoney();
    /**
     * 转动曲柄
     */
    void turnCrank();
    /**
     * 出商品
     */
    void dispense();
}
```

代码较长，粘贴出典型的未投币、投币，所有代码[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/chain)

```java
public class NoMoneyState implements State {
    private VendingMachine machine;

    public NoMoneyState(VendingMachine machine){
        this.machine = machine;

    }

    @Override
    public void insertMoney(){
        System.out.println("投币成功");
        machine.setState(machine.getHasMoneyState());
    }

    @Override
    public void backMoney(){
        System.out.println("您未投币，不能退钱...");
    }

    @Override
    public void turnCrank(){
        System.out.println("您未投币，不能拿东西...");
    }

    @Override
    public void dispense(){
        throw new IllegalStateException("非法状态！");
    }
}

public class HasMoneyState implements State{

    private VendingMachine machine;
    private Random random = new Random();

    public HasMoneyState(VendingMachine machine){
        this.machine = machine;
    }

    @Override
    public void insertMoney(){
        System.out.println("您已经投过币了，无需再投....");
    }

    @Override
    public void backMoney(){
        System.out.println("退币成功");

        machine.setState(machine.getNoMoneyState());
    }

    @Override
    public void turnCrank(){
        System.out.println("你转动了手柄");
        int winner = random.nextInt(10);
        if (winner == 0 && machine.getCount() > 1){
            machine.setState(machine.getWinnerState());
        } else{
            machine.setState(machine.getSoldState());
        }
    }

    @Override
    public void dispense(){
        throw new IllegalStateException("非法状态！");
    }

}
```

**售货机类**

```java
public class VendingMachine{
    private State noMoneyState;
    private State hasMoneyState;
    private State soldState;
    private State soldOutState;
    private State winnerState ;

    private int count = 0;
    private State currentState = noMoneyState;

    public VendingMachine(int count){
        noMoneyState = new NoMoneyState(this);
        hasMoneyState = new HasMoneyState(this);
        soldState = new SoldState(this);
        soldOutState = new SoldOutState(this);
        winnerState = new WinnerState(this);

        if (count > 0){
            this.count = count;
            currentState = noMoneyState;
        }
    }

    public void insertMoney(){
        currentState.insertMoney();
    }

    public void backMoney(){
        currentState.backMoney();
    }

    public void turnCrank(){
        currentState.turnCrank();
        if (currentState == soldState || currentState == winnerState){
            currentState.dispense();
        }
    }

    public void dispense() {
        System.out.println("发出一件商品...");
        if (count != 0){
            count -= 1;
        }
    }

    public void setState(State state){
        this.currentState = state;
    }

    //getter setter omitted ...
}    
```

**测试**

```java
public class Test{
    public static void main(String[] args){
        VendingMachine machine = new VendingMachine(10);
        machine.insertMoney();
        machine.backMoney();

        System.out.println("----我要中奖----");

        machine.insertMoney();
        machine.turnCrank();
        machine.insertMoney();
        machine.turnCrank();
        machine.insertMoney();
        machine.turnCrank();
        machine.insertMoney();
        machine.turnCrank();
        machine.insertMoney();
        machine.turnCrank();
        machine.insertMoney();
        machine.turnCrank();
        machine.insertMoney();
        machine.turnCrank();

        System.out.println("-------压力测试------");

        machine.insertMoney();
        machine.backMoney();
        machine.backMoney();
        machine.turnCrank();// 无效操作
        machine.turnCrank();// 无效操作
        machine.backMoney();

    }
}
```

上面所有的代码[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern)

---
### 参考资料 
[1]:https://github.com/youlookwhat/DesignPattern
- [Java 设计模式归纳](https://github.com/youlookwhat/DesignPattern)
- [设计模式](http://www.runoob.com/design-pattern/design-pattern-tutorial.html)