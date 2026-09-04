@echo off
:: =====================================================================
:: InternetAspas - NIC (Network Adapter) Advanced Properties
:: =====================================================================
:: สิ่งที่ไฟล์นี้ทำ: ปรับค่า advanced ของ NIC ทุกตัวผ่าน Registry
::   ปิดฟีเจอร์ประหยัดพลังงาน, offload ที่ไม่จำเป็น,
::   เพิ่ม buffer, เปิด RSS/LLI
:: ⚠ ต้อง Run as Administrator
:: =====================================================================

echo =============================================
echo  InternetAspas - NIC Advanced Properties
echo =============================================
echo.

:: Path ของ NIC class ใน Registry
:: แต่ละ adapter จะอยู่ใน subkey 0001, 0002, ... ฯลฯ
set NICPATH=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}

echo ใช้ PowerShell เพื่อปรับค่า NIC ทุกตัวอัตโนมัติ...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$nicRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}';" ^
"$adapters = Get-ChildItem $nicRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' -and $_.GetValue('DriverDesc') -ne $null };" ^
"Write-Host ('พบ NIC ' + $adapters.Count + ' ตัว');" ^
"" ^
"# === รายการค่าที่ปรับ ===" ^
"$props = @{" ^
"    # --- ปิดฟีเจอร์ประหยัดพลังงาน ---" ^
"    # ปิดการ sleep เมื่อถอดสาย LAN" ^
"    '*DeviceSleepOnDisconnect' = '0'" ^
"    # ปิด Energy Efficient Ethernet (ลด speed เพื่อประหยัดไฟ)" ^
"    '*EEE' = '0'" ^
"    # ปิด Flow Control (ส่ง PAUSE frame เมื่อ buffer เต็ม)" ^
"    '*FlowControl' = '0'" ^
"    # ปิด Auto Power Save Mode" ^
"    'AutoPowerSaveModeEnabled' = '0'" ^
"    # ปิด Wake-on-LAN (Magic Packet)" ^
"    '*WakeOnMagicPacket' = '0'" ^
"    # ปิด Wake-on-Pattern" ^
"    '*WakeOnPattern' = '0'" ^
"    # ปิด Wake on Link Change" ^
"    'WakeOnLink' = '0'" ^
"    'WakeOnSlot' = '0'" ^
"    'WakeUpModeCap' = '0'" ^
"    # ปิด Selective Suspend (USB NIC)" ^
"    '*SelectiveSuspend' = '0'" ^
"    # ปิด EEE variants" ^
"    'EEELinkAdvertisement' = '0'" ^
"    'EeePhyEnable' = '0'" ^
"    'AdvancedEEE' = '0'" ^
"    # ปิด Green Ethernet (ลด speed ตามสาย)" ^
"    'EnableGreenEthernet' = '0'" ^
"    'GigaLite' = '0'" ^
"    # ปิด Power Saving modes ทุกตัว" ^
"    'PowerSavingMode' = '0'" ^
"    'ULPMode' = '0'" ^
"    'ReduceSpeedOnPowerDown' = '0'" ^
"    'PowerDownPll' = '0'" ^
"    'EnablePME' = '0'" ^
"    'EnableDynamicPowerGating' = '0'" ^
"    'EnableConnectedPowerGating' = '0'" ^
"    'NicAutoPowerSaver' = '0'" ^
"    'DisableDelayedPowerUp' = '0'" ^
"    '' = ''" ^
"    # --- ปิด Interrupt Moderation ---" ^
"    # Interrupt Moderation = NIC รอสะสม packet ก่อนส่ง interrupt" ^
"    # ปิด = interrupt ทุก packet → latency ต่ำสุด (ดีสำหรับเกม)" ^
"    # ⚠ อาจเพิ่ม CPU usage เล็กน้อย" ^
"    '*InterruptModeration' = '0'" ^
"    '*InterruptModerationRate' = '0'" ^
"    'DMACoalescing' = '0'" ^
"    'ITR' = '0'" ^
"    '' = ''" ^
"    # --- ปิด Offload ที่ไม่จำเป็น ---" ^
"    # LSO (Large Send Offload) = NIC แบ่ง segment แทน CPU" ^
"    # ปิดเพราะบาง NIC ทำได้ไม่ดี → เพิ่ม latency" ^
"    '*LsoV2IPv4' = '0'" ^
"    '*LsoV2IPv6' = '0'" ^
"    '*LsoV1IPv4' = '0'" ^
"    # ปิด Checksum Offload" ^
"    '*IPChecksumOffloadIPv4' = '0'" ^
"    '*TCPChecksumOffloadIPv4' = '0'" ^
"    '*TCPChecksumOffloadIPv6' = '0'" ^
"    '*UDPChecksumOffloadIPv4' = '0'" ^
"    '*UDPChecksumOffloadIPv6' = '0'" ^
"    # ปิด ARP/NS Offload (Wake-on-LAN related)" ^
"    '*PMARPOffload' = '0'" ^
"    '*PMNSOffload' = '0'" ^
"    '*PacketDirect' = '0'" ^
"    '' = ''" ^
"    # --- เปิดฟีเจอร์ที่ช่วย ---" ^
"    # RSS = กระจาย packet ไปหลาย CPU core" ^
"    '*RSS' = '1'" ^
"    '*NumRssQueues' = '2'" ^
"    # เพิ่ม Buffer (ค่า default มักเป็น 256)" ^
"    '*ReceiveBuffers' = '2048'" ^
"    '*TransmitBuffers' = '2048'" ^
"    # Priority VLAN Tag (จำเป็นสำหรับ QoS)" ^
"    '*PriorityVLANTag' = '1'" ^
"    # ไม่รอ Auto-Negotiation ให้เสร็จ → connect เร็วขึ้น" ^
"    'WaitAutoNegComplete' = '0'" ^
"    # เปิด Low Latency Interrupt" ^
"    'EnableLLI' = '1'" ^
"    # ปิด Coalescing" ^
"    'EnableCoalesce' = '0'" ^
"    'CoalesceBufferSize' = '2048'" ^
"    'EnableUDPTxScaling' = '0'" ^
"    # MTU = 1492 (เหมาะกับ PPPoE)" ^
"    'MTU' = '1492'" ^
"};" ^
"" ^
"$count = 0;" ^
"foreach ($adapter in $adapters) {" ^
"    $desc = $adapter.GetValue('DriverDesc');" ^
"    Write-Host ('  NIC: ' + $desc);" ^
"    foreach ($key in $props.Keys) {" ^
"        if ($key -eq '') { continue }" ^
"        try { Set-ItemProperty -Path $adapter.PSPath -Name $key -Value $props[$key] -ErrorAction SilentlyContinue } catch {}" ^
"    }" ^
"    # PnPCapabilities = 24 (DWord) — ปิด Power Management ของ NIC" ^
"    try { Set-ItemProperty -Path $adapter.PSPath -Name 'PnPCapabilities' -Value 24 -Type DWord -ErrorAction SilentlyContinue } catch {}" ^
"    $count++;" ^
"}" ^
"Write-Host '';" ^
"Write-Host ('✅ ปรับค่า NIC เสร็จ ' + $count + ' ตัว')"

echo.
echo =============================================
echo  ✅ NIC Advanced Properties เสร็จเรียบร้อย!
echo  ⚠ กรุณา Restart Windows เพื่อให้มีผล
echo =============================================
pause
