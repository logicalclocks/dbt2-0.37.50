###############################################################################
##
## Top script, v0.9RC
##
## 
## Tonci Grgin, Oracle corp, 2015. All rights reserved.
##
## In PS window, type: Get-Help .\test-top.ps1 -Full
## from the directory where script is for details.
##
###############################################################################

<#

.SYNOPSIS
Displays Linux "top" tool data for single Windows machine. Requires
PowerShell v3 or newer. Script does not work in PowerShell_ISE. Please use 
Get-Help .\test-top.ps1 -Examples to see the description of the display.

.DESCRIPTION
Using Windows performance counters through PowerShell CIM classes, it is
possible to gather stats on computer performance. The script functions like
this:
  o Main code starts 2 background jobs; one for collecting details for header
  table ("Top_Header_Job") and one for processes table ("Top_Processes_Job").
  o Each of the jobs then collects stats and writes them into a file
  ("header" job to TempDir\headerres.txt file, "tasks" job to 
  TempDir\thrprocstats.txt) which is, in turn read by script main code.
  Main code uses TempDir\topcfg.txt to pass info to "tasks" job (currently, 
  the field to sort the table by). All of the files are overwritten each time 
  so there is not much data in them.
  o After the files are read by main code, the data is displayed. To be able to
  properly position the output on screen, I used various [console] functions
  not available in PowerShell_ISE.
  o Keyboard shortcuts:
  r –To sort by PID number
  p –Sort by process CPU util DESC, WS(MB) DESC. Toggles Normal/Normalized.
  m –To sort by RAM utilization
  n -To sort by NAME
  q or CTRL+BREAK –To quit the top script.
  c –Clear screen
--
  + -Display individual CPU(s)
  1 -Display individual socket(s).
  - -Cancel displaying individual CPUs/Sockets

Requirements:
The script can not be run in _ISE. Use Powershell console.
The script requires PS 3+.
The script requires at least 50 x 80 console window.
The script might work with .NET FW older than 4 but it was tested only with .NET 4.5.x.

.EXAMPLE
14:21:17,Uptime:00d:06h:36m, Users: 1, #thds ready but queued for CPU: 0
-------------------------------------------------------------------------------
| RUNNING           | CPU                           | RAM[MB]                 |
-------------------------------------------------------------------------------
| services:    104  | Sys: 50.78%(P  4.30%/U 46.48%)| Installed:         8192 |
| processes:   126  | Idle:49.22%                   | HW reserv:       320.77 |
| threads:    1483  | HWint:             7087/0.38% | Visible:        7871.23 |
| handles:   32696  | SWint:              278/0.38% | Available:         5136 |
| CoSw/s:     6351  | High-prio thd exec:    50.38% | Modified:        117.07 |
|                   | Total # of cores:           4 | Standby:        3936.44 |
|                   |                               | PagesIn/Read ps:      2 |
-------------------------------------------------------------------------------



_PID_ PPID PrioB Name                   _CPUpt_N Thds Hndl WS(MB) VM(MB) PM(MB)
----- ---- ----- ---------------------- -------- ---- ---- ------ ------ ------
 3916  852     8 mcshield                  10.14   53  490     46    225    100
 1836 5452     8 powershell#2               1.09   15  377     67    616     46
 7436 5452     8 powershell#1               0.72   17  556     85    624     67
 3984  156     8 WmiPrvSE                   0.72    9  303     14     56      9
 7024  156     8 WmiPrvSE#2                 0.72    7  201     10     52      7
 5452 5148     8 powershell                 0.36   18  454     90    628     79
 2292  852     8 FireSvc                    0.36   28  539     10    156     36
 7864 5148     8 thunderbird                0.00   52  630    293    656    264
 2880 5148     8 powershell_ise             0.00   12  427    181    869    164
 5148 3860     8 explorer                   0.00   25  810     81    267     53
 7028 6648     8 googledrivesync#1          0.00   29  712     76    193     64
 1124  852     8 svchost#5                  0.00   45 1560     46    187     31
 6508 5148     8 sidebar                    0.00   20  433     39    195     20
  816  796    13 csrss#1                    0.00   10  765     35    126      3
 6592 5148     8 iCloudServices             0.00   16  442     32    167     18
 6868 6764     8 pcee4                      0.00    7  202     32    612     32
 1976 1052    13 dwm                        0.00    5  135     31    140     26
 3400  156     8 WmiPrvSE#1                 0.00   12  297     28     91     22
 1088  852     8 svchost#4                  0.00   21  584     27    126     14
 3648  852     8 dataserv                   0.00   10  510     24    224     21
  980  852     8 svchost#2                  0.00   25  575     23    119     26
 2404  852     8 PresentationFontCache      0.00    6  149     21    506     28
