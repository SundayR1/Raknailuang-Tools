@echo off
:: =====================================================================
:: InternetAspas - Boot Timer Settings (BcdEdit)
:: =====================================================================
:: สิ่งที่ไฟล์นี้ทำ: ปรับค่า Boot Configuration เพื่อลด timer overhead
:: ⚠ ต้อง Run as Administrator
:: ⚠⚠ ระวัง: การเปลี่ยน BCD อาจส่งผลกับการบูต / Hyper-V
:: =====================================================================

echo =============================================
echo  InternetAspas - Boot Timer Tweaks (BcdEdit)
echo =============================================
echo.

:: --- Platform Tick ---
:: ปิด — ไม่ใช้ platform timer (HPET) สำหรับ clock tick
:: ให้ Windows ใช้ TSC (CPU timestamp counter) แทน ซึ่งเร็วกว่า
echo [1/5] ปิด Platform Tick...
bcdedit /set useplatformtick No

:: --- Platform Clock ---
:: ปิด — เหมือนกับด้านบน บังคับให้ใช้ TSC
:: ลด interrupt overhead จาก HPET
echo [2/5] ปิด Platform Clock...
bcdedit /set useplatformclock No

:: --- TSC Sync Policy ---
:: ลบค่านี้เพื่อให้ Windows ใช้ค่า default
:: (บางทีถูก set เป็น Enhanced ซึ่งเพิ่ม overhead)
echo [3/5] ลบ TSC Sync Policy...
bcdedit /deletevalue tscsyncpolicy 2>nul

:: --- Dynamic Tick ---
:: เปิด — ให้ OS ข้าม timer interrupt เมื่อ CPU idle
:: ลด power consumption + ลด unnecessary interrupts
echo [4/5] เปิด Dynamic Tick Disable...
bcdedit /set disabledynamictick yes

:: --- Hypervisor ---
:: ปิด Hyper-V hypervisor launch
:: ⚠⚠ สำคัญ: ถ้าใช้ Hyper-V, WSL2, Docker, Windows Sandbox
::    การปิดจะทำให้ใช้งานไม่ได้!
:: แต่ถ้าไม่ใช้ → ปิดจะลด overhead จาก virtualization layer
echo [5/5] ปิด Hypervisor...
bcdedit /set hypervisorlaunchtype off

echo.
echo =============================================
echo  ✅ BcdEdit Tweaks เสร็จเรียบร้อย!
echo.
echo  ⚠ กรุณา Restart Windows เพื่อให้มีผล
echo.
echo  ⚠⚠ ถ้าใช้ Hyper-V / WSL2 / Docker ให้รัน:
echo     bcdedit /set hypervisorlaunchtype auto
echo     เพื่อเปิดคืน
echo =============================================
pause
