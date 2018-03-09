---
layout:     post
title:      "java projects分析开篇"
subtitle:   "java projects分析开篇"
date:       2018-03-08 12:00:00
author:     "julyerr"
header-img: "img/projects/start.png"
header-mask: 0.5
catalog: 	true
tags:
    - projects
    - ssm
---

>java web后台开发的理论知识点总结覆盖有60-70%的样子，可以适当放慢进度，去做一些实践项目了。本人以前做过的项目有基于python的、golang的，java没有（尴尬，虽然以前在github上看过几个java做的demo）。<br>

所谓技术是相通的，开发语言似乎不太重要。但是面试官可不管这些，没有实际的java项目，那只能ByeBye。在接下来的一两个月的时间内，会将自己以前和现在陆续看过的一些优秀的java web项目通过blog整理出来。主要就项目实现的功能，所使用的技术，整个项目的workflow等理清楚；庖丁解牛，看过几个优秀的项目之后，争取自己也能DIY一番...

[Spring+SpringMVC+Mybatis+easyUI实现简单的后台管理系统](https://github.com/ZHENFENG13/ssm-demo)

**实现的功能**

- 管理员的注册功能，登录功能，删除功能。 
- 文章的增删改查功能，图片的增删改查功能。 
- 图片上传功能。 
- 多文本编辑器UEditor整合。 

下面对项目实现进行分析

#### 数据库层面
**数据库表**<br>

**ssm_user**
![](/img/projects/ssm/ssm1/table-user.png)
**ssm_article**
![](/img/projects/ssm/ssm1/table-article.png)
**ssm_book**
![](/img/projects/ssm/ssm1/table-book.png)
**ssm_picture**
![](/img/projects/ssm/ssm1/table-pic.png)

其中book和picture表都有一个path，分别代表book封面所在的路径和图片所在位置<br>

**数据库的配置信息**<br>

```
# database configure
jdbc.url=jdbc:mysql://localhost:3306/demo?useUnicode=true&characterEncoding=utf8&autoReconnect=true
jdbc.username=root
jdbc.password=root
```
使用druid数据库连接池，但是本人还没有怎么上手过，因此这里就掠过，后面会进行更新。

**entity层**

```java
public class User{
    private Integer id; // 主键
    private String userName; // 用户姓名
    private String password; // 密码
    private String roleName; //
    //getter & setter
}

//实现序列化能够在网络中传输
public class Article implements Serializable {
    private String id;//主键
    private String articleTitle;//文章标题
    private String articleCreateDate;//创建日期
    private String articleContent;//文章内容
    private int articleClassID;//文章类别id
    private int isTop;//置顶字段
    private String addName;//添加者
    //...
}    

public class Book implements Serializable {
    private String id;// 主键id
    private String isbn;// ISBN码
    private String path;// 图片
    private String title;// 标题
    private String subtitle;// 副标题
    private String originalTitle;
    private String marketPrice;// 市场价
    private String intro;// 简介
    private String binding;// 装订方式
    private String pages;// 页数
    private String author;// 作者
    private String publisher;// 出版社
    private String catalog;// 目录
    private int supply;// 库存
    private String status;// 状态
    private int hot;// 热度值
    //...
} 

public class Picture implements Serializable {
    private String id;
    private String path;// 路径
    private String type;// 外键类别
    private String time;// 插入时间
    private String url;//
    private String grade;// 另一个外键
    //...
}

//分页对象,为了方便显示起始和结束位置
public class PageBean {
    private int page; // 页码
    private int pageSize; // 单页数据量
    private int start;
}
```

---
#### DAO层

**dao和service的bean的配置**

```xml
<!-- 自动扫描 -->
<context:component-scan base-package="com.ssm.maven.core.dao"/>
<context:component-scan base-package="com.ssm.maven.core.service"/>
```

**dao 层**<br>

使用mybatis需要配置映射关系

```xml
<!-- 配置mybatis的sqlSessionFactory -->
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
    <property name="dataSource" ref="dataSource"/>
    <!-- 自动扫描mappers.xml文件 -->
    <property name="mapperLocations" value="classpath:/mappers/*.xml"></property>
    <!-- mybatis配置文件 -->
    <property name="configLocation" value="classpath:mybatis-config.xml"></property>
</bean>

<!-- DAO接口所在包名，Spring会自动查找其下的类 -->
<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
    <property name="basePackage" value="com.ssm.maven.core.dao"/>
    <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"></property>
</bean>
```

**用户操作接口**

```java
@Repository
public interface UserDao {
    /**
     * 登录
     */
    public User login(User user);
    /**
     * 查找用户列表
     */
    public List<User> findUsers(Map<String, Object> map);
    public Long getTotalUser(Map<String, Object> map);
    /**
     * 实体修改
     */
    public int updateUser(User user);
    /**
     * 添加用户
     */
    public int addUser(User user);
    /**
     * 删除用户
     */
    public int deleteUser(Integer id);
}
``` 

```xml
<mapper namespace="com.ssm.maven.core.dao.UserDao">
    <resultMap type="User" id="UserResult">
        <result property="id" column="id"/>
        <result property="userName" column="user_name"/>
        <result property="password" column="password"/>
        <result property="roleName" column="role_name"/>
    </resultMap>

    <select id="login" parameterType="User" resultMap="UserResult">
        select id,user_name,password,role_name from
        ssm_user where user_name=#{userName} and password=#{password} limit 1
    </select>

    <!--传入的类型是Map，支持多种属性设置-->
    <select id="findUsers" parameterType="Map" resultMap="UserResult">
        select id,user_name,password,role_name from ssm_user
        <where>
            <if test="userName!=null and userName!='' ">
                and user_name like #{userName}
            </if>
        </where>
#         范围限制
        <if test="start!=null and size!=null">
            limit #{start},#{size}
        </if>
    </select>

    <select id="getTotalUser" parameterType="Map" resultType="Long">
        select count(*) from ssm_user
        <where>
            <if test="userName!=null and userName!='' ">
                and user_name like #{userName}
            </if>
        </where>
    </select>

    <insert id="addUser" parameterType="User">
        insert into ssm_user(user_name,password)
        values(#{userName},#{password})
    </insert>

    <update id="updateUser" parameterType="User">
        update ssm_user
        <set>
            <if test="userName!=null and userName!='' ">
                user_name=#{userName},
            </if>
            <if test="password!=null and password!='' ">
                password=#{password}
            </if>
        </set>
        where id=#{id} and <![CDATA[ id <> 2 ]]>
    </update>

    <delete id="deleteUser" parameterType="Integer">
        delete from ssm_user
        where id=#{id}
    </delete>
</mapper> 
```

**文章操作接口**,xml文件和User基本一致，就不粘贴出来

```java
@Repository
public interface ArticleDao {
    /**
     * 返回相应的数据集合
     */
    public List<Article> findArticles(Map<String, Object> map);
    /**
     * 数据数目
     */
    public Long getTotalArticles(Map<String, Object> map);
    /**
     * 添加文章
     */
    public int insertArticle(Article article);
    /**
     * 修改文章
     */
    public int updArticle(Article article);
    /**
     * 删除
     */
    public int delArticle(String id);
    /**
     * 根据id查找
     */
    public Article getArticleById(String id);
}
```

**书操作接口**,xml文件也类似

```java
@Repository
public interface BookDao extends Serializable {
    /**
     * 返回相应的数据集合
     */
    public List<Book> findBooks(Map<String, Object> map);
    /**
     * 数据数目
     */
    public Long getTotalBooks(Map<String, Object> map);
    /**
     * 添加书籍
     */
    public int insertBook(Book book);
    /**
     * 根据id查找
     */
    public Book getBookById(String id);
}
```

**图片操作接口**

```java
@Repository
public interface PictureDao {
    /**
     * 返回相应的数据集合
     */
    public List<Picture> findPictures(Map<String, Object> map);
    /**
     * 数据数目
     */
    public Long getTotalPictures(Map<String, Object> map);
    /**
     * 添加图片
     */
    public int insertPicture(Picture picture);
    /**
     * 修改图片
     */
    public int updPicture(Picture picture);
    /**
     * 删除
     */
    public int delPicture(String id);
    /**
     * 根据id查找
     */
    public Picture findPictureById(String id);
}
```

各个dao基本都包含insert、update、del、find的接口,返回对象通过ResultMap实现映射,值得注意的是Map对象的传入实现自定义查询(动态sql语句)。<br>

**service的实现**<br>


**UserService接口及其实现**

```java
public interface UserService {
    public User login(User user);
    public List<User> findUser(Map<String, Object> map);
    public Long getTotalUser(Map<String, Object> map);
    public int updateUser(User user);
    public int addUser(User user);
    public int deleteUser(Integer id);
}

@Service("userService")
public class UserServiceImpl implements UserService {
    @Resource
    private UserDao userDao;

    @Override
    public User login(User user) {
        return userDao.login(user);
    }

    @Override
    public List<User> findUser(Map<String, Object> map) {
        return userDao.findUsers(map);
    }

    @Override
    public int updateUser(User user) {
        //防止有人胡乱修改导致其他人无法正常登陆
        if ("admin".equals(user.getUserName())) {
            return 0;
        }
        return userDao.updateUser(user);
    }

    @Override
    public Long getTotalUser(Map<String, Object> map) {
        return userDao.getTotalUser(map);
    }

    @Override
    public int addUser(User user) {
        if (user.getUserName() == null || user.getPassword() == null || getTotalUser(null) > 90) {
            return 0;
        }
        return userDao.addUser(user);
    }

    @Override
    public int deleteUser(Integer id) {
        //防止有人胡乱修改导致其他人无法正常登陆
        if (2 == id) {
            return 0;
        }
        return userDao.deleteUser(id);
    }

}
```

**ArticleService接口，实现也是调用mapper**

```java
public interface ArticleService {
    /**
     * 返回相应的数据集合
     */
    public List<Article> findArticle(Map<String, Object> map);
    /**
     * 数据数目
     */
    public Long getTotalArticle(Map<String, Object> map);
    /**
     * 添加文章
     */
    public int addArticle(Article article);
    /**
     * 修改文章
     */
    public int updateArticle(Article article);
    /**
     * 删除
     */
    public int deleteArticle(String id);
    /**
     * 根据id查找
     */
    public Article findById(String id);
}
```

**PictureService接口**

```java
public interface PictureService {
    /**
     * 返回相应的数据集合
     */
    public List<Picture> findPicture(Map<String, Object> map);
    /**
     * 数据数目
     */
    public Long getTotalPicture(Map<String, Object> map);
    /**
     * 添加图片
     */
    public int addPicture(Picture picture);
    /**
     * 修改图片
     */
    public int updatePicture(Picture picture);
    /**
     * 删除
     */
    public int deletePicture(String id);
    /**
     * 根据id查找
     */
    public Picture findById(String id);
}
```

service层只是对dao层进行了简单的封装，直接调用mapper接口方法完成核心功能，需要注意的是接口实现类，注入操作接口

```java
@Resource
private UserDao userDao;
```
---
#### view 层
spring mvc基于MVC的实现的框架，为了便于理解，先看看view层面需要后端提供的哪些请求处理。<br>

**spring mvc配置**

```xml
<!-- 使用注解的包，包括子集 -->
<context:component-scan base-package="com.ssm.maven.core.admin"/>

<!-- 视图解析器 -->
<bean id="viewResolver"
      class="org.springframework.web.servlet.view.InternalResourceViewResolver">
    <property name="prefix" value="/"/>
    <property name="suffix" value=".jsp"></property>
</bean>

<!-- 文件上传支持 -->
<bean id="multipartResolver"
      class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
    <property name="maxUploadSize" value="3500000"/>
    <property name="defaultEncoding" value="UTF-8"/>
</bean>
```

**web.xml中的配置**

```xml
<display-name>ssm-maven-demo</display-name>
<welcome-file-list>
    <welcome-file>index.html</welcome-file>
</welcome-file-list>
<!--spring 配置文件-->
<context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>classpath:spring-context.xml</param-value>
</context-param>

<!--配置字符过滤器-->
<filter>
    <filter-name>encodingFilter</filter-name>
    <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
    <init-param>
        <param-name>encoding</param-name>
        <param-value>UTF-8</param-value>
    </init-param>
</filter>

<filter-mapping>
    <filter-name>encodingFilter</filter-name>
    <url-pattern>/*</url-pattern>
</filter-mapping>

<!--spring监听类-->
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>

<!-- spring请求配置，指向springmvc的核心配置文件，定义所有以.do结尾的请求都被springmvc拦截 -->
<servlet>
    <servlet-name>springMVC</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:spring-context-mvc.xml</param-value>
    </init-param>
    <!--加载顺序为1 -->
    <load-on-startup>1</load-on-startup>
</servlet>

<servlet-mapping>
    <servlet-name>springMVC</servlet-name>
    <url-pattern>*.do</url-pattern>
</servlet-mapping>

<!--错误页面配置,这里只是简单的配置了一下 -->
<error-page>
    <error-code>404</error-code>
    <location>/main.jsp</location>
</error-page>

<error-page>
    <error-code>500</error-code>
    <location>/main.jsp</location>
</error-page>
<!--错误页面配置 -->
```

本人打算从事后端开发，所以前端的内容在这里就稍微提及一点，具体请参见对应的文件。<br>

`login.jsp`中有一个提交表单的操作

```html
<form id=adminlogin method=post
      name=adminlogin action="${pageContext.request.contextPath}/user/login.do">
```

`login_chk.jsp`中判断用户的session是否失效需要重新登入

```jsp
<%
    if (session.getAttribute("currentUser") == null) {
        out.println("<script>window.location.href='" + session.getServletContext().getContextPath() + "/login.jsp';</script>");
    }
%>
```

`main.jsp`是主界面文件，通过超链接的形式将其他的jsp包含起来<br>

`/views/userManager.jsp`

添加用户

```html
${pageContext.request.contextPath}/user/save.do
```

修改用户

```html
${pageContext.request.contextPath}/user/save.do?id=" + row.id
```

删除用户

```jsp
$.post("${pageContext.request.contextPath}/user/delete.do", {
                        ids: ids
 }
```

`/views/articleManage.jsp`

代码逻辑和userManager.jsp一致，请求资源的URL的后缀不同<br>

请求单篇文章

```jsp
$.ajax({
            type: "post",
            dataType: "json",
            url: '/article/findById.do',
            data: {"id": getQueryStringByName("id")},
       ...
      {);      
```


文章列表

```jsp
 $.ajax({
            type: "POST",
            url: "/article/list.do",
            contentType: "application/json; charset=utf-8",
            data: "{}",
            dataType: "json",
            ...
         });
```

`/views/allBooksManage.jsp`<br>

主要是查询功能

```jsp
function searchBook() {
        $("#dg").datagrid('load', {
            "title": $("#biaoti").val(),
            "author": $("#zuozhe").val(),
            "isbn": $("#bianma").val(),
        });
    }
```

图片管理功能类似，主要不同之处是**文件上传**部分

```jsp
$("#uploadify2").uploadify({
            'uploader': 'swf/uploadify2.swf',           //flash文件的相对路径
            'script': '../loadimg/upload.do',           //后台处理程序的路径
            ...
```

---
#### Controller层

通过上面大致了解了前台需要后台提供哪些请求处理的URL，下面就来看看Controller的逻辑.由于代码量较多，只对核心进行分析，其他的实现大同小异。<br>

**UserController**

```java
@Controller
@RequestMapping("/user")
public class UserController {
    ...
}
```

登入

```java
@RequestMapping("/login")
public String login(User user, HttpServletRequest request) {
    try {
        String MD5pwd = MD5Util.MD5Encode(user.getPassword(), "UTF-8");
//            将对用户传进来的密码进行加密
        user.setPassword(MD5pwd);
    } catch (Exception e) {
        user.setPassword("");
    }
//        判断是否用户名或者密码有效
    User resultUser = userService.login(user);
    log.info("request: user/login , user: " + user.toString());
    if (resultUser == null) {
        request.setAttribute("user", user);
        request.setAttribute("errorMsg", "请认真核对账号、密码！");
        return "login";
    } else {
        HttpSession session = request.getSession();
//            将用户存入sessoion，
        session.setAttribute("currentUser", resultUser);
//            记入登入日志信息
        MDC.put("userName", user.getUserName());
        return "redirect:/main.jsp";
    }
}
```

查询用户列表

```java
@RequestMapping("/list")
//    对输入的参见进行映射
public String list(@RequestParam(value = "page", required = false) String page, @RequestParam(value = "rows", required = false) String rows, User s_user, HttpServletResponse response) throws Exception {
//        将整个查询信息放到同一个map中
    Map<String, Object> map = new HashMap<String, Object>();
//        限制返回的数量，其实就是数据库中的limit start,size
    if (page != null && rows != null) {
        PageBean pageBean = new PageBean(Integer.parseInt(page),
                Integer.parseInt(rows));
        map.put("start", pageBean.getStart());
        map.put("size", pageBean.getPageSize());
    }
    map.put("userName", StringUtil.formatLike(s_user.getUserName()));
    List<User> userList = userService.findUser(map);
    Long total = userService.getTotalUser(map);
//        返回json格式的数据
    JSONObject result = new JSONObject();
    JSONArray jsonArray = JSONArray.fromObject(userList);
    result.put("rows", jsonArray);
    result.put("total", total);
    log.info("request: user/list , map: " + map.toString());
    ResponseUtil.write(response, result);
    return null;
}
```

ArticleController、BookController、PictureController具体操作和UserController基本类似,比较有特点的是图片上传处理LoadImageController

```java
@RequestMapping("/upload")
//    图片上传格式MultipartFile
public String upload(HttpServletRequest request, HttpServletResponse response, @RequestParam("file") MultipartFile file) throws Exception {
    ServletContext sc = request.getSession().getServletContext();
    String dir = sc.getRealPath("/upload");
    String type = file.getOriginalFilename().substring(file.getOriginalFilename().lastIndexOf(".")+1, file.getOriginalFilename().length());

    SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss");
    Random r = new Random();
    String imgName = "";
    if (type.equals("jpg")) {
        imgName = sdf.format(new Date()) + r.nextInt(100) + ".jpg";
    } else if (type.equals("png")) {
        imgName = sdf.format(new Date()) + r.nextInt(100) + ".png";
    } else if (type.equals("jpeg")) {
        imgName = sdf.format(new Date()) + r.nextInt(100) + ".jpeg";
    } else {
        return null;
    }
//        保存到具体文件路径
    FileUtils.writeByteArrayToFile(new File(dir, imgName), file.getBytes());
    response.getWriter().print("upload/" + imgName);
    return null;
}
```

**其他配置**<br>

该项目使用声明式方式了配置了事务传播属性

```xml
<!-- 配置事务通知属性 -->
<tx:advice id="txAdvice" transaction-manager="transactionManager">
    <!-- 定义事务传播属性 -->
    <tx:attributes>
        <tx:method name="insert*" propagation="REQUIRED"/>
        <tx:method name="update*" propagation="REQUIRED"/>
        <tx:method name="upd*" propagation="REQUIRED"/>
        <tx:method name="edit*" propagation="REQUIRED"/>
        <tx:method name="save*" propagation="REQUIRED"/>
        <tx:method name="add*" propagation="REQUIRED"/>
        <tx:method name="new*" propagation="REQUIRED"/>
        <tx:method name="set*" propagation="REQUIRED"/>
        <tx:method name="remove*" propagation="REQUIRED"/>
        <tx:method name="delete*" propagation="REQUIRED"/>
        <tx:method name="del*" propagation="REQUIRED"/>
        <tx:method name="change*" propagation="REQUIRED"/>
        <tx:method name="check*" propagation="REQUIRED"/>
        <tx:method name="get*" propagation="REQUIRED" read-only="true"/>
        <tx:method name="search*" propagation="REQUIRED" read-only="true"/>
        <tx:method name="find*" propagation="REQUIRED" read-only="true"/>
        <tx:method name="load*" propagation="REQUIRED" read-only="true"/>
        <tx:method name="*" propagation="REQUIRED" read-only="true"/>
    </tx:attributes>
</tx:advice>

<!-- 配置事务切面 -->
<aop:config>
    <aop:pointcut id="serviceOperation"
                  expression="(execution(* com.ssm.maven.core.service.*.*(..)))"/>
    <aop:advisor advice-ref="txAdvice" pointcut-ref="serviceOperation"/>
</aop:config>
```

---
### 参考资料
- [Spring+SpringMVC+Mybatis+easyUI实现简单的后台管理系统](https://github.com/ZHENFENG13/ssm-demo)