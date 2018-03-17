---
layout:     post
title:      "mybatis 总结三"
subtitle:   "mybatis 总结三"
date:       2018-03-15 12:00:00
author:     "julyerr"
header-img: "img/sql/mybatis/mybatis.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - sql
    - mybatis
---

>接着上篇文章的内容，这篇blog就mybatis中的逆向工程、分页插件等进行总结。

### 逆向工程

mybatis中逆向工程可以根据单表生成mapper.xml、mapper.java、po等文件，主要是减少开发人员工作量。<br>

1.**建立工程**

建议新建一个工程作为文件生成用，然后将生成文件复制到原有项目中（在原有项目中直接自动创建会有一定风险，比如名称相同文件或者目录直接被覆盖等）。

2.**加入对应的mybatis包并配置**

在mybatis基础包之上，只需要增加mybatis-generator-core.jar包（添加到maven中)。<br>

编写一个generator的xml格式的配置文件用于描述生成方式（针对哪些表、生成文件的路径之类等），如果使用idea,可以安装一个mybatis的插件，然后初始化生层模板，修改方便一点。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE generatorConfiguration PUBLIC
        "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
        "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd" >
<generatorConfiguration>

    <context id="context" targetRuntime="MyBatis3">
        <commentGenerator>
            <!--是否去除生成注释-->
            <property name="suppressAllComments" value="true"/>
            <!--是否去除生成时间-->
            <property name="suppressDate" value="true"/>
        </commentGenerator>

        <!--数据连接信息-->
        <jdbcConnection userId="root" password="root" driverClass="com.mysql.jdbc.Driver" connectionURL="jdbc:mysql://localhost:3306/demo"/>

        <javaTypeResolver>
            <!--把JDBC DECIMAL 和 NUMERIC 类型解析为 Integer，为 true时把JDBC DECIMAL和NUMERIC类型解析为java.math.BigDecimal-->
            <property name="forceBigDecimals" value="false"/>
        </javaTypeResolver>

        <!--PO对象的生成包的位置-->
        <javaModelGenerator targetPackage="com.julyerr.mybatis.model" targetProject=".">
            <property name="enableSubPackages" value="false"/>
            <!--去除数据库两端的空格-->
            <property name="trimStrings" value="true"/>
        </javaModelGenerator>

        <!--mapper.xml生成位置-->
        <sqlMapGenerator targetPackage="com.julyerr.mybatis.mapper" targetProject=".">
            <property name="enableSubPackages" value="false"/>
        </sqlMapGenerator>

        <!--mapper interface生成位置-->
        <javaClientGenerator targetPackage="com.julyerr.mybatis.mapper" type="XMLMAPPER" targetProject=".">
            <property name="enableSubPackages" value="false"/>
        </javaClientGenerator>

        <!--生成哪些表-->
        <table tableName="user" enableCountByExample="false" enableDeleteByExample="false"
               enableSelectByExample="false" enableUpdateByExample="false"/>
        <table tableName="orders" enableCountByExample="false" enableDeleteByExample="false"
               enableSelectByExample="false" enableUpdateByExample="false"/>
    </context>
