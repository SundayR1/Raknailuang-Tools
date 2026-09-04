@echo off
:: =====================================================================
:: InternetAspas - Disable Network Bindings + DNS Optimization
:: =====================================================================
:: สิ่งที่ไฟล์นี้ทำ:
::   1. ปิด Network Protocol Bindings ที่ไม่จำเป็น
::   2. เปลี่ยน DNS เป็น Cloudflare (1.1.1.1) + flush cache
:: ⚠ ต้อง Run as Administrator
:: =====================================================================

echo =============================================
echo  InternetAspas - Bindings + DNS
echo =============================================
echo.

:: ===========================================
:: 1. ปิด Network Bindings ที่ไม่จำเป็น
:: ===========================================
echo [1/2] ปิด Network Bindings ที่ไม่จำเป็น...
echo.

:: ms_tcpip6      = IPv6
::   ปิดเพราะ: ISP ส่วนใหญ่ในไทยยังใช้ IPv4 เป็นหลัก
::   IPv6 เพิ่ม overhead + บาง game server ไม่รองรับ
::   ⚠ ถ้า ISP ใช้ IPv6 อย่าปิด!
echo   - ปิด IPv6 (ms_tcpip6)...

:: vmware_bridge  = VMware Bridge Protocol
::   ปิดเพราะ: ใช้เฉพาะ VMware → ถ้าไม่ได้ใช้ VM ปิดได้
echo   - ปิด VMware Bridge...

:: ms_lldp        = Link-Layer Discovery Protocol
::   ปิดเพราะ: ใช้ใน enterprise network เท่านั้น
echo   - ปิด LLDP...

:: ms_lltdio      = Link-Layer Topology Discovery I/O
::   ปิดเพราะ: ใช้สำหรับ network map ใน Windows → ไม่จำเป็น
echo   - ปิด LLTD I/O...

:: ms_implat       = Microsoft Network Adapter Multiplexor
::   ปิดเพราะ: ใช้สำหรับ NIC teaming → คนทั่วไปไม่ได้ใช้
echo   - ปิด Network Adapter Multiplexor...

:: ms_rspndr      = Link-Layer Topology Discovery Responder
::   ปิดเพราะ: เหมือน LLTD I/O → ไม่จำเป็น
echo   - ปิด LLTD Responder...

:: ms_server      = File and Printer Sharing
::   ปิดเพราะ: ถ้าไม่ share file/printer ในเครือข่าย ปิดได้
::   ⚠ ถ้าใช้ share folder ในบ้าน อย่าปิด!
echo   - ปิด File and Printer Sharing...

:: ms_msclient    = Client for Microsoft Networks
::   ปิดเพราะ: ใช้สำหรับ access shared resources
::   ⚠ ถ้าใช้ network drive / share folder อย่าปิด!
echo   - ปิด Client for Microsoft Networks...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$bindings = @('ms_tcpip6','vmware_bridge','ms_lldp','ms_lltdio','ms_implat','ms_rspndr','ms_server','ms_msclient');" ^
"foreach ($b in $bindings) {" ^
"    try {" ^
"        Disable-NetAdapterBinding -Name '*' -ComponentID $b -ErrorAction SilentlyContinue" ^
"        Write-Host ('    ✓ ปิด ' + $b)" ^
"    } catch {" ^
"        Write-Host ('    ⚠ ข้าม ' + $b + ' (ไม่พบ)')" ^
"    }" ^
"}"

echo.
echo     ✓ Bindings เสร็จ
echo.

:: ===========================================
:: 2. DNS Optimization
:: ===========================================
echo [2/2] เปลี่ยน DNS เป็น Cloudflare + Google...
echo.

:: Cloudflare DNS:
::   Primary:   1.1.1.1
::   Secondary: 1.0.0.1
::   ข้อดี: เร็วที่สุดในโลก (avg ~11ms), privacy-focused
::
:: Google DNS:
::   Primary:   8.8.8.8
::   Secondary: 8.8.4.4
::   ข้อดี: เสถียร, มี global anycast
::
:: InternetAspas ใช้: Preferred=1.1.1.1, Alternate=1.0.0.1 (Cloudflare เท่านั้น)

:: ปรับ DNS ทุก adapter ที่ active
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceType -ne 24 };" ^
"foreach ($a in $adapters) {" ^
"    $name = $a.Name;" ^
"    Write-Host ('  Adapter: ' + $name);" ^
"    netsh interface ip set dns name=$name static 1.1.1.1 primary | Out-Null;" ^
"    netsh interface ip add dns name=$name 1.0.0.1 index=2 | Out-Null;" ^
"    Write-Host ('    DNS → 1.1.1.1 / 1.0.0.1 (Cloudflare)');" ^
"}" ^
"Write-Host ''" ^
"Write-Host '  Flushing DNS cache...';" ^
"ipconfig /flushdns | Out-Null;" ^
"Write-Host '    ✓ DNS cache cleared'"

echo.
echo =============================================
echo  ✅ Bindings + DNS เสร็จเรียบร้อย!
echo.
echo  DNS ปัจจุบัน: 1.1.1.1 / 1.0.0.1 (Cloudflare)
echo.
echo  ถ้าต้องการเปลี่ยนเป็น Google DNS:
echo    netsh interface ip set dns name="Wi-Fi" static 8.8.8.8 primary
echo    netsh interface ip add dns name="Wi-Fi" 8.8.4.4 index=2
echo.
echo  ถ้าต้องการกลับเป็น Auto (DHCP):
echo    netsh interface ip set dns name="Wi-Fi" dhcp
echo =============================================
pause
