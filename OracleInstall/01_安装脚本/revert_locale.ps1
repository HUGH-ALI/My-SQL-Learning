$log = "D:\Oracle\downloads\locale_revert.log"
"start $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Encoding utf8
try { Set-WinSystemLocale -SystemLocale zh-CN; "systemlocale_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8 } catch { "systemlocale_error=$($_.Exception.Message)" | Out-File -FilePath $log -Append -Encoding utf8 }
try { Set-Culture -CultureInfo zh-CN; "culture_exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8 } catch { "culture_error=$($_.Exception.Message)" | Out-File -FilePath $log -Append -Encoding utf8 }
$pending = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -ErrorAction SilentlyContinue
"registry_ACP=$($pending.ACP)" | Out-File -FilePath $log -Append -Encoding utf8
Get-WinSystemLocale | Select-Object Name,LCID | Format-List | Out-File -FilePath $log -Append -Encoding utf8
"done $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $log -Append -Encoding utf8
