# ============================================================
#  Aspas Settings - ASPAS Power Plan + CPU Boost + HW Latency
#  กลุ่ม "ASPAS Power Plan Tweaks" (powerplan + cpu-boost + hw-latency)
#  แกะมาจาก Aspas Settings.exe
# ============================================================
#  ⚠️ ต้องรัน PowerShell ด้วยสิทธิ์ Admin
#  ⚠️ ชุดนี้จะ "ลบ power plan อื่นทิ้งทั้งหมด" เหลือแผน ASPAS แผนเดียว!
# ============================================================

Write-Host "=== ASPAS Power Plan + CPU Boost + HW Latency ===" -ForegroundColor Cyan

# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 1: สร้าง + เปิดแผน "ASPAS"                       ║
# ║  ลำดับ: แกะจาก Ultimate Performance ก่อน                 ║
# ║         ไม่ได้ → แกะจาก High Performance                  ║
# ║         ยังไม่ได้ → แกะจากแผนที่ active อยู่              ║
# ╚═══════════════════════════════════════════════════════════╝

$active = powercfg /getactivescheme
$activeGuid = ""
if ($active -match "([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})") {
    $activeGuid = $Matches[1]
}

# e9a42b02-... = Ultimate Performance | 8c5e7fda-... = High Performance
$outArray = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
$out = $outArray -join " "
$targetGuid = ""
if ($out -match "([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})") {
    $targetGuid = $Matches[1]
} else {
    $outArray = powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    $out = $outArray -join " "
    if ($out -match "([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})") {
        $targetGuid = $Matches[1]
    } elseif ($activeGuid) {
        $outArray = powercfg -duplicatescheme $activeGuid 2>$null
        $out = $outArray -join " "
        if ($out -match "([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})") {
            $targetGuid = $Matches[1]
        }
    }
}

if ($targetGuid) {
    # เปลี่ยนชื่อแผนเป็น "ASPAS" แล้วเปิดใช้
    powercfg /changename $targetGuid "ASPAS" "aspaswellesley" 2>$null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$targetGuid" /v FriendlyName /t REG_SZ /d "ASPAS" /f 2>$null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$targetGuid" /v Description  /t REG_SZ /d "aspaswellesley" /f 2>$null
    powercfg /setactive $targetGuid 2>$null
    Write-Host "  ✓ สร้างและเปิดแผน ASPAS: $targetGuid" -ForegroundColor Green

    # ⚠️ ลบ power plan อื่นทั้งหมด (เหลือแผน ASPAS เท่านั้น!)
    $all = powercfg /l
    foreach ($line in $all) {
        if ($line -match "([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})") {
            $guid = $Matches[1]
            if ($guid -ne $targetGuid) {
                powercfg /delete $guid 2>$null
                Write-Host "  ✗ ลบแผนเดิม: $guid" -ForegroundColor DarkYellow
            }
        }
    }
}

# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 2: CPU Boost / Processor Power Management       ║
# ║  Subgroup 54533251-... = Processor Power Management      ║
# ║  เขียน Attributes=0 เพื่อ "ปลดล็อก" ค่าซ่อนขึ้นมาก่อน     ║
# ╚═══════════════════════════════════════════════════════════╝

$ppm = 'HKLM\System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00'
$hidden = @(
    '5d76a2ca-e8c0-402f-a133-2158492d58ad',  # Performance Boost Mode
    '36687f9e-e3a5-4dbf-b1dc-15eb381c68dc',
    '45bcc044-d885-43e1-8605-ee0ebceb2921',
    '06cadf0e-64ed-448a-8927-ce7bf90eb35d',
    'be337238-0d82-4146-a960-4f3749d470c7',
    '12a0ab44-fe28-4fa9-b3bd-4b64f44960a6',
    '619b7505-003b-4e82-b7a6-4dd29c300971',
    '0cc5b647-c1df-4637-891a-dec35c318583',  # Core Parking min cores
    'ea062031-0e34-4ff1-9b6d-eb1059334028'
)
foreach ($h in $hidden) {
    reg add "$ppm\$h" /v Attributes /t REG_DWORD /d 0 /f 2>$null
}

# ─── ตั้งค่าลงแผน ASPAS (ทั้ง AC และ DC) ───
# EPP (893dee8e) = 100 → บังคับประสิทธิภาพสูงสุด
powercfg /setacvalueindex $targetGuid $ppm 893dee8e-2bef-41e0-89c6-b55d0929964c 0x00000064 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 893dee8e-2bef-41e0-89c6-b55d0929964c 0x00000064 2>$null

