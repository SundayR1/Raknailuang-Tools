# ============================================================
#  Aspas Settings - TCP/IP & AFD System Settings
#  สคริปต์ปรับค่า TCP/IP ระดับ Windows + Winsock (AFD)
#  แกะมาจาก Aspas Settings.exe
# ============================================================
#  ⚠️ ต้องรัน PowerShell ด้วยสิทธิ์ Admin
# ============================================================

Write-Host "=== TCP/IP & AFD System Optimization ===" -ForegroundColor Cyan

# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 1: TCP Global Settings (netsh)                  ║
# ╚═══════════════════════════════════════════════════════════╝

# ─── TCP Auto-Tuning Level → Normal ───
# ให้ Windows ปรับ TCP Receive Window Size อัตโนมัติ
# "normal" = ค่าเริ่มต้นที่ดี — Windows จะเพิ่ม/ลด window size ตาม bandwidth
netsh int tcp set global autotuninglevel=normal

# ─── ดูค่า TCP Global ปัจจุบัน ───
Write-Host "`n--- TCP Global Settings ---" -ForegroundColor Yellow
netsh int tcp show global

Write-Host "`n--- IPv4 Global Settings ---" -ForegroundColor Yellow
netsh int ipv4 show global


# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 2: Registry - Tcpip Parameters                  ║
# ║  ที่อยู่: HKLM:\SYSTEM\CurrentControlSet\Services\       ║
# ║          Tcpip\Parameters                                 ║
# ╚═══════════════════════════════════════════════════════════╝

$tcpipPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'

Write-Host "`n--- Tcpip\Parameters Registry Values ---" -ForegroundColor Yellow

# ค่าที่ Aspas อ่าน (ไม่ได้เซ็ตเอง — แค่แสดงสถานะ):
$tcpipKeys = @(
    # DisableTaskOffload:
    #   0 = เปิด (ปกติ) — ให้ NIC ช่วย CPU ทำงาน (checksum, LSO)
    #   1 = ปิด — บังคับให้ CPU ทำทุกอย่างเอง
    'DisableTaskOffload',

    # EnableWannaOutcoming:
    #   ค่า custom ที่ไม่ได้มีใน Windows มาตรฐาน
    #   อาจเกี่ยวกับ WAN optimization
    'EnableWannaOutcoming'
)

foreach ($key in $tcpipKeys) {
    $val = (Get-ItemProperty -Path $tcpipPath -Name $key -EA SilentlyContinue).$key
    $status = if ($val -ne $null) { $val } else { "(ไม่ได้ตั้ง)" }
    Write-Host "  $key = $status"
}


# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 3: AFD (Ancillary Function Driver) Parameters   ║
# ║  ที่อยู่: HKLM:\SYSTEM\CurrentControlSet\Services\       ║
# ║          AFD\Parameters                                   ║
# ║                                                           ║
# ║  AFD = driver ที่อยู่ระหว่าง Winsock API กับ TCP/IP      ║
# ║  ควบคุม buffer sizes, connection behavior, performance    ║
# ╚═══════════════════════════════════════════════════════════╝

$afdPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters'

Write-Host "`n--- AFD Parameters Registry Values ---" -ForegroundColor Yellow
Write-Host "(AFD = Winsock kernel driver ที่ควบคุม buffer ส่ง/รับ data)" -ForegroundColor DarkGray

