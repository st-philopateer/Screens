# ==============================================================================
# Screen Controller Companion Script for Windows
# This script monitors the timer state from Supabase and minimizes/maximizes
# the browser window accordingly.
# ==============================================================================

# 1. Compile User32.dll window controls and enumeration in memory if not already loaded
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

$lastState = ""

Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "     St-Philopateer Screens Companion (Zero-Data)" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Mode: 100% Local Window Monitor (0 KB Internet Usage)" -ForegroundColor DarkGray
Write-Host "Monitoring window title state in local memory..." -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

while ($true) {
    try {
        # Find all windows containing "Display-Screen" locally in RAM
        $hwnds = [WindowHelper]::FindWindowsByTitle("Display-Screen")

        if ($hwnds -and $hwnds.Count -gt 0) {
            foreach ($hwnd in $hwnds) {
                $title = [WindowHelper]::GetWindowTitle($hwnd)
                
                if ($title -match "\[MINIMIZE\]") {
                    if ($lastState -ne "minimize") {
                        $lastState = "minimize"
                        Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MINIMIZE -> Minimizing browser window..." -ForegroundColor Yellow
                        [void][WindowHelper]::ShowWindowAsync($hwnd, 6) # SW_MINIMIZE
                    }
                } elseif ($title -match "\[MAXIMIZE\]") {
                    if ($lastState -ne "maximize") {
                        $lastState = "maximize"
                        Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MAXIMIZE -> Maximizing browser window..." -ForegroundColor Green
                        [void][WindowHelper]::ShowWindowAsync($hwnd, 3) # SW_MAXIMIZE
                        [void][WindowHelper]::SetForegroundWindow($hwnd)
                    }
                } elseif ($title -match "\[INACTIVE\]") {
                    if ($lastState -ne "inactive") {
                        $lastState = "inactive"
                        Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: INACTIVE -> Window normal/maximized..." -ForegroundColor Gray
                        [void][WindowHelper]::ShowWindowAsync($hwnd, 3) # SW_MAXIMIZE
                        [void][WindowHelper]::SetForegroundWindow($hwnd)
                    }
                }
            }
        }
    } catch {
        # Silently catch any local enumeration exceptions
    }
    Start-Sleep -Seconds 1
}