...
Data displayed:
    HEADER:
        Current time, uptime, # of active users, # of threads per CPU that are
        ready for execution but can't get CPU cycles. Obviously, you want to
        keep this as low as possible (<= 2).
        RUNNING section:
            # of services in Started state
            # of user processes
            # of threads spawned
            # of handles open
            # of context switches per second
        CPU section:
            % of CPU used (% used by privileged instr. / % used by user instr.)
            % of CPU consumed by Idle process.
            # of HW interrupts per sec./% of CPU used to service HW interrupts
            # of SW interrupts queued for servicing per sec./
                % of CPU used to service SW interrupts
            % of CPU consumed by high-priority threads execution.
            # of phys. and virt. cores. In this example, 4 is Dual-Core + HT.
        RAM[MB] section:
            Installed RAM.
            RAM reserved by Windows for HW.
            Amount of RAM user actually sees.
            Amount of available RAM for user processes.
            Amount of RAM marked as "Modified".
            Amount of RAM marked as "Standby" (cached).
            Ratio between Memory\Pages Input/sec and Memory\Page Reads/sec.
              Number of pages per disk read. Should keep below 5.

    TABLE:
        _PID_    Unique identified of the process.
        PPID     Unique identifier of the process that started this one.
        PrioB    Base priority.
        Name     Name of the process.
        CPUpt_(N)    % of CPU used by process. On machines with multiple CPUs,
            this number can be over 100% unless you see _CPUpt_N caption which
            means "Normalized" (i.e. CPUutilization / # of CPUs).
            Toggle Normal/Normalized display by pressing key p.
        Thds     # of threads spawned by the process.
        Hndl     # of handles opened by the process.
        WS(MB)   Total RAM used by the process. Working Set is, basically,
            the set of memory pages touched recently by the threads belonging
            to the process. 
        VM(MB)   Size of the virtual address space in use by the process.
        PM(MB)   The current amount of VM that this process has reserved for
            use in the paging files.

    With 4 CPUs detailed (Notice that Process CPUUtil is NOT normalized thus
    mcshield is actually using 93.39/Total # of CPU's (which is ~23%):
14:05:15, Uptime: 00d:05h:20m, Users:   1, #thds ready but queued for CPU:   1
-------------------------------------------------------------------------------
| RUNNING           | CPU                           | RAM[MB]                 |
-------------------------------------------------------------------------------
| services:    106  | Sys: 28.12%(P  6.51%/U 21.05%)| Installed:         8192 |
| processes:   135  | Idle:71.95%                   | HW reserv:       320.77 |
| threads:    1698  | HWint:                5613/0% | Visible:        7871.23 |
| handles:   39057  | SWint:                 309/0% | Available:         3867 |
| CoSw/s:    10846  | High-prio thd exec:    27.31% | Modified:         53.71 |
|                   | Total # of CPU's:           4 | Standby:           3774 |
|                   |                               | PagesIn/Read ps:    NaN |
-------------------------------------------------------------------------------


        User  Priv  Idle  HWin  SWIn               User  Priv  Idle  HWin  SWIn
------------------------------------       ------------------------------------
%CPU 0:   12,   12,   81,    0,    0       %CPU 1:    0,    6,   93,    6,    0
%CPU 2:   48,    6,   42,    0,    0       %CPU 3:    0,    0,   97,    0,    0

_PID_ PPID PrioB Name                   _CPUpt__ Thds Hndl WS(MB) VM(MB) PM(MB)
----- ---- ----- ---------------------- -------- ---- ---- ------ ------ ------
 3832  852     8 mcshield                  93.39   54  487     36    226    103
 4140  320     8 WmiPrvSE                   8.76    9  319     15     56     10
 1128  852     8 svchost#5                  7.30   64 1793    120    503     48
 8480 4352     8 firefox                    5.84   61  664    321    718    294
 8868 1028     8 audiodg                    2.92   13  388     20     73     18
10544  320     8 WmiPrvSE#2                 2.92   14  240     11     57      9
 6300 6888     8 googledrivesync#1          1.46   30  849     76    194     64
10868 8244     8 powershell#2               1.46   15  374     74    622     53
 7012 8244     8 powershell#1               1.46   13  490     66    623     46
 4176  320     8 WmiPrvSE#1                 1.46   18  342     28     94     22
 2300  852     8 FireSvc                    1.46   29  551     12    157     37
 7516 4352     8 powershell_ise             0.00   27  870    363   1063    317
 4352 3712     8 explorer                   0.00   34 1270    314    365     75
 8016 4352     8 thunderbird                0.00   52  605    314    661    274
 6864 4352     8 iCloudServices             0.00   18 1067    209    408    218
 8244 4352     8 powershell                 0.00   25  997    126    667    109
 1100  852     8 svchost#4                  0.00   21  614    108    137     25
 2216  852     8 CrashPlanService           0.00   68  694     97   1327    107

.LINK
http://toncigrgin.blogspot.hr/2015/12/windows-perf-counters-blog8.html
https://dev.mysql.com/downloads/benchmarks.html
#>

#region Functions
#endregion

#region Check
if ($host.Name -ne 'ConsoleHost')
{
    #Running in ISE
    $host.UI.WriteErrorLine("`t This script can not be run in _ISE. Exiting.")
    Exit 1
}

if ( ($PSVersionTable).PSVersion.Major -lt 3) {
    $host.UI.WriteErrorLine("`t This script can not be run in PS 2. Exiting.")
    Exit 2
}

if (([console]::WindowHeight -lt 50) -or ([console]::WindowWidth -lt 80)) {
    $host.UI.WriteErrorLine("`t This script requires at least 50 x 80 console size. Exiting.")
    Exit 3
}

$clrVer = ((Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select Version | Sort Version -Desc | Select -First 1).Version).Split('.')[0]
if ( $clrVer -lt 4) {
    $host.UI.WriteErrorLine("`t This script can not be run in .NET v"+$clrVer+". Exiting.")
    Exit 4
}

Set-StrictMode -Version Latest
Set-PSDebug -strict

#endregion

#region Variable Declarations
Write-Host "Preparing for run."
$pthf = (dir Env:\TEMP).Value + '\thrprocstats.txt'
$conf = (dir Env:\TEMP).Value + '\topcfg.txt'
$TotProc = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
[console]::TreatControlCAsInput = $true #Block CTRL+C from stopping the script.
$lastTimeHeader = Get-Date #Last modified time
$lastTimeProc = Get-Date
$CPUDispLines = 0 #Lines for displaying individual CPUs load.
$SocketDispLines = 0 #Lines for displaying individual Scokets load.
$procToDisp = 25 + 3 # 3 for the header, 25 for processes.
#endregion

Write-Host "Preparing individual CPU(s) counters."
#Prep for showing individual CPU's by manipulating $Instance
$CPUdata = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation | Where {$_.Name -match "^(\d{1}),(\d{1})"} #Just the individual CPUs.
$Socketdata = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation | Where {$_.Name -match "^(\d{1}),_Total"} #Just the individual Sockets.

Write-Host "Checking Sockets/CPUs topology."
#Sockets/Processors
$sockets = ($Socketdata | Measure-Object -Property Name).Count
#CPUs
$CPUs = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
#CPUs per Processor(Socket)
$CPUsPerSock = [int]($CPUs / $sockets)

Write-Host "Starting header job."

#region Header job
$j = Start-Job -ArgumentList $TotProc -ScriptBlock {
    #Permanent values.
    $TotProc = $args[0]

    $w = [math]::Round((get-ciminstance -class "cim_physicalmemory" | Measure-Object Capacity -Sum).Sum / 1024 / 1024, 2)
    $VisMemS = (Get-CimInstance win32_operatingsystem).TotalVisibleMemorySize / 1024
    $queryExists = Get-Command "query.exe" -ErrorAction SilentlyContinue

    $System_UpTime = New-Object Diagnostics.PerformanceCounter("System", "System Up Time")
    $null = $System_UpTime.NextValue() #1st is Empty!
    $System_ProQL = New-Object Diagnostics.PerformanceCounter("System", "Processor Queue Length")
    $null = $System_ProQL.NextValue() #1st is Empty!
    $System_ProcCnt = New-Object Diagnostics.PerformanceCounter("System", "Processes")
    $null = $System_ProcCnt.NextValue() #1st is Empty!
    $System_ThdCnt = New-Object Diagnostics.PerformanceCounter("System", "Threads")
    $null = $System_ThdCnt.NextValue() #1st is Empty!
    $System_CSpS = New-Object Diagnostics.PerformanceCounter("System", "Context Switches/sec")
    $null = $System_CSpS.NextValue()

    $InstanceName = "_Total"
    $PI_PT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% Processor Time")
    $PI_PT.InstanceName = $InstanceName
    $null = $PI_PT.NextValue()
    $PI_PPT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% Privileged Time")
    $PI_PPT.InstanceName = $InstanceName
    $null = $PI_PPT.NextValue()
    $PI_PUT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% User Time")
    $PI_PUT.InstanceName = $InstanceName
    $null = $PI_PUT.NextValue()
    $PI_PIT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% Idle Time")
    $PI_PIT.InstanceName = $InstanceName
    $null = $PI_PIT.NextValue()
    $PI_INTPS = New-Object Diagnostics.PerformanceCounter("Processor Information", "Interrupts/sec")
    $PI_INTPS.InstanceName = $InstanceName
    $null = $PI_INTPS.NextValue()
    $PI_PINTT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% Interrupt Time")
    $PI_PINTT.InstanceName = $InstanceName
    $null = $PI_PINTT.NextValue()
    $PI_DPCQPS = New-Object Diagnostics.PerformanceCounter("Processor Information", "DPCs Queued/sec")
    $PI_DPCQPS.InstanceName = $InstanceName
    $null = $PI_DPCQPS.NextValue()
    $PI_PDPCT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% DPC Time")
    $PI_PDPCT.InstanceName = $InstanceName
    $null = $PI_PDPCT.NextValue()
    $PI_PPRIOT = New-Object Diagnostics.PerformanceCounter("Processor Information", "% Priority Time")
    $PI_PPRIOT.InstanceName = $InstanceName
    $null = $PI_PPRIOT.NextValue()

    $Memory_AvailMB = New-Object Diagnostics.PerformanceCounter("Memory", "Available MBytes")
    $null = $Memory_AvailMB.NextValue()
    $Memory_ModPLBy = New-Object Diagnostics.PerformanceCounter("Memory", "Modified Page List Bytes")
    $null = $Memory_ModPLBy.NextValue()
    $Memory_SBCCBy = New-Object Diagnostics.PerformanceCounter("Memory", "Standby Cache Core Bytes")
    $null = $Memory_SBCCBy.NextValue()
    $Memory_SBCNPBy = New-Object Diagnostics.PerformanceCounter("Memory", "Standby Cache Normal Priority Bytes")
    $null = $Memory_SBCNPBy.NextValue()
    $Memory_SBCRBy = New-Object Diagnostics.PerformanceCounter("Memory", "Standby Cache Reserve Bytes")
    $null = $Memory_SBCRBy.NextValue()
#--
    $Memory_PIps = New-Object Diagnostics.PerformanceCounter("Memory", "Pages Input/sec")
    $null = $Memory_PIps.NextValue()
    $Memory_PRps = New-Object Diagnostics.PerformanceCounter("Memory", "Page Reads/sec")
    $null = $Memory_PRps.NextValue()


    $Processes_HndlCnt = New-Object Diagnostics.PerformanceCounter("Process", "Handle Count")
    $Processes_HndlCnt.InstanceName = $InstanceName
    $null = $Processes_HndlCnt.NextValue()
    $sw = New-Object Diagnostics.Stopwatch
    do {
        $sw.Start()
        if ($queryExists) {
            $a = query user /server:localhost
            $usrs = 0
            for ($i = 0; $i -lt $a.Count; $i++)
            { 
                if ($a[$i+1] -match 'active') {$usrs+=1}
            }
        } else {
            $usrs = -1
        }
        #From here
        $tmpCPUQL = ($System_ProQL.NextValue() / $TotProc)
        $tmpCPUQL  = [uint32]$tmpCPUQL
        
        $ln0 = ($("{0:HH:mm:ss}" -f (get-date))).TrimEnd()+
          ", Uptime: " + ($System_UpTime.NextValue() | % {[timespan]::fromseconds($_)} | % {[string]::Format("{0:d2}d:{1:d2}h:{2:d2}m",$_.days,$_.hours,$_.minutes)}) +
          ", Users: " + ($usrs).ToString().PadLeft(3) + ", #thds ready but queued for CPU: " + $tmpCPUQL.ToString().PadLeft(3)
        $ln1 = '-------------------------------------------------------------------------------'
        $ln2 = '| RUNNING           | CPU                           | RAM[MB]                 |'
        #Line 3 is Line 1
        $ln4 = '| services:'+ ((Get-Service | Where-Object {$_.Status -ne 'Stopped'} | Measure-Object).Count).ToString().PadLeft(7) + 
          '  | Sys:' + (("{0,6:N2}" -f ([math]::Round($PI_PT.NextValue(),2)))+"%(P "+("{0,5:N2}" -f ([math]::Round($PI_PPT.NextValue(),2)))+"%/U "+("{0,5:N2}" -f ([math]::Round($PI_PUT.NextValue(),2)))+"%)").ToString().PadLeft(17) +
          '| Installed:' + $w.ToString("0.00").PadLeft(13) + ' |'
        $ln5 = '| processes:' + ($System_ProcCnt.NextValue()).ToString().PadLeft(6) + '  | Idle:' + ([math]::Min([math]::Round($PI_PIT.NextValue(),2), 100.00)).ToString("0.00").PadLeft(5) + "%                   | HW reserv:"+
          ([math]::Round($w - $VisMemS, 2)).ToString("0.00").PadLeft(13) + ' |'
        $ln6 = '| threads:' + ($System_ThdCnt.NextValue()).ToString().PadLeft(8) + '  | HWint:    ' + (([int]$PI_INTPS.NextValue()).ToString()+"/"+([math]::Round($PI_PINTT.NextValue(),2)).ToString("0.00")).ToString().PadLeft(18) +
          '% | Visible:'+([math]::Round(($VisMemS),2)).ToString("0.00").PadLeft(15) + ' |'
        $ln7 = '| handles:'+ ($Processes_HndlCnt.NextValue()).ToString().PadLeft(8) +
          '  | SWint:    ' + (([int]$PI_DPCQPS.NextValue()).ToString()+"/"+(([math]::Round($PI_PDPCT.NextValue(),2))).ToString("0.00")).ToString().PadLeft(18) +
          '% | Available:' + (([math]::Round($Memory_AvailMB.NextValue(),2))).ToString("0.00").PadLeft(13) + ' |'
        $ln8 = '| CoSw/s:'+([uint32]$System_CSpS.NextValue()).ToString().PadLeft(9) +'  | High-prio thd exec:    ' + ([math]::Round($PI_PPRIOT.NextValue(),2)).ToString("0.00").PadLeft(5) + '% | Modified:'+
          ([math]::Round($Memory_ModPLBy.NextValue() / 1024 / 1024,2)).ToString("0.00").PadLeft(14) + ' |'
        $ln9 = "|                   | Total # of CPU's:"+$TotProc.ToString().PadLeft(12) +" | Standby:" +
          ([math]::Round($Memory_SBCCBy.NextValue()/1024/1024 + $Memory_SBCNPBy.NextValue()/1024/1024+$Memory_SBCRBy.NextValue()/1024/1024,2)).ToString("0.00").PadLeft(15) + ' |'
        $ln10 = "|                   |                               | PagesIn/Read ps:" +
          ([math]::Round($Memory_PIps.NextValue() / $Memory_PRps.NextValue(),2)).ToString("0.00").PadLeft(7) + ' |'
        #Line 11 is Line 1
        $stream = [System.IO.StreamWriter] ((dir Env:\TEMP).Value + "\headerres.txt")
        
        $stream.WriteLine($ln0)
        $stream.WriteLine($ln1)
        $stream.WriteLine($ln2)
        $stream.WriteLine($ln1)
        $stream.WriteLine($ln4)
        $stream.WriteLine($ln5)
        $stream.WriteLine($ln6)
        $stream.WriteLine($ln7)
        $stream.WriteLine($ln8)
        $stream.WriteLine($ln9)
        $stream.WriteLine($ln10)
        $stream.WriteLine($ln1)
        $stream.WriteLine("")
        $stream.WriteLine("")
        $stream.close()
        
        $sw.Stop()
        if ($sw.ElapsedMilliseconds -lt 1000) {
            Start-Sleep -Milliseconds (1000-$sw.ElapsedMilliseconds)
        }
        $sw.Reset()
    } while ($true)
    $sw = $null
} -Name "Top_Header_Job"
#endregion

#Sleep until "header" job produces first result.
$i = 0
do {
    Start-Sleep -Seconds 1
    $i += 1
} until ((Test-Path ((dir Env:\TEMP).Value + "\headerres.txt")) -or ($i -eq 20))

#region Tasks job
$m = Start-Job -ArgumentList $TotProc -ScriptBlock {
    [ScriptBlock]$sb = {
        if ($procSortBy -eq 'CPUpt') {
            if ($CPUDSw) {
                $Input | Sort @{Expression="_CPUpt__";Descending=$true}, @{Expression="WS(MB)";Descending=$true}
            } else {$Input | Sort @{Expression="_CPUpt_N";Descending=$true}, @{Expression="WS(MB)";Descending=$true}}
        } else {
            if ($procSortBy -eq 'WS(MB)') {
                if ($CPUDSw) {
                    $Input | Sort @{Expression="WS(MB)";Descending=$true}, @{Expression="_CPUpt__";Descending=$true}
                } else {$Input | Sort @{Expression="WS(MB)";Descending=$true}, @{Expression="_CPUpt_N";Descending=$true}}
            } else {
                if ($procSortBy -eq '_PID_') {
                    if ($CPUDSw) {
                        $Input | Sort @{Expression="_PID_";Descending=$false}, @{Expression="_CPUpt__";Descending=$true}
                    } else {$Input | Sort @{Expression="_PID_";Descending=$false}, @{Expression="_CPUpt_N";Descending=$true}}
                } else { $Input | Sort 'Name                  ' }
            }
        }
    }

    $CPUDSw = $true #Do not divide CPU% by process with # of CPUs (i.e. non-normalized view).
    $procToDisp = 25 #This is the number of processes to send back, wo header lines.
    $procSortBy = 'CPUpt'
    $TotProc = $args[0]
    #Permanent values.
    $pth = (dir Env:\TEMP).Value + '\thrprocstats.txt'
    $cfg = (dir Env:\TEMP).Value + '\topcfg.txt'
    $sw = New-Object Diagnostics.Stopwatch
    do {
        $sw.Start()
        do {
        } while (Test-Path $pth)

        if ($CPUDSw) {
            Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | 
                select @{Name='_PID_'; Expression={$_.IDProcess}},
                @{Name='PPID'; Expression={$_.CreatingProcessID}},
                @{Name='PrioB'; Expression={$_.PriorityBase}},
                @{Name='Name                  '; Expression={(($_.Name).PadRight(22)).substring(0, [System.Math]::Min(22, ($_.Name).Length))}}, 
                @{Name='_CPUpt__'; Expression={($_.PercentProcessorTime).ToString("0.00").PadLeft(8)}},
                @{Name='Thds'; Expression={$_.ThreadCount}},
                @{Name='Hndl'; Expression={$_.HandleCount}},
                @{Name='WS(MB)'; Expression={[math]::Truncate($_.WorkingSet/1MB)}},
                @{Name='VM(MB)'; Expression = {[math]::Truncate($_.VirtualBytes/1MB)}},
                @{Name='PM(MB)'; Expression={[math]::Truncate($_.PageFileBytes/1MB)}} |
                where { $_._PID_ -gt 0} | &$sb | 
                Select-Object -First $procToDisp | FT * -Auto 1> $pth
        } else {
            Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | 
                select @{Name='_PID_'; Expression={$_.IDProcess}},
                @{Name='PPID'; Expression={$_.CreatingProcessID}},
                @{Name='PrioB'; Expression={$_.PriorityBase}},
                @{Name='Name                  '; Expression={(($_.Name).PadRight(22)).substring(0, [System.Math]::Min(22, ($_.Name).Length))}}, 
                @{Name='_CPUpt_N'; Expression={"{0,8:N2}" -f ($_.PercentProcessorTime / $TotProc)}},
                @{Name='Thds'; Expression={$_.ThreadCount}},
                @{Name='Hndl'; Expression={$_.HandleCount}},
                @{Name='WS(MB)'; Expression={[math]::Truncate($_.WorkingSet/1MB)}},
                @{Name='VM(MB)'; Expression = {[math]::Truncate($_.VirtualBytes/1MB)}},
                @{Name='PM(MB)'; Expression={[math]::Truncate($_.PageFileBytes/1MB)}} |
                where { $_._PID_ -gt 0} | &$sb | 
                Select-Object -First $procToDisp | FT * -Auto 1> $pth
        }
        if (Test-Path $cfg) { 
            $tmp = ''
            $tmp = Get-Content $cfg
            if (($tmp) -and ($tmp -ne $procSortBy)) {
                $procSortBy = $tmp
                if ($procSortBy -eq 'CPUpt') {$CPUDSw = $true}
            } else {
                if ($tmp -eq 'CPUpt') {
                    $procSortBy = $tmp
                    $CPUDSw = !$CPUDSw
                }
            }
            $tmp = $null
            $tmp > $cfg #Reset.
        }
        $sw.Stop()
        if ($sw.ElapsedMilliseconds -lt 1000) {
            Start-Sleep -Milliseconds (1000-$sw.ElapsedMilliseconds)
        }
        $sw.Reset()

    } while ($true)
    $sw = $null
}  -Name "Top_Processes_Job"
#endregion

#region Main-start
$i = 0
#Sleep until "tasks" job produces first result.
do {
    Start-Sleep -Seconds 1
    $i += 1
} until ((Test-Path $pthf) -or ($i -eq 20))

[System.Console]::Clear()
if (Test-Path ((dir Env:\TEMP).Value + "\headerres.txt")) {
    $lastTimeHeader = Get-Date
    $l = Get-Content ((dir Env:\TEMP).Value + "\headerres.txt")
    [console]::setcursorposition(0,0)
    $l
    $l = $null
} else {
  $host.UI.WriteErrorLine("`t No data generated. Exiting.")
  try {
      Stop-Job -Job $j
      Receive-Job $j
      Remove-Job $j

      Stop-Job -Job $m
      Receive-Job $m
      Remove-Job $m
  } catch {}
  Exit 1
}

$saveYH = [console]::CursorTop
$saveXH = [console]::CursorLeft
#$procToDisp = [console]::WindowHeight - [console]::CursorTop - 5

if (Test-Path $pthf) {
    $lastTimeProc = Get-Date
    $l1 = Get-Content $pthf
    [console]::setcursorposition($saveXH,$saveYH)
    $l1
    $l1 = $null
    if (Test-Path $pthf) {
        Remove-Item $pthf -Force -ErrorAction SilentlyContinue
    }
} else {
  $host.UI.WriteErrorLine("`t No data generated. Exiting.")
  try {
      Stop-Job -Job $j
      Receive-Job $j
      Remove-Job $j

      Stop-Job -Job $m
      Receive-Job $m
      Remove-Job $m
  } catch {}
  Exit 2
}
#endregion

#region Main-loop
$sw = New-Object Diagnostics.Stopwatch
do {
    $sw.Start()
    [console]::CursorVisible = $false
    $l = Get-Content ((dir Env:\TEMP).Value + "\headerres.txt") -ErrorAction SilentlyContinue
    $tc = Get-Item ((dir Env:\TEMP).Value + "\headerres.txt") -ErrorAction SilentlyContinue
    if (($l) -and ($tc) -and ($tc.LastWriteTime -gt $lastTimeHeader)) {
        $lastTimeHeader = Get-Date
    } else { $l = $null }

    $l1 = Get-Content $pthf -ErrorAction SilentlyContinue
    $tc = Get-Item $pthf -ErrorAction SilentlyContinue
    if (($l1) -and ($tc) -and ($tc.LastWriteTime -gt $lastTimeProc)) {
        $lastTimeProc = Get-Date
    } else { $l1 = $null }

    if (Test-Path $pthf) {
        Remove-Item $pthf -Force -ErrorAction SilentlyContinue
    }

    if ($l) { 
        #[System.Console]::Clear()
        [console]::setcursorposition(0,0)
        $l
    }

    if ($CPUDispLines -gt 0) {
        #Display individual CPUs
        #$CPUNdx
        $CPUl  = "         User  Priv  Idle  HWin  SWIn              User  Priv  Idle  HWin  SWIn"
        $CPUl += "`n-------------------------------------     -------------------------------------"
        $tt = $CPUdata | Get-CimInstance | Select Name, PercentUserTime, PercentPrivilegedTime, PercentIdleTime, PercentInterruptTime, PercentDPCTime | Sort Name
        for ($x = 0; $x -lt $CPUNdx.Count; $x++) {
            $CInstance = ($SocketNdx[$x]).ToString()+","+($CPUNdx[$x]).ToString() #Offset into PerfCounter

            $tmp = $x + 1
            $tmp = $tmp % 2
            $absNdx = $inArr[$x]

            if ($tmp -gt 0) {
                $LineX0 = "%CPU"+($absNdx).ToString().PadLeft(3)+":" `
                  +([math]::Min($tt.PercentUserTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentPrivilegedTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentIdleTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentInterruptTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentDPCTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)
            } else {
                $LineX1 = "     %CPU"+($absNdx).ToString().PadLeft(3)+":" `
                  +([math]::Min($tt.PercentUserTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentPrivilegedTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentIdleTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentInterruptTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($tt.PercentDPCTime[[array]::IndexOf($tt.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)
                $CPUl += "`n"+$LineX0+$LineX1
                $LineX0 = ''
                $LineX1 = ''
            }
        }
        [console]::setcursorposition($saveXH,$saveYH)
        if ($LineX0.Length -gt 5) { $CPUl += "`n"+$LineX0 } #Collect the odd one.
        $CPUl
    }

    if ($SocketDispLines -gt 0) {
        #Display individual Sockets
        #$SocketNdx
        $CPUl  = "         User  Priv  Idle  HWin  SWIn              User  Priv  Idle  HWin  SWIn"
        $CPUl += "`n-------------------------------------     -------------------------------------"
        $ts = $Socketdata | Get-CimInstance | Select Name, PercentUserTime, PercentPrivilegedTime, PercentIdleTime, PercentInterruptTime, PercentDPCTime | Sort Name
        for ($x = 0; $x -lt $SocketNdx.Count; $x++) {
            $CInstance = (($SocketNdx[$x]).ToString()+",_Total").ToString() #Offset into PerfCounter

            $tmp = $x + 1
            $tmp = $tmp % 2

            if ($tmp -gt 0) {
                $LineX0 = "%Pro"+($x).ToString().PadLeft(3)+":" `
                  +([math]::Min($ts.PercentUserTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentPrivilegedTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentIdleTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentInterruptTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentDPCTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)
            } else {
                $LineX1 = "     %Pro"+($x).ToString().PadLeft(3)+":" `
                  +([math]::Min($ts.PercentUserTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentPrivilegedTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentIdleTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentInterruptTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)+"," `
                  +([math]::Min($ts.PercentDPCTime[[array]::IndexOf($ts.Name, $CInstance)], 100.0)).ToString().PadLeft(5).Substring(0,5)
                $CPUl += "`n"+$LineX0+$LineX1
                $LineX0 = ''
                $LineX1 = ''
            }
        }
        [console]::setcursorposition($saveXH,$saveYH)
        if ($LineX0.Length -gt 5) { $CPUl += "`n"+$LineX0 } #Collect the odd one.
        $CPUl
    }

    if ($l1) {
        $l1 | Select -First $procToDisp
    }

    $l = $null
    $l1 = $null
    if ($Host.UI.RawUI.KeyAvailable) {
        $k = $Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyDown,IncludeKeyUp,NoEcho").Character
        if ("p" -eq $k) {
            'CPUpt' > $conf
            $HOST.UI.RawUI.Flushinputbuffer()
        } else {
            if ("r" -eq $k) {
                '_PID_' > $conf
                $HOST.UI.RawUI.Flushinputbuffer()
            } else {
                if ("m" -eq $k) {
                    'WS(MB)' > $conf
                    $HOST.UI.RawUI.Flushinputbuffer()
                } else {
                    if ("n" -eq $k) {
                        'Name' > $conf
                        $HOST.UI.RawUI.Flushinputbuffer()
                    } else {
                        if ($k -eq "q") {
                            break;
                        } else {
                            if ("+" -eq $k) {
                                #Do a check IF Something is showing.
                                #Clear screen area if so.
                                $CPUNdx = $null
                                $SocketNdx = $null
                                $inArr = $null
                                $CPUDispLines = 0
                                $SocketDispLines = 0
                                $tmp = ($CPUs-1).ToString()+'])'
                                
                                [console]::setcursorposition($saveXH,$saveYH + $procToDisp + 3)
                                [console]::ForegroundColor = "white"
                                [console]::BackgroundColor= "darkred"
                                [string]$usrInput = Read-host "Enter zero-based CPU indexes. Separate multiple values with , ([0-$tmp"
                                [console]::ResetColor()
                                if (($usrInput.Trim()).Length -lt 1) {
                                    #Default will be ALL CPU's in Socket 0
                                    $usrInput = ''
                                    for ($x = 0; $x -lt $CPUsPerSock; $x++) {
                                        $usrInput += "$x,"
                                    }
                                    $usrInput = $usrInput.TrimEnd(',')
                                }
                                $b = $usrInput.Split(",").Trim()
                                if (($b.GetType()).Name -ne 'String') {
                                    if ($b.Count -gt 40) {
                                      #Displaying 40 CPUs takes 20 lines leaving 5 for processes.
                                      $host.UI.WriteErrorLine("Too much CPUs selected.")
                                      Sleep -Seconds 2
                                      break
                                    }
                                    $CPUNdx = New-Object ‘Int32[]’ $b.Count
                                    $SocketNdx = New-Object ‘Int32[]’ $b.Count
                                    #Do some checks and sort the array of indexes.
                                    $inArr = $b | foreach {[convert]::ToInt16($_, 10)} | Sort -Unique
                                    if ($inArr.Count -ne $b.Count) {
                                      $host.UI.WriteErrorLine("Duplicate entries found.")
                                      Sleep -Seconds 2
                                      break
                                    }
                                } else {# Just 1 CPU index provided.
                                    $inArr = New-Object ‘Object[]’ 1
                                    $inArr[0] = $b[0]
                                    $CPUNdx = New-Object ‘Int32[]’ 1
                                    $SocketNdx = New-Object ‘Int32[]’ 1
                                }

                                if ($inArr.Count -gt 1) {
                                    if ($inArr[$inArr.Count-1] -gt ($CPUs-1)) {
                                      $host.UI.WriteErrorLine("Larger than CPU count index found.")
                                      Sleep -Seconds 2
                                      break
                                    }
                                }
                                if ($inArr[0] -lt 0) { #It's sorted.
                                  $host.UI.WriteErrorLine("Less than 0 CPU index found.")
                                  Sleep -Seconds 2
                                  break
                                }

                                for ($x = 0; $x -lt $inArr.Count; $x++) {
                                  $AbsoluteIndex = $inArr[$x]
                                  $ndx = $AbsoluteIndex + 1
                                  if ($ndx -gt $CPUs) {continue} #Skip wrong index
                                  #Get socket:
                                  if ($ndx -le $CPUsPerSock) {
                                    $SocketNdx[$x] = 0
                                    $CPUNdx[$x] = $AbsoluteIndex
                                  } else {
                                    $tmp = $ndx % $CPUsPerSock
                                    if ($tmp -eq 0) {
                                        $CPUNdx[$x] = $CPUsPerSock - 1
                                        $SocketNdx[$x] = [int]([math]::Truncate($ndx/$CPUsPerSock)) - 1
                                    } else {
                                        $CPUNdx[$x] = $tmp - 1
                                        $SocketNdx[$x] = [int]([math]::Truncate($ndx/$CPUsPerSock))
                                    }
                                  }
                                }
                                #How much lines will it take to display given I display 2 in 1 line?
                                $CPUDispLines = [math]::Max([int]($CPUNdx.Count / 2),1) #It can only be round number or X.5 which [int] will round up or 0.
                                $CPUDispLines += 2 #Add two lines for header.
                                $HOST.UI.RawUI.Flushinputbuffer()
                                #First one takes a while. Subsequent calls are 0.3seconds, as expected.
                                $tt = $CPUdata | Get-CimInstance | Select Name, PercentUserTime, PercentPrivilegedTime, PercentIdleTime, PercentInterruptTime, PercentDPCTime | Sort Name
                                $procToDisp -= $CPUDispLines
                                [System.Console]::Clear()
                                $HOST.UI.RawUI.Flushinputbuffer()
                            } else {
                              if ("-" -eq $k) {
                                $CPUNdx = $null
                                $SocketNdx = $null
                                $inArr = $null
                                $CPUDispLines = 0
                                $SocketDispLines = 0
                                $HOST.UI.RawUI.Flushinputbuffer()
                                $procToDisp = 25 + 3
                                [System.Console]::Clear()
                              } else {
                                if ("1" -eq $k) {
                                    #Do a check IF Something is showing.
                                    #Clear screen area if so.
                                    $CPUNdx = $null
                                    $SocketNdx = $null
                                    $inArr = $null
                                    $CPUDispLines = 0
                                    $SocketDispLines = 0
                                    $tmp = ($sockets-1).ToString()+'])'
                                
                                    [console]::setcursorposition($saveXH,$saveYH + $procToDisp + 3)
                                    [console]::ForegroundColor = "white"
                                    [console]::BackgroundColor= "darkred"
                                    $usrInput = Read-host "Enter zero-based Socket indexes. Separate multiple values with , ([0-$tmp"
                                    if (($usrInput.Trim()).Length -lt 1) {
                                        #Default is Socket 0
                                        $usrInput = ''
                                        for ($x = 0; $x -lt $sockets; $x++) {
                                            $usrInput += "$x,"
                                        }
                                        $usrInput = $usrInput.TrimEnd(',')
                                    }
                                    [console]::ResetColor()
                                    
                                    $b = $usrInput.Split(",").Trim()
                                    if (($b.GetType()).Name -ne 'String') {
                                        if ($b.Count -gt 40) {
                                          #Displaying 40 Sockets takes 20 lines leaving 5 for processes.
                                          $host.UI.WriteErrorLine("Too much Sockets selected.")
                                          Sleep -Seconds 2
                                          break
                                        }
                                        $SocketNdx = New-Object ‘Int32[]’ $b.Count
                                        #Do some checks and sort the array of indexes.
                                        $inArr = $b | foreach {[convert]::ToInt16($_, 10)} | Sort -Unique
                                        if ($inArr.Count -ne $b.Count) {
                                          $host.UI.WriteErrorLine("Duplicate entries found.")
                                          Sleep -Seconds 2
                                          break
                                        }
                                    } else {# Just 1 CPU index provided.
                                        $inArr = New-Object ‘Object[]’ 1
                                        $inArr[0] = $b[0]
                                        $SocketNdx = New-Object ‘Int32[]’ 1
                                    }

                                    if ($inArr.Count -gt 1) {
                                        if ($inArr[$inArr.Count-1] -gt ($CPUs-1)) {
                                          $host.UI.WriteErrorLine("Larger than Sockets count index found.")
                                          Sleep -Seconds 2
                                          break
                                        }
                                    }
                                    if ($inArr[0] -lt 0) { #It's sorted.
                                      $host.UI.WriteErrorLine("Less than 0 Socket index found.")
                                      Sleep -Seconds 2
                                      break
                                    }

                                    $SocketNdx = $inArr
                                    #How much lines will it take to display given I display 2 in 1 line?
                                    $SocketDispLines = [math]::Max([int]($SocketNdx.Count / 2),1) #It can only be round number or X.5 which [int] will round up or 0.
                                    $SocketDispLines += 2 #Add two lines for header.
                                    $HOST.UI.RawUI.Flushinputbuffer()
                                    #First one takes a while. Subsequent calls are 0.3seconds, as expected.
                                    $ts = $Socketdata | Get-CimInstance | Select Name, PercentUserTime, PercentPrivilegedTime, PercentIdleTime, PercentInterruptTime, PercentDPCTime | Sort Name
                                    $procToDisp -= $SocketDispLines
                                    [System.Console]::Clear()
                                    $HOST.UI.RawUI.Flushinputbuffer()
                                } else {
                                    if ("c" -eq $k) {
                                        $HOST.UI.RawUI.Flushinputbuffer()
                                        [System.Console]::Clear()
                                    }
                                }
                              }
                            } 
                        }
                    }
                }
            }
        }
        $HOST.UI.RawUI.Flushinputbuffer()
    }
    $sw.Stop()
    if ($sw.ElapsedMilliseconds -lt 1000) {
        Start-Sleep -Milliseconds (1000-$sw.ElapsedMilliseconds)
    }
    $sw.Reset()

} while ($true)

#region cleanup
$sw = $null
[console]::TreatControlCAsInput = $false
[console]::setcursorposition($saveXH,$saveYH + $procToDisp + $CPUDispLines + $SocketDispLines)
Write-Host "Exiting...." -Background DarkRed
[console]::CursorVisible = $true

$OldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
#"Top_Header_Job" & "Top_Processes_Job"
Stop-Job -Job $j
$null = Receive-Job $j
Remove-Job $j

Stop-Job -Job $m
$null = Receive-Job $m
Remove-Job $m

Sleep -Seconds 3

if (Test-Path ((dir Env:\TEMP).Value + "\headerres.txt")) { 
    Remove-Item ((dir Env:\TEMP).Value + "\headerres.txt") -Force -ErrorAction SilentlyContinue
}
if (Test-Path $pthf) { 
    Remove-Item $pthf -Force -ErrorAction SilentlyContinue
}
if (Test-Path $conf) {
    Remove-Item $conf -Force -ErrorAction SilentlyContinue
}
$ErrorActionPreference = $OldErrorActionPreference
#endregion
#endregion