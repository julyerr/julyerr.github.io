---
layout:     post
title:      "mysql 架构和优化简析"
subtitle:   "mysql 架构和优化简析"
date:       2018-03-23 8:00:00
author:     "julyerr"
header-img: "img/sql/mysql/mysql.png"
header-mask: 0.5
catalog:    true
tags:
    - mysql
---

### MYSQL 架构简析

![](/img/sql/mysql/mysql-arch.png)

上图较为详细展示了mysql各个模块的工作逻辑，下图是mysql的逻辑架构

![](/img/sql/mysql/mysql-arch-whole.png)

- **第一层**<br>主要功能如连接处理、授权认证、安全等 
- **第二层**<br> 是核心服务层，包括查询解析、分析、优化、缓存、内置函数。所有跨域存储引擎的功能都在这一层实现如，存储过程、触发器、视图 
- **第三层**<br>包含存储引擎，负责Mysql数据的存储和提取。通常存储引擎不会去解析SQL（InnoDB会解析外键定义除外）。

#### 请求处理流程

![](/img/sql/mysql/query-process.png)


---
### MySQL常见优化

#### 锁优化

**mysql中三种锁的特性**

- **表级锁**<br>开销小，加锁快;不会出现死锁；锁定粒度大，发生锁冲突的概率最高，并发度最低
- **行级锁**<br>开销大，加锁慢;会出现死锁;锁定粒度小，发生锁冲突的概率最低，并发度最高
- **页面锁**<br>开销和加锁时间介于表锁和行锁之间；会出现死锁；锁定粒度介于表锁和行锁之间，并发度一般

MyISAM和MEMORY存储引擎采用的表级锁;BDB存储引擎采用的是页面锁；Innodb存储引擎既支持行级锁，也支持表级锁，默认采用行级锁.<br>