$afdKeys = @{
    # ════════════════════════════════════════════════════════
    # Buffer Sizes
    # ════════════════════════════════════════════════════════

    'DefaultReceiveWindow' = @{
        Desc = "ขนาด buffer รับข้อมูล (bytes)"
        Note = "ยิ่งใหญ่ = รับ data ได้มากขึ้นต่อรอบ → ดีสำหรับ throughput"
    }
    'DefaultSendWindow' = @{
        Desc = "ขนาด buffer ส่งข้อมูล (bytes)"
        Note = "ยิ่งใหญ่ = queue data ส่งได้มากขึ้น"
    }
    'SmallBufferSize' = @{
        Desc = "ขนาด buffer เล็ก (bytes)"
        Note = "สำหรับ packet เล็กๆ เช่น ACK, keepalive"
    }
    'MediumBufferSize' = @{
        Desc = "ขนาด buffer กลาง (bytes)"
        Note = "สำหรับ packet ทั่วไป"
    }
    'LargeBufferSize' = @{
        Desc = "ขนาด buffer ใหญ่ (bytes)"
        Note = "สำหรับ data chunk ใหญ่"
    }
    'HugeBufferSize' = @{
        Desc = "ขนาด buffer ใหญ่มาก (bytes)"
        Note = "สำหรับ data transfer ขนาดใหญ่"
    }

    # ════════════════════════════════════════════════════════
    # Buffer Pool Depths
    # ════════════════════════════════════════════════════════

    'SmallBufferListDepth' = @{
        Desc = "จำนวน buffer เล็กที่เตรียมไว้ (pool)"
        Note = "เพิ่ม = มี buffer พร้อมใช้มากขึ้น → ลด allocation overhead"
    }
    'MediumBufferListDepth' = @{
        Desc = "จำนวน buffer กลางที่เตรียมไว้"
        Note = "เพิ่ม = รองรับ concurrent connections มากขึ้น"
    }
    'LargBufferListDepth' = @{
        Desc = "จำนวน buffer ใหญ่ที่เตรียมไว้"
        Note = "สำหรับ large transfers"
    }

    # ════════════════════════════════════════════════════════
    # Performance Tuning
    # ════════════════════════════════════════════════════════

    'BufferMultiplier' = @{
        Desc = "ตัวคูณ buffer"
        Note = "เพิ่ม = ขยาย buffer ทั้งหมดตามสัดส่วน"
    }
    'BufferAlignment' = @{
        Desc = "การจัด alignment ของ buffer ใน memory"
        Note = "จัดให้ตรงกับ cache line → เร็วขึ้น"
    }
    'DoNotHoldNICBuffers' = @{
        Desc = "ไม่ยึด NIC buffers ไว้"
        Note = "1 = ปล่อย buffer NIC กลับเร็ว → ลด latency"
    }
    'TransmitWorker' = @{
        Desc = "จำนวน worker threads สำหรับส่งข้อมูล"
        Note = "เพิ่ม = ส่ง data พร้อมกันได้หลาย thread"
    }
    'PriorityBoost' = @{
        Desc = "เพิ่ม priority ให้ network I/O"
        Note = "1 = ให้ network ได้ CPU priority สูงขึ้น"
    }

    # ════════════════════════════════════════════════════════
    # Thresholds
    # ════════════════════════════════════════════════════════

    'FastSendDatagramThreshold' = @{
        Desc = "ขนาด datagram ที่จะใช้ fast path (bytes)"
        Note = "packet เล็กกว่าค่านี้จะส่งแบบ fast path → ลด latency"
    }
    'FastCopyReceiveThreshold' = @{
        Desc = "ขนาด data ที่จะ copy แบบ fast (bytes)"
        Note = "data เล็กกว่าค่านี้จะ copy เร็ว → ดีสำหรับ game packets"
    }

    # ════════════════════════════════════════════════════════
    # Feature Toggles
    # ════════════════════════════════════════════════════════

    'DisableAddressSharing' = @{
        Desc = "ปิด Address Sharing (SO_REUSEADDR)"
        Note = "1 = ไม่ให้ share address → ปลอดภัยกว่า"
    }
    'DisableChainedReceive' = @{
        Desc = "ปิด Chained Receive"
        Note = "1 = ไม่รวม receive buffers เป็น chain"
    }
    'DisableDirectAcceptEx' = @{
        Desc = "ปิด Direct AcceptEx"
        Note = "เกี่ยวกับ accept() ของ server socket"
    }
    'DisableRawSecurity' = @{
        Desc = "ปิด Raw Socket Security"
        Note = "0 = เปิด security check สำหรับ raw sockets"
    }
    'DynamicSendBufferDisable' = @{
        Desc = "ปิด Dynamic Send Buffer"
        Note = "1 = ใช้ fixed send buffer → predictable latency"
    }
    'IgnorePushBitOnReceives' = @{
        Desc = "ไม่สนใจ PSH flag ตอนรับ"
        Note = "1 = รอสะสม data ก่อนส่งให้ app → เพิ่ม throughput"
    }
    'IgnoreOrderlyRelease' = @{
        Desc = "ไม่สนใจ orderly release (FIN)"
        Note = "1 = ปิด connection เร็วขึ้น"
    }
}

foreach ($key in $afdKeys.Keys | Sort-Object) {
    $info = $afdKeys[$key]
    $val = (Get-ItemProperty -Path $afdPath -Name $key -EA SilentlyContinue).$key
    $status = if ($val -ne $null) { $val } else { "(ไม่ได้ตั้ง)" }
    Write-Host "  $($key.PadRight(35)) = $status" -NoNewline
    Write-Host "  # $($info.Desc)" -ForegroundColor DarkGray
}


# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 4: FiveM Specific Settings                      ║
# ╚═══════════════════════════════════════════════════════════╝

Write-Host "`n--- FiveM Settings ---" -ForegroundColor Yellow

$fmPath = 'HKCU:\Software\CitizenFX\FiveM'
$fmProps = Get-ItemProperty -Path $fmPath -EA SilentlyContinue

# CEF Hardware Acceleration
# CEF = Chromium Embedded Framework (ใช้แสดง UI ในเกม)
# เปิด = ใช้ GPU render UI → ลดภาระ CPU
$cef = if ($fmProps -and $fmProps.PSObject.Properties['CEFHardwareAcceleration']) { $fmProps.CEFHardwareAcceleration } else { "(ไม่ได้ตั้ง)" }
Write-Host "  CEFHardwareAcceleration = $cef  # ใช้ GPU render UI ในเกม"

# CPU Priority Class
# ตั้ง priority ของ FiveM.exe ให้สูงกว่า process อื่น
$fmPriPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FiveM.exe\PerfOptions'
$cpuPri = (Get-ItemProperty -Path $fmPriPath -Name 'CpuPriorityClass' -EA SilentlyContinue).CpuPriorityClass
$cpuPriStatus = if ($cpuPri -ne $null) { "$cpuPri (3=High, 2=AboveNormal)" } else { "(ไม่ได้ตั้ง)" }
Write-Host "  CpuPriorityClass = $cpuPriStatus  # priority ของ FiveM process"

# Global Timer Resolution
# ลด timer resolution ของ Windows → tick เร็วขึ้น → game loop แม่นยำขึ้น
$timerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$timer = (Get-ItemProperty -Path $timerPath -Name 'GlobalTimerResolutionRequests' -EA SilentlyContinue).GlobalTimerResolutionRequests
$timerStatus = if ($timer -ne $null) { "$timer (1=Enabled)" } else { "(ไม่ได้ตั้ง)" }
Write-Host "  GlobalTimerResolutionRequests = $timerStatus  # ให้ app ขอ timer resolution ที่ละเอียดขึ้น"

Write-Host "`n✅ แสดงค่าทั้งหมดเสร็จสมบูรณ์!" -ForegroundColor Green
