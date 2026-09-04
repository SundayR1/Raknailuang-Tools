@echo off
:: =====================================================================
:: InternetAspas - RESTORE ALL (กลับค่าเดิม)
:: =====================================================================
:: รัน as Administrator เพื่อกลับค่า Windows ทั้งหมดเป็นค่า default
:: =====================================================================

echo =============================================
echo  InternetAspas - RESTORE DEFAULT VALUES
echo =============================================
echo.
echo กำลังกลับค่าเป็น Windows Default...
echo.

:: --- Netsh: กลับค่า default ---
echo [1/4] คืนค่า Netsh...
netsh int tcp set heuristics default >nul 2>&1
netsh int tcp set global ecncapability=default >nul 2>&1
netsh int tcp set global timestamps=default >nul 2>&1
netsh int tcp set global nonsackrttresiliency=default >nul 2>&1
netsh int tcp set global initialRto=3000 >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global rsc=enabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global fastopen=enabled >nul 2>&1
netsh int ip set global taskoffload=enabled >nul 2>&1
netsh int ip set global icmpredirects=enabled >nul 2>&1
netsh int ip set global multicasting=enabled >nul 2>&1
echo     ✓ Netsh คืนค่าแล้ว

:: --- BcdEdit: กลับค่า default ---
echo [2/4] คืนค่า BcdEdit...
bcdedit /deletevalue useplatformtick >nul 2>&1
bcdedit /deletevalue useplatformclock >nul 2>&1
bcdedit /deletevalue disabledynamictick >nul 2>&1
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
echo     ✓ BcdEdit คืนค่าแล้ว

:: --- Registry: ลบค่าที่เพิ่ม ---
echo [3/4] คืนค่า Registry...
echo     (ถ้ามี backup_*.reg ที่ Desktop ให้ double-click เพื่อ restore)
echo     กำลังลบค่าที่เพิ่มเข้าไป...

:: ลบ TCP/IP tweaks
for %%v in (Tcp1323Opts TcpWindowSize GlobalMaxTcpWindowSize MaxUserPort TcpTimedWaitDelay TcpMaxDataRetransmissions DefaultTTL EnablePMTUDiscovery EnablePMTUBHDetect SackOpts MaxFreeTcbs MaxHashTableSize IRPStackSize DisableTaskOffload TcpNumConnections EnableECNCapability DisableUserTOSSetting ArpCacheLife ArpCacheMinReferencedLife ArpUseEtherSNAP KeepAliveTime KeepAliveInterval TcpAckFrequency TCPNoDelay TcpDelAckTicks DelayedAckTicks DelayedAckFrequency EnableWsd UdpMaxDatagramSend UdpMaxDatagramReceive TcpMaxDupAcks DefaultRcvWindow DefaultSendWindow TcpRfc1323 SynAttackProtect MaxSynBacklog TcpInitialRtt TcpSendSegmentSize FastUserModeLimit TcpConnectionsPerNetworkInterface) do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v %%v /f >nul 2>&1
)

:: ลบ QoS
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /f >nul 2>&1

:: ลบ AFD tweaks
for %%v in (FastSendDatagramThreshold FastCopyReceiveThreshold DefaultReceiveWindow DefaultSendWindow DynamicSendBufferDisable IgnorePushBitOnReceives NonBlockingSendSpecialBuffering DoNotUseBufferChaining PriorityBoost ReusePortMinimum ReusePortUpper) do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v %%v /f >nul 2>&1
)

:: ลบ DNS Cache tweaks
for %%v in (MaxCacheTtl MaxNegativeCacheTtl NegativeCacheTime NetFailureCacheTime CacheHashTableBucketSize MaximumCacheSize) do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v %%v /f >nul 2>&1
)

echo     ✓ Registry คืนค่าแล้ว

:: --- DNS: กลับเป็น DHCP ---
echo [4/4] คืนค่า DNS เป็น DHCP...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {" ^
"    netsh interface ip set dns name=$($_.Name) dhcp | Out-Null;" ^
"    Write-Host ('    ✓ ' + $_.Name + ' → DHCP')" ^
"}"

:: --- Bindings: เปิดคืน ---
echo.
echo เปิด Bindings คืน...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$bindings = @('ms_tcpip6','ms_lldp','ms_lltdio','ms_rspndr','ms_server','ms_msclient');" ^
"foreach ($b in $bindings) {" ^
"    try { Enable-NetAdapterBinding -Name '*' -ComponentID $b -EA SilentlyContinue; Write-Host ('    ✓ เปิด ' + $b) } catch {}" ^
"}"

echo.
echo =============================================
echo  ✅ กลับค่า Default ทั้งหมดเสร็จแล้ว!
echo  ⚠ กรุณา Restart Windows เพื่อให้มีผล
echo =============================================
pause