# Boost Mode (5d76a2ca) = 000 → ปิด auto-boost คง clock ฐาน
#   (frametime นิ่ง / อุณหภูมิต่ำ — ถ้าอยากให้ Turbo ทำงาน แก้เป็น 001 หรือ 002)
powercfg /setacvalueindex $targetGuid $ppm 5d76a2ca-e8c0-402f-a133-2158492d58ad 000 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 5d76a2ca-e8c0-402f-a133-2158492d58ad 000 2>$null

# เวลา/เกณฑ์เพิ่ม-ลดความถี่ + Core Parking 100% (ห้าม park คอร์)
powercfg /setacvalueindex $targetGuid $ppm 36687f9e-e3a5-4dbf-b1dc-15eb381c68dc 0x00000000 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 36687f9e-e3a5-4dbf-b1dc-15eb381c68dc 0x00000000 2>$null
powercfg /setacvalueindex $targetGuid $ppm 45bcc044-d885-43e1-8605-ee0ebceb2921 0x00000064 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 45bcc044-d885-43e1-8605-ee0ebceb2921 0x00000064 2>$null
powercfg /setacvalueindex $targetGuid $ppm 06cadf0e-64ed-448a-8927-ce7bf90eb35d 0x00000001 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 06cadf0e-64ed-448a-8927-ce7bf90eb35d 0x00000001 2>$null
powercfg /setacvalueindex $targetGuid $ppm be337238-0d82-4146-a960-4f3749d470c7 0x00000002 2>$null
powercfg /setdcvalueindex $targetGuid $ppm be337238-0d82-4146-a960-4f3749d470c7 0x00000002 2>$null
powercfg /setacvalueindex $targetGuid $ppm 12a0ab44-fe28-4fa9-b3bd-4b64f44960a6 0x00000000 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 12a0ab44-fe28-4fa9-b3bd-4b64f44960a6 0x00000000 2>$null
powercfg /setacvalueindex $targetGuid $ppm 619b7505-003b-4e82-b7a6-4dd29c300971 0x00000064 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 619b7505-003b-4e82-b7a6-4dd29c300971 0x00000064 2>$null
powercfg /setacvalueindex $targetGuid $ppm 94d3a615-a899-4ac5-ae2b-e4d8f634367f 001 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 94d3a615-a899-4ac5-ae2b-e4d8f634367f 001 2>$null
powercfg /setacvalueindex $targetGuid $ppm bc5038f7-23e0-4960-96da-33abaf5935ec 0x00000064 2>$null
powercfg /setdcvalueindex $targetGuid $ppm bc5038f7-23e0-4960-96da-33abaf5935ec 0x00000064 2>$null
# Core Parking min = 100 → ทุกคอร์ตื่นตลอด ไม่ถูก "จอด" เพื่อประหยัดไฟ
powercfg /setacvalueindex $targetGuid $ppm 0cc5b647-c1df-4637-891a-dec35c318583 0x00000064 2>$null
powercfg /setdcvalueindex $targetGuid $ppm 0cc5b647-c1df-4637-891a-dec35c318583 0x00000064 2>$null
powercfg /setacvalueindex $targetGuid $ppm ea062031-0e34-4ff1-9b6d-eb1059334028 0x00000064 2>$null
powercfg /setdcvalueindex $targetGuid $ppm ea062031-0e34-4ff1-9b6d-eb1059334028 0x00000064 2>$null

# ╔═══════════════════════════════════════════════════════════╗
# ║  ส่วนที่ 3: HW Latency (NVMe / USB / Wireless / Sleep)   ║
# ╚═══════════════════════════════════════════════════════════╝

# NVMe Idle Timeout = 0 → SSD NVMe ไม่เข้าโหมด idle (ตอบสนองทันที)
powercfg /setacvalueindex $targetGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0x00000000 2>$null
powercfg /setdcvalueindex $targetGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0x00000000 2>$null

# USB power settings = 001
powercfg /setacvalueindex $targetGuid 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 001 2>$null
powercfg /setdcvalueindex $targetGuid 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 001 2>$null

# Wireless Adapter Power Saving = 000 → Maximum Performance
powercfg /setacvalueindex $targetGuid 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 000 2>$null
powercfg /setdcvalueindex $targetGuid 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 000 2>$null

# Sleep after = 0 (ไม่หลับ) / Hibernate after = 000 (ไม่ hibernate)
powercfg /setacvalueindex $targetGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0x00000000 2>$null
powercfg /setdcvalueindex $targetGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0x00000000 2>$null
powercfg /setacvalueindex $targetGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 000 2>$null
powercfg /setdcvalueindex $targetGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 000 2>$null

powercfg /setactive $targetGuid 2>$null

Write-Host "`n✅ ASPAS Power Plan + CPU Boost + HW Latency เสร็จสมบูรณ์!" -ForegroundColor Green
Write-Host "⚠️ เตือน: power plan เดิมทั้งหมดถูกลบ — ต้องการคืน: powercfg -restoredefaultschemes" -ForegroundColor Yellow
