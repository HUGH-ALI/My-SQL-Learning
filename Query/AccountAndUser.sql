--list all of users
select name,password_hash,is_disabled,create_date from sys.sql_logins order by name;

--reset passqord
--alter login wyao5980@gmail.com with password='200410Wy@?';
--登录名里面包含 `@`、`.` 特殊符号，SQL Server 要求这种名字必须用方括号 `[]` 包起来
alter login [wyao5980@gmail.com] with password='200410Wy@?';
--查看是否启用，`is_disabled=1` 代表账号禁用，0代表启用
select name,password_hash,is_disabled,create_date from sys.sql_logins where name='wyao5980@gmail.com';

--### 登录账号 ≠ 数据库用户
--就算登录进去了，大概率还看不到数据库，因为：
--`wyao5980@gmail.com` 只是**服务器登录名（login）**，还没有映射到具体数据库里面的用户（user），没有数据库访问权限。
--想让它能访问 student 数据库，需要执行：

--分配和system admin一样的权限
alter server role sysadmin add member [wyao5980@gmail.com];
--回收权限
--alter server role sysadmin drop member [wyao5980@gmail.com];
--切换用户：
--①新开一个查询窗口连接>数据库引擎 每个窗口独立登录，老窗口还是你原来的 Windows 账号。
--②命令行切换 sqlcmd -S LAPTOP-SMS3QHLC\SQL2016 -U wyao5980@gmail.com -P 200410Wy@?

--创建只能查询某张表的用户，先建立用户再授权
--create login username with password='';
create login [query_only_user] with password='Test@123456';
--CREATE USER 数据库用户名  FOR LOGIN 服务器登录名; 
--一个登录账号（login），可以在不同的数据库里，分别绑定不同的数据库用户（user）；
--每个数据库单独一套 user，每个 user 可以单独分配权限。
use [26-9-25] create user[query_only_user] for login[query_only_user]; 
--在26-9-25这个数据库中的 用户query_only_user 在 登录登录账号query_only_user 名下
grant select to [query_only_user];
--精细到某张表的权限 ：grant 权限 on 表名 to 用户名;
use [26-9-25] revoke select from [query_only_user];
grant select on student to [query_only_user];
--回收 use 数据库名 revoke 权限 from user;
--use [26-9-25] revoke select from [query_only_user];
--删除用户
--use 数据库名; 指定接下来操作在哪一个数据库执行
--drop user username; 后不能再用loginname这个账号登录数据库了
--drop login loginname;清理**库内的身份**，只在当前库生效

--库内模拟切换用户
use [26-9-25] execute as user='query_only_user';--让当前这条会话，临时假装成数据库用户 u1，之后所有 SQL，都用 u1 的权限去检查。
select * from dbo.student; --这条查询，数据库会判断：u1 有没有 teacher 表的 SELECT 权限。有>查询成功,没有>直接报权限不足
--.............
SELECT SUSER_SNAME() as "当前登录账户";--查询当前是哪一个登录账号
SELECT user as "当前用户";
revert; --取消模拟，变回你原来登录的身份。
