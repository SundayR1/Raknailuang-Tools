# Raknailuang Tools

โปรแกรมรวมเครื่องมือปรับเครือข่าย ระบบ และเกม จากแนวคิดของ Aspas Settings และ InternetAspas ในหน้าตาใหม่เดียว (Web UI บน pywebview) — **เวอร์ชัน 1.1**

## วิธีเปิด

- ดับเบิลคลิก `Start Raknailuang Tools.cmd` — จะเรียก `dist\RaknailuangTools\RaknailuangTools.exe` ถ้ามี หรือรัน `python app_web.py` (ขอสิทธิ์ Administrator ทุกครั้ง)
- หรือเปิด `dist\RaknailuangTools\RaknailuangTools.exe` โดยตรง (หรือใช้ shortcut `Raknailuang Tools` บน Desktop)
- เปิดครั้งแรกอาจเจอหน้าจอสีน้ำเงินของ SmartScreen (เพราะ .exe ไม่ได้ลงลายเซ็นดิจิทัล) — กด `More info` → `Run anyway`

**เงื่อนไขระบบ:** ต้องมี **Microsoft Edge WebView2 Runtime** (Windows 11 มีในตัว, Windows 10 ส่วนใหญ่มี) — ถ้าไม่มี โปรแกรมจะแจ้งเตือนพร้อมลิงก์ดาวน์โหลดตอนเปิด

## โครงสร้าง

| ไฟล์/โฟลเดอร์ | คำอธิบาย |
|---|---|
| `app_web.py` | ตัว host หลัก (Python + pywebview) พร้อม task ในตัวและตัวเรียกโมดูล |
| `RaknailuangUI.html` | หน้า UI ทั้งหมด (Dashboard / Network / System / Gaming / Diagnostics / Activity log) |
| `modules/aspas/` | สคริปต์ PowerShell 12 ตัวจาก Aspas Settings (ไม่มี KMS / anti-debug) |
| `modules/internet/` | สคริปต์ .bat 6 ตัวจาก InternetAspas (มี `99_restore_defaults.bat` สำหรับคืนค่า) |
| `dist/RaknailuangTools.exe` | โปรแกรมเดี่ยว build ด้วย PyInstaller |
| `icon.ico` | ไอคอนของโปรแกรม |

## สิ่งที่มี

- Network: adapter, QoS FiveM/GTA, TCP/MTU, DNS (Cloudflare/DHCP), Winsock, bindings
- System: restore point, power plan, services, BCD/USB/Hibernate, ล้างไฟล์ชั่วคราว, คืนค่า network
- Gaming: FiveM cache/priority/timer, GTA5 + CitizenFX config
- Diagnostics: รายงานอ่านอย่างเดียว (adapter, TCP/AFD, NIC registry)

⚠️ เครื่องมือ `ASPAS • Gaming power plan` (module 08) จะลบ power plan อื่นทั้งหมดเหลือแผนเดียว — ถ้าไม่ต้องการแบบนั้น ให้ใช้ `Raknailuang gaming power plan` (built-in) แทน

## Build .exe ด้วยตัวเอง

แบบ onedir (แนะนำ — เปิดเกือบทันที ไม่ต้องแตกไฟล์ทุกครั้งที่เปิดโปรแกรม):

```
pyinstaller --noconfirm --clean --onedir --windowed --name RaknailuangTools --icon icon.ico --add-data "RaknailuangUI.html;." --add-data "modules;modules" --collect-all webview --collect-all pythonnet app_web.py
```

→ ตัวโปรแกรมคือ `dist\RaknailuangTools\RaknailuangTools.exe`

แบบ onefile (ได้ไฟล์เดียวพกพาง่าย แต่เปิดช้าขึ้น ~5 วินาที เพราะต้องแตกไฟล์ตัวเองทุกครั้ง):

```
pyinstaller --noconfirm --clean --onefile --windowed --name RaknailuangTools --icon icon.ico --add-data "RaknailuangUI.html;." --add-data "modules;modules" --collect-all webview --collect-all pythonnet app_web.py
```

ทดสอบเบื้องหลัง: `<ตัว exe> --selftest` แล้วดูผลที่ `%TEMP%\raknailuang_selftest.txt`

## Logs และ Revert center

- ทุก task จะถูกบันทึกลง log รายวันที่ `%LOCALAPPDATA%\Raknailuang Tools\logs\raknailuang-YYYY-MM-DD.log` (กดปุ่ม `⎙ OPEN LOG FOLDER` ในหน้า Activity log เพื่อเปิดโฟลเดอร์)
- หน้า `Revert center` รวมปุ่มคืนค่าทั้งหมด — เครื่องมือที่มี undo ตรง ๆ จะมีป้าย `↩ UNDO` บนการ์ด ส่วนโมดูล ASPAS/Internet ใช้ปุ่ม Restore all defaults ในหน้าเดียวกัน

## ข้อควรระวัง

แต่ละรายการที่เปลี่ยนค่าเครื่องจะขอการยืนยันก่อนเริ่มงาน ควรสร้าง Restore Point ก่อนทุกครั้ง และรีสตาร์ตหลังใช้ Winsock, BCD หรือการคืนค่า network

ไม่มี KMS, ตัวเปิดใช้งานลิขสิทธิ์, anti-debug หรือกลไกหลบการวิเคราะห์รวมอยู่ในโปรเจกต์นี้

