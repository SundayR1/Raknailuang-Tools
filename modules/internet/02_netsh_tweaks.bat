@echo off
:: =====================================================================
:: InternetAspas - Network Optimization: Netsh Commands
:: =====================================================================
:: สิ่งที่ไฟล์นี้ทำ: ปรับค่า TCP/IP stack ผ่าน netsh command
:: ⚠ ต้อง Run as Administrator
:: =====================================================================

echo =============================================
echo  InternetAspas - Netsh TCP/IP Tuning
echo =============================================
echo.

:: --- TCP Heuristics ---
:: ปิด heuristics ที่ Windows ใช้ปรับ auto-tuning เอง
:: เพื่อให้เราควบคุมค่าเองได้
echo [1/18] ปิด TCP Heuristics...
netsh int tcp set heuristics disabled

:: --- ECN (Explicit Congestion Notification) ---
:: ปิด ECN เพราะ router/ISP เก่าบางตัวไม่รองรับ
:: ทำให้ packet ถูกทิ้งแทนที่จะบอก congestion
echo [2/18] ปิด ECN...
netsh int tcp set global ecncapability=disabled

:: --- ISATAP (IPv6 tunneling) ---
:: ปิด ISATAP tunnel — ไม่จำเป็นในเน็ตบ้านทั่วไป
:: ลด overhead จาก IPv6 tunneling ที่ไม่ได้ใช้
echo [3/18] ปิด ISATAP...
netsh interface isatap set state disabled

:: --- TCP Timestamps ---
:: ปิด TCP timestamp — ลดขนาด TCP header 12 bytes ต่อ packet
:: ⚠ อาจส่งผลกับ PAWS (Protection Against Wrapped Sequences)
echo [4/18] ปิด TCP Timestamps...
netsh int tcp set global timestamps=disabled

:: --- Non-SACK RTT Resiliency ---
:: ปิด — ไม่ต้องการ fallback RTT calculation เมื่อไม่มี SACK
echo [5/18] ปิด Non-SACK RTT Resiliency...
netsh int tcp set global nonsackrttresiliency=disabled

:: --- Initial RTO (Retransmission Timeout) ---
:: ค่า 1000ms (1 วินาที) — ค่า default คือ 3000ms
:: ส่งซ้ำเร็วขึ้นถ้า packet แรกหาย → เชื่อมต่อเร็วขึ้น
echo [6/18] ตั้ง Initial RTO = 1000ms...
netsh int tcp set global initialRto=1000

:: --- Congestion Provider = CUBIC ---
:: ใช้ CUBIC algorithm สำหรับทุก template (internet/compat/custom)
:: CUBIC ดีกว่า NewReno สำหรับ high-bandwidth, high-latency links
:: ใช้กันทั่วไปใน Linux / modern networks
echo [7/18] ตั้ง Congestion Provider = CUBIC...
netsh int tcp set supplemental template=internet congestionprovider=cubic
netsh int tcp set supplemental template=compat congestionprovider=cubic
netsh int tcp set supplemental template=custom congestionprovider=cubic

:: --- Task Offload ---
:: เปิด — ให้ NIC ช่วยคำนวณ checksum, segmentation แทน CPU
echo [8/18] เปิด Task Offload...
netsh int ip set global taskoffload=enabled

:: --- Auto-Tuning Level = Restricted ---
:: จำกัดการขยาย receive window อัตโนมัติ
:: "restricted" = ขยายได้บ้างแต่ไม่มาก
:: ช่วยกับ ISP บางเจ้าที่จำกัด window size
:: ค่าอื่นที่เลือกได้: normal, highlyrestricted, disabled, experimental
echo [9/18] ตั้ง Auto-Tuning = Restricted...
netsh int tcp set global autotuninglevel=restricted

:: --- RSC (Receive Segment Coalescing) ---
:: ปิด — RSC รวม packet หลายตัวเป็นก้อนใหญ่
:: ดีสำหรับ throughput แต่เพิ่ม latency → ปิดเพื่อลด latency
echo [10/18] ปิด RSC...
netsh int tcp set global rsc=disabled

:: --- RSS (Receive Side Scaling) ---
:: เปิด — กระจาย network interrupt ไปหลาย CPU core
:: ดีสำหรับ multi-core CPU → ประมวลผล packet ได้เร็วขึ้น
echo [11/18] เปิด RSS...
netsh int tcp set global rss=enabled

:: --- DCA (Direct Cache Access) ---
:: เปิด — ให้ NIC เขียนข้อมูลตรงเข้า CPU cache
:: ลด memory latency สำหรับ network data
echo [12/18] เปิด DCA...
netsh int tcp set global dca=enabled

:: --- TCP Fast Open ---
:: เปิด — ส่งข้อมูลพร้อม SYN packet ตั้งแต่ handshake แรก
:: ลด round-trip 1 ครั้ง → เปิดเว็บเร็วขึ้น
echo [13/18] เปิด TCP Fast Open...
netsh int tcp set global fastopen=enabled
netsh int tcp set global fastopenfallback=enabled

:: --- ICMP Redirects ---
:: ปิด — ไม่ให้ router เปลี่ยนเส้นทาง packet ผ่าน ICMP
:: เพิ่มความปลอดภัย (ป้องกัน ICMP redirect attack)
echo [14/18] ปิด ICMP Redirects...
netsh int ip set global icmpredirects=disabled

:: --- Multicasting ---
:: ปิด — ไม่ใช้ multicast (IGMP) → ลด traffic ที่ไม่จำเป็น
echo [15/18] ปิด Multicasting...
netsh int ip set global multicasting=disabled

echo.
echo =============================================
echo  ✅ Netsh TCP/IP Tuning เสร็จเรียบร้อย!
echo  ⚠ กรุณา Restart Windows เพื่อให้มีผล
echo =============================================
pause
