---
layout:     post
title:      "mybatis 总结二"
subtitle:   "mybatis 总结二"
date:       2018-03-05 12:00:00
author:     "julyerr"
header-img: "img/sql/mybatis/mybatis.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - sql
    - mybatis
---


>上文简单介绍了mybatis工作原理和常见使用，这篇blog主要总结mybatis中高级内容，如动态sql、关联配置以及spring框架集成等

#### 动态sql

使用mybatis提供的动态sql可以拼接出不同的sql语句，主要动态sql如下：
`if`、`choose`、`when`、`otherwise`、`trim`、`where`、`set`以及`foreach`。以下内容主要参考[1]<br>

**if**<br>
if常常和test配合使用

```xml
<select id="getUser" resultMap="u" parameterType="String">
    select * from user2
    <if test="address!=null and address !=''">
        WHERE address LIKE concat('%',#{address},'%')
    </if>
</select>
```

**where**<br>
只有where元素中有条件成立，才会将where关键字组装到SQL中.<br>

**choose**<br>
常常配合when和otherwise一起来使用

```xml
<select id="getUser2" resultMap="u">
    SELECT * FROM user2 
    <where>
	    <choose>
	        <when test="id!=null">
	            AND id=#{id}
	        </when>
	        <when test="address!=null">
	            AND address=#{address}
	        </when>
	        <otherwise>
	            AND 10>id
	        </otherwise>
	    </choose>
	</where>
</select>
```


**set**<br>
更新表，设置字段的值

```xml
<update id="update">
    UPDATE user2
    <set>
        <if test="username!=null">
            user_name=#{username},
        </if>
        <if test="password!=null">
            password=#{password}
        </if>
    </set>
    WHERE id=#{id}
</update>
```

**foreach**<br>
用来遍历集合,例如查询`SELECT * FROM user2 WHERE address IN（'西安'，'北京'）`

```xml
<select id="getUserInCities" resultMap="u">
    SELECT * FROM user2
    WHERE address IN
    <foreach collection="cities" index="city" open="(" separator="," close=")" item="city">
        #{city}
    </foreach>
</select>
```

**bind**<br>

预先定义一些变量，然后在查询语句中使用
```xml
<select id="getUserByName" resultMap="u">
    <bind name="un" value="username+'%'"></bind>
        SELECT* FROM user2 WHERE user_name LIKE #{un}

</select>
```

**trim**<br>

可以将特定的值替换为设置的值

```xml
<select id="getUser4" resultMap="u">
    SELECT * FROM user2
    <trim prefix="where" prefixOverrides="and">
        AND id=1
    </trim>
</select>
```

实际执行 `SELECT * FROM user2 where id = 1`

---
#### mybatis关联配置

上文提及resultMap中有association 和 collection 标签；
前者使用在一对一的情况下，后者应用在一对多中。
下面使用demo的形式展示配置使用的方式

**User**

```java
public class User implements Serializable {

    private static final long serialVersionUID = -4637590911523717296L;

    private Integer id;
    private String username;
    private Date birthday;
    private String sex;
    private String address;

    private List<Orders> ordersList;
    //getter && setter...
}
```

**Order**

```java
public class Orders {
    private Integer id;

    private Integer userId;

    private String number;

    private Date createtime;

    private String note;

    private User user;

    private List<Orderdetail> orderdetails;
    //getter && setter...
}
```

**OrderDetail**

```java
public class Orderdetail {
    private Integer id;

    private Integer ordersId;

    private Integer itemsId;

    private Integer itemsNum;

    private Items items;
    //getter && setter...
}
```

**Items**

```java
public class Items {
    private Integer id;

    private String name;

    private Float price;

    private String pic;

    private Date createtime;

    private String detail;
    //getter && setter...
}    
```

一个用户对应多个订单，一个订单又可以对应多个订单详情，一个订单详情对应一个商品；用户和订单之间的关系就是多对多的。<br>

**一对一配置**<br>

以订单详情和商品配置为例

```xml
<association property="items" javaType="items">
    <id column="items_id" property="id"/>
    <result column="items_name" property="name"/>
    <result column="items_detail" property="detail"/>
    <result column="items_price" property="price"/>
</association>
```

**一对多**<br>

以用户和订单配置为例

```xml
<collection property="ordersList" ofType="orders">
    <id column="id" property="id"/>
    <result column="user_id" property="userId"/>
    <result column="number" property="number"/>
    <result column="createtime" property="createtime"/>
    <result column="note" property="note"/>
</collection>
```

