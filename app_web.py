"""Native host for the Raknailuang Tools Web UI (Python 3.12 + pywebview)."""
import ctypes
import os
import subprocess
import sys
import time

APP = "Raknailuang Tools"
VERSION = "1.1"
FROZEN = getattr(sys, "frozen", False)
BASE_DIR = getattr(sys, "_MEIPASS", None) or os.path.dirname(os.path.abspath(__file__))

UTF8_PREFIX = "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; "

# Feature 9: persistent daily log files under %LOCALAPPDATA%\Raknailuang Tools\logs
LOG_DIR = os.path.join(os.environ.get("LOCALAPPDATA", os.path.expanduser("~")), "Raknailuang Tools", "logs")

def _log_file():
    return os.path.join(LOG_DIR, "raknailuang-" + time.strftime("%Y-%m-%d") + ".log")

def _log_write(text):
    """Append timestamped lines to today's log file. Never raises."""
    try:
        os.makedirs(LOG_DIR, exist_ok=True)
        stamp = time.strftime("%Y-%m-%d %H:%M:%S")
        with open(_log_file(), "a", encoding="utf-8") as handle:
            handle.write("\n".join("[%s] %s" % (stamp, line) for line in text.split("\n")) + "\n")
    except Exception:
        pass

def powershell(script):
    # Force UTF-8 console output so Thai text from scripts is captured cleanly.
    return ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", UTF8_PREFIX + script]

TASKS = {
    "network_overview": "Get-NetAdapter | Format-Table -Auto; Get-NetIPConfiguration; netsh int tcp show global",
    "adapter": "Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Enable-NetAdapterRss -Name $_.Name -ErrorAction SilentlyContinue; Set-NetAdapterPowerManagement -Name $_.Name -AllowComputerToTurnOffDevice Disabled -ErrorAction SilentlyContinue }; Get-NetAdapterRss",
    "qos": "'FiveM.exe','FiveM_GTAProcess.exe','GTA5.exe' | ForEach-Object {$n='Raknailuang-'+$_; if(-not(Get-NetQosPolicy -Name $n -ErrorAction SilentlyContinue)){New-NetQosPolicy -Name $n -AppPathNameMatchCondition $_ -DSCPAction 46}}; Get-NetQosPolicy | Where-Object Name -like 'Raknailuang-*'",
    "tcp": "netsh int tcp set heuristics disabled; netsh int tcp set global autotuninglevel=normal; netsh int tcp set global rss=enabled; netsh int tcp set global rsc=disabled; netsh int tcp show global",
    "cloudflare": "Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('1.1.1.1','1.0.0.1')}; Get-DnsClientServerAddress -AddressFamily IPv4",
    "dns_auto": "Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses}; Get-DnsClientServerAddress -AddressFamily IPv4",
    "flush_dns": "Clear-DnsClientCache; ipconfig /flushdns",
    "winsock": "netsh winsock reset; netsh int ip reset",
    "restore_point": "Enable-ComputerRestore -Drive 'C:\\' -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'Raknailuang Tools Backup' -RestorePointType MODIFY_SETTINGS",
    "power_plan": "$id=(powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String -Pattern '[0-9a-f-]{36}' | ForEach-Object {$_.Matches.Value} | Select-Object -First 1); if($id){powercfg /changename $id 'Raknailuang Gaming' 'Gaming performance profile'; powercfg /setactive $id}; powercfg /list",
    "services": "'DiagTrack','SysMain' | ForEach-Object {Stop-Service $_ -ErrorAction SilentlyContinue; Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue}; Get-Service DiagTrack,SysMain",
    "bcd": "powercfg /hibernate off; bcdedit /set disabledynamictick yes; powercfg /setacvalueindex scheme_current sub_usb USBSELECTIVE 0; powercfg /setactive scheme_current",
    "cleanup": "Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; 'Temporary files cleaned.'",
    "network_defaults": "netsh int tcp reset; netsh winsock reset; Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses}; ipconfig /flushdns",
    "fivem_cache": "$p=Join-Path $env:LOCALAPPDATA 'FiveM\\FiveM.app\\data'; 'cache','server-cache','server-cache-priv' | ForEach-Object {$x=Join-Path $p $_; if(Test-Path $x){Remove-Item $x -Recurse -Force -ErrorAction SilentlyContinue; 'Cleared '+$x}}",
    "citizenfx": "$p=Join-Path $env:LOCALAPPDATA 'FiveM\\FiveM.app'; if(Test-Path $p){Set-Content -Path (Join-Path $p 'CitizenFX.ini') -Value '[Game]`nnet_mtu=1472`n' -Encoding ASCII; 'CitizenFX.ini updated'} else {'FiveM installation not found'}",
    "tcp_report": "netsh int tcp show global; Get-ItemProperty 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\AFD\\Parameters' -ErrorAction SilentlyContinue",
    "adapter_report": "Get-NetAdapter | Format-List Name,InterfaceDescription,Status,LinkSpeed,MacAddress; Get-NetAdapterRss",
    # Feature 10: one-click undo tasks (Revert center)
    "undo_qos": "'FiveM.exe','FiveM_GTAProcess.exe','GTA5.exe' | ForEach-Object { Remove-NetQosPolicy -Name ('Raknailuang-'+$_) -ErrorAction SilentlyContinue }; 'Raknailuang QoS policies removed'",
    "undo_tcp": "netsh int tcp set heuristics default; netsh int tcp set global rsc=enabled; netsh int tcp set global autotuninglevel=normal; netsh int tcp show global",
    "undo_services": "'DiagTrack','SysMain' | ForEach-Object { Set-Service $_ -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service $_ -ErrorAction SilentlyContinue }; Get-Service DiagTrack,SysMain",
    "undo_bcd": "bcdedit /deletevalue disabledynamictick 2>$null; powercfg /setacvalueindex scheme_current sub_usb USBSELECTIVE 1; powercfg /setdcvalueindex scheme_current sub_usb USBSELECTIVE 1; powercfg /setactive scheme_current; powercfg /hibernate on; 'BCD, USB selective suspend and hibernate restored to defaults'",
    "undo_power_plan": "$plans=powercfg /list | Select-String 'Raknailuang Gaming'; if($plans){foreach($l in $plans){$id=[regex]::Match($l.ToString(),'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}').Value; if($id){powercfg /delete $id}}}; powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e; powercfg /getactivescheme",
}

