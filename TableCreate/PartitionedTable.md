1. 核心概念  
把一张逻辑上的大表，拆成多个独立、更小的物理片段，每一段叫分区。  
✅ 逻辑上：还是同一张表，查询、增删改语句不变（操作透明）  
✅ 物理上：分区分开存储，可以放不同磁盘、不同表空间  

分区优点  
1. 安全性：一个分区坏了，别的分区不受影响  
2. 并行性能：多分区放不同磁盘，IO可以并行，查询更快  
3. 管理方便：单独把某个分区离线/只读、删除分区，不用动整张表  
4. 对上层SQL透明：你写select，不用管它分了区  


我的理解  
分区表是把一张表根据某列的内容在硬盘中分开存放，但是这些分开存放的内容合起来还是这张表的总内容和存储所需空间  
注意：不是在内存分开存放。内存是临时放数据的，关机就没了；分区是永久的硬盘存储。  
例子  
学生  籍贯  
张三  浙江  
李四  贵州  

我根据籍贯分区就是  
CREATE TABLE student(  
    sname VARCHAR2(10),  
    native_place VARCHAR2(10)  
)  
PARTITION BY LIST(native_place)  
(  
    PARTITION p_zj VALUES ('浙江'),  
    PARTITION p_gz VALUES ('贵州')  
);  
结果  
P1:  
学生  籍贯  
张三  浙江  
P2：  
学生  籍贯  
李四  贵州  

分区之后假如我  
select * from student where 籍贯='浙江'  
就是是先找根据籍贯分区里的浙江分区然后就直接在浙江这个分区里找，而不用管其他(贵州)分区，这样就提高了查询效率  

注意：  
1. 普通表（没分区）+ Oracle11g：不能建完表后续再分区，只能建表的时候定义分区  
2. 已经是分区表了：可以用ALTER TABLE 新增、删除、拆分分区  
举例子：你已经建好这个LIST分区表（p_zj、p_gz），现在想再加一个江苏分区：  
ALTER TABLE student ADD PARTITION p_js VALUES ('江苏');  
这条是给已经存在的分区表追加新分区，这个是允许的！  
⚠️ 前提：这张表本身一开始就是分区表，不是普通表。  

4种基础分区方式  

1. 范围分区 RANGE（最常用！例子就是它）  
按值的区间划分，适合：日期、数字。  
语法：  
CREATE TABLE 表名(  
    字段定义...  
)  
PARTITION BY RANGE (分区列1[,分区列2,...])  
(  
    PARTITION 分区1名 VALUES LESS THAN(常量|MAXVALUE) [TABLESPACE 表空间名],  
    PARTITION 分区2名 VALUES LESS THAN(常量|MAXVALUE) [TABLESPACE 表空间名],  
    ...  
);  

例：按生日分区  
p1：生日 < 1980-01-01  
p2：1980-01-01 ≤ 生日 <1990-01-01  
p3：生日 ≥1990-01-01（ MAXVALUE 代表无穷大）  
CREATE TABLE student_range(  
sno NUMBER(6) PRIMARY KEY,  
sname VARCHAR2(10),  
sage int,  
birthday DATE  
)  
PARTITION BY RANGE(birthday)  
(  
 PARTITION p1 VALUES LESS THAN (TO_DATE('1980-1-1', 'YYYY-MM-DD')) TABLESPACE ORCLTBS1,  
 PARTITION p2 VALUES LESS THAN (TO_DATE('1990-1-1', 'YYYY-MM-DD')) TABLESPACE ORCLTBS2,  
 PARTITION p3 VALUES LESS THAN (MAXVALUE) TABLESPACE ORCLTBS3  
);  
重点： VALUES LESS THAN  是小于这个值，是区间上界！最后一个分区的LESS THAN (MAXVALUE)中的MAXVALUE是指无穷大  

2. 列表分区 LIST  
分区列的值是离散集合（不是连续区间），适合省份、性别、班级这种固定枚举值。  
比如：p1存省份='浙江'，p2存'贵州'，p3存其他。  
CREATE TABLE table(...)  
PARTITION BY LIST (column)  
(  
 PARTITION partition1 VALUES ([literal|NULL] | [DEFAULT]) [TABLESPACE tablespace],  
 [, PARTITION partition2 VALUES ([literal|NULL] | [DEFAULT]) [TABLESPACE tablespace], ...]  
)  
就是VALUES()里能按常量分区，然后没有填写数据的就放在NULL分区，最后除了按前面常量分区的和没有数据的NULL去，其他都放在Default区里  

1.literal ：字面常量，就是你写的  '浙江' 、 '贵州'  这种值  
2.  NULL ：可以专门把空值分到一个分区里（LIST分区特有，RANGE分区不能直接写NULL）  
3.  DEFAULT ：兜底，所有没匹配上的值进这个分区  
4.  [ ] ：代表这一段可选，可以不写（比如表空间TABLESPACE可以省略）  
5.  | ：或者，二选一   
6.  [, ...] ：可以继续加更多分区  

CREATE TABLE student(  
    sname VARCHAR2(10),  
    native_place VARCHAR2(10)  
)  
PARTITION BY LIST(native_place)  
(  
    PARTITION p_zj VALUES ('浙江'),  
    PARTITION p_gz VALUES ('贵州'),  
    PARTITION p_null VALUES (NULL),  
    PARTITION p_other VALUES (DEFAULT)  
);  



