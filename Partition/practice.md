第1题（LIST列表分区 + 本地分区索引）  
需求：  
创建学生表  student ，字段：s_id(数字)，s_name(varchar2)，province(varchar2)  
按省份 province 做列表分区：  
- p_zj：'浙江'  
- p_gz：'贵州'  
- p_other：DEFAULT 其他省份  
给这张分区表，建立本地分区索引，索引字段 s_id  

1，  
create table student(  
sid int primary key,sname varchar2(20) ,province varchar2(40))  
partition by List(province)  
(  
partition pzj values('浙江')，  
partition pgz values('贵州'),  
partition null values(null),  
partition pother values(default)  
);  
create index index_local_sid on student(province) local;  
❌ 错误：partition null 不能用null做分区名，关键字冲突  
❌ 需求：索引字段是sid，你写了province  
✅ 修正后  
create table student(  
sid int primary key,sname varchar2(20) ,province varchar2(40))  
partition by list(province)  
(  
partition p_zj values('浙江'),  
partition p_gz values('贵州'),  
partition p_null values(null),  
partition p_other values(default)  
);  
create index index_local_sid on student(sid) local;  

 
第2题（RANGE范围分区 + 全局分区索引）  
需求：  
创建成绩表  score ，字段：sc_id，stu_id，score(分数)  
按 score 范围分区：  
- p_low：小于60  
- p_mid：60~80  
- p_high：>=80  
在这张分区表上，建立全局分区索引，按 stu_id 分区（分成2个分区）  

2,create table score(  
scid varchar(10) primary key,  
stuid varchar(10) not null,  
score int check(score between 0 and 100)  
)  
partition by Range(score)  
(  
partition plow values less than(60),  
partition pmid values less than(80),  
partiton phigh values less than(Maxvalue)  
)  
- ❌ 全局分区索引缺少 GLOBAL PARTITION BY  
create index index_global_stuid on score(stuid)  
(  
partition p1 ,  
partition p2  
)  
✅ 修正后   
create table score(  
scid varchar(10) primary key,  
stuid varchar(10) not null,  
score int check(score between 0 and 100)  
)   
partition by range(score)  
(  
partition p_low values less than(60),  
partition p_mid values less than(80),  
partition p_high values less than(maxvalue)  
);  
create index index_global_stuid on score(stuid)  
global partition by range(stuid)  
(  
partition p1 values less than(5000),  
partition p2 values less than(maxvalue)  
);  


第3题（普通非分区表 + 全局分区索引）  
需求：  
创建课程表  course ，字段：c_id，c_name，credit  
这是一张普通不分区表  
给它建立全局分区索引，基于 c_id，分成2个分区  

3,create table course(  
cid char(10) primary key,  
-❌ 类型是varchar2，没有char2  
cname char2(20) unique,  
credit int not null)  
- ❌ 缺少 GLOBAL PARTITION BY  
create index index_global_cid on course(cid)  
(  
partition p1 ,  
partition p2  
)  
✅ 修正后   
create table course(  
cid char(10) primary key,  
cname varchar2(20) unique,  
credit int not null  
);  
create index index_global_cid on course(cid)  
global partition by range(cid)  
(  
partition p1 values less than('C00000'),  
partition p2 values less than(maxvalue)  
);  

第4题（HASH哈希分区 + 全局非分区索引）  
需求：  
创建日志表  oper_log ，字段：log_id，op_user，op_time  
按 log_id 做哈希分区，一共4个分区  
给这张分区表，建立全局非分区索引，索引字段 op_time  

4,cteate table operlog(  
logid char(20) primary key,  
opuser char(20) not null,  
optime char(20) not null  
)  
partition by hash(logid)  
(  
partition p1 ,  
partition p2,  
partition p3,  
partition p4  
)  
create index index_global_optime on operlog(optime)  