# Full modules retained from the two source projects (KMS deliberately excluded).
# Values: (engine, project-relative path, optional PowerShell arguments)
MODULES = {
    "aspas_01": ("ps", "modules/aspas/01_Network_Adapter_Optimization.ps1", []),
    "aspas_02": ("ps", "modules/aspas/02_QoS_Policy_FiveM.ps1", []),
    "aspas_03": ("ps", "modules/aspas/03_TCPIP_AFD_System_Settings.ps1", []),
    "aspas_04": ("ps", "modules/aspas/04_NIC_Registry_Properties.ps1", []),
    "aspas_05": ("ps", "modules/aspas/05_Netsh_TCP_MTU_Latency_Registry.ps1", []),
    "aspas_06": ("ps", "modules/aspas/06_Windows_Services_Disable.ps1", []),
    "aspas_07": ("ps", "modules/aspas/07_BCD_USB_Hibernate_Tweaks.ps1", []),
    "aspas_08": ("ps", "modules/aspas/08_ASPAS_Power_Plan_CPU_Boost.ps1", []),
    "aspas_09": ("ps", "modules/aspas/09_FiveM_Tweaks.ps1", []),
    "aspas_10": ("ps", "modules/aspas/10_GTA5_CitizenFX_Config.ps1", []),
    "aspas_11": ("ps", "modules/aspas/11_Adapter_Interface_Power_Settings.ps1", []),
    "aspas_dns": ("ps", "modules/aspas/12_System_Tools.ps1", ["-Action", "dns"]),
    "aspas_winsock": ("ps", "modules/aspas/12_System_Tools.ps1", ["-Action", "winsock"]),
    "aspas_junk": ("ps", "modules/aspas/12_System_Tools.ps1", ["-Action", "junk"]),
    "aspas_restorepoint": ("ps", "modules/aspas/12_System_Tools.ps1", ["-Action", "restorept"]),
    "aspas_defaults": ("ps", "modules/aspas/12_System_Tools.ps1", ["-Action", "defaults"]),
    "internet_01": ("bat", "modules/internet/01_registry_tweaks.bat", []),
    "internet_02": ("bat", "modules/internet/02_netsh_tweaks.bat", []),
    "internet_03": ("bat", "modules/internet/03_bcdedit_tweaks.bat", []),
    "internet_04": ("bat", "modules/internet/04_nic_tweaks.bat", []),
    "internet_05": ("bat", "modules/internet/05_bindings_dns.bat", []),
    "internet_restore": ("bat", "modules/internet/99_restore_defaults.bat", []),
}

# Tasks that need a Windows restart to fully apply (also drives the restart toast in the UI).
RESTART_TASKS = {"winsock", "bcd", "undo_bcd", "network_defaults", "aspas_defaults",
                 "aspas_05", "aspas_07", "aspas_11", "internet_02", "internet_03", "internet_restore"}