</generatorConfiguration>
```

3.**编写程序启动生成过程**

```java
public class GeneratorDemo {
    public void generator() throws Exception{

        List<String> warnings = new ArrayList<String>();
//        是否对原来文件进行覆盖
        boolean overwrite = true;
        //指向逆向工程配置文件
        File configFile = new File("/home/julyerr/github/webutils/generatordemo/src/main/resources/MybatisGenerator.xml");
        ConfigurationParser cp = new ConfigurationParser(warnings);
        Configuration config = cp.parseConfiguration(configFile);
        DefaultShellCallback callback = new DefaultShellCallback(overwrite);
        MyBatisGenerator myBatisGenerator = new MyBatisGenerator(config,
                callback, warnings);
        myBatisGenerator.generate(null);

    }
    public static void main(String[] args) throws Exception {
        try {
            GeneratorDemo generatorSqlmap = new GeneratorDemo();
            generatorSqlmap.generator();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

4.**编写测试文件**

```java
public class GeneratorTest {
    private SqlSessionFactory sqlSessionFactory ;

    @Before
    public void setUp() throws IOException {
        String resource = "sqlMapConfig.xml";

//        读取配置文件
        InputStream inputStream = Resources.getResourceAsStream(resource);
//        根据配置文件生成sqlSessionFactory
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
    }

    @Test
    public void testInsertUser(){
        SqlSession sqlSession = sqlSessionFactory.openSession();
        UserMapper userMapper = sqlSession.getMapper(UserMapper.class);

        User user = new User();
        user.setId(501);
        user.setUsername("test");
        userMapper.insert(user);
        sqlSession.commit();
    }
}
```

当然事前需要将mybatis本身的配置文件设置好，同时测试出错看看生成的xml文件是否内容重复。<br>

以上完整代码[参见](https://github.com/julyerr/webutils/tree/master/generatordemo)

---
### 分页插件

**分页**<br>
    数据库查询结果只返回指定范围的数据，如 `select * from  user limit 1,5`,1表示从第一行开始（返回的行数从0开始编号），5表示返回多少行。<br>

分页有两种实现方式**逻辑分页、物理分页**，下面结合实例加以说明<br>

UserMapper.xml添加


```java
//    逻辑分页
List<User> findUsersLogic();
//    物理分页
List<User> findUsers(Map<String,Integer> stringIntegerMap);
```

UserMapper.xml

```xml
<!--逻辑分页-->
<select id="findUsersLogic" resultType="user">
    SELECT * FROM user
</select>

<!--物理分页-->
<select id="findUsers" parameterType="Map" resultType="user">
    select *
    from user LIMIT #{start},#{end};
</select>
```

**逻辑分页**<br>
    数据库实际查询获取的是所有的结果，只不过返回给用户的是指定区间的内容

```java
@Test
public void testSelectLogic() {
    SqlSession session = sqlSessionFactory.openSession();
    List<User> users = session.selectList("com.julyerr.interviews.sql.mybatis.mapper.UserMapper.findUsersLogic", new Object(),
            new RowBounds(1, 5));
    System.out.println(users);
}
```

**物理分页**<br>
    查询数据库的时候就指定范围

```java
@Test
public void testSelectSqlLayer(){
    SqlSession sqlSession = sqlSessionFactory.openSession();
    Map<String,Integer> map = new HashMap<>();
    map.put("start",1);
    map.put("end",5);

    UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
    List<User> users = userMapper.findUsers(map);
    System.out.println(users);
}
```

但是这事先需要用户指定起始和结束位置，当然可以使用动态sql指定默认范围。<br>


#### PageHelper插件

在实际场合中使用比较多的还有PageHelper这个mybatis分页的插件，其实现原理就是在mappedStatement对象在执行sql时添加上limit，实现物理分页,本文暂时不打算分析源码，[这篇文章](http://www.cnblogs.com/jeffen/p/6286335.html)讲解还不错。<br>


使用之前，**安装好使用的包**

```xml
<!--分页插件-->
<dependency>
    <groupId>com.github.pagehelper</groupId>
    <artifactId>pagehelper</artifactId>
    <version>4.0.0</version>
</dependency>
```

**插件配置**

```xml
<!--插件配置-->
<plugins>
    <plugin interceptor="com.github.pagehelper.PageHelper">
        <!-- 4.0.0以后版本可以不设置该参数 -->
        <property name="dialect" value="mysql"/>
        <!-- 该参数默认为false -->
        <!-- 设置为true时，会将RowBounds第一个参数offset当成pageNum页码使用 -->
        <!-- 和startPage中的pageNum效果一样-->
        <property name="offsetAsPageNum" value="true"/>
        <!-- 该参数默认为false -->
        <!-- 设置为true时，使用RowBounds分页会进行count查询 -->
        <property name="rowBoundsWithCount" value="true"/>
        <!-- 设置为true时，如果pageSize=0或者RowBounds.limit = 0就会查询出全部的结果 -->
        <!-- （相当于没有执行分页查询，但是返回结果仍然是Page类型）
        <property name="pageSizeZero" value="true"/>-->
        <!-- 3.3.0版本可用 - 分页参数合理化，默认false禁用 -->
        <!-- 启用合理化时，如果pageNum<1会查询第一页，如果pageNum>pages会查询最后一页 -->
        <!-- 禁用合理化时，如果pageNum<1或pageNum>pages会返回空数据 -->
        <property name="reasonable" value="true"/>
        <!-- 3.5.0版本可用 - 为了支持startPage(Object params)方法 -->
        <!-- 增加了一个`params`参数来配置参数映射，用于从Map或ServletRequest中取值 -->
        <!-- 可以配置pageNum,pageSize,count,pageSizeZero,reasonable,不配置映射的用默认值 -->
        <!-- 不理解该含义的前提下，不要随便复制该配置 
        <property name="params" value="pageNum=start;pageSize=limit;"/>    -->
    </plugin>
</plugins>
```

使用较为简单，有以下**两种方式**<br>

- **使用RowBounds**

- **使用PageHelper.startPage(start,end)**

```java
public void testSelectPlugin() {
    SqlSession session = sqlSessionFactory.openSession();
    List<User> users = session.selectList("com.julyerr.interviews.sql.mybatis.mapper.UserMapper.findUsersLogic", new Object(),
            new RowBounds(1,5));
//        PageHelper.startPage(1,5);
    System.out.println(new PageBean<User>(users).getList());
}
```

返回的是Page对象，但是为了更好支持json格式数据，通常会简单的封装一层PageBean，如下

```java
public class PageBean<T> implements Serializable {
    private long total;        //总记录数
    private List<T> list;    //结果集
    private int pageNum;    // 第几页
    private int pageSize;    // 每页记录数
    private int pages;        // 总页数
    private int size;        // 当前页的数量 <= pageSize，该属性来自ArrayList的size属性

    /**
     * 包装Page对象，因为直接返回Page对象，在JSON处理以及其他情况下会被当成List来处理，
     * 而出现一些问题。
     */
    public PageBean(List<T> list) {
        if (list instanceof Page) {
            Page<T> page = (Page<T>) list;
            this.pageNum = page.getPageNum();
            this.pageSize = page.getPageSize();
            this.total = page.getTotal();
            this.pages = page.getPages();
            this.list = page;
            this.size = page.size();
        }
    }
    //getter & setter
}
```

---
### 参考资料
- [【MyBatis学习15】MyBatis的逆向工程生成代码](http://blog.csdn.net/eson_15/article/details/51694684)
- [浅入浅出MyBatis(10)：分页查询](http://www.letiantian.me/2015-01-14-learn-mybatis-from-scratch-10/)
- [Mybatis分页插件PageHelper的使用详解](https://www.jianshu.com/p/dade4116111e)