3. 散列/哈希分区 HASH  
不自己划分区间，交给HASH函数，均匀打散数据到各个分区。  
适合：没有范围、不需要按业务归类，只想均匀分摊数据压力。  
哈希分区没有VALUES！ 它不靠你写值划分，Oracle自动用哈希算法打散数据，均匀分到各个分区，这个是和RANGE、LIST最大区别！  
语法：  
CREATE TABLE table(...)  
PARTITION BY HASH (column1[,column2,...])  
[ (PARTITION partition [TABLESPACE tablespace][,...]) ]  
[PARTITIONS hash_partition_quantity STORE IN (tablespace1[,...]) ]  

写法①  
【例6-35】创建一个分区表，根据学号将学生信息均匀分布到ORCLTBS1和ORCLTBS2  
两个表空间中。  
CREATE TABLE student_hash (  
    sno NUMBER(6) PRIMARY KEY,  
    sname VARCHAR2(10)  
)  
PARTITION BY HASH(sno)  
(  
    PARTITION p1 TABLESPACE ORCLTBS1,  
    PARTITION p2 TABLESPACE ORCLTBS2  
);  

写法②  
只写分区数量，名字自动生成  
CREATE TABLE student_hash (  
    sno NUMBER(6) PRIMARY KEY,  
    sname VARCHAR2(10)  
)  
PARTITION BY HASH(sno)  
PARTITIONS 2 STORE IN (ORCLTBS1,ORCLTBS2);  
自动起分区名如： SYS_P1 、 SYS_P2 、 SYS_P3 ……  


4. 复合分区  
两层分区：先按一种方式分，每个子分区再用另一种分。  
例：先RANGE按年份分，每个年份分区里面再LIST按地区分。  
常见：范围-列表、范围-hash等。  
创建复合分区表时，首先在CREATE TABL语中使PARTITION BY子句指定分区方  
法、分区列，然后使SPATITION BY子句指定子分区方法、子分区列、子分区数量及  
子分区的描。  
【例6-37】创建一个范围-列表复合分区表，将1980年1月1日前出生的男、女学生信  
息分别保存在ORCLTBS1和ORCLTBS2表空间中，1980年1月1日到1990年1月1日出生  
的男、女学生信息分别保存在ORCLTBS3和ORCLTBS4表空间中，其他学生信息保存在  
ORCLTBS5表空间中  

CREATE TABLE student_range_list(  
sno NUMBER(6) PRIMARY KEY,  
sname VARCHAR2(10),  
sex CHAR(2) CHECK(sex IN ('M','F')),  
sage NUMBER(4),  
birthday DATE  
)  
PARTITION BY RANGE(birthday)  
SUBPARTITION BY LIST(sex)  
(  
PARTITION p1 VALUES LESS THAN (TO_DATE('1980-1-1', 'YYYY-MM-DD'))  
(SUBPARTITION p1_sub1 VALUES ('M') TABLESPACE ORCLTBS1,  
 SUBPARTITION p1_sub2 VALUES ('F') TABLESPACE ORCLTBS2),  

PARTITION p2 VALUES LESS THAN (TO_DATE('1990-1-1', 'YYYY-MM-DD'))  
(SUBPARTITION p2_sub1 VALUES ('M') TABLESPACE ORCLTBS3,  
 SUBPARTITION p2_sub2 VALUES ('F') TABLESPACE ORCLTBS4),  

PARTITION p3 VALUES LESS THAN(MAXVALUE) TABLESPACE ORCLTBS5  
);  


3. 分区的操作特点  
- 插入数据时，数据库自动判断这条记录放进哪个分区，不用我们指定  
- 可以单独修改单个分区状态：只读、离线，不影响别的分区  
- 查询的时候优化器会做分区裁剪：只扫描符合条件的分区，跳过无关分区，速度变快  
比如：查1985年的学生 → 直接只扫描p2分区，不去扫p1、p3  

查询分区  
1. 查外层分区（一级分区）  
视图： user_tab_partitions  
SELECT table_name,partition_name,tablespace_name,high_value  
FROM user_tab_partitions  
WHERE table_name='STUDENT_RANGE_LIST';  
high_value ：分区上限（RANGE分区的边界）  

2. 查子分区（复合分区重点！）  
视图： user_tab_subpartitions  
SELECT table_name,partition_name,subpartition_name,tablespace_name  
FROM user_tab_subpartitions  
WHERE table_name='STUDENT_RANGE_LIST';  

3. 查看分区表本身（分区类型RANGE/LIST/HASH）  
SELECT table_name,partitioning_type,subpartitioning_type  
FROM user_part_tables  
WHERE table_name='STUDENT_RANGE_LIST';  

4. 直接查询某个分区里面的数据  
-- 查询p1分区的数据  
SELECT * FROM student_range_list PARTITION(p1);  
-- 查询子分区p1_sub1的数据  
SELECT * FROM student_range_list SUBPARTITION(p1_sub1);  

5. 查看分区键（按哪个字段分区）  
SELECT table_name,column_name  
FROM user_part_key_columns  
WHERE table_name='STUDENT_RANGE_LIST';  

user_tab_partitions  → 分区  
-  user_tab_subpartitions  → 子分区（复合分区必考）  
user_part_tables  → 表是什么分区类型  
