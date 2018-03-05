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
### mybatis原理简介和基本使用

mybatis是一个持久层框架，其核心是输入映射和输出映射
![](/img/sql/mybatis/workflow.png)

#### mybatis工作环境搭建
本文主要讲解独立mybatis工程使用，没有结合spring(参见[下一篇](http://julyerr.club/2018/03/05/mybatis-sumuptwo/#mybatis和spring框架集成))

1.加入依赖包mybatis.jar以及mysql-connector-java.jar，为了显示日志信息推荐使用log4j.jar

2.**mybatis配置**<br>
    单独使用mybatis需要配置MybatisConfiguration.xml文件，如果使用了spring只需要配置映射实体类映射即可。
```xml
<!--如果使用spring，该配置交由sprig负责-->
<environments default="development">
    <environment id="development">
        <!-- 使用jdbc事务管理，目前由mybatis来管理 -->
        <transactionManager type="JDBC"/>
        <!-- 数据库连接池，目前由mybatis来管理 -->
        <dataSource type="POOLED">
        <property name="driver" value="com.mysql.jdbc.Driver"/>
        <property name="url" value="jdbc:mysql://localhost:3306/demo"/>
        <property name="username" value="root"/>
        <property name="password" value="root"/>
        </dataSource>
    </environment>
</environments>

<typeAliases>
        <!--<package name="com.julyerr.interviews.sql.mybatis.po"/>-->
        <typeAlias alias="User" type="com.julyerr.interviews.sql.mybatis.po.User"/>
</typeAliases>

<mappers>
    <!--<package name="sqlMap"/>-->
    <mapper resource="sqlMap/User.xml"/>
</mappers>
```

**常见属性配置说明**

- `<environment>`元素是配置数据库,可以设置不同的id选择使用
- typeAliases：方便在配置文件中引用类，不用书写全路径名称，直接使用别名。类种数太多，可以设置package属性
- mappers：说明实体类的路径。mapper文件太多，可以设置mapper的package属性。

3.**相关数据表的创建**

```sql
CREATE TABLE `user` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(32) NOT NULL COMMENT '用户名称',
  `birthday` DATE DEFAULT NULL COMMENT '生日',
  `sex` CHAR(1) DEFAULT NULL COMMENT '性别',
  `address` VARCHAR(256) DEFAULT NULL COMMENT '地址',
  PRIMARY KEY (`id`)
) ENGINE=INNODB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;

insert into user(username,birthday,sex,address) values("张三1","1990-09-19","男","同济大学");
insert into user(username,birthday,sex,address) values("张三2","1990-09-19","男","同济大学");
```

4.**po 类**

```java
public class User{
    private Integer id;
    private String username;
    private Date birthday;
    private String sex;
    private String address;
    //getter & setter
}
```

5.**User.xml配置映射文件**

```xml
<mapper namespace="test">
    <!-- 需求：通过id查询用户 -->
    <select id="findUserById" parameterType="int" resultType="com.julyerr.interviews.sql.mybatis.po.User">
        select * from user where id = #{id}
    </select>

    <!-- 添加用户 -->
    <insert id="insertUser" parameterType="com.julyerr.interviews.sql.mybatis.po.User">
        insert into user(username,birthday,sex,address) values(#{username},#{birthday},#{sex},#{address})
    </insert>
</mapper>
```

mybatis提供了非常灵活的sql书写方式，除了常见的`<select>`、`<delete>`、`<update>`等，
还提供动态sql的支持（参加后文）以及输入和输出类型映射（参见后文）。

6.dao层接口以及实现

```java
public interface UserDao {
    //根据id查询用户信息
    public User findUserById(int id) throws Exception;
    //添加用户信息
    public void insertUser(User user) throws Exception;
    //...
}
```

```java
public class UserDaoImpl implements UserDao {
    private SqlSessionFactory sqlSessionFactory;
    //需要向dao实现类中注入SqlSessionFactory，由于没和Spring整合，这里通过构造函数注入
    public UserDaoImpl(SqlSessionFactory sqlSessionFactory) {
        this.sqlSessionFactory = sqlSessionFactory;
    }
    @Override
    public User findUserById(int id) throws Exception {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        User user = sqlSession.selectOne("test.findUserById", id);
        //释放资源
        sqlSession.close();
        return user;
    }
    @Override
    public void insertUser(User user) throws Exception {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        sqlSession.insert("test.insertUser", user);
        sqlSession.commit();//执行插入要先commit
        sqlSession.close();
    }
    //...
}
```

7.测试文件

```java
public class MybatisDemo1Test {
    private SqlSessionFactory sqlSessionFactory;

    @Before
    public void setUp() throws Exception {
        //创建sqlSessionFactory
        String resource = "MybatisConfiguration.xml"; //mybatis配置文件

        //得到配置文件的流
        InputStream inputStream = Resources.getResourceAsStream(resource);

        //创建会话工厂SqlSessionFactory,要传入mybaits的配置文件的流
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);

    }

    @Test
    public void testFindUserById() throws Exception {
        //创建UserDao的对象
        UserDao userDao = new UserDaoImpl(sqlSessionFactory);
        System.out.println(userDao.findUserById(1));
    }
}
```

以上只是粘贴核心代码，完整代码示例[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/sql/mybatis/)以及对应的test文件。

---
#### 输入映射和输出映射

**输入映射**<br>
`parameterType`指定输入参数的类型，类型可以是简单类型、hashmap、pojo的包装类型.<br>
需要传入查询条件很复杂（可能包括用户信息、其它信息，比如商品、订单的），那么我们单纯的传入一个User就不行了，所以首先我们得根据查询条件，自定义一个新的pojo，在这个pojo中包含所有的查询条件。<br>

**输出映射**<br>
resultType指定输出的类型，但是要求pojo列名和pojo中对应的属性名要一致才可以做正确的映射；
使用resultMap可以实现自定义映射关系。<br>

拥有下面常见的属性：

- id：必填属性，且唯一，在select标签中，resultMap指定的值就是id值
- type：必填属性，用于配置查询列所映射到的Java对象类型
- extends：可填属性，表明该resultMap继承自哪个resultMap

常见的标签

- id：一个id结果，标记结果作为id（唯一值）
- result：注入到Java对象属性的普通结果
- association：一个复杂的类型关联，许多结果将包成该类型
- collection：复杂类型的集合

```xml
<select id="findUserByIdResultMap" parameterType="int" resultMap="userResultMap">
        SELECT id id_,username username_ from user where id = #{id}
</select>
<resultMap type="user" id="userResultMap">
    <id column="id_" property="id"/>
    <result column="username_" property="username"/>
</resultMap>
```

关联关系配置参见后文的一对一、一对多配置<br>



**mybatis**优势<br>

- 使用数据库连接池管理数据库的连接提高资源利用效率
- 把sql语句放在xml配置文件中，修改sql语句也不需要重新编译java代码 
- 查询的结果集，自动映射成 java对象

下一篇[参见](http://julyerr.club/2018/03/05/mybatis-sumuptwo/)

---
### 参考资料
- [mybatis知识点总结和梳理](http://blog.csdn.net/jaryle/article/details/51228751)
- [Spring之——c3p0配置详解](http://blog.csdn.net/l1028386804/article/details/51162560)
- [使用Spring JDBCTemplate简化JDBC的操作](http://www.cnblogs.com/lichenwei/p/3902294.html)
- [使用Spring JDBC框架连接并操作数据库](http://blog.csdn.net/wanghuiqi2008/article/details/46239753)
- [MyBatis 学习](http://blog.csdn.net/column/details/smybatis.html)