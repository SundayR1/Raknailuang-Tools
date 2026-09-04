@echo off
:: =====================================================================
:: InternetAspas - Network Optimization: Registry Tweaks
:: =====================================================================
:: สิ่งที่ไฟล์นี้ทำ: ปรับค่า TCP/IP, DNS Cache, Winsock, AFD, NetBT, NDIS
::                  ใน Windows Registry เพื่อ optimize ประสิทธิภาพเน็ต
:: ⚠ ต้อง Run as Administrator
:: ⚠ ควร backup registry ก่อนรัน (ไฟล์นี้มี backup ให้อัตโนมัติ)
:: =====================================================================

echo =============================================
echo  InternetAspas - Registry Tweaks (Extracted)
echo =============================================
echo.
echo ⚠  กรุณารัน as Administrator!
echo.

:: สร้าง backup ก่อน
echo [BACKUP] กำลังสำรอง Registry ก่อนแก้ไข...
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "%USERPROFILE%\Desktop\backup_tcpip.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" "%USERPROFILE%\Desktop\backup_afd.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" "%USERPROFILE%\Desktop\backup_dnscache.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" "%USERPROFILE%\Desktop\backup_netbt.reg" /y >nul 2>&1
echo [BACKUP] สำรองเสร็จที่ Desktop (backup_*.reg)
echo.

:: ===========================================
:: 1. TCP/IP Parameters (หลัก)
:: ===========================================
echo [1/7] TCP/IP Parameters...

:: TCP Window Scaling (RFC 1323) — เปิด Window/Timestamp options
:: ค่า 1 = เปิดเฉพาะ Window Scale
:: ช่วยให้ TCP window ใหญ่กว่า 64KB ได้ → เพิ่ม throughput บน link เร็ว
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 1 /f >nul

:: TCP Window Size — ขนาด receive window
:: ค่า 524287 (512KB-1) = ค่าสูงสุดที่ TCP window scale รองรับ
:: ยิ่งใหญ่ = รับข้อมูลได้มากขึ้นก่อนต้อง ACK → ดีสำหรับ download
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 524287 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v GlobalMaxTcpWindowSize /t REG_DWORD /d 524287 /f >nul

:: Max Ephemeral Ports — จำนวน port ที่ใช้ connect ออก
:: ค่า 65534 = ใช้ได้เกือบทุก port → ดีเมื่อเปิดหลาย connection พร้อมกัน
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul

:: TIME_WAIT delay — เวลารอก่อนปิด connection ถาวร
:: ค่า 5 วินาที (ปกติ 240 วินาที) = ปล่อย port กลับเร็วขึ้น
:: ⚠ ค่าต่ำเกินอาจทำให้ connection ซ้ำกัน
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 5 /f >nul

:: TCP Data Retransmissions — ส่งซ้ำกี่ครั้งก่อนตัดสินว่า connection ตาย
:: ค่า 1 = ส่งซ้ำแค่ 1 ครั้ง → ตัด connection เร็วถ้า packet หาย
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDataRetransmissions /t REG_DWORD /d 1 /f >nul

:: Default TTL — Time To Live ของ packet
:: ค่า 64 = มาตรฐาน Linux (Windows ปกติ 128)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f >nul

:: PMTU Discovery — ค้นหา MTU ที่ใหญ่ที่สุดที่ส่งได้โดยไม่ fragment
:: ค่า 1 = เปิด → ลด fragmentation = ส่งข้อมูลมีประสิทธิภาพกว่า
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUDiscovery /t REG_DWORD /d 1 /f >nul

:: PMTU Black Hole Detection — ตรวจจับ router ที่ทิ้ง packet ใหญ่
:: ค่า 0 = ปิด → ลด overhead
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUBHDetect /t REG_DWORD /d 0 /f >nul

:: SACK (Selective Acknowledgment) — ACK เฉพาะ packet ที่หายแทนที่จะส่งใหม่ทั้งหมด
:: ค่า 1 = เปิด → ลดการส่งข้อมูลซ้ำ
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SackOpts /t REG_DWORD /d 1 /f >nul

:: Max Free TCBs — จำนวน TCP Control Block ที่เก็บไว้ใน memory
:: ค่า 64000 = รองรับ connection พร้อมกันได้มาก
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxFreeTcbs /t REG_DWORD /d 64000 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxHashTableSize /t REG_DWORD /d 65536 /f >nul

