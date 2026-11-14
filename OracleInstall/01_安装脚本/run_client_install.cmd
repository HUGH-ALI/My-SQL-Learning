@echo off
set TEMP=D:\Temp
set TMP=D:\Temp
cd /d E:\Oracle\p13390677_112040_WINNT_3of6\client
setup.exe -silent -ignorePrereq -responseFile D:\Oracle\downloads\client_rsp.rsp
echo exit=%ERRORLEVEL%
