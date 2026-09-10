# ==============================================================================
# Screen Controller Companion Script for Windows
# This script monitors the timer state from Supabase and minimizes/maximizes
# the browser window accordingly.
# ==============================================================================

# 1. Terminate any older companion processes to prevent conflicts
$currentPid = $PID
try {
    Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessId -ne $currentPid -and ($_.CommandLine -like "*companion.ps1*" -or $_.CommandLine -like "*companion*")
    } | ForEach-Object {
        Write-Host "Terminating older companion process ($($_.ProcessId))..." -ForegroundColor DarkYellow
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
} catch {}

# 2. Compile User32.dll window controls and enumeration in memory if not already loaded
if ($null -eq ("WindowHelper" -as [type])) {
    Add-Type @"
    using System;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    using System.Text;

    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumCallBackDelegate lpMethod, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowText(IntPtr hWnd, StringBuilder strText, int maxCount);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowTextLength(IntPtr hWnd);

        private delegate bool EnumCallBackDelegate(IntPtr hwnd, IntPtr lParam);

        public static IntPtr[] FindWindowsByTitle(string substring) {
            List<IntPtr> result = new List<IntPtr>();
            EnumWindows(new EnumCallBackDelegate((hwnd, lParam) => {
                int length = GetWindowTextLength(hwnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hwnd, sb, sb.Capacity);
                    string title = sb.ToString();
                    if (title.IndexOf(substring, StringComparison.OrdinalIgnoreCase) >= 0) {
                        result.Add(hwnd);
                    }
                }
                return true;
            }), IntPtr.Zero);
            return result.ToArray();
        }

        public static string GetWindowTitle(IntPtr hwnd) {
            int length = GetWindowTextLength(hwnd);
            if (length > 0) {
                StringBuilder sb = new StringBuilder(length + 1);
                GetWindowText(hwnd, sb, sb.Capacity);
                return sb.ToString();
            }
            return string.Empty;
        }
    }
"@
}

# 2. Supabase configuration
$supabaseUrl = "https://zabocfwhfqntmumiahlt.supabase.co"
$supabaseKey = "sb_publishable_aD0xKcUmcwKfaSS1_Vnmfg_W3ExePcE"
$apiUrl = "$supabaseUrl/rest/v1/timer_state?id=eq.1&select=*"
$headers = @{
    "apikey" = $supabaseKey
    "Authorization" = "Bearer $supabaseKey"
}

$lastState = ""
$lastCloudSync = 0
$cachedTimerData = $null
$SYNC_INTERVAL_SEC = 3 # Responsive cloud sync every 3s

Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "     St-Philopateer Screens Companion Script" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Sync: Cloud sync every 3s (sub-second local cycle flip)" -ForegroundColor DarkGray
Write-Host "Monitoring state change... Press Ctrl+C to exit." -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

while ($true) {
    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

    # 1. Sync from cloud every $SYNC_INTERVAL_SEC seconds
    if (($nowMs - $lastCloudSync) -ge ($SYNC_INTERVAL_SEC * 1000) -or $null -eq $cachedTimerData) {
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers -TimeoutSec 4
            $items = @($response)
            if ($items.Count -gt 0 -and $null -ne $items[0]) {
                $cachedTimerData = $items[0]
                $lastCloudSync = $nowMs
            }
        } catch {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') | Offline / Cloud unreachable, maintaining local cycle..." -ForegroundColor DarkGray
        }
    }

    # 2. Local cycle execution (runs every second in RAM)
    if ($cachedTimerData -and $cachedTimerData.active -and $cachedTimerData.startTime) {
        $maxMs = [long]($cachedTimerData.maxMins * 60 * 1000)
        $minMs = [long]($cachedTimerData.minMins * 60 * 1000)
        $totalCycleMs = $maxMs + $minMs

        if ($totalCycleMs -gt 0) {
            $diff = $nowMs - [long]$cachedTimerData.startTime
            if ($diff -lt 0) { $diff = 0 }
            $elapsed = $diff % $totalCycleMs
            $currentState = if ($elapsed -lt $maxMs) { "maximize" } else { "minimize" }

            if ($currentState -ne $lastState) {
                $hwnds = [WindowHelper]::FindWindowsByTitle("Display-Screen")

                if ($hwnds -and $hwnds.Count -gt 0) {
                    foreach ($hwnd in $hwnds) {
                        if ($currentState -eq "minimize") {
                            Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MINIMIZE -> Minimizing window ($hwnd)..." -ForegroundColor Yellow
                            [void][WindowHelper]::ShowWindowAsync($hwnd, 6) # SW_MINIMIZE
                        } else {
                            Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MAXIMIZE -> Restoring & Maximizing ($hwnd)..." -ForegroundColor Green
                            [void][WindowHelper]::ShowWindowAsync($hwnd, 9) # SW_RESTORE
                            [void][WindowHelper]::ShowWindowAsync($hwnd, 3) # SW_MAXIMIZE
                            [void][WindowHelper]::SetForegroundWindow($hwnd)
                        }
                    }
                    $lastState = $currentState
                } else {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') | Waiting for '*Display-Screen*' window..." -ForegroundColor DarkYellow
                }
            }
        }
    } else {
        # Timer inactive - ensure window is restored & maximized
        if ($lastState -ne "inactive") {
            $hwnds = [WindowHelper]::FindWindowsByTitle("Display-Screen")
            if ($hwnds -and $hwnds.Count -gt 0) {
                foreach ($hwnd in $hwnds) {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') | Timer is INACTIVE. Restoring & Maximizing ($hwnd)..." -ForegroundColor Gray
                    [void][WindowHelper]::ShowWindowAsync($hwnd, 9) # SW_RESTORE
                    [void][WindowHelper]::ShowWindowAsync($hwnd, 3) # SW_MAXIMIZE
                    [void][WindowHelper]::SetForegroundWindow($hwnd)
                }
                $lastState = "inactive"
            }
        }
    }

    Start-Sleep -Seconds 1
}
