$log = "D:\Oracle\downloads\client_task.log"
"start $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Encoding utf8
$sc = "$env:SystemRoot\System32\schtasks.exe"
& $sc /create /tn OraClientInstall /tr "D:\Oracle\downloads\run_client_install.cmd" /ru oracle /rp Oracle12345 /rl HIGHEST /sc once /st 23:58 /f 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"create_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
& $sc /run /tn OraClientInstall 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
"run_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
"done $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Append -Encoding utf8