**多对多**<br>

多对多的关系可以转换成一对多的两次叠加,即`<collection>`中还嵌套一层`<collection>`<br>

上面示例的代码[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/sql/mybatis/)以及对应的测试文件。

---
#### 缓存策略

![](/img/sql/mybatis/cache.png)
上图展示了mybatis中的一级和二级缓存作用范围<br>

- 一级缓存是SqlSession级别的缓存
- 二级缓存是mapper级别的缓存,跨SqlSession的。

**一级缓存**<br>
![](/img/sql/mybatis/oneLayerCache.png)
sqlSession在执行插入、更新、删除等操作然后执行commit操作，会清空SqlSession中的一级缓存。但是如果**手动修改sql不会导致缓存更新**会发生脏读现象。

```java
@Test
public void testCache1() throws Exception {
    SqlSession sqlSession = sqlSessionFactory.openSession();//创建代理对象
    UserMapper userMapper = sqlSession.getMapper(UserMapper.class);

    //第一次发起请求，查询id为1的用户
    User user1 = userMapper.findUserById(1);
    System.out.println(user1);

    //第二次发起请求，查询id为1的用户，进行了缓存，不会进行数据库查询操作
    user1 = userMapper.findUserById(1);
    System.out.println(user1);

//      如果sqlSession去执行commit操作（执行插入、更新、删除），清空SqlSession中的一级缓存，这样做的目的为了让缓存中存储的是最新的信息，避免脏读。

    //更新user1的信息
    user1.setUsername("测试用户22");
    userMapper.updateUser(user1);
    //执行commit操作去清空缓存
    sqlSession.commit();

    //第三次发起请求，查询id为1的用户
    User user2 = userMapper.findUserById(1);
    System.out.println(user2);

    sqlSession.close();

}
```

整个测试结果可以参看查询的日志信息，需要先配置好日志格式<br>

**二级缓存**<br>

![](/img/sql/mybatis/twoLayerCache.png)
工作原理和一级缓存类似，只不过现在设置为mapper级别而不是sqlSession级别。<br>
mybatis默认是禁用二级缓存的，除了在MybatisConfguration.xml中启用之外，还需要在mapper.xml配置开启二级缓存。<br>

MybatisConfiguration.xml

```xml
<setting name="cacheEnabled" value="true"/>
```

UserMapper.xml

```xml
 <cache/>
```

```java
@Test
public void testCache2() throws Exception {
    SqlSession sqlSession1 = sqlSessionFactory.openSession();
    SqlSession sqlSession2 = sqlSessionFactory.openSession();
    SqlSession sqlSession3 = sqlSessionFactory.openSession();
    // 创建代理对象
    UserMapper userMapper1 = sqlSession1.getMapper(UserMapper.class);
    // 第一次发起请求，查询id为1的用户
    User user1 = userMapper1.findUserById(1);
    System.out.println(user1);  
    //这里执行关闭操作，将sqlsession中的数据写到二级缓存区域
    sqlSession1.close();

    //sqlSession3用来清空缓存的，如果要测试二级缓存，需要把该部分注释掉
    //使用sqlSession3执行commit()操作
    UserMapper userMapper3 = sqlSession3.getMapper(UserMapper.class);
    User user  = userMapper3.findUserById(1);
    user.setUsername("julyerr");
    userMapper3.updateUser(user);
    //执行提交，清空UserMapper下边的二级缓存
    sqlSession3.commit();
    sqlSession3.close();

    UserMapper userMapper2 = sqlSession2.getMapper(UserMapper.class);
    // 第二次发起请求，查询id为1的用户
    User user2 = userMapper2.findUserById(1);
    System.out.println(user2);

    sqlSession2.close();

}
```

**语句执行属性选项**<br>

- useCache 是否禁用二级缓存,如果设置为false,则当前语句每次执行的时候不使用缓存
- flushCache 是否刷新缓存，默认为true。执行insert、update、delete操作数据后需要刷新缓存，不然可能出现脏读的情况。

```xml
<select id="findOrderListResultMap" resultMap="ordersUserMap" useCache="false">
```

**notes**<br>

mybatis对缓存有两个不足之处：<br>

