$log = "D:\Oracle\downloads\cleanup_task.log"
"start $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Encoding utf8
$sc  = "$env:SystemRoot\System32\schtasks.exe"
$net = "$env:SystemRoot\System32\net.exe"

& $sc /delete /tn OraDbInstall /f 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"del_db_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8

& $sc /delete /tn OraClientInstall /f 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"del_client_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8

& $net user oracle /active:no 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"disable_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8

& $sc /query /tn OraDbInstall 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
& $sc /query /tn OraClientInstall 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"done $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Append -Encoding utf8
