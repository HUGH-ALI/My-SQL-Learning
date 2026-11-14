$log = "D:\Oracle\downloads\oracle_acct.log"
"start $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Encoding utf8
$net = "$env:SystemRoot\System32\net.exe"
$sc  = "$env:SystemRoot\System32\schtasks.exe"

& $net user oracle Oracle12345 /add /comment:"Oracle installer account" 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"add_user_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8

& $net localgroup Administrators oracle /add 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"add_admin_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8

& $sc /create /tn OraDbInstall /tr "D:\Oracle\downloads\run_db_install.cmd" /ru oracle /rp Oracle12345 /rl HIGHEST /sc once /st 23:58 /f 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"create_task_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8

Get-LocalUser -Name oracle -ErrorAction SilentlyContinue | Select-Object Name,Enabled | Format-List | Out-File -FilePath $log -Append -Encoding utf8
Get-LocalGroupMember -Group Administrators -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "oracle" } | Select-Object Name | Format-List | Out-File -FilePath $log -Append -Encoding utf8

& $sc /run /tn OraDbInstall 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"run_task_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
"done $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Append -Encoding utf8