- 默认自带实现的二级缓存策略只能存储在当前服务器上，如果多台服务之间需要共享缓存的话，需要使用其他的缓存框架的支持。比较常用的是ehcache分布式缓存框架，需要了解，请自行google.
- 二级缓存对细粒度的数据级别的缓存实现不好,例如在同一个mapper之下，一个商品信息变化会将所有商品信息的缓存数据全部清空。此时需要业务逻辑处理缓存。

---
### mybatis和spring框架集成
理解mybatis和spring集成配置，关键是理解spring ioc工作原理。单纯的mybatis工程中，不论是基于dao进行开发还是mapper开发，需要自己new一个对象,然后调用；但是在spring框架中，所有的bean在使用之前已经全部创建好了，直接取出来用即可。因此关键是配置好需要的各个bean,可以对照先前的配置。<br>

1.加载需要的包spring-mybatis.jar、log4j.jar等<br>

2.sqlSessionFactory配置

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

<!--sqlSessionFactory配置-->
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
    <property name="dataSource" ref="dataSource"></property>
    <!-- mybatisConfig.xml作为mybatis的配置文件，配置基本类似，知识不能设置dataSource属性 -->
    <property name="configLocation" value="classpath:mybatisConfig.xml"></property>
</bean>
```

mybatisConfig.xml

```xml
<typeAliases>
    <package name="com.julyerr.mybatis.po"/>
</typeAliases>
<!-- Continue editing here -->
<mappers>
    <mapper resource="sqlMapper/User.xml"/>
    <package name="com.julyerr.mybatis.mapper"/>
</mappers>
```

为了便于理解，讲解下面两种配置方式的时候以具体的demo为例

#### 基于dao的开发配置

**User.xml文件**

```xml
<mapper namespace="test">
    <select id="findUserById" parameterType="int" resultType="user">
        SELECT * FROM user WHERE id = #{id}
    </select>
</mapper>
```

**dao层及其具体实现类**<br>

由于dao层需要sqlSessionFactory才能进行操作，所以需要注入sqlSessionFactory（可继承`SqlSessionDaoSupport`类），然后配置bean

```xml
<bean id="userDao" class="com.julyerr.mybatis.dao.UserDaoImpl">
    <property name="sqlSessionFactory" ref="sqlSessionFactory"></property>
</bean>
```

```java
public interface UserDao {
    //根据用户id查询用户信息
    public User findUserById(int id) throws Exception;
}

public class UserDaoImpl extends SqlSessionDaoSupport implements UserDao {
    public User findUserById(int id) throws Exception {

        //继承SqlSessionDaoSupport，通过this.getSqlSession()就能得到sqlSession，因为SqlSessionDaoSupport中有该方法
        SqlSession sqlSession = this.getSqlSession();
        User user = sqlSession.selectOne("test.findUserById", id);
        return user;
    }
}
```

**测试用例**

```java
public void testDaoFind() throws Exception {
    ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext("applicationContext.xml");
    UserDao userDao = (UserDao)ctx.getBean("userDao");
    User user = userDao.findUserById(1);
    System.out.println(user);
}
```

#### 基于mapper的开发配置

**mapper bean**<br>

单纯mybatis项目中，mybatis能够自动扫描获取mapper;在spring需要配置生成对应的mapper bean.

```xml
<!--针对的是mapper package-->
<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
    <property name="basePackage" value="com.julyerr.mybatis.mapper" />
    <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"/>
</bean>

<!--具体的mapper文件-->
<!--<bean id="userMapper" class="org.mybatis.spring.mapper.MapperFactoryBean">-->
    <!--<property name="mapperInterface" value="com.julyerr.mybatis.mapper.UserMapper"/>-->
    <!--<property name="sqlSessionFactory" ref="sqlSessionFactory" />-->
<!--</bean>-->
```

**测试用例**

```java
public void testMapperFind() throws Exception {
    ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext("applicationContext.xml");
    UserMapper userMapper = (UserMapper)ctx.getBean("userMapper");
    User user = userMapper.findUserById(1);
    System.out.println(user);
}
```

框架集成代码[参见](https://github.com/julyerr/springdemo/tree/master/src/main/java/com/julyerr/mybatis/)以及对应的测试文件。

---
### 参考资料

[1]:http://blog.csdn.net/u012702547/article/details/55105400
- [MyBatis 学习](http://blog.csdn.net/column/details/smybatis.html)
- [mybatis中的动态SQL](http://blog.csdn.net/u012702547/article/details/55105400)