关于数据库中锁方面内容[参见](http://julyerr.club/2018/03/13/sql-basic/#数据库中的锁),下面具体看看mysql中两种存储引擎(MyISAM和InnoDB)锁的相关内容

### MyISAM锁	

**并发锁**

- 当concurrent_insert设置为0时，不允许并发插入;
- 当concurrent_insert设置为1时，如果MyISAM允许在一个读表的同时，另一个进程从表尾插入记录,这也是MySQL的默认设置;
- 当concurrent_insert设置为2时，无论MyISAM表中有没有空洞，都允许在表尾插入记录，都允许在表尾并发插入记录。

**锁调度**<br>
MySQL认为写请求一般比读请求重要。读进程先请求先到锁等待队列，写请求后到，写锁也会插到读请求之前，因此MyISAM表不太适合于有大量更新操作和查询操作应用<br>

**调整方式**

- 通过指定启动参数low-priority-updates，使MyISAM引擎默认给予读请求以优先的权利;
- 通过执行命令`SET LOW_PRIORITY_UPDATES=1`，使该连接发出的更新请求优先级降;
- 通过指定INSERT、UPDATE、DELETE语句的LOW_PRIORITY属性，降低该语句的优先级。
- 折中的方式,给系统参数max_write_lock_count设置一个合适的值，当一个表的读锁达到这个值后，MySQL暂时将写请求的优先级降低，给读进程一定获得锁的机会。

### InnoDB锁
InnoDB支持事务(关于事务的概念[参见](http://julyerr.club/2018/03/13/sql-basic/#事务))，而且引入了行级锁。<br>

MySQL InnoDB存储引擎采用MVVC支持高并发，实现了四个标准的隔离级别(默认为REPEATABLE READ)，并且通过间隙锁(next-key lock)策略使得InnoDB锁定查询涉及的行，还会对索引中的间隙进行锁定，防止幻读出现。<br>

#### 多版本并发控制(MVVC)
实现了非阻塞的读操作，写操作也只锁定必要的行<br>

**实现原理**

- 数据在不同时间点的快照对应不同的版本;
- 每一个事务对同一张表，多个事务同一个时刻看到的数据可能是不一样的。

**innodb简化实现过程**<br>

- 只在REPEATABLE READ和READ COMMITED两个隔离级别下工作;
- 在每行记录后面保存两个隐藏的列，一列保存了行的创建时间，一个保存行的过期时间。

**在执行不同的SQL对应处理如下**

- **SELECT**
    - 只查找版本号小于等于当前事务版本号的数据行。确保数据行是在事务开始前已经存在的，或者是事务本身插入或者修改过的
	- 并且行的删除版本号要么未定义，要么大于当前事务版本号。确保数据行在事务读取前未被删除
- **INSERT**<br>为新插入的每一数据行保存当前系统版本号为行版本号;
- **DELETE**<br>为删除的每一行保存当前系统版本号作为行删除标识;
- **UPDATE**<br>插入一条新的记录，保存当前系统版本号为行版本号，保存当前系统版本号到原来的行作为行删除标识。

**InnoDB行锁模式**

- **共享锁（S）**<br>允许一个事务去读一行，阻止其他事务获得相同数据集的排他锁
- **排他锁（X）**<br>允许获取排他锁的事务更新数据，阻止其他事务取得相同的数据集共享读锁和排他写锁				
- **意向共享锁（IS）**<br>事务打算给数据行共享锁，在给一个数据行加共享锁前必须先取得该表的IS锁
- **意向排他锁（IX）**<br>事务打算给数据行加排他锁，在给一个数据行加排他锁前必须先取得该表的IX锁。

意向锁是表锁，主要是处理表锁和行锁之间的冲突而引入的,它们之间兼容性如下

|当前锁模式/是否兼容/请求锁模式|X|IX|S|IS|
|-|-|-|-|-|
|X|	冲突|	冲突	|冲突|	冲突|
|IX	|冲突	|兼容	|冲突|	兼容|
|S	|冲突	|冲突	|兼容|	兼容|
|IS|	冲突	|兼容	|兼容	|兼容	|

对于UPDATE、DELETE和INSERT语句，InnoDB会自动给涉及及数据集排他锁（X）；对于普通SELECT语句，InnoDB不会任何锁；事务可以通过以下语句显示给记录集加共享锁或排锁。

```sql
# 共享锁（Ｓ）
SELECT * FROM table_name WHERE ... LOCK IN SHARE MODE
# 排他锁（X）
SELECT * FROM table_name WHERE ... FOR UPDATE	
```

**InnoDB行锁实现原理**<br>
通过给索引上的索引项加锁来实现，如果没有索引，InnoDB将通过隐藏的聚簇索引来对记录加锁

**间隙锁（Next-key lock）**

- **Record Locks** 对索引项加锁
- **Gap lock** 对索引项之间的“间隙“（第一条记录前的”间隙“，或最后一条记录后的”间隙“）加锁
- **next-key lock** 其实是前两种的组合，主要是为了防止幻读的情况发生。

```sql
SELECT * FROM emp WHERE empid > 100 FOR UPDATE
```

上面的sql是一个范围条件的检索，InnoDB不仅会对符合条件的empid值为101的记录加锁，也会对empid大于101（这些记录并不存在）的“间隙”加锁。如果不加上间隙锁的话，如果一个另一个事务插入一条102的记录，可能出现幻读的情况。<br>

**表锁使用**<br>
表锁不是由InnoDB存储引擎层管理的，而是由其上一层ＭySQL Server负责的，仅当autocommit=0、innodb_table_lock=1（默认设置）时，InnoDB层才能知道MySQL加的表锁，ＭySQL Server才能感知InnoDB加的行锁。<br>

对于下面常见场景可以显示指定使用表锁

- 事务需要更新大部分或全部数据，表又比较大，如果使用默认的行锁，不仅这个事务执行效率低，而且可能造成其他事务长时间锁等待和锁冲突。
- 事务涉及多个表，比较复杂，很可能引起死锁，造成大量事务回滚。使用表锁避免死锁、减少数据库因事务回滚带来的开销。

锁只在COMMIT或ROLLBACK时被释放。但是事务结束前，不要用UNLOCAK TABLES释放表锁，因为UNLOCK TABLES会隐含地提交事务，正确使用方式如下：

```sql
SET AUTOCOMMIT=0;
LOCAK TABLES t1 WRITE, t2 READ, ...;
[do something with tables t1 and here];
COMMIT;
UNLOCK TABLES;
```	

#### 死锁
ＭyISAM表锁是deadlock free的，这是因为ＭyISAM总是一次性获得所需的全部锁，要么全部满足，要么等待，因此不会出现死锁。但是InnoDB中除单个SQL组成的事务外，锁是逐步获得的，这就决定了InnoDB发生死锁是可能的。<br>
下面是常见的造成死锁的情况

- **锁表顺序不当**
![](/img/sql/mysql/lock-order.png)
session1锁住了表au_id=1记录，session2锁住了re_id=3的记录；session1想获取re_id=3的记录没有获取到锁只能等待， 同样的，session2也只能等待，造成了死锁。<br>
**解决方式**：只需要调整session2中sql的执行顺序即可。
- **锁申请级别不够**
![](/img/sql/mysql/lock-prio.png)
开始两个事务由于上的都是共享锁，所以在对au_id=1加锁都是成功的;但是需要更新的时候，互斥只能等待，造成死锁。<br>
**解决方式**:需要更新数据就需要申请排他锁。

- **REPEATATABLE-READ隔离级别下的死锁**
![](/img/sql/mysql/lock-repeatable.png)
由于re_id=4的记录在数据库中不存在，session1和session2加锁都会成功。两个session加锁成功的是gap锁，锁住了大于3的记录，加锁成功以后，session1插入re_id=4记录的时候由于session1加了插入意向锁，导致session1插入数据等待，同理session2也会进入等待，形成死锁。<br>
**解决方式**：修改隔离级别为READ COMMITTED，对duplicate key错误执行ROLLBACK释放获得的排他锁。

发生死锁后，InnoDB一般都能自动检测到，并使一个事务释放锁并退回，另一个事务获得锁，继续完成事务。通过设置锁等待超时参数`innodb_lock_wait_timeout`来解决死锁问题，而且此参数能够解决大量事务在没有获取所需的锁被挂起而带来的资源浪费问题。<br>

**锁的优化策略**

- 多个线程尽量以相同的顺序去获取资源
- 减少锁持有的时间
- 读写分离(下面有介绍),减少读写锁冲突

---
### 语句优化

#### 状态查询

```sql
show status like 'Com_%';
```

**所有的查询等操作**

- `Com_select`执行select操作的次数，依次查询之累加1
- `Com_insert`执行insert操作的次数，对于批量插入的insert操作，只累加依次
- `Com_update`执行update操作的次数
- `Com_delete`执行delete的次数

**特定的存储引擎查询等操作**

- `Innodb_rows_read` SELECT查询返回的行数
- `Innodb_rows_insered` 执行inser操作插入的行数
- `Innodb_rows_updated` 执行UPDATE操作更新的行数
- `Innodb_rows_deleted` 执行DELETE操作删除的行数

- **事务**

- `Com_commit`和`Com_rollback`可以了解事务提交和回滚的情况


#### 定位效率较低的SQL语句
	
**慢日志**<br>

1.开启慢日志查询功能

```sql
set global slow_query_log = ON;
```

2.慢查询分析 `mysqldumpslow logfile.log`<br>

**通过explain分析执行sql**<br>
模拟优化器执行SQL查询语句，从而知道MySQL是如何处理你的SQL语句的

```sql
explain select * from film where rating>9;
```
返回的结果信息

- **select_type**<br>表示SELECT的类型，常见的取值有simple（简单表，即不用表连接或者子查询），primary（主查询，即外部查询），union（union中的第二个或者后面的查询语句），subquery（子查询中的第一个select）等
- **table**<br>对应查询的表
- **type**<br>表示Mysql在表中找到所需行的方式或者叫访问类型，常见类型如：all,index,range（范围）,ref（索引扫描）,eq_ref（唯一索引）,const,system,null,从做到右，性能由差到好
- **extra**
    - using index：只用到索引,可以避免访问表. 
	- using tmporary：用到临时表
	- using filesort：用到额外的排序. (当使用order by v1,而没用到索引时,就会使用额外的排序,出现性能降低)	

**通过profile**<br>
可以得到更准确的SQL执行消耗系统资源的信息

```sql
# 可以查看之前的queryid
show profiles;

# 可以查看执行过程中线程的每个状态和消耗时间
show profile for query 2
```

#### 简单的优化方法
ANALYZE,CHECK,OPTIMIZE,ALTER TABLE分别用于分析、检验、优化、修改表，执行期间都是对表进行锁定，因此要在数据库不频繁的时候才选择执行这些操作。其中optimize可以使表中的空间碎片进行合并、并且可以消除由于删除或者更新造成的空间浪费。

#### 常用SQL优化

**大批量的插入数据**

- 导入数据强执行`SET UNIQUE_CHECKS=0`，关闭唯一性校验，在导入结束后执行`SET UNIQUE_CHECKS=1`,恢复唯一性校验；
- 如果应用使用自动提交的方式，建议在导入前执行`SET AUTOCOMMIT=0`时，关闭自动提交，导入结束后再执行`SET AUTOCOMMIT=1`，打开自动提交，也可以提高导入的效率	

**优化insert语句**

- insert delayed语句提高更高的速度，delayed的含义是让insert语句马上执行，其实数据都被放到内存的队列中，并没有真正写入磁盘，这比每条语句分别插入要快的多；
- 使用多个值表的insert语句那比单个insert语句快上好几倍,其他语句如delete、update等都可以合并进行操作以提高性能；
- 当从一个文本文件装载一个表时，使用`LOAD DATA INFILE`,这通常比使用很多INSERT语句块快20倍

**优化order by语句**

- 通过有序排序索引顺序扫描，不需要额外的排序，操作效率很高;
- 通过返回数据进行排序，也就是通常说的Filesort排序（可能存在磁盘文件或者临时表的创建等，`sort_buffer_size`大小不足还需要在保存在外存中)效率很低;

**优化group by 语句**
	如果查询包括group by 但用户想要避免排序结果的消耗，可以指定group by null
**优化嵌套查询**<br>
子查询可以被更有效率的连接替代，因为mysql不需要在内存中创建临时表来完成嵌套查询的过程

```sql
explain select * from customer where customer_id not in(select customer_id from payment)

explain select * from customer a left join payment b on a.customer_id=b.customer_id where b.customer id is null
```			

**使用固定长度的表，查询效率更高**<br>
**避免使用临时表**<br>
临时表驻扎在TempDb数据库中，因此临时表上的操作需要跨数据库通信，速度自然慢
**避免在WHERE子句中使用in，not  in，or 或者having**<br>
可以使用 exist 和not exist代替 in和not in,可以使用表链接代替 exist<br>
**尽量减少查询的模糊匹配使用**<br>
修改前台程序，把查询条件的供应商名称一栏由原来的文本输入改为下拉列表，而不是根据用户输入到后台查询

---
### 索引
索引相关知识[参见](http://julyerr.club/2018/03/13/sql-basic/#索引)。<br>
MySIAM使用非聚集索引，InnoDB使用聚集索引,两者适用常见如下
![](/img/sql/cluster-nocluster.png)

InnoDB建议大部分表使用默认的自增的主键作为索引<br>

下面情况下设置了索引但无法使用

- 以“%”开头的LIKE语句，模糊匹配
- OR语句前后没有同时使用索引
- 数据类型出现隐式转化（如varchar不加单引号的话可能会自动转换为int型）    

---
#### 主从复制
数据复制的实际就是Slave从Master获取Binary log文件，然后再本地镜像的执行日志中记录的操作过程。<br>

**读写分离**

- 让master数据库处理写操作，slave数据库处理读操作;
- master将写操作的变更同步到各个slave节点
		
![](/img/sql/mysql/read-write-isolation.png)

有下面益处

- 主从只负责各自的读和写，极大程度缓解X锁和S锁争用
- slave可以配置myiasm引擎，提升查询性能以及节约系统开销;
- master直接写是并发的，slave通过主库发送来的binlog恢复数据是异步;
- slave可以单独设置一些参数来提升其读的性能
- 增加冗余，提高可用性

---
#### 数据库分库与分表
业务初期，很多应用都采用集中式的架构。随着业务规模的增大，访问量的增大，我们不得不对业务进行拆分。每一个模块都使用单独的数据库来进行存储。<br>

数据库拆分通常有三种拆分方式,水平拆分、水平拆分、垂直水平拆分<br>

**水平拆分**<br>
水平拆分可以降低单表数据量，让每个单表的数据量保持在一定范围内，从而提升单表读写性能。<br>数据量比较大的时候，考虑分配多少数据到不同的表中。以用户id分表为例，用户ID更多的可能是通过UUID生成的，这样的话，我们可以首先将UUID进行hash获取到整数值，然后在进行取模操作，找到对应的表进行查询。

![](/img/sql/mysql/level-split.png)        

**垂直拆分**<br>
分表的实质还是在一个数据库上进行的操作，很容易受数据库IO性能的限制。垂直拆分根据数据库里面的数据表的相关属性进行拆分,比如根据不同表order,user等划分为order和user数据库，或者是把一个多字段的大表按常用字段和非常用字段进行拆分;

![](/img/sql/mysql/vertical-split.jpg)        

**垂直水平拆分**<br>
结合垂直、水平拆分两者的优势
![](/img/sql/mysql/vertical-level-split.jpg)        
        
上图中定位数据在表中位置使用到的计算公式如下：
1. 中间变量　＝ user_id%（库数量*每个库的表数量）;
2. 库序号　＝　取整（中间变量／每个库的表数量）;
3. 表序号　＝　中间变量％每个库的表数量;


还可以针对某些查询比较频繁的操作考虑使用内存缓存起来，例如使用redis缓存服务器，只有没有查到的时候才真正进行查询操作
![](/img/sql/mysql/weipinhui.jpg)       

上图展示了唯品会订单分库分表的实践总结，[具体参见](http://www.infoq.com/cn/articles/summary-and-key-steps-of-vip-orders-depots-table)

---
#### 配置优化

- **max_connections** 最大连接数
- **back_log** MySQL暂时停止回答新请求之前的短时间内有多少个请求可以被存在堆栈中
- **interactive_timeout** 一个交互连接在被服务器在关闭前等待行动的秒数		
- **key_buffer_size** 指定索引缓冲区的大小
- **query_cache_size** 查询缓冲区的大小
- **record_buffer_size** 每个进行一个顺序扫描的线程为其扫描的每张表分配这个大小的一个缓冲区。
- **sort_buffer_size** 每个需要进行排序的线程分配该大小的一个缓冲区
- **tmp_table_size** 通过设置tmp_table_size选项来增加一张临时表的大小
- **thread_concurrency** 推荐设置为服务器 CPU核数的2倍
- **wait_timeout** 指定一个请求的最大连接时间
	
以上参数需要根据实际业务情形配置，具体[参见](http://www.oicto.com/mysql-explain-show/)

---
#### 硬件优化	  

使用SSD替代机械硬盘等	  	

---
#### 如何设计一个高并发的系统

- 数据库的优化，包括合理的事务隔离级别、SQL语句优化、索引优化
- 使用缓存、尽量减少数据库IO
- 分布式数据库、分布式缓存
- 服务器的负载均衡			

---
### 参考资料
- [MYSQL优化（一）：【架构解析、sql语句执行详细流程】](https://blog.csdn.net/xkx_1223_xkx/article/details/77892465)
- [MySQL系列-- 1.MySQL架构](https://juejin.im/post/59ec528bf265da43333d8bb0)
- [MySql 优化](https://juejin.im/entry/589147155c497d0056dae2e5)
- [InnoDB常见死锁分析](https://blog.csdn.net/lml200701158/article/details/77917176)
- [mysql性能优化-慢查询分析、优化索引和配置](http://www.oicto.com/mysql-explain-show/)
- [MySQL读写分离介绍及搭建](https://segmentfault.com/a/1190000003716617)
- [唯品会订单分库分表的实践总结以及关键步骤](http://www.infoq.com/cn/articles/summary-and-key-steps-of-vip-orders-depots-table)
- [数据库分库分表策略的具体实现方案](https://blog.csdn.net/xlgen157387/article/details/53976153)