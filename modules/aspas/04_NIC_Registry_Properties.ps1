# ============================================================
#  Aspas Settings - NIC Registry Adapter Properties
#  สคริปต์แสดงค่า Registry ระดับ NIC driver
#  แกะมาจาก Aspas Settings.exe
# ============================================================
#  ⚠️ ต้องรัน PowerShell ด้วยสิทธิ์ Admin
# ============================================================

Write-Host "=== NIC Registry-Level Adapter Properties ===" -ForegroundColor Cyan
Write-Host "(ค่าเหล่านี้อยู่ใน Registry ของ driver การ์ดเน็ตโดยตรง)" -ForegroundColor DarkGray

# ค้นหา adapter ทั้งหมด
$adapters = Get-NetAdapter -Physical -EA SilentlyContinue

foreach ($ad in $adapters) {
    $guid = $ad.InterfaceGuid
    $desc = $ad.InterfaceDescription
    Write-Host "`n─── $($ad.Name) ($desc) ───" -ForegroundColor Yellow

    # หา subkey ใน registry
    $sub = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}" -EA SilentlyContinue |
        Where-Object { $_.PSChildName -match '^\d{4}$' } |
        Where-Object { (Get-ItemProperty $_.PSPath -Name "NetCfgInstanceId" -EA SilentlyContinue).NetCfgInstanceId -eq $guid } |
        Select-Object -ExpandProperty PSChildName

    if (-not $sub) { Write-Host "  (ไม่พบ registry key)" -ForegroundColor DarkGray; continue }

    $ap = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\$sub"
    $props = Get-ItemProperty -Path $ap -EA SilentlyContinue

    # ════════════════════════════════════════════════════════
    # ค่าที่ Aspas Settings อ่าน (17 ค่า)
    # ════════════════════════════════════════════════════════
    $keys = @{
        '*FlowControl' = @{
            Desc = "Flow Control"
            Note = "0=Disabled, 1=Tx, 2=Rx, 3=Rx/Tx — ปิดลด latency"
        }
        '*IPChecksumOffloadIPv4' = @{
            Desc = "IPv4 Checksum Offload"
            Note = "0=Disabled, 1=Tx, 2=Rx, 3=Rx/Tx — ปิดให้ CPU ทำแทน"
        }
        '*TCPChecksumOffloadIPv4' = @{
            Desc = "TCP Checksum Offload (IPv4)"
            Note = "0=Disabled, 3=Rx/Tx — เปิดให้ NIC ช่วย checksum TCP"
        }
        '*TCPChecksumOffloadIPv6' = @{
            Desc = "TCP Checksum Offload (IPv6)"
            Note = "เหมือน IPv4 แต่สำหรับ IPv6"
        }
        '*UDPChecksumOffloadIPv4' = @{
            Desc = "UDP Checksum Offload (IPv4)"
            Note = "FiveM ใช้ UDP → เปิด Rx/Tx ดีกว่า"
        }
        '*UDPChecksumOffloadIPv6' = @{
            Desc = "UDP Checksum Offload (IPv6)"
            Note = "เหมือน IPv4 แต่สำหรับ IPv6"
        }
        '*LsoV2IPv4' = @{
            Desc = "Large Send Offload v2 (IPv4)"
            Note = "0=Disabled — ปิดเพื่อลด latency (ไม่ต้องรอสะสม packet)"
        }
        '*LsoV2IPv6' = @{
            Desc = "Large Send Offload v2 (IPv6)"
            Note = "0=Disabled — ปิดเหมือน IPv4"
        }
        '*PriorityVLANTag' = @{
            Desc = "Priority & VLAN Tagging"
            Note = "3=Priority+VLAN Enabled — ต้องเปิดเพื่อให้ QoS/DSCP ทำงาน"
        }
        '*InterruptModeration' = @{
            Desc = "Interrupt Moderation"
            Note = "1=Enabled — รวม interrupt ลดภาระ CPU"
        }
        'ITR' = @{
            Desc = "Interrupt Throttle Rate (interrupts/sec)"
            Note = "ยิ่งสูง = responsive มากแต่ CPU load สูง — 950-2000 เหมาะกับเกม"
        }
        '*PacketDirect' = @{
            Desc = "Packet Direct"
            Note = "0=Disabled — technology สำหรับ server, ไม่จำเป็นสำหรับ desktop"
        }
        '*ReceiveBuffers' = @{
            Desc = "Receive Buffers (จำนวน)"
            Note = "เพิ่ม = รับ packet ได้มากขึ้นก่อนจะ drop — 4096 เหมาะ"
        }
        '*TransmitBuffers' = @{
            Desc = "Transmit Buffers (จำนวน)"
            Note = "ลด = ส่ง packet เร็วขึ้น — 128 ลด latency"
        }
        'TxIntDelay' = @{
            Desc = "Transmit Interrupt Delay (microsec)"
            Note = "delay ก่อนส่ง interrupt — ยิ่งต่ำ = ส่งเร็วขึ้น"
        }
        'CoalesceBufferSize' = @{
            Desc = "Coalesce Buffer Size"
            Note = "ขนาด buffer ที่ใช้รวม interrupt — ยิ่งเล็ก = ส่ง interrupt ถี่ขึ้น"
        }
        '*PMARPOffload' = @{
            Desc = "PM ARP Offload (Power Management)"
            Note = "0=Disabled — ปิดเพื่อไม่ให้ NIC ตอบ ARP ในโหมดหลับ"
        }
        '*PMNSOffload' = @{
            Desc = "PM NS Offload (Power Management)"
            Note = "0=Disabled — ปิดเพื่อไม่ให้ NIC ตอบ IPv6 NS ในโหมดหลับ"
        }
    }

    foreach ($k in $keys.Keys | Sort-Object) {
        $info = $keys[$k]
        $val = if ($props.PSObject.Properties[$k]) { $props.$k } else { "(ไม่ได้ตั้ง)" }
        Write-Host ("  {0,-35} = {1,-15} # {2}" -f $k, $val, $info.Desc) -ForegroundColor White
        Write-Host ("  {0,-35}   {1}" -f "", $info.Note) -ForegroundColor DarkGray
    }

    # ════════════════════════════════════════════════════════
    # MSI (Message Signaled Interrupt)
    # ════════════════════════════════════════════════════════
    $pnpId = $ad.PnpDeviceID
    if ($pnpId) {
        Write-Host "`n  --- Interrupt Management ---" -ForegroundColor Cyan
        $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $msiVal = (Get-ItemProperty -Path $msiPath -Name 'MSISupported' -EA SilentlyContinue).MSISupported
        Write-Host "  MSISupported = $(if ($msiVal -ne $null) { "$msiVal (1=Enabled)" } else { '(ไม่ได้ตั้ง)' })"
        Write-Host "  # MSI = interrupt ผ่าน memory แทน pin → เร็วกว่า, ลด latency" -ForegroundColor DarkGray

        $affPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId\Device Parameters\Interrupt Management\Affinity Policy"
        $devPri = (Get-ItemProperty -Path $affPath -Name 'DevicePriority' -EA SilentlyContinue).DevicePriority
        $devPol = (Get-ItemProperty -Path $affPath -Name 'DevicePolicy' -EA SilentlyContinue).DevicePolicy
        Write-Host "  DevicePriority = $(if ($devPri -ne $null) { $devPri } else { '(ไม่ได้ตั้ง)' })"
        Write-Host "  # Priority ของ device interrupt (2=Normal, 3=High)" -ForegroundColor DarkGray
        Write-Host "  DevicePolicy = $(if ($devPol -ne $null) { "$devPol (1=AllClose, 4=SpreadAcross)" } else { '(ไม่ได้ตั้ง)' })"
        Write-Host "  # วิธีกระจาย interrupt ไปแต่ละ CPU core" -ForegroundColor DarkGray
    }

    # ════════════════════════════════════════════════════════
    # IP Interface Properties
    # (Get-NetIPInterface ใช้ InterfaceIndex — ไม่มีพารามิเตอร์ Description)
    # ════════════════════════════════════════════════════════
    $netIp = Get-NetIPInterface -InterfaceIndex $ad.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue
    if ($netIp) {
        Write-Host "`n  --- IPv4 Interface Settings ---" -ForegroundColor Cyan
        Write-Host "  MTU              = $($netIp.NlMtu)  # ขนาด packet สูงสุด (ปกติ 1500)"
        Write-Host "  AutomaticMetric  = $($netIp.AutomaticMetric)  # ให้ Windows เลือก route อัตโนมัติ"
        Write-Host "  BaseReachableTime= $($netIp.BaseReachableTime) ms  # เวลาก่อนจะ re-check neighbor"
        Write-Host "  RetransmitTime   = $($netIp.RetransmitTime) ms  # เวลาก่อนส่ง packet ซ้ำ"
    }
}

Write-Host "`n✅ แสดงค่า NIC Registry ทั้งหมดเสร็จสมบูรณ์!" -ForegroundColor Green