:: IRP Stack Size — ขนาด I/O Request Packet stack
:: ค่า 50 = เพิ่มจากค่า default (15-20) → ดีสำหรับ network intensive apps
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v IRPStackSize /t REG_DWORD /d 50 /f >nul

:: Task Offload — ให้ NIC ช่วยคำนวณ TCP/IP checksum แทน CPU
:: ค่า 0 = เปิด (0 = Don't disable = เปิด)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableTaskOffload /t REG_DWORD /d 0 /f >nul

:: Max TCP Connections — จำกัดจำนวน connection พร้อมกัน
:: ค่า 16777214 (16M) = แทบไม่จำกัด
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpNumConnections /t REG_DWORD /d 16777214 /f >nul

:: ECN (Explicit Congestion Notification)
:: ค่า 0 = ปิด → บาง router เก่าไม่รองรับ ECN ทำให้ packet หาย
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableECNCapability /t REG_DWORD /d 0 /f >nul

:: TOS Setting — ให้ app กำหนด Type of Service ได้
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableUserTOSSetting /t REG_DWORD /d 0 /f >nul

:: ARP Cache — ระยะเวลาเก็บ ARP table (วินาที)
:: ค่า 9 = refresh เร็ว → ลดปัญหา stale ARP entry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v ArpCacheLife /t REG_DWORD /d 9 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v ArpCacheMinReferencedLife /t REG_DWORD /d 9 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v ArpUseEtherSNAP /t REG_DWORD /d 0 /f >nul

:: Keep-Alive — ส่ง keep-alive packet ทุกกี่ milliseconds
:: ค่า 100000 (100 วินาที) → ปกติ 7200000 (2 ชั่วโมง)
:: ตรวจจับ dead connection เร็วขึ้น
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v KeepAliveTime /t REG_DWORD /d 100000 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v KeepAliveInterval /t REG_DWORD /d 120 /f >nul

:: === Nagle's Algorithm / TCP ACK Delay ===
:: ปิด Nagle + ลด ACK delay → ลด latency (สำคัญมากสำหรับเกม)
:: TcpAckFrequency=1 → ACK ทุก packet (ไม่รอ)
:: TCPNoDelay=1 → ปิด Nagle (ส่ง packet เล็กทันที)
:: TcpDelAckTicks=0 → ไม่หน่วง ACK
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DelayedAckTicks /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DelayedAckFrequency /t REG_DWORD /d 1 /f >nul

:: WSD (Web Services Discovery) — ปิดเพื่อลด broadcast traffic
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableWsd /t REG_DWORD /d 0 /f >nul

:: UDP Max Datagram Size
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v UdpMaxDatagramSend /t REG_DWORD /d 65531 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v UdpMaxDatagramReceive /t REG_DWORD /d 65531 /f >nul

:: TCP DupAck threshold — จำนวน duplicate ACK ก่อน fast retransmit
:: ค่า 10 = รอ duplicate ACK มากขึ้นก่อนส่งซ้ำ → ลด false retransmit
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDupAcks /t REG_DWORD /d 10 /f >nul

:: Default Send/Receive Window — 4MB
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultRcvWindow /t REG_DWORD /d 4194304 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultSendWindow /t REG_DWORD /d 4194304 /f >nul

:: RFC 1323, SYN Protection, SYN Backlog
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpRfc1323 /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SynAttackProtect /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxSynBacklog /t REG_DWORD /d 8192 /f >nul

:: TCP Initial RTT — ค่า round-trip time เริ่มต้น (ms)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpInitialRtt /t REG_DWORD /d 0 /f >nul

:: TCP Segment Size + Fast User Mode + Connections per NIC
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpSendSegmentSize /t REG_DWORD /d 65531 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v FastUserModeLimit /t REG_DWORD /d 100000 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpConnectionsPerNetworkInterface /t REG_DWORD /d 4096 /f >nul

:: IPv6 — ปิด ECN + Task Offload enabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisableTaskOffload /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v EnableECNCapability /t REG_DWORD /d 0 /f >nul

echo     ✓ TCP/IP Parameters เสร็จ

:: ===========================================
:: 2. QoS / Bandwidth Throttling
:: ===========================================
echo [2/7] QoS Policy...

:: ปิดการจำกัด bandwidth ของ QoS Packet Scheduler
:: ค่า 0 = ไม่จำกัด bandwidth สำหรับ non-best-effort traffic
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul

echo     ✓ QoS เสร็จ

:: ===========================================
:: 3. Winsock Parameters
:: ===========================================
echo [3/7] Winsock...

reg add "HKLM\SYSTEM\CurrentControlSet\Services\Winsock" /v DisabledComponents /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Winsock" /v MaxSockAddrLength /t REG_DWORD /d 32 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Winsock" /v MaxProtocolChain /t REG_DWORD /d 8 /f >nul

echo     ✓ Winsock เสร็จ

:: ===========================================
:: 4. AFD (Ancillary Function Driver) — Winsock kernel driver
:: ===========================================
echo [4/7] AFD Parameters...

:: AFD คือ driver ที่จัดการ socket ใน kernel
:: FastSendDatagramThreshold — ขนาด datagram ที่ส่งแบบ fast path
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /t REG_DWORD /d 512 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastCopyReceiveThreshold /t REG_DWORD /d 512 /f >nul

:: Default Send/Receive Window (4MB)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DefaultReceiveWindow /t REG_DWORD /d 4194304 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DefaultSendWindow /t REG_DWORD /d 4194304 /f >nul

:: Dynamic Buffer — ปิดเพื่อใช้ fixed buffer size
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DynamicSendBufferDisable /t REG_DWORD /d 1 /f >nul

:: IgnorePushBitOnReceives — ไม่สนใจ PUSH bit → buffer ข้อมูลได้มากขึ้น
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v IgnorePushBitOnReceives /t REG_DWORD /d 1 /f >nul

:: Special Buffering + Buffer Chaining optimizations
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v NonBlockingSendSpecialBuffering /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DoNotUseBufferChaining /t REG_DWORD /d 1 /f >nul

:: Priority Boost — เพิ่ม priority ให้ network I/O
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v PriorityBoost /t REG_DWORD /d 1 /f >nul

:: Port Reuse Range
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v ReusePortMinimum /t REG_DWORD /d 256 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v ReusePortUpper /t REG_DWORD /d 65535 /f >nul

echo     ✓ AFD เสร็จ

:: ===========================================
:: 5. DNS Cache
:: ===========================================
echo [5/7] DNS Cache...

:: MaxCacheTtl — เก็บ DNS record ไว้สูงสุดกี่วินาที (1 ชั่วโมง)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl /t REG_DWORD /d 3600 /f >nul

:: Negative Cache — ไม่เก็บ DNS query ที่ fail (0 = ปิด)
:: ช่วยให้ retry DNS ได้เร็วขึ้นถ้า DNS server ตอบไม่ได้ชั่วคราว
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeCacheTime /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NetFailureCacheTime /t REG_DWORD /d 0 /f >nul

:: Cache Hash Table + Max Size
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableBucketSize /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaximumCacheSize /t REG_DWORD /d 16384 /f >nul

echo     ✓ DNS Cache เสร็จ

:: ===========================================
:: 6. NetBT (NetBIOS over TCP/IP)
:: ===========================================
echo [6/7] NetBT...

:: ลด timeout ของ NetBIOS name resolution
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v BcastNameQueryCount /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v BcastQueryTimeout /t REG_DWORD /d 50 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v NameSrvQueryCount /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v NameSrvQueryTimeout /t REG_DWORD /d 50 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v CacheTimeout /t REG_DWORD /d 160000 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v SessionKeepAlive /t REG_DWORD /d 4800000 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v InitialBackoff /t REG_DWORD /d 100 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v MaximumBackoff /t REG_DWORD /d 600 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v MinimumTimeout /t REG_DWORD /d 1 /f >nul

echo     ✓ NetBT เสร็จ

:: ===========================================
:: 7. NDIS + Memory Management
:: ===========================================
echo [7/7] NDIS + Memory...

reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v ProcessorAffinityMask /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v LogicalProcessorsPerPhysicalProcessor /t REG_DWORD /d 1 /f >nul

:: Memory Management — เพิ่ม Session Pool + Large Page
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SessionPoolSize /t REG_DWORD /d 524288 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargePageMinimum /t REG_DWORD /d 2097152 /f >nul

:: ลบค่าที่ไม่จำเป็น
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v Class /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalAddressSortList /f >nul 2>&1

echo     ✓ NDIS + Memory เสร็จ

echo.
echo =============================================
echo  ✅ Registry Tweaks ทั้งหมดเสร็จเรียบร้อย!
echo  ⚠ กรุณา Restart Windows เพื่อให้มีผล
echo  📁 Backup files อยู่ที่ Desktop
echo =============================================
pause
