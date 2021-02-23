Displays Linux "top" tool data for single Windows machine. Requires PowerShell v3 or newer. Script does not work in
PowerShell_ISE. Please use Get-Help .\test-top.ps1 -Examples to see the description of the display.

Requirements:
The script can not be run in _ISE. Use Powershell console.
The script requires PS 3+.
The script requires at least 50 x 80 console window.
The script might work with .NET FW older than 4 but it was tested only with .NET 4.5.x.

Getting started:
1) Put script somewhere.
2) Start PowerShell (NOT PS_ISE)
3) cd to "somewhere" directory
4) .\top-script.ps1
	a) Get-Help .\top-script.ps1
	b) Get-Help .\top-script.ps1 -Examples
5) While script is running you can use (single key) shortcuts:
  q - Quit (CTRL + BREAK)
  m - Sort by process WS (occupied RAM) DESC, CPUpt DESC
  p - Sort by process CPU util DESC, WS(MB) DESC. Toggles Normal/Normalized view.
  n - Sort by process Name ASC
  r - Sort by process PID ASC, CPUpt DESC
  c – Clear screen
--
  + - Display individual CPU(s)
  1 - Display individual socket(s).
  - - Cancel displaying individual CPUs/Sockets

OUTPUT:
09:21:17,Uptime:00d:00h:36m, Users: 1, # thds ready but queued for CPU: 0
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
		  this number can be over 100% unles you see _CPUpt_N caption which
		  means "Normalized" (i.e. CPUutilization / # of CPUs).
        Thds     # of threads spawned by the process.
        Hndl     # of handles opened by the process.
        WS(MB)   Total RAM used by the process. Working Set is, basically,
            the set of memory pages touched recently by the threads belonging
            to the process. 
        VM(MB)   Size of the virtual address space in use by the process.
        PM(MB)   The current amount of VM that this process has reserved for
            use in the paging files.

Longer explanation of values:
    HEADER:
		Foreword: Since Windows is not "process" based OS (like Linux) it is impossible to calculate the "System load".
		The next best thing is CPU queue length (see below).
		Uptime:
			Category/Counter: System.Diagnostics.PerformanceCounter("System", "System Up Time")
		Users:
			Category/Counter: WMI query using query.exe tool which should be a part of your installation.
			query user /server:localhost
			Description: Number of users currently logged in. If query.exe is not available, the value is fixed to -1.
		# thds ready but queued for CPU:
			Category/Counter: System.Diagnostics.PerformanceCounter("System", "Processor Queue Length")
			Description: The System\Processor Queue Length counter shows how many threads are in the processor queue
			ready to be executed but not currently able to use cycles. Windows OS has single queue length counter thus
			the value displayed is counter value divided with number of CPU's.
			Link: https://technet.microsoft.com/en-us/library/cc940375.aspx
		
        RUNNING section:
            services:
				Category/Counter: PowerShell interface:
				(Get-Service | Where-Object {$_.Status -ne 'Stopped'} | Measure-Object).Count
				Description: Total # of services actually running.
            processes:
				Category/Counter: System.Diagnostics.PerformanceCounter("System", "Processes")
				Description: Total number of user processes running.
				Link: https://msdn.microsoft.com/en-us/library/aa394277%28v=vs.85%29.aspx
            threads:
				Category/Counter: System.Diagnostics.PerformanceCounter("System", "Threads")
				Description: Total # of threads spawned.
            handles:
				Category/Counter: System.Diagnostics.PerformanceCounter("Process", "Handle Count")
				Description: Total # of open handles.
            CoSw/s:
				Category/Counter: System.Diagnostics.PerformanceCounter("System", "Context Switches/sec")
				Description: Context switching happens when a higher priority thread pre-empts a lower priority thread
				that is currently running or when a high priority thread blocks. High levels of context switching can
				occur when many threads share the same priority level. This often indicates that there are too many
				threads competing for the processors on the system. If you do not see much processor utilization and you
				see very low levels of context switching, it could indicate that threads are blocked.
				Link: https://msdn.microsoft.com/en-us/library/aa394279%28v=vs.85%29.aspx

        CPU section:
			Foreword: Windows OS has special thread called "Idle" which consumes free CPU cycles thus these counters
			return values relating to this one. Also, Windows are not "process" based but rather "thread" based so all
			of these numbers are approximations. This is even more important in the TABLE which shows CPU utilization
			per process (see explanation there). Most of these counters are multi-instance so instance name is '_Total'
			(ie. CPU utilization in total as opposed to per NUMA node, Core, CPU...).
            Sys: nn.nn%(P  mm.mm%/U zz.zz%):
				Category/Counter: System.Diagnostics.PerformanceCounter("Processor Information", "% Processor Time"),
				System.Diagnostics.PerformanceCounter("Processor Information", "% Privileged Time"),
				System.Diagnostics.PerformanceCounter("Processor Information", "% User Time")
				Description: First number shows (100-CPUIdle), effectively, % of cycles CPU(s) didn't spend running the
				Idle thread. Second number is the time CPU(s) spent on executing Privileged instructions while third is
				time CPU(s) spent executing user-mode instructions. I.e. when your application calls OS functions
				(say to do file/network I/O or to allocate memory), these OS functions are executed in privileged mode.
				Link: https://msdn.microsoft.com/en-us/library/aa394271%28v=vs.85%29.aspx
            Idle:
				Category/Counter: System.Diagnostics.PerformanceCounter("Processor Information", "% Idle Time")
				Link: https://msdn.microsoft.com/en-us/library/aa394271%28v=vs.85%29.aspx
            HWint:
				Category/Counter: System.Diagnostics.PerformanceCounter("Processor Information", "Interrupts/sec") and
				System.Diagnostics.PerformanceCounter("Processor Information", "% Interrupt Time").
				Description: Rate of hardware interrupts per second and a percent of CPU time this takes.
				Link: https://msdn.microsoft.com/en-us/library/aa394271%28v=vs.85%29.aspx
            SWint:
				Category/Counter: System.Diagnostics.PerformanceCounter("Processor Information", "DPCs Queued/sec") and
				System.Diagnostics.PerformanceCounter("Processor Information", "% DPC Time")
				Description: Rate at which SW interrupts are queued for execution and a percent of CPU time this takes.
				Link: https://msdn.microsoft.com/en-us/library/aa394271%28v=vs.85%29.aspx
            High-prio thd exec:
				Category/Counter: System.Diagnostics.PerformanceCounter("Processor Information", "% Priority Time")
				Description: CPU utilization by high priority threads.
				Link: Can't find any links in MSDN...
            Total # of cores:
			
        RAM[MB] section:
            Installed:
				Category/Counter: cim_physicalmemory, 
				(get-ciminstance -class "cim_physicalmemory" | Measure-Object Capacity -Sum).Sum / 1024 / 1024
				Description:
            HW reserv:
				Category/Counter: Installed - Visible ;-)
				Description:
            Visible:
				Category/Counter: (Get-CimInstance win32_operatingsystem).TotalVisibleMemorySize
				Description:
            Available:
				Category/Counter: System.Diagnostics.PerformanceCounter("Memory", "Available MBytes") 
				Description:
            Modified:
				Category/Counter: System.Diagnostics.PerformanceCounter("Memory", "Modified Page List Bytes")
				Description:
            Standby:
				Category/Counter: System.Diagnostics.PerformanceCounter("Memory", "Standby Cache Core Bytes") + 
				System.Diagnostics.PerformanceCounter("Memory", "Standby Cache Normal Priority Bytes") + 
				System.Diagnostics.PerformanceCounter("Memory", "Standby Cache Reserve Bytes")
				Description: Basically, cache memory.
			PagesIn/Read ps:
				Category/Counter: System.Diagnostics.PerformanceCounter("Memory", "Pages Input/sec") / 
				  System.Diagnostics.PerformanceCounter("Memory", "Page Reads/sec")
				Description: Ratio between Memory\Pages Input/sec and Memory\Page Reads/sec which is number of pages
				per disk read. Should keep below 5.
			

    TABLE:
		Foreword: Windows is not "process" based OS (like Linux) but rather "thread" based so all of the numbers
		relating to CPU usage are approximations. I did made a "proper" CPU per Process looping and summing up Threads
		counter (https://msdn.microsoft.com/en-us/library/aa394279%28v=vs.85%29.aspx) based on PID but that proved too
		slow given I have ~1 sec to deal with everything. CPU utilization uses RAW counters with 1s delay between
		samples. This proved to produce a bit more reliable result than just reading Formatted counters.

		Category/Counter: CPU utilization by process: Win32_PerfRawData_PerfProc_Process; rest of the data:
		Win32_PerfFormattedData_PerfProc_Process
		Link: https://msdn.microsoft.com/en-us/library/aa394277%28v=vs.85%29.aspx
		
        _PID_    Unique identified of the process.
        PPID     Unique identifier of the process that started this one.
        PrioB    Base priority.
        Name     Name of the process.
        CPUpt_(N)    % of CPU used by process. On machines with multiple CPUs, this number can be over 100% unless you
		see _CPUpt_N caption which means "Normalized" (i.e. CPUutilization / # of CPUs). Toggle Normal/Normalized
		display by pressing key p.
        Thds     # of threads spawned by the process.
        Hndl     # of handles opened by the process.
        WS(MB)   Total RAM used by the process. Working Set is, basically,
            the set of memory pages touched recently by the threads belonging
            to the process. 
        VM(MB)   Size of the virtual address space in use by the process.
        PM(MB)   The current amount of VM that this process has reserved for
            use in the paging files.



TRICKS:
-------
As opposed to Windows TaskManager, I show background processes too
(ie. "services") thus the numbers will differ.

Number of processes to display is controlled by $procToDisp variable. Default
is 25 ($procToDisp = 25).

Initial sort order is defined by $procSortBy variable. Default is non-normalized %CPU utilization
($procSortBy = 'CPUpt').

IF by any chance script does not terminate normally:
- First type Get-Job
- Check that Name has "Top_Header_Job" & "Top_Processes_Job". Remember the Id (or use Name parameter).
Say Id's are 14 and 16.
- Type commands (text after # is just a comment):
[console]::CursorVisible = $true #reclaims the cursor
[console]::TreatControlCAsInput = $false #reverts CTRL+C processing to default value
receive-job -id 14
receive-job -id 16
stop-job -id 16
stop-job -id 14
remove-job -id 14
remove-job -id 16

If display becomes garbled, press key [c] to redraw entire screen.

If you do not want to enter CPU indexes separated by comma, after pressing [+] just press [ENTER]. This will display all
of the CPUs in socket 0.

If you do not want to enter Socket indexes separated by comma, after pressing [1] just press [ENTER]. This will display
Socket 0.


CHANGES:
--------
- Changed Header section to table format.
- Added double Sort (CPU% DESC, Name ASC...)
- Added key capturing.
- Added flicker-free code to draw Header.
- Added readme file.
- Fixed many things :)

CHANGES 2015-09-30:
-------------------
- Replaced system.environment.ProcessorCount which often fails randomly with
more reliable Get-CimInstance -Namespace root/CIMV2 -ClassName CIM_Processor
NumberOfLogicalProcessors. Affects CPU% calculation per process.
- Some optimizations.
- Removed UserTime, put in PM(MB) (PageFileBytes)

CHANGES 2015-10-01:
-------------------
- Fixed CPU utilization by process code. Although correct now, it is MUCH slower...
Word on Windows: As opposed to *nix, Windows is *thread* based. Thus to get more or less accurate numbers on CPU
utilization per process running, one has to sum up CPU utilization for all the threads in the process. This takes time.
- Replaced Get-WMI with Get-CIM which is much faster.
- Removed some unnecessary calls (Visible memory, HWreserved... is always the same).

CHANGES 2015-10-05:
-------------------
- Moved Header and Table calculation into background jobs allowing for faster calculation (parallel execution) and
smoother display change.
- IF CPU utilization by thread counter returns all 0-s, Table with running processes is NOT updated.

CHANGES 2015-10-06:
-------------------
- Reverted *back* to calculating CPU utilization from Processes Category (and not summing up Threads) due to timing
issues. However, now I take samples 1 second apart thus approximation should be ok.

CHANGES 2015-10-09:
-------------------
- Handle CTRL+C for graceful shutdown.
- Test if query.exe is in the Path. If not, Users = -1
- Do not refresh display if no new data available.

CHANGES 2015-10-13:
-------------------
- CTRL+C is just ignored.
- Fixed CPU count on boxes with many NUMA nodes.
- When displaying memory stats for process, use [math]::Truncate instead casting number to [int] (some values might fall
 way outside of int range on big boxes).
---
- Fix hide AM/PM (2 digit hour) in current time.
- Added Powershell minimal version check.
- Added .NET FW minimal version check.

CHANGES 2015-10-26:
-------------------
- Added PagesIn/Read ps to Memory.

CHANGES 2015-10-28:
-------------------
- CPUpt is changed now so that, by default, it does not normalize CPU utilization by the process (i.e. you can have 
1500% utilization on many CPUs machine).
IF non-normalized value is the source for data, the column title will be '_CPUpt__'.

Normalized CPU utilization value (CPUpt / # of CPUs) will display as '_CPUpt_N'.

To toggle between the two, just press p key.

- Fixed so that process names are now fixed to the length of 25 characters preventing shifting the columns to the right.

CHANGES 2015-10-29:
-------------------
- Fix Sort by Name of the process.
- Name of the process is now 22 characters max. Rest is cut off.

CHANGES 2015-10-30:
-------------------
- Added showing info for CPU. To select CPU(s) just press + key. When prompted for CPU indexes remember:
  a) CPU indexes are 0 based
and
  b) separate multiple values with comma (,)
To show all 8 CPUs on 1st Socket (Quad core with HT) you would enter: 0,1,2,3,4,5,6,7
To show 1st CPU on 2nd Socket (Quad core with HT) you would enter: 8

Cancelling "Show individual CPU's" command is done by pressing - key.


CHANGES 2015-11-02:
-------------------
- Preparing for release:
    Removed recursive scan of Threads category for CPU utilization by the process, relying on just Processes category
	now. Bit less accurate (UINT instead of Decimal) but much smoother.
	Removed excess code.
	Added check for console size being 50 x 80 at least.
	Fixed line counting.
	Fixed cleanup code.
- Added Load per Socket (keyboard shortcut 1). Script displays either Socket load or CPU load.


CHANGES 2015-11-25:
-------------------
- Error handling when stopping the script.
- Keyboard shortcut "c" - Clear console.
- IF + or 1 keys are pressed and nothing is entered (ie. just ENTER or [space]...[ENTER]) the script will default to 0
as CPU/Socket to monitor index.


CHANGES 2015-11-26:
-------------------
- Changed defaults for displaying CPU/Socket data:
	For CPU data (+ key pressed) if you provide just [ENTER], all of the CPUs in socket 0 will be displayed.
	For Socket data (1 key pressed) if you provide just [ENTER], Socket 0 will be displayed.
- Most of the values in header table now formatted to 2 decimal places to avoid shifting of display.


CHANGES 2015-12-15:
-------------------
- Timer creation/freeing changes.