class Api:
    def login(self):
        return {"success": True, "message": "Local access granted"}

    def status(self):
        return {"app": APP, "version": VERSION, "state": "READY", "admin": bool(ctypes.windll.shell32.IsUserAnAdmin())}

    def run_task(self, name, title=""):
        script = TASKS.get(name)
        module = MODULES.get(name)
        if not script and not module:
            return {"success": False, "output": "Unknown task"}
        started = time.time()
        _log_write("START  %-20s %s" % (name, title or "-"))
        try:
            if module:
                engine, relative_path, args = module
                path = os.path.join(BASE_DIR, relative_path)
                if not os.path.isfile(path):
                    _log_write("ERROR  %-20s missing module %s" % (name, relative_path))
                    return {"success": False, "output": "Module file is missing: " + relative_path}
                utf8 = UTF8_PREFIX
                command = (powershell(utf8 + "& '" + path.replace("'", "''") + "' " + " ".join(args))
                           if engine == "ps" else ["cmd.exe", "/d", "/s", "/c", "chcp 65001 >nul & call \"" + path + "\""])
                result = subprocess.run(command, cwd=os.path.dirname(path), stdin=subprocess.DEVNULL, capture_output=True, text=True, encoding="utf-8", errors="replace", creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                result = subprocess.run(powershell(script), capture_output=True, text=True, encoding="utf-8", errors="replace", creationflags=subprocess.CREATE_NO_WINDOW)
            output = (result.stdout or result.stderr or "Completed").strip()
            success = result.returncode == 0
            restart = name in RESTART_TASKS
            _log_write("RESULT %-20s success=%s exit=%s %.1fs restart=%s" % (name, success, result.returncode, time.time() - started, restart))
            log_output = output if len(output) <= 20000 else output[:20000] + "\n... (truncated)"
            _log_write("OUTPUT BEGIN\n" + log_output + "\nOUTPUT END")
            return {"success": success, "output": output, "restart": restart}
        except Exception as exc:
            _log_write("ERROR  %-20s %s" % (name, exc))
            return {"success": False, "output": str(exc)}

    def get_log_path(self):
        """Return today's log file path (creates the logs folder if needed)."""
        try:
            os.makedirs(LOG_DIR, exist_ok=True)
            return _log_file()
        except Exception:
            return ""

    def open_log_folder(self):
        """Open the log folder in Windows Explorer."""
        try:
            os.makedirs(LOG_DIR, exist_ok=True)
            os.startfile(LOG_DIR)
            return {"success": True}
        except Exception as exc:
            return {"success": False, "message": str(exc)}

def _webview2_available():
    """Check for the Microsoft Edge WebView2 Runtime (required by pywebview on Windows)."""
    try:
        import winreg
        key = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
        paths = [
            (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients"),
            (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\EdgeUpdate\Clients"),
            (winreg.HKEY_CURRENT_USER, r"Software\Microsoft\EdgeUpdate\Clients"),
        ]
        for root, path in paths:
            try:
                with winreg.OpenKey(root, path + "\\" + key):
                    return True
            except OSError:
                continue
        return False
    except Exception:
        return True  # never block the app because the check itself failed

def _selftest():
    """Headless check used by the frozen build: RaknailuangTools.exe --selftest"""
    _log_write("APP    selftest")
    api = Api()
    lines = ["status: " + repr(api.status())]
    result = api.run_task("network_overview")
    lines.append("network_overview success: " + repr(result.get("success")))
    lines.append("output: " + ((result.get("output") or "")[:400].replace("\n", " | ")))
    missing = [k for k, (e, p, a) in MODULES.items() if not os.path.isfile(os.path.join(BASE_DIR, p))]
    lines.append("missing modules: " + (repr(missing) if missing else "none"))
    lines.append("html bundled: " + str(os.path.isfile(os.path.join(BASE_DIR, "RaknailuangUI.html"))))
    out = os.path.join(os.environ.get("TEMP", BASE_DIR), "raknailuang_selftest.txt")
    with open(out, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    return out

if __name__ == "__main__":
    if "--selftest" in sys.argv:
        _selftest()
        sys.exit()
    if os.name == "nt" and not ctypes.windll.shell32.IsUserAnAdmin():
        params = "" if FROZEN else " ".join('"' + x + '"' for x in sys.argv)
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, params, None, 1)
        sys.exit()
    _log_write("APP    start  admin=%s frozen=%s" % (bool(ctypes.windll.shell32.IsUserAnAdmin()), FROZEN))
    try:
        import webview
    except ImportError:
        ctypes.windll.user32.MessageBoxW(None, "pywebview is not installed.\n\nRun this command:\npip install pywebview", APP, 0x10)
        sys.exit(1)
    if not _webview2_available():
        ctypes.windll.user32.MessageBoxW(None, "Microsoft Edge WebView2 Runtime is required but not installed.\n\nDownload it from:\nhttps://developer.microsoft.com/microsoft-edge/webview2/\n\n(Windows 11 already includes it.)", APP, 0x30)
        sys.exit(1)
    path = os.path.join(BASE_DIR, "RaknailuangUI.html")
    webview.create_window(APP, path, js_api=Api(), width=1280, height=800, min_size=(1060, 680), background_color="#070709")
    webview.start()
