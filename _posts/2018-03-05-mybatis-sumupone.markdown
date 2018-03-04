---
layout:     post
title:      "mybatis 总结一"
subtitle:   "mybatis 总结一"
date:       2018-03-04 12:00:00
author:     "julyerr"
header-img: "img/sql/mybatis/mybatis.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - sql
    - mybatis
---

>本文先对spring 中数据库访问支持和mybatis的工作原理进行简单介绍，然后对mybatis常见使用进行总结，后文blog会加以介绍mybatis、spring和springmvc框架集成等。

### spring 对数据库操作
使用jdbc操作数据库，连接和关闭数据库等操作占据很大代码量；spring中提供JDBC框架，借助jdbcTemplate，我们只需要关注数据库操作，其他连接和释放数据库等均由spring自动处理。<br>

为了节省篇幅，不对具体的代码粘贴出来，后面有本示例项目的所有代码。因此只对较为重要的部分进行介绍。<br>

1.**编写model**<br>

2.**编写dao层**<br>
**jdbcTemplate常见类接口和方法**<br>

- execute方法：可以用于执行任何SQL语句，一般用于执行DDL语句；
- update方法: 用于执行新增、修改、删除等语句；
- batchUpdate: batchUpdate方法用于执行批处理相关语句；
- call方法：用于执行存储过程、函数相关语句.
- query方法及queryForXXX方法：用于执行查询相关语句；

简单查询，返回原始数据类型， String类型

```java
// int queryForInt(String sql)
String sql = "select count(*) from user"; 
// <T> T queryForObject(String sql, Class<T> requiredType, Object... args)
String sql = "select name from user where id = ? "; 
```

复杂查询,手动完成对象封装,例如

```java
public class StudentMapper implements RowMapper<Student> {

    public Student mapRow(ResultSet rs, int rownum) throws SQLException {
        Student student = new Student();
        student.setID(rs.getString("ID"));
        student.setname(rs.getString("name"));
        student.setage(rs.getInt("age"));
        student.setFM(rs.getString("FM"));

        return student;
    }
}
```	

查询单个或者多个对象: 

```java
public <T> List<T> query(String sql, Object[] args, RowMapper<T> rowMapper)
public <T> T queryForObject(String sql, RowMapper<T> rowMapper, Object... args)
```

如下的示例

```java
public interface StudentDao {
    public void setDataSource(DataSource ds);
    public void addstudent(Student student);
    public void delstudentbyID(String ID);
    public void delstudentbyname(String name);
    public void delallstudent();
    public void updstudent(Student student);
    public List<Student> allstudent();
    public List<Student> querystudentbyID(String ID);
    public List<Student> querystudentbyname(String name);
    public List<Student> querystudentbyage(int age);
}
```
```java
public class StudentDaoImpl implements StudentDao {
//    属性注入	
    private DataSource datasource;
    private JdbcTemplate jdbcTemplateObject;

    public DataSource getDatasource() {
        return datasource;
    }

    public void setDataSource(DataSource ds) {
        this.datasource = datasource;
    }

    public JdbcTemplate getJdbcTemplateObject() {
        return jdbcTemplateObject;
    }

    public void setJdbcTemplateObject(JdbcTemplate jdbcTemplateObject) {
        this.jdbcTemplateObject = jdbcTemplateObject;
    }

    public void addstudent(Student student) {
        String sql = "INSERT INTO student(ID,name,age,FM)VALUES(?,?,?,?)";

        jdbcTemplateObject.update(sql, student.getID(),
                student.getname(),student.getage(),student.getFM());
        return ;
    }

    public void delstudentbyID(String ID) {
        String sql = "DELETE FROM student WHERE ID=?";
        jdbcTemplateObject.update(sql,ID);
        return ;
    }

    public void delstudentbyname(String name) {
        String sql = "DELETE FROM student WHERE name=?";
        jdbcTemplateObject.update(sql,name);
        return ;
    }

    public void delallstudent() {
        String sql = "DELETE FROM student";
        jdbcTemplateObject.update(sql);
        return ;
    }

    public void updstudent(Student student) {
        String sql = "UPDATE student set name=?,age=?,FM=? WHERE ID=?";
        jdbcTemplateObject.update(sql,student.getname(),
                student.getage(),student.getFM(),student.getID());
        return ;
    }

    public List<Student> allstudent() {
        List<Student> students = null;
        String sql = "SELECT * FROM student";
        students = jdbcTemplateObject.query(sql, new StudentMapper());
        return students;
    }

    public List<Student> querystudentbyID(String ID) {
        List<Student> students = null;
        String sql = "SELECT * FROM student WHERE ID=?";
        students = jdbcTemplateObject.query(sql, new Object[]{ID}, new StudentMapper());
        return students;
    }

    public List<Student> querystudentbyname(String name) {
        List<Student> students = null;
        String sql = "SELECT * FROM student WHERE name=?";
        students = jdbcTemplateObject.query(sql, new Object[]{name}, new StudentMapper());
        return students;
    }

    public List<Student> querystudentbyage(int age) {
        List<Student> students = null;
        String sql = "SELECT * FROM student WHERE age=?";
        students = jdbcTemplateObject.query(sql, new Object[]{age}, new StudentMapper());
        return students;
    }

    public void displayall(){
        List<Student> students = allstudent();
        for(Student s : students){
            s.display();
        }
    }
}
```

3.**配置dataSource**<br>


```xml
<!--使用c3p0数据库管理容器-->
<bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource" destroy-method="close">
    <property name="driverClass" value="com.mysql.jdbc.Driver"></property>
    <property name="jdbcUrl" value="jdbc:mysql://localhost:3306/demo"></property>
    <property name="user" value="root"></property>
    <property name="password" value="root"></property>

    <!-- 连接池参数 -->
    <property name="minPoolSize" value="3"></property>
    <property name="maxPoolSize" value="12"></property>
    <property name="initialPoolSize" value="5"></property>
    <!--最大空闲等待时间-->
    <property name="maxIdleTime" value="60"></property>

</bean>

<!--jdbcTemplate bean-->
<bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
    <property name="dataSource" ref="dataSource"></property>
</bean>

<!--studentDao层操作依赖jdbcTemplate-->
<bean id="studentDaoImpl"
      class="com.julyerr.jdbcTemplate.dao.Impl.StudentDaoImpl">
    <property name="dataSource" ref="dataSource"/>
    <property name="jdbcTemplateObject" ref="jdbcTemplate"/>
</bean>
```

4.**编写测试用例**<br>

[示例项目的代码参见](https://github.com/julyerr/springdemo/tree/master/src/main/java/com/julyerr/jdbcTemplate)

---
### mybatis工作原理

mybatis是一个持久层框架，其核心是输入映射和输出映射
![](/img/sql/mybatis/workflow.png)




**mybatis**优势<br>

- 使用数据库连接池管理数据库的连接提高资源利用效率
- 把sql语句放在xml配置文件中，修改sql语句也不需要重新编译java代码 
- 查询的结果集，自动映射成 java对象



---
### 参考资料
- [mybatis知识点总结和梳理](http://blog.csdn.net/jaryle/article/details/51228751)
- [Spring之——c3p0配置详解](http://blog.csdn.net/l1028386804/article/details/51162560)
- [使用Spring JDBCTemplate简化JDBC的操作](http://www.cnblogs.com/lichenwei/p/3902294.html)
- [使用Spring JDBC框架连接并操作数据库](http://blog.csdn.net/wanghuiqi2008/article/details/46239753)