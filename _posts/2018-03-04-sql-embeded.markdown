---
layout:     post
title:      "java 操作sql和nosql"
subtitle:   "java 操作sql和nosql"
date:       2018-03-04 6:00:00
author:     "julyerr"
header-img: "img/sql/sql-opt.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - sql
    - nosql
---

>本文总结java对sql和nosql常见操作

### sql操作
首先需要加载对应的jar包(mysql-connector-java)

1.**加载JDBC驱动程序**

```java
try{              
    Class.forName("com.mysql.jdbc.Driver");  
}catch(ClassNotFoundException e){  
    System.out.println("No jdbc driver");  
    e.printStackTrace();  
}  
```

2.**提供JDBC连接的URL**

```java
String url="jdbc:mysql://localhost:3306/mysql?useUnicode=true&characterEncoding=utf-8";  
String username = "root";  
String password = "julyerr";  
```

3.**创建数据库的连接**
DriverManager的getConnectin(String url , String username , String password )返回一个数据库连接
```java
try{  
    Connection con = DriverManager.getConnection(url,username,password);              
}catch(SQLException e){  
    System.out.println("Database connect failure!");  
    e.printStackTrace();  
}  
```

4.**创建Statement**<br>
通常有以下三种类型
	
- 通过Statement实例,执行静态SQL语句
- 通过PreparedStatement实例,执行动态SQL翑语句
- 通过CallableStatement实例，执行数据库的存储过程
	
```java
try{  
    Statement stmt = con.createStatement();  
}catch(SQLException e){  
    System.out.println("Statement create failure!");  
    e.printStackTrace();  
}  
```

5.**执行SQL语句**<br>

Statement接口提供了三种执行SQL语句的方法：executeQuery 、executeUpdate和execute
	
- ResultSet executeQuery(String sqlString)：执行查询数据库的SQL语句，返回一个结果集（ResultSet）对象
- int executeUpdate(String sqlString)：用于执行INSERT、UPDATE或DELETE语句以及SQL DDL语句，如：CREATE TABLE和DROP TABLE等
- execute(sqlString):用于执行返回多个结果集、多个更新计数或二者组合的语句

```java
ResultSet rs = stmt.executeQuery("SELECT * FROM ...");     
int rows = stmt.executeUpdate("INSERT INTO ...");     
boolean flag = stmt.execute(String sql);    
```	

6.**处理结果**<br>

有两种操作方式
	
- 执行更新返回的是本次操作影响到的记录数
- 执行查询返回的结果是一个ResultSet对象（较为常用）

```java
while(rs.next()){  
    String qname = rs.getString("name");  
    String qage = rs.getString(3);  //此种方法比较高效，列是从左向右编号的，编号从1开始
    System.out.println(qname + " " + qage);  
}  
```	

7.**关闭JDBC对象**<br>

将所有使用的JDBC对象（记录集、声明、连接对象等）全都关闭，打开和断开操作开销较大，实际开发中通常使用数据连接池提高性能，参见后文

```java
try{  
    if(rs != null){  
        rs.close();  
    }  
    if(stmt != null){  
        stmt.close();  
    }  
    if(con != null){  
        con.close();  
    }             
}catch(SQLException e){  
    e.printStackTrace();  
}     
```

[示例的demo代码文件](https://github.com/julyerr/collections/tree/master/java/src/com/julyerr/interviews/sql/jdbc/)

---
### 数据库连接池

创建connection是一个非常浪费时间的过程，而且操作过程中没有必要关闭连接。为提升性能，需要专门管理
数据库连接的容器(c3p0，druid等)。
![](/img/sql/pool.png)

上图展示了连接池使用注意点，调用Connection的close()方法也不会真的关闭Connection，而是把Connection“归还”给池。

#### 连接池通用的配置和使用

- 初始大小：数据库连接池创建时，可以获取到的连接数
- 最小空闲连接数
- 最大空闲连接数
- 增量：当空闲连接数不足的时候，一次增加的连接数量
- 最大连接数：数据库连接池的容量
- 最大的等待时间：当连接池中所有连接都使用完毕之后，外界还需要申请连接允许等待的最长时间

有多种第三方数据库连接池管理软件，如下是它们直接的对比情况
![](/img/sql/pool-compare.png)

下面以c3p0(较为常用)展示使用方式<br>

1.导入c3p0的包
2.获取连接池对象
3.配置数据库连接池（可以基于代码，或者基于xml配置文件）
4.获取数据库连接，其他使用方式和正常数据库操作没有什么太大的区别

```java
public class Demo1 {
    private static String url = "jdbc:mysql://localhost:3306/";
    private static String user = "root";
    private static String password = "root";
    private static String driverClass = "com.mysql.jdbc.Driver";


    public static void main(String[] args) throws Exception {
        //1)创建连接池对象
        ComboPooledDataSource cds = new ComboPooledDataSource();
        
        //2)设置连接参数
        cds.setJdbcUrl(url);
        cds.setUser(user);
        cds.setPassword(password);
        cds.setDriverClass(driverClass);
        
        //3)设置连接池相关的参数
        cds.setInitialPoolSize(5);//初始化连接数
        cds.setMaxPoolSize(10);//最大连接数
        cds.setCheckoutTimeout(3000);//最大等待时间
        cds.setMinPoolSize(3); //最小连接数
        
        //4)获取连接
        for(int i=1;i<=11;i++){
            Connection conn = cds.getConnection();
            System.out.println(conn);
            
            //关闭第3个
            if(i==3){
                conn.close();//本质是把连接对象放回连接池中
            }
        }
    }
    
}
```

基于xml的配置方式，参见[spring与c3p0集成](http://julyerr.club/2018/03/04/mybatis-sumupone/#spring-对数据库操作)。

---
### 参考资料
- [JAVA通过JDBC连接并操作MySQL数据库](http://blog.csdn.net/wanghuiqi2008/article/details/46238457)
- [Java常用的数据库连接池【c3p0】【dbcp】](http://blog.csdn.net/marvel__dead/article/details/73470153)
- [07 c3p0 连接池的使用](https://www.jianshu.com/p/52581d64e503)