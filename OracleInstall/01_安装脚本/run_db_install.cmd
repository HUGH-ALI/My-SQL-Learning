@echo off
set TEMP=D:\Temp
set TMP=D:\Temp
cd /d D:\Oracle\downloads\free26ai
setup.exe /s /v"RSP_FILE=D:\Oracle\downloads\free26ai\FREEInstall_D.rsp" /v"/L*v D:\Oracle\downloads\db26ai_silent.log" /v"/qn"
echo exit=%ERRORLEVEL%
