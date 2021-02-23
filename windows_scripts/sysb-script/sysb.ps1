##############################################################################
##
## sysb script, v0.93RC
##
## 
## Tonci Grgin, Oracle corp, 2016. All rights reserved.
##
## In PS window, type: Get-Help .\sysb.ps1 -Full
## from the directory where script is for details.
##
##############################################################################

<#

.SYNOPSIS
Sets up Sysbench and MySQL Server or MySQL Cluster for running OLTP tests on
single Windows machine. Requires PowerShell v3 or newer, MySQL Server v5.6+ and
MySQL Cluster version 7.4+.

.DESCRIPTION
Script (extracts archives), (builds), deploys locally, tests with Sysbench and
shuts down MySQL Server or Cluster providing results.

Inside script folder there should be:
  o MANDATORY sysb.ps1 PowerShell script.
  o MANDATORY autobench.conf; either created or copied from Linux tarball.
  o MANDATORY MySql.Data.dll - core mySQL connector/NET.
  o ICSharpCode.SharpZipLib.dll/7-zip. Only for *.tar.gz processing.

Inside the test folder (TARBALLDIR) there should be:
  o MANDATORY Either Server or Cluster tarball and Sysbench tarball. If it's source
  archive, it will be built providing tools are installed (see notes).
  o sysbench.conf file; either created or copied from Linux tarball.
  o config.ini file for Cluster configuration.

If ICSharpCode.SharpZipLib.dll/7-zip is not provided you will not be able to process
tar.gz archives.
If sysbench.conf is not provided, Sysbench will run with predefined set of
parameters (.\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql
--test=oltp --mysql-user=root --mysql-db=test).
If config.ini is not provided, script will create minimal one for MySQL Cluster.

The minimal autobench.conf has 2 entries in [GENERAL] section:
[GENERAL]
TARBALL_DIR=E:\test
CLUSTERNODES=2
You might wish to add BENCHMARK_TO_RUN=sysbench too.

The layout of script folder:
PS > dir
    Directory: C:\Users\user\Documents\WindowsPowerShell\testingfw

Mode                LastWriteTime     Length Name                                                            
----                -------------     ------ ----                                                            
-a---         03.09.15.     12:00       8088 autobench.conf                                                  
-a---         07.05.14.     13:29     200704 ICSharpCode.SharpZipLib.dll                                     
-a---         17.02.15.     18:47     457216 MySql.Data.dll                                                  
-a---         07.09.15.     11:19     169292 sysb.ps1                                                        
-a---         05.09.15.     17:12      14675 Version-info.txt                                                

The layout of test folder (TARBALLDIR):
PS > dir E:\test
    Directory: E:\test
Mode                LastWriteTime     Length Name                                                            
----                -------------     ------ ----                                                            
d----         03.09.15.     19:30            mysql-5.6.24-winx64                                             
d----         27.07.15.     20:35            sysbench-0.4.12.10                                              
-a---         27.07.15.     13:13       1090 config.ini                                                      
-a---         15.04.15.     18:02  366063432 mysql-5.6.24-winx64.zip                                         
-a---         07.04.15.     07:48     867859 sysbench-0.4.12.10.tar.gz                                       
-a---         12.08.15.     18:13       1668 sysbench.conf                                                   
Note that MySQL and Sysbench archives are already extracted. This is allowed 
since script looks for ArchiveName directory when it encounters
ArchiveName.ext archive before extraction. It also checks that already existing
ArchiveName directory has required binaries.


.INPUTS
  On command line, none.
  In script directory, autobench.conf.
  In test directory, sysbench.conf, config.ini (for Cluster).


.OUTPUTS
Script produces following output:
  o sessiondump-timestamp.txt - Dump of Powershell console.
  o mysqld-output-timestamp.txt - Mysqld process output.
  o runlogtimestamp.txt - Sysbench process output.
  o results.csv - Sysbench process output formatted as spreadsheet.
  o ndb_data-timestamp - ndb_data directory if Cluster was tested.
All of the output is compressed into archrun-timestamp.zip providing
autobench.conf sets ARCHIVERUN=yes.


.NOTES
Downloads:
Server download (ZIP Archive): http://dev.mysql.com/downloads/mysql/
Cluster download (ZIP Archive): http://dev.mysql.com/downloads/cluster/
Script + Sysbench: http://downloads.mysql.com/source/dbt2-0.3X.YY.Z.tar.gz
All of the downloads can be precompiled binaries or source archives.

Required:
You should have a folder with Sysbench and server or cluster archives.
MySQL server 5.6 and up.
MySQL Cluster 7.0 and up.
PowerShell v3+
ONLY if source files are used:
  VisualStudio (Express) - only if you use sources and need compilation.
  CMAKE 3+
  GNU BISON 2.4+

With script, there might be two libraries provided:
  MySql.Data.dll - core mySQL connector/NET.
  ICSharpCode.SharpZipLib.dll - compression/decompression library by Mike
  Krueger and John Reilly. You can download it from
http://icsharpcode.github.io/SharpZipLib/. IF you do not plan to use TAR archives,
  you do not need this library.

Setting up Windows:
  1) Visual studio (Express will do just fine):
http://www.microsoft.com/en-us/download/details.aspx?id=44914
	Might require registration with MSDN.

  2) CMAKE installer:
http://www.cmake.org/files/v3.0/cmake-3.0.2-win32-x86.exe (or newer)
	Install somewhere with short path (ie. mine is in d:\CMake302)

  3) GNU Bison:
http://sourceforge.net/projects/gnuwin32/files/bison/2.4.1/bison-2.4.1-setup.exe/download
	Install somewhere with short path (ie. mine is in c:\GnuWin32)

  4) BOOST: MySQL 5.7 uses BOOST headers (1.58 ATM) which you can download from
http://sourceforge.net/projects/boost/files/boost-binaries/. Install somewhere with
short path (ie. mine is in C:\boost_1_58_0)

For convenience, add BOOST, CMAKE and BISON to PATH:
	a) Right-click "My Computer", choose "Properties".
	b) Click on "Advanced System settings".
	c) Click on "Environment variables", find PATH.
	d) Add "C:\boost_1_58_0;", "C:\GnuWin32\bin;" and "D:\CMake302\bin;". CMAKE
    might have done it during install.
    e) For BOOST, and new variable:
    Name:  WITH_BOOST
    Value: C:\boost_1_58_0

  5) Check PS version and update if necessary (script requires v3 or newer):
	a) Start PowerShell, check version:
PS C:\Users\...> $PSVersionTable

Name                           Value
----                           -----
CLRVersion                     2.0.50727.5485
BuildVersion                   6.1.7601.17514
PSVersion                      2.0
WSManStackVersion              2.0
PSCompatibleVersions           {1.0, 2.0}
SerializationVersion           1.1.0.1
PSRemotingProtocolVersion      2.1

If it is 2, update to v3 (at least) from:
http://www.microsoft.com/en-us/download/details.aspx?id=34595. Check
requirements (Win7 SP1, .NET FW 4+ etc). Package for Windows 7 Service Pack 1
64-bit versions is: WINDOWS6.1-KB2506143-x64.msu


Global variables description:
$SCRIPT:MySQLServer = $null - Will be set by script based on zipball name
  or read from autobench.conf::MYSQLTARBALL
$SCRIPT:MySQLCluster = $null - Will be set by script based on zipball name
  or read from autobench.conf::CLUSTERTARBALL
$SCRIPT:Sysbench = $null - Will be set by script based on zipball name
  or read from autobench.conf::SYSBENCHTARBALL
$SCRIPT:VSBuildEnv = $null - Will be set by script based on system.
$SCRIPT:MSBuildEnv = $null - Will be set by script based on system.
$SCRIPT:CMAKEGenerator = $null - Can be set by hand to specific generator
  and read from autobench.conf::CMAKE_GENERATOR (say "Visual Studio 12 2013 Win64").
$SCRIPT:CLUSTERCL - Number of Cluster data nodes to start.
  Read from autobench.conf::CLUSTERCL
$SCRIPT:SERVERCL - Array of command line parameters to pass to Server when starting.
  Read from autobench.conf::SERVERCL
$SysbenchMap - Hash map of *NIX/Windows parameters for Sysbench.
$SysbenchAllowed - Map of Sysbench values script is processing on Windows.
When configuration value is read from a file, it is first matched against $SysbenchMap
to check if it needs conversion from *NIX to Windows and then it's matched against 
$SysbenchAllowed.

.EXAMPLE
C:\PS> .\sysb.ps1

.LINK
http://www.mysql.com/
http://dev.mysql.com/downloads/mysql/
http://dev.mysql.com/downloads/cluster/
https://dev.mysql.com/downloads/benchmarks.html
http://www.cmake.org
http://sourceforge.net/projects/gnuwin32/files/bison
https://www.visualstudio.com/en-us/products/visual-studio-community-vs
http://sourceforge.net/projects/boost/files/boost-binaries/
http://icsharpcode.github.io/SharpZipLib/

#>

Set-StrictMode -Version Latest
Set-PSDebug -strict
#[console]::TreatControlCAsInput = $true #Trap CTRL+C for graceful exit.
#$SCRIPT:UserBreakDetected = $false

$SCRIPT:MySQLServer = $null
$SCRIPT:MySQLCluster = $null
$SCRIPT:Datadir = $null
$SCRIPT:Basedir = $null
$SCRIPT:Sysbench = $null
$SCRIPT:DBT2 = $null
$SCRIPT:VSBuildEnv = $null
$SCRIPT:MSBuildEnv = $null
$SCRIPT:CMAKEGenerator = $null #determine automagically
$SCRIPT:CMAKEConfigure = $null
$SCRIPT:CLUSTERCL = $null
$SCRIPT:SERVERCL = $null
$SCRIPT:MaxAffinity = $null
$SCRIPT:TotProc = 1
$SCRIPT:ArchiveRun = 'No' #autobench.conf::ARCHIVERUN
$SCRIPT:OPTIONDATAD = 'COPY_CLEAN'  #autobench.conf::OPTIONDATAD
$SCRIPT:SBDUMPPREPED = 'Yes' #autobench.conf::SBDUMPPREPED
$SCRIPT:SBPREPEDDATA = 'data_sb.sql' #autobench.conf::SBPREPEDDATA
$SCRIPT:SHOW_INNODB_STATUS = $true #autobench.conf::SHOW_INNODB_STATUS

$SCRIPT:MYSQLD_jobRunning = $false

$SCRIPT:Can_Do_TB = 0 # Enum; 0 - Can't proc. tarballs, 1 - ICSharp, 2 - 7Zip

$SCRIPT:logfile = $null #sysbench.conf::LOG_FILE 

$SysbenchMap = @{ 
    #Map variables used in Unix environment to Sybench varables.
    SERVER_HOST = "--mysql-host";
    SERVER_PORT = "--mysql-port";
    #--MACROS--
    #--oltp-test-mode=STRING                  test type to use {simple,complex,nontrx,sp}
    RUN_RO = "RUN_RO";
    RUN_RW = "RUN_RW";
    RUN_RW_WRITE_INT = "RUN_RW_WRITE_INT";
    RUN_RW_LESS_READ = "RUN_RW_LESS_READ";
    RUN_RO_PS = "RUN_RO_PS";
    RUN_WRITE = "RUN_WRITE";
    #--
    SB_USE_SECONDARY_INDEX = "--oltp-secondary";#[yes|no]/[on|off]
    SB_USE_MYSQL_HANDLER = "--oltp-point-select-mysql-handler";#[yes|no]/[on|off]
    SB_NUM_PARTITIONS = "--oltp-num-partitions";
    SB_NUM_TABLES = "--oltp-num-tables";
    THREAD_COUNTS_TO_RUN = "--num-threads";
    SB_AVOID_DEADLOCKS = "--oltp-avoid-deadlocks";#[yes|no]/[on|off]
    SB_USE_TRX = "--oltp-skip-trx"; #[yes|no]/[on|off] - NEGATE
    ENGINE = "--mysql-table-engine";
    TRX_ENGINE = "--mysql-engine-trx";
    SB_DIST_TYPE = "--oltp-dist-type";
    SB_POINT_SELECTS = "--oltp-point-selects";
    SB_RANGE_SIZE = "--oltp-range-size";
    SB_SIMPLE_RANGES = "--oltp-simple-ranges";
    SB_SUM_RANGES = "--oltp-sum-ranges";
    SB_ORDER_RANGES = "--oltp-order-ranges";
    SB_DISTINCT_RANGES = "--oltp-distinct-ranges";
    SB_USE_IN_STATEMENT = "--oltp-use-in-statement";
    SB_USE_AUTO_INC = "--oltp-auto-inc";
    MAX_TIME = "--max-time";
    SB_TX_RATE = "--tx-rate";
    SB_TX_JITTER = "--tx-jitter";
    SYSBENCH_ROWS = "--oltp-table-size"; #???"--myisam-max-rows";
    #--General test FW variables.
    NUM_TEST_RUNS = "NUM_TEST_RUNS";
    TEST_DESCRIPTION = "TEST_DESCRIPTION";
    BETWEEN_RUNS = "BETWEEN_RUNS";
    AFTER_INITIAL_RUN = "AFTER_INITIAL_RUN";
    AFTER_SERVER_START = "AFTER_SERVER_START";
    BETWEEN_CREATE_DB_TEST = "BETWEEN_CREATE_DB_TEST";
    NUM_CREATE_DB_ATTEMPTS = "NUM_CREATE_DB_ATTEMPTS";
    NUM_CHANGE_MASTER_ATTEMPTS = "NUM_CHANGE_MASTER_ATTEMPTS";
    BETWEEN_CHANGE_MASTER_TEST = "BETWEEN_CHANGE_MASTER_TEST";
    AFTER_SERVER_STOP = "AFTER_SERVER_STOP";
    LOG_FILE = "LOG_FILE";
    MAX_REQUESTS = '--max-requests';
    RUN_AS_HARNESS = 'RUN_AS_HARNESS';
    #Missing:
    SB_SEED_RNG = '--seed-rng';
    #SB_INIT_RNG ON/OFF - Not needed, just check seed > 0
    SB_REPORT_INTERVAL = '--report-interval';
    SB_THREAD_STACK_SIZE = '--thread-stack-size';  #Default:32K
    SB_OLTP_DIST_ITER = '--oltp-dist-iter';
    SB_OLTP_DIST_PCT = '--oltp-dist-pct'; #--oltp-dist-type=special!
    SB_OLTP_DIST_RES = '--oltp-dist-res'; #--oltp-dist-type=special!
    SB_OLTP_POINT_SELECT_ALL_COLS = '--oltp-point-select-all-cols'; #[on|off], --oltp-point-select-mysql-handler
    SB_OLTP_SP_NAME = '--oltp-sp-name';
    SB_OLTP_TEST_MODE = '--oltp-test-mode';
    SB_OLTP_READ_ONLY = '--oltp-read-only' #ON/OFF
}
$SysbenchAllowed = @( 
    '--test';
    '--mysql-host';
    '--mysql-port';
    '--mysql-user';
    '--mysql-db';
    '--oltp-read-only';
    '--oltp-secondary';
    '--oltp-point-select-mysql-handler';
    '--oltp-index-updates';
    '--oltp-num-partitions';
    '--oltp-num-tables';
    '--num-threads';
    '--mysql-table-engine';
    '--oltp-avoid-deadlocks';
    '--oltp-skip-trx';
    '--oltp-dist-type';
    '--mysql-engine-trx';
    '--oltp-point-selects';
    '--oltp-range-size';
    '--oltp-simple-ranges';
    '--oltp-sum-ranges';
    '--oltp-order-ranges';
    '--oltp-distinct-ranges';
    '--oltp-use-in-statement';
    '--oltp-auto-inc';
    '--max-time';
    '--tx-rate';
    '--tx-jitter';
    '--myisam-max-rows'; #Just hanging...
    '--oltp-table-size';
    '--max-requests';
    #Missing
    '--seed-rng';  #0 - ignore
    #--init-rng on/off depending if seed > 0
    '--report-interval';  #0 - ignore
    '--thread-stack-size';
    '--oltp-dist-iter';
    '--oltp-dist-pct'; #--oltp-dist-type=special!
    '--oltp-dist-res'; #--oltp-dist-type=special!
    '--oltp-point-select-all-cols'; #--oltp-point-select-mysql-handler
    '--oltp-sp-name';
    '--oltp-test-mode';
    '--oltp-read-only'; #ON/OFF
    #--
    #Macro
    "RUN_RO";
    "RUN_RW";
    'RUN_RW_LESS_READ';
    'RUN_RW_WRITE_INT';
    'RUN_RO_PS';
    'RUN_WRITE';
    #General test setup
    'NUM_TEST_RUNS';
    'TEST_DESCRIPTION';
    'BETWEEN_RUNS';
    'AFTER_INITIAL_RUN';
    'AFTER_SERVER_START';
    'BETWEEN_CREATE_DB_TEST';
    'NUM_CREATE_DB_ATTEMPTS';
    'NUM_CHANGE_MASTER_ATTEMPTS';
    'BETWEEN_CHANGE_MASTER_TEST';
    'AFTER_SERVER_STOP';
    'LOG_FILE';
    'RUN_AS_HARNESS'
)
<#
-t <socket>
        socket for connection to mysql server
-u <db user>
-a <db password>
#>
$DBT2Map = @{ 
    #Map variables used in Unix environment to DBT2 varables.
    DB_HOST = "-h";
    DB_PORT = "-l"; #Will be ignored and determined. --port?
    DB_SOCKET = "-t";
    DBCONN = "--connections";
    DB_USER = "--user";
    DB_PASSWORD = "--password";
    DURATION = "--time";
    WAREHOUSES = '-w';
    CLIENT_PORT = "-p"; #Default 30000
    TPW = "--terminals";
    SLEEPY = "--thread-start-delay";
    #Datagen:
    CUST_CARD = '-c';
    ITEM_CARD = '-i';
    ORD_CARD = '-o';
    NEWORD_CARD = '-n';
    DATA_PATH = '-d';
    #--General test FW variables.
    RUN_NUMBER = "--run-number";
    VERBOSE = "--verbose";
    ZERO_DELAY = "--zero-delay"; #yes/no(def)
    comment = "--comment"; #TEST_DESCRIPTION
    BETWEEN_RUNS = "BETWEEN_RUNS";
    AFTER_INITIAL_RUN = "AFTER_INITIAL_RUN";
    AFTER_SERVER_START = "AFTER_SERVER_START";
    BETWEEN_CREATE_DB_TEST = "BETWEEN_CREATE_DB_TEST";
    NUM_CREATE_DB_ATTEMPTS = "NUM_CREATE_DB_ATTEMPTS";
    NUM_CHANGE_MASTER_ATTEMPTS = "NUM_CHANGE_MASTER_ATTEMPTS";
    BETWEEN_CHANGE_MASTER_TEST = "BETWEEN_CHANGE_MASTER_TEST";
    AFTER_SERVER_STOP = "AFTER_SERVER_STOP";
    LOG_FILE = "--log-file";
    RUN_AS_HARNESS = 'RUN_AS_HARNESS';
    DBT2_DATA_DIR = '-d' #DBT2 always...
}

$DBT2Allowed = @( 
    '-h';
    '-l'; #Will be ignored and determined. --port?
    '-t';
    '--connections';
    '--user';
    '--password';
    '--time';
    '-w';
    #Data gen
    '-c'; #        customer cardinality, default 3000
    '-i'; #        item cardinality, default 100000
    '-o'; #        order cardinality, default 3000
    '-n'; #        new-order cardinality, default 900
    '-d'; # <path> output path of data files
    #--
    '-p'; #Default 30000
    '--terminals';
    '--thread-start-delay';
    '--run-number';
    '--verbose';
    '--zero-delay'; #yes/no(def)
    '--comment'; #TEST_DESCRIPTION
    'BETWEEN_RUNS';
    'AFTER_INITIAL_RUN';
    'AFTER_SERVER_START';
    'BETWEEN_CREATE_DB_TEST';
    'NUM_CREATE_DB_ATTEMPTS';
    'AFTER_SERVER_STOP';
    '--log-file';
    'RUN_AS_HARNESS'
)


function Parse_Ini_File ([string]$IniFile)
{
	<#
	.SYNOPSIS
    Parse ini file out into hash(-of-hashes) table. Comments discarded.
	#>

    if (Test-Path $IniFile)
    {
        $ini = @{}  
        switch -regex -file $IniFile  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Windows style comment  
            {  
                #break
            }   
            "^(#.*)$" # *nix style comment  
            {  
                #break
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                #Not necessary after adding BREAK above
                if ($name -notmatch "^[#;].") #parse out comments
                {
                    $ini[$section][$name] = $value  
                }
            }  
        }  
        Return $ini  

    } else {
        #No file provided
        return $null
    }
}

function GetSet_Cluster_ini
{
	<#
	.SYNOPSIS

	Method to create minimal config.ini file for Cluster nodes in Cluster_Root\ndb_data directory.
    If user has provided config.ini in test directory, the contents of files are merged.
	#>

    #Make initial configuration here (script knows ports, dirs and such).
    #It will grow as capabilities of script grow.
    $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster
    $NewIniFile = $p + '\ndb_data\config.ini' 
    Set-Content -Value '#' -Path $NewIniFile #So I do not have to monitor for Set vs Add-Content
    #What we want to write to config.ini by default:
    $inilist = New-Object Collections.Generic.List[string]
    $inilist.Add("[ndb_mgmd default]")
    $inilist.Add("[mysqld default]")
    
    $inilist.Add("[ndb_mgmd]")
    $inilist.Add("hostname=localhost")
    #$dd = 'datadir=' + "$p" + '\data'
    $dd = 'datadir=' + "$p" + '\ndb_data'
    $inilist.Add($dd)
    $inilist.Add('NodeId=1')

    $inilist.Add('[ndbd default]')
    $dd = 'noofreplicas=1' # + $SCRIPT:CLnodes
    $inilist.Add($dd)
    $dd = 'datadir=' + "$p" + '\ndb_data'
    $inilist.Add($dd)    
    for ($i = 0; $i -lt $SCRIPT:CLnodes; $i++) { 
        $inilist.Add('[ndbd]')
        $inilist.Add('hostname=localhost')
        $dd = ($i + 3)
        $dd = 'NodeId=' + $dd
        $inilist.Add($dd)
    }
        
    $inilist.Add('[mysqld]')
    $inilist.Add('NodeId=50')
    $LNodeP = $null
    #Check port for Cluster node(s)
    for ($i = 1186; $i -lt 1886; $i++) {
        if (IsLocalPortListening($i) = "Not listening") {
            $LNodeP = $i
            break
        }
    }

    $preconfini = $null
    $dd = $SCRIPT:TarballDir + '\config.ini' # are we provided with config.ini?
    if (Test-Path $dd) {
        #Add preconfigured
        $preconfini = Parse_Ini_File $dd
    }
    
    if ($preconfini)
    {
        #Merge settings from provided ini file
        foreach ($key in $preconfini.Keys) #SECTIONS, ie. top-level HASH table
        {
            #Not in known sections
            if ( @('ndb_mgmd','ndb_mgmd default','ndbd','ndbd default','mysqld','mysqld default') -notcontains  $key) 
            {
                if ($preconfini[$key].Count -gt 0)
                {
                    #Add *non-empty* section
                    $i = '[' + $key + ']'
                    $inilist.Add($i)
                    
                    $hash = $preconfini.Item($key) #Assign Next-level hash table
                    foreach ($k in $hash.Keys)
                    {
                        $i = ($k, $hash[$k]) -join '='
                        $inilist.Add($i)
                    }
                    $hash = $null
                }
            } else {
                #In the sections where script puts values.
                if ($preconfini[$key].Count -gt 0)
                {
                    $hash = $preconfini.Item($key) #Assign Next-level hash table
                    foreach ($k in $hash.Keys)
                    {
                        if (@('ndb_mgmd','ndb_mgmd default') -contains  $key)
                        {
                            if (@('hostname', 'datadir', 'NodeId') -notcontains  $k)
                            {
                                $i = ($k, $hash[$k]) -join '='

                                $s = '['+$key+']' #Index of section
                                $inilist.Insert($inilist.IndexOf($s)+1, $i)
                            } #Otherwise ignore
                        } else {
                            if (@('ndbd','ndbd default') -contains  $key)
                            {
                                if (@('noofreplicas', 'datadir', 'hostname', 'NodeId') -notcontains  $k)
                                {
                                    $i = ($k, $hash[$k]) -join '='
                                    $s = '['+$key+']' #Index of section
                                    $inilist.Insert($inilist.IndexOf($s)+1, $i)
                                }
                            } else {
                                if (@('mysqld','mysqld default') -contains  $key)
                                {
                                    if ($k -ne 'NodeId')
                                    {
                                        $i = ($k, $hash[$k]) -join '='
                                        $s = '['+$key+']' #Index of section
                                        $inilist.Insert($inilist.IndexOf($s)+1, $i)
                                    }
                                }

                            }
                        }
                    }
                }
            }
        }

    }
    #Write the file, return Port.
    foreach ($line in $inilist) {
        Add-Content $NewIniFile $line 
    }
    return $LNodeP
}

function Parse_SysbenchNew ([string] $TestDesc, [string] $LogF, [int]$runNo, [bool]$sampleRun)
{
	<#
	.SYNOPSIS

	Method to parse Sysbench OLTP test results. CSV file is then saved
    in TARBALLDIR directory and opened at the end (results.csv).
    To replace Parse_SysbenchOLTPResults completely as it has more options.
    To mimic Parse_SysbenchOLTPResults, add -1 $false to Parse_SysbenchNew.
	#>

    $noOfPasses = 0
    $doingFlag = $false
    $thrFlag = $false
    $alertFlag = $false
    $fatalFlag = $false
    $doneFlag = $false
    $sampleMatched = $false
    $sbFlag = $false
    $cnt = 0
    $cmdLn = ''
    if (Test-Path $LogF) {
        $lines = Get-Content $LogF
    } else {
        $host.UI.WriteErrorLine("`t Sysbench output file not found!")
        return
    }
    $StatsVar = ''
    $x = 0
    if (!$sampleRun) {
        $Null = popd
        $Null = Set-Location -Path $SCRIPT:TarballDir #TARBALLDIR

        $ToOutput = New-Object Collections.Generic.List[string]
        Set-Content -Value 'sep=,' -Path 'results.csv' #In case Excel is used to open, set the separator.
        Add-Content 'results.csv' "Test results for: " # $TestDesc"
        Add-Content 'results.csv' ""
    }
 
    do #HEADER start
    {
        if ($x -lt $lines.Count) {
            $line = $lines[$x]
        } else { break }

        $doingFlag = ($line -match "^Doing.*")
        
        if (!$sampleRun) {
            #Output general stuff to file
            if ($line -notmatch "sysbench") {
                if ($line -match "^--.*") {
                    $cmdLn = ($cmdLn,$line) -join ' ' 
                } else { 
                    if (!$doingFlag) { 
                        if ($line -notmatch "Running the test with following") {
                            Add-Content 'results.csv' $line }
                    }
                }
            }
        }
        
        if ($doingFlag) { break }

	    if ($line -match "sysbench") {
    	    	$cnt += 1
	    }
	    if ($line -match "Usage:")
	    {
            	#Failed run due to wrong params!
            	if ($cnt -ge 2) {
                	#Nothing to do
                    $Null = pushd
                	return $null
            	}
	    }
        $x+=1
    } while ($x -lt $lines.Count)
    #END Header, reached Doing test.
    if (!$sampleRun -and $cmdLn) {
        #Otherwise Excel treats --key=value as formula :-/ 
        Add-Content 'results.csv' 'Running the test with following options:'
        Add-Content 'results.csv' $cmdLn
    }

    $x+=1
    do
    {
        #For subsequent runs which will bypass HEADER!
        $doingFlag = ($line -match "^Doing.*")

        if (!$sampleRun) {
            #Output general stuff to file
            Add-Content 'results.csv' $line
        }

        if ($doingFlag) { break }

        if ($x -lt $lines.Count) {
            $line = $lines[$x]
        } else { break }

        $thrFlag = ($line -match "^Threads st.*")

        if (!$sampleRun) {
            #Output general stuff to file
            Add-Content 'results.csv' $line
        }

        if ($thrFlag) { break }
        $x+=1
    }
    while ($true)
    #END Threads started.

    do
    {
        $OLTPFound = $false
        $OLTPAdded = $false
        $noOfPasses += 1
        $x+=1
        #We have Doing... AND Threads started.
        #loop until DONE
        do {
            $x+=1
            if ($x -lt $lines.Count) {
                $line = $lines[$x]
            } else { break }
            $doneFlag = ($line -match "^Done.")
            if ($doneFlag) { break }

            $alertFlag = ($line -match "^ALERT:.*")
            if ($alertFlag) {
                if (!$sampleRun) {Add-Content 'results.csv' "$line"}
                else {Write-Warning $line}
                $x+=1
                if ($x -lt $lines.Count) {
                    $line = $lines[$x]
                } else { break }
                $fatalFlag = ($line -match "^FATAL:.*")
                if ($fatalFlag) { 
                    if (!$sampleRun) {Add-Content 'results.csv' "$line"}
                    else {Write-Warning $line}
                    break
                }
            }

            $sampleMatched = ($line -match "^\[.*")
            if ($sampleMatched) {
                if ($sampleRun -and ($runNo -eq $noOfPasses)) { 
                    #Match $runNo with separate counter for number of samples encountered.
                    $ln1 = $line.Split(',')

                    $ln3 = $line.Split(',')
                    $ln3 = $ln3[3]
                    $ln3 = $ln3.split(':')
                    $ln3 = $ln3[2]
                    $ln3 = $ln3.Split(' ')
                    $ln3 = $ln3[1]
                    while ($ln3.Length -lt 10) {$ln3 = ' ' + $ln3}
                    $ln3 = 'response:'+$ln3

                    $ln2 = $ln1[1].TrimStart('tps: ')
                    [int]$i = [convert]::ToInt32($ln2.Remove($ln2.IndexOf('.')), 10)
                    $i = [convert]::ToInt32([int][Math]::Round(($i / $Host.UI.RawUI.BufferSize.Width)), 10)
                    $ln1 = ''
                    While ($i -gt 0) {
                        $ln1 += 'o'
                        $i -= 1
                    }
                    while ($ln2.Length -le 8) {$ln2 = ' ' + $ln2}
                    $ln2 = 'tps:'+$ln2

                    $i = 4 + $ln1.Length + $ln2.Length + $ln3.Length
                    while ($i -lt $Host.UI.RawUI.BufferSize.Width)
                    {
                        $i += 1
                        $ln1 += ' '
                    }
                    Write-Host $ln2 $ln1 $ln3
                }
            } #Skip samples for full file processing.
        } while ($x -lt $lines.Count)

        #We came to DONE and drew chart of samples if any. Reset.
        $doingFlag = $false
        $thrFlag = $false
        if (!$fatalFlag) {
            do {
                $x+=1
                if ($x -lt $lines.Count) {
                    $line = $lines[$x]
                } else { break }
                if ($line -match "test statistics:") { break }

            } while ($x -lt $lines.Count)

        }

        #Did we break or there are stuff to process
        if ($line -match "test statistics:") {
            if (!$sampleRun) {
                if (!$StatsVar) { $StatsVar = $line}
                #Output detailed results to file
                #Take old code and store data
                do {
                    $x+=1
                    if ($x -lt $lines.Count) {
                        $line = $lines[$x]
                    } else { break }
                    if ($line -match "^sysbench") { break }

                    #Process stuff
                    if ($line) 
                    {   #It's not empty
                        $si = $line.Split(':')
                        if ($si)
                        {
                            #Two choices; Either it's a Key ($si[1] is empty) or it's a K/V ($si[1])
                            # If it's K/V, I need to know if I encountered variable already (to add to value).
                            #Test if variable exists and add dynvar
                            if (!($si[1]))
                            {
                                #Key only. Test if already in
                                if ($ToOutput.IndexOf($si[0]) -lt 0)
                                {
                                    $ToOutput.Add($si[0])
                                }
                             } else {
                                #Make dyn var to hold K/V pair, add dyn var name to list
                                #later, we do IndexOf, RemoveAt, Insert
                                if ($ToOutput.IndexOf($si[0].Trim()) -lt 0)
                                {
                                    #Not in so create variable
                                    $d = $si[0] + ':' + $si[1]
                                    New-Variable -Name $si[0].Trim() -Value $d
                                    $ToOutput.Add($si[0].Trim())
                                } else {
                                    #We had this already
                                    $d = 'variable:\' + $si[0].Trim()
                                    if (Test-Path $d)
                                    {
                                        Set-Variable -Name $($si[0].Trim()) -Value ((Get-Variable $($si[0].Trim()) -ValueOnly) + ', ' + $si[1])
                                        $d = (Get-Variable $($si[0].Trim()) -ValueOnly)
                                    } else {
                                        Write-Warning 'Prasing SB results went horribly horribly wrong :-/'
                                    }
                                }                       
                            }
                        }
                    }
                } while ($x -lt $lines.Count)
            } else {
                #--Write just AVG TPS to host too.
                if ($sampleRun -and ($runNo -eq $noOfPasses)) {
                    do {
                        $x+=1
                        if ($x -lt $lines.Count) {
                            $line = $lines[$x]
                        } else { break }
                        if ($line -match "^sysbench") { break }
                        if ($line -match "transactions:") {
                            Write-Host $line.Trim()
                            break
                        }
                    } while ($x -lt $lines.Count)
                }
            }
        } #if ($line -match "test statistics:")

        $fatalFlag = $false
        $alertFlag = $false
        #Repeat
    }
    while ($x -lt $lines.Count)

    if (!$sampleRun) {
        #We are done, write to results.csv
        #We have list to output but first need to replace the variables that are
        #placeholders with actual variables

        Add-Content 'results.csv' $StatsVar

        $s = $ToOutput.Count
        $i = -1
        While ($true)
        {
            $i += 1
            $d = 'variable:\' + $ToOutput[$i]
            if (Test-Path $d)
            {
                #We have placeholder!
                #Get-Variable $($i[0].Trim()) -ValueOnly
                #we do RemoveAt, Insert
                $d = Get-Variable $($ToOutput[$i]) -ValueOnly
                Remove-Variable $ToOutput[$i]
                $ToOutput.RemoveAt($i)
                $ToOutput.Insert($i, $d)
            }
            if ($i -eq $s-1) { break }      
        }
        #Finally, write the file:
        #Not for test runs...
        for ($i = 0; $i -lt $ToOutput.Count; $i++) { Add-Content 'results.csv' $ToOutput[$i] }
        $Null = pushd
    }
}

function Parse_Sysbench_Conf ([string] $ConfFile)
{
    $RunMap = @{}
    #Map things, first Linux conf -> Windows conf
    foreach($line in (Get-Content $ConfFile))
    {   
	    $i = $null
	    ## Check if it is variable:
	    if ($line -match "^[a-zA-Z]")
	    {
		    ## So, we parse out K/V pair.
		    $i = $line.Split("=")
            $i[1] = $i[1].Trim('"')
		    if ($i[1]) { #Guard against empty string and quoted values
                #There IS a value to Key but watch for "special" ones...
                switch ($i[0])
                {
                    "SB_OLTP_READ_ONLY" {
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        }
                    }
                    "SB_USE_TRX"  { #--oltp-skip-trx!
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        }
                    }
                    "SB_USE_SECONDARY_INDEX" {
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        }
                    }
                    "SB_USE_MYSQL_HANDLER" {
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        }
                    }
                    "SB_AVOID_DEADLOCKS" {
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        }
                    }
                    "SB_SEED_RNG" {
                        try
                        {
                            [int64]$intNum = 0 #init to "off"
                            [string]$strNum = $i[1]
                            $intNum = [convert]::ToInt32($strNum, 10)
                            #$RunMap.Add($SysbenchMap[$i[0]], $strNum)
                        }
                        catch
                        {
                            Write-Warning `t`t'SB parameter seed-rng defined incorectly. Ignoring'
                            $intNum = 0
                        }
                        if ($intNum -gt 0) {
                            #$RunMap.Add('--init-rng', 'on') ERROR to have BOTH set!
                            $RunMap.Add($SysbenchMap[$i[0]], $strNum)
                        }
                    }
                    "RUN_AS_HARNESS" {
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        }
                    }
                    default { 
                        if ($SysbenchAllowed.Contains($SysbenchMap[$i[0]]))
                        {
                            $RunMap.Add($SysbenchMap[$i[0]], $i[1].Trim('"')) 
                        }
                    }
                }

		    }
	    }
    }

    #Check general parameters of the test for sanity:
    #'NUM_TEST_RUNS';
    if ($RunMap.Contains('NUM_TEST_RUNS')) {
        try {
            $i = [int16]$RunMap['NUM_TEST_RUNS']
            #No more than 100 runs!
            if (($i -gt 100) -or ($i -le 0)) {
                $RunMap.Remove('NUM_TEST_RUNS')
            }
        } catch {
            $RunMap.Remove('NUM_TEST_RUNS')
        }
    }
    #'TEST_DESCRIPTION';
    #'BETWEEN_RUNS';
    if ($RunMap.Contains('BETWEEN_RUNS')) {
        try {
            $i = [int16]$RunMap['BETWEEN_RUNS']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('BETWEEN_RUNS')
            }
        } catch {
            $RunMap.Remove('BETWEEN_RUNS')
        }
    }
    #'AFTER_INITIAL_RUN';
    if ($RunMap.Contains('AFTER_INITIAL_RUN')) {
        try {
            $i = [int16]$RunMap['AFTER_INITIAL_RUN']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('AFTER_INITIAL_RUN')
            }
        } catch {
            $RunMap.Remove('AFTER_INITIAL_RUN')
        }
    }
    #'AFTER_SERVER_START';
    if ($RunMap.Contains('AFTER_SERVER_START')) {
        try {
            $i = [int16]$RunMap['AFTER_SERVER_START']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('AFTER_SERVER_START')
            }
        } catch {
            $RunMap.Remove('AFTER_SERVER_START')
        }
    }
    #'BETWEEN_CREATE_DB_TEST';
    if ($RunMap.Contains('BETWEEN_CREATE_DB_TEST')) {
        try {
            $i = [int16]$RunMap['BETWEEN_CREATE_DB_TEST']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('BETWEEN_CREATE_DB_TEST')
            }
        } catch {
            $RunMap.Remove('BETWEEN_CREATE_DB_TEST')
        }
    }
    #'NUM_CREATE_DB_ATTEMPTS';
    if ($RunMap.Contains('NUM_CREATE_DB_ATTEMPTS')) {
        try {
            $i = [int16]$RunMap['NUM_CREATE_DB_ATTEMPTS']
            #No more than 100 runs!
            if (($i -gt 100) -or ($i -le 0)) {
                $RunMap.Remove('NUM_CREATE_DB_ATTEMPTS')
            }
        } catch {
            $RunMap.Remove('NUM_CREATE_DB_ATTEMPTS')
        }
    }
    #'NUM_CHANGE_MASTER_ATTEMPTS';
    if ($RunMap.Contains('NUM_CHANGE_MASTER_ATTEMPTS')) {
        try {
            $i = [int16]$RunMap['NUM_CHANGE_MASTER_ATTEMPTS']
            #No more than 100 runs!
            if (($i -gt 100) -or ($i -le 0)) {
                $RunMap.Remove('NUM_CHANGE_MASTER_ATTEMPTS')
            }
        } catch {
            $RunMap.Remove('NUM_CHANGE_MASTER_ATTEMPTS')
        }
    }
    #'BETWEEN_CHANGE_MASTER_TEST';
    if ($RunMap.Contains('BETWEEN_CHANGE_MASTER_TEST')) {
        try {
            $i = [int16]$RunMap['BETWEEN_CHANGE_MASTER_TEST']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('BETWEEN_CHANGE_MASTER_TEST')
            }
        } catch {
            $RunMap.Remove('BETWEEN_CHANGE_MASTER_TEST')
        }
    }
    #'AFTER_SERVER_STOP';
    if ($RunMap.Contains('AFTER_SERVER_STOP')) {
        try {
            $i = [int16]$RunMap['AFTER_SERVER_STOP']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('AFTER_SERVER_STOP')
            }
        } catch {
            $RunMap.Remove('AFTER_SERVER_STOP')
        }
    }

    #'LOG_FILE'    
    if ($RunMap.Contains('LOG_FILE'))
    {
        $i = $RunMap['LOG_FILE'].Trim('"')
        if (!(Test-Path (Split-Path $i -Parent))) {
            $RunMap.Remove('LOG_FILE') }
    }
    if ($RunMap.Contains('RUN_AS_HARNESS')) {
        $i = $RunMap['RUN_AS_HARNESS'].Trim('"')
        if ( @('on', 'off','yes','no') -notcontains $i) {
                $RunMap.Remove('RUN_AS_HARNESS')
        }
    }
    #Check Sysbench parameters of the test for sanity:
    #'--mysql-host';
    if ($RunMap.Contains('--mysql-port')) {
        try {
            $i = [int16]$RunMap['--mysql-port']
            if (($i -gt 10000) -or ($i -le 0)) {
                $RunMap.Remove('--mysql-port')
            }
        } catch {
            $RunMap.Remove('--mysql-port')
        }
    }
    if ($RunMap.Contains('--oltp-read-only')) {
        if (($RunMap['--oltp-read-only'] -ne 'on') -and ($RunMap['--oltp-read-only'] -ne 'off')) {
                $RunMap.Remove('--oltp-read-only')
        }
    }
    if ($RunMap.Contains('--oltp-secondary')) {
        if (($RunMap['--oltp-secondary'] -ne 'on') -and ($RunMap['--oltp-secondary'] -ne 'off')) {
                $RunMap.Remove('--oltp-secondary')
        }
    }
    if ($RunMap.Contains('--oltp-point-select-mysql-handler')) {
        if (($RunMap['--oltp-point-select-mysql-handler'] -ne 'on') -and ($RunMap['--oltp-point-select-mysql-handler'] -ne 'off')) {
                $RunMap.Remove('--oltp-point-select-mysql-handler')
        }
    }
    if ($RunMap.Contains('--oltp-point-select-all-cols')) {
        if (!$RunMap.Contains('--oltp-point-select-mysql-handler')) {
            $RunMap.Remove('--oltp-point-select-all-cols')
        }
        if ($RunMap['--oltp-point-select-mysql-handler'] -eq 'off') {
                $RunMap.Remove('--oltp-point-select-all-cols')
        }
    }
    if ($RunMap.Contains('--oltp-num-partitions')) {
        try {
            $i = [int16]$RunMap['--oltp-num-partitions']
            #Max 100 partitions
            if (($i -gt 100) -or ($i -lt 0)) {
                $RunMap.Remove('--oltp-num-partitions')
            }
        } catch {
            $RunMap.Remove('--oltp-num-partitions')
        }
    }
    if ($RunMap.Contains('--oltp-num-tables')) {
        try {
            $i = [int16]$RunMap['--oltp-num-tables']
            #Max 1000 tables
            if (($i -gt 1000) -or ($i -le 0)) {
                $RunMap.Remove('--oltp-num-tables')
            }
        } catch {
            $RunMap.Remove('--oltp-num-tables')
        }
    }
    if ($RunMap.Contains('--num-threads')) {
        try {
            $i = [int32]$RunMap['--num-threads']
            #Max 65535 threads
            if (($i -gt 65535) -or ($i -le 0)) {
                $RunMap.Remove('--num-threads')
            }
        } catch {
            $RunMap.Remove('--num-threads')
        }
    }
    if ($RunMap.Contains('--oltp-test-mode')) {
        if ( @('simple','complex','nontrx','sp') -notcontains  $RunMap['--oltp-test-mode']) {
                $RunMap.Remove('--oltp-test-mode')
        }
    }
    if ($RunMap.Contains('--mysql-table-engine')) {
        if ( @('myisam','innodb','bdb','heap','ndbcluster','federated','ndb') -notcontains  $RunMap['--mysql-table-engine']) {
                $RunMap.Remove('--mysql-table-engine')
        }
    }

    if ($RunMap.Contains('--oltp-avoid-deadlocks')) {
        if ( @('on', 'off') -notcontains $RunMap['--oltp-avoid-deadlocks']) {
                $RunMap.Remove('--oltp-avoid-deadlocks')
        }
    }

    if ($RunMap.Contains('--oltp-skip-trx')) {
        if ( @('on', 'off') -notcontains $RunMap['--oltp-skip-trx']) {
                $RunMap.Remove('--oltp-skip-trx')
        }
    }
    if ($RunMap.Contains('--oltp-dist-type')) {
        if ( @('uniform','gaussian','special') -notcontains  $RunMap['--oltp-dist-type']) {
                $RunMap.Remove('--oltp-dist-type')
        }
    }

    if ($RunMap.Contains('--mysql-engine-trx')) {
        if ( @('yes', 'no', 'auto') -notcontains $RunMap['--mysql-engine-trx']) {
                $RunMap.Remove('--mysql-engine-trx')
        }
    }
    if ($RunMap.Contains('--oltp-point-selects')) {
        try {
            $i = [int16]$RunMap['--oltp-point-selects']
            if ($i -lt 0) {
                $RunMap.Remove('--oltp-point-selects')
            }
        } catch {
            $RunMap.Remove('--oltp-point-selects')
        }
    }
    if ($RunMap.Contains('--oltp-range-size')) {
        try {
            $i = [int16]$RunMap['--oltp-range-size']
            #Max 1000 threads
            if (($i -gt 1000) -or ($i -lt 0)) {
                $RunMap.Remove('--oltp-range-size')
            }
        } catch {
            $RunMap.Remove('--oltp-range-size')
        }
    }
    if ($RunMap.Contains('--oltp-simple-ranges')) {
        try {
            $i = [int16]$RunMap['--oltp-simple-ranges']
            #Max 1000 ranges
            if (($i -gt 1000) -or ($i -le 0)) {
                $RunMap.Remove('--oltp-simple-ranges')
            }
        } catch {
            $RunMap.Remove('--oltp-simple-ranges')
        }
    }
    if ($RunMap.Contains('--oltp-sum-ranges')) {
        try {
            $i = [int16]$RunMap['--oltp-sum-ranges']
            #Max 1000 ranges
            if (($i -gt 1000) -or ($i -le 0)) {
                $RunMap.Remove('--oltp-sum-ranges')
            }
        } catch {
            $RunMap.Remove('--oltp-sum-ranges')
        }
    }
    if ($RunMap.Contains('--oltp-order-ranges')) {
        try {
            $i = [int16]$RunMap['--oltp-order-ranges']
            #Max 1000 ranges
            if (($i -gt 1000) -or ($i -le 0)) {
                $RunMap.Remove('--oltp-order-ranges')
            }
        } catch {
            $RunMap.Remove('--oltp-order-ranges')
        }
    }
    if ($RunMap.Contains('--oltp-distinct-ranges')) {
        try {
            $i = [int16]$RunMap['--oltp-distinct-ranges']
            #Max 1000 ranges
            if (($i -gt 1000) -or ($i -le 0)) {
                $RunMap.Remove('--oltp-distinct-ranges')
            }
        } catch {
            $RunMap.Remove('--oltp-distinct-ranges')
        }
    }
    if ($RunMap.Contains('--oltp-use-in-statement')) {
        try {
            $i = [int16]$RunMap['--oltp-use-in-statement']
            #Max 1000 ranges
            if (($i -gt 1000) -or ($i -lt 0)) {
                $RunMap.Remove('--oltp-use-in-statement')
            }
        } catch {
            $RunMap.Remove('--oltp-use-in-statement')
        }
    }
    if ($RunMap.Contains('--oltp-auto-inc')) {
        if ( @('on', 'off') -notcontains $RunMap['--oltp-auto-inc']) {
                $RunMap.Remove('--oltp-auto-inc')
        }
    }
    if ($RunMap.Contains('--max-time')) {
        try {
            $i = [int16]$RunMap['--max-time']
            if ($i -le 0) {
                $RunMap.Remove('--max-time')
            }
        } catch {
            $RunMap.Remove('--max-time')
        }
    }
    if ($RunMap.Contains('--tx-rate')) {
        try {
            $i = [int16]$RunMap['--tx-rate']
            if ($i -lt 0) {
                $RunMap.Remove('--tx-rate')
            }
        } catch {
            $RunMap.Remove('--tx-rate')
        }
    }
    if ($RunMap.Contains('--tx-jitter')) {
        try {
            $i = [int16]$RunMap['--tx-jitter']
            if ($i -lt 0) {
                $RunMap.Remove('--tx-jitter')
            }
        } catch {
            $RunMap.Remove('--tx-jitter')
        }
    }
    if ($RunMap.Contains('--myisam-max-rows')) {
        try {
            $i = [int32]$RunMap['--myisam-max-rows']
            if ($i -le 0) {
                $RunMap.Remove('--myisam-max-rows')
            }
        } catch {
            $RunMap.Remove('--myisam-max-rows')
        }
    }
    if ($RunMap.Contains('--oltp-table-size')) {
        try {
            $i = [int32]$RunMap['--oltp-table-size']
            if ($i -le 0) {
                $RunMap.Remove('--oltp-table-size')
            }
        } catch {
            $RunMap.Remove('--oltp-table-size')
        }
    }
    if ($RunMap.Contains('--oltp-dist-pct')) {
        try {
            if (!$RunMap.Contains('--oltp-dist-type')) {
                $RunMap.Remove('--oltp-dist-pct')
            } else {
                if ($RunMap['--oltp-dist-type'] -ne 'special') {
                    $RunMap.Remove('--oltp-dist-pct')
                }
            }
        } catch {
            $RunMap.Remove('--oltp-dist-pct')
        }
    }
    if ($RunMap.Contains('--oltp-dist-res')) {
        try {
            if (!$RunMap.Contains('--oltp-dist-type')) {
                $RunMap.Remove('--oltp-dist-res')
            } else {
                if ($RunMap['--oltp-dist-type'] -ne 'special') {
                    $RunMap.Remove('--oltp-dist-res')
                }
            }
        } catch {
            $RunMap.Remove('--oltp-dist-res')
        }
    }

    if (!$RunMap.Contains('NUM_TEST_RUNS')) {
        $RunMap.Add('NUM_TEST_RUNS', 1)
    }
    if (!$RunMap.Contains('NUM_CREATE_DB_ATTEMPTS')) {
        $RunMap.Add('NUM_CREATE_DB_ATTEMPTS', 3)
    }
    
    #--MACROS--
    #Hash map Remove does NOT throw error if there is no Key in the map!
    #Only 1 enabled macro per run!
    if ($RunMap.Contains('RUN_RW') -and ($RunMap['RUN_RW'] -eq 'yes')) {
      Write-Host -background DarkBlue -foreground Green `t`t"Test to run is Sysbench OLTP RW"
      $TEST="oltp_complex_rw"
    } else {
	    if ($RunMap.Contains('RUN_RW_WRITE_INT') -and ($RunMap['RUN_RW_WRITE_INT'] -eq 'yes')) {
          Write-Host -background DarkBlue -foreground Green `t`t"Test to run is Sysbench OLTP RW Write Intensive"
          $TEST="oltp_complex_rw_write_intensive"
        } else {
	        if ($RunMap.Contains('RUN_RO') -and ($RunMap['RUN_RO'] -eq 'yes')) {
              Write-Host -background DarkBlue -foreground Green `t`t"Test to run is Sysbench OLTP RO"
              $TEST="oltp_complex_ro"
            } else {
	            if ($RunMap.Contains('RUN_RO_PS') -and ($RunMap['RUN_RO_PS'] -eq 'yes')) {
                  Write-Host -background DarkBlue -foreground Green `t`t"Test to run is Sysbench OLTP RO Point Select"
                  $TEST="oltp_complex_ro_ps"
                } else {
	                if ($RunMap.Contains('RUN_RW_LESS_READ') -and ($RunMap['RUN_RW_LESS_READ'] -eq 'yes')) {
                      Write-Host -background DarkBlue -foreground Green `t`t"Test to run is Sysbench OLTP RW Less Read"
                      $TEST="oltp_complex_rw_less_read"
                    } else {
	                    if ($RunMap.Contains('RUN_WRITE') -and ($RunMap['RUN_WRITE'] -eq 'yes')) {
                          Write-Host -background DarkBlue -foreground Green `t`t"Test to run is Sysbench OLTP Write"
                          $TEST="oltp_complex_write"
                        }
                    }
                }
            }
        }
    }

    $RunMap.Remove('--oltp-test-mode')
    $RunMap.Add('--oltp-test-mode','complex')
    
    switch ($TEST)
    {
        "oltp_complex_rw" {
            $RunMap.Remove('--oltp-read-only')
            $RunMap.Add('--oltp-read-only','off')
        }
        "oltp_complex_rw_write_intensive" {

            $RunMap.Remove('--oltp-read-only')
            $RunMap.Add('--oltp-read-only','off')
            $RunMap.Remove('--oltp-index-updates')
            $RunMap.Add('--oltp-index-updates', '10')
        }
        "oltp_complex_ro_ps" {
            $RunMap.Remove('--oltp-read-only')
            $RunMap.Add('--oltp-read-only', 'on')
            $RunMap.Remove('--oltp-skip-trx')
            $RunMap.Add('--oltp-skip-trx', 'on')
            $RunMap.Remove('--oltp-point-selects')
            $RunMap.Add('--oltp-point-selects', '1')
            $RunMap.Remove('--oltp-simple-ranges')
            $RunMap.Add('--oltp-simple-ranges', '0')
            $RunMap.Remove('--oltp-sum-ranges')
            $RunMap.Add('--oltp-sum-ranges', '0')
            $RunMap.Remove('--oltp-order-ranges')
            $RunMap.Add('--oltp-order-ranges', '0')
            $RunMap.Remove('--oltp-distinct-ranges')
            $RunMap.Add('--oltp-distinct-ranges', '0')
        }
        "oltp_complex_ro" {
            $RunMap.Remove('--oltp-read-only')
            $RunMap.Add('--oltp-read-only', 'on')
        }
        "oltp_complex_rw_less_read" {
            $RunMap.Remove('--oltp-read-only')
            $RunMap.Add('--oltp-read-only','off')
            $RunMap.Remove('--oltp-point-selects')
            $RunMap.Add('--oltp-point-selects', '1')
            $RunMap.Remove('--oltp-range-size')
            $RunMap.Add('--oltp-range-size', '5')
                    
        }
        "oltp_complex_write" {
            $RunMap.Remove('--oltp-read-only')
            $RunMap.Add('--oltp-read-only', 'off')
            $RunMap.Remove('--oltp-point-selects')
            $RunMap.Add('--oltp-point-selects', '0')
            $RunMap.Remove('--oltp-simple-ranges')
            $RunMap.Add('--oltp-simple-ranges', '0')
            $RunMap.Remove('--oltp-sum-ranges')
            $RunMap.Add('--oltp-sum-ranges', '0')
            $RunMap.Remove('--oltp-order-ranges')
            $RunMap.Add('--oltp-order-ranges', '0')
            $RunMap.Remove('--oltp-distinct-ranges')
            $RunMap.Add('--oltp-distinct-ranges', '0')
        }
    }

    return $RunMap
}

function SBRecreate_TestDB {
	<#
	.SYNOPSIS

	Function to (re)create empty test database using MySQL c/NET.
	#>

    #1) MAKE SURE database for testing exists...
    $ConnectionString = "Server=localhost;Uid=" + $userToRun.Split('=')[1] +"; Port="+$Port
    $connection = New-Object MySql.Data.MySqlClient.MySqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = New-Object MySql.Data.MySqlClient.MySqlCommand
    $command.Connection = $connection
    $z = $DBToRun.Split('=')[1]
    $query = 'DROP DATABASE IF EXISTS ' + $z + ';'
    $command.CommandText = $query
    $cnt = $command.ExecuteNonQuery()

    $query = 'CREATE DATABASE ' + $z + ';'
    $command.CommandText = $query
    $cnt = $command.ExecuteNonQuery()
 
    $command.Dispose()
    $connection.Close()
    $connection.Dispose()
    $ConnectionString = $Null
    $z = $Null
    $query = $Null
    Write-Host `t'END setting up empty test database.'
}

function Do_SBLoad {
	<#
	.SYNOPSIS

	Function to load data prepared with mysqldump into test database
    using MySQL command line tool mysql.exe.
	#>

    #Prepared database provided.
    Write-Host `t'Loading provided data.'
    if ($SCRIPT:MySQLServer) { $dd = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer + '\bin\mysql.exe'}
    else {$dd = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster + '\bin\mysql.exe'}
    if (Test-Path $dd) {
        $StopWatch2 = [System.Diagnostics.Stopwatch]::StartNew()
        $cl = $dd + ' -u' + $userToRun.Split('=')[1] + ' -P' + $Port + ' ' + $DBToRun.Split('=')[1] +
          ' < ' + $SCRIPT:TarballDir + '\' + $SCRIPT:SBPREPEDDATA

        #$cl = "& " + '"'+$cl+'"'
        Write-Host `t$cl
        $cl = '"'+$cl+'"'
        &cmd /c $cl
        #invoke-expression $cl | out-null
        $StopWatch2.Stop()
        $CurrentTime = $StopWatch2.Elapsed
        Write-Host `t'Loading SB dump took ' $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
                $CurrentTime.hours, 
                $CurrentTime.minutes, 
                $CurrentTime.seconds))
        $StopWatch2 = $null
        $CurrentTime = $null
        return ($LASTEXITCODE -eq 0)
    } else {
        Write-Warning `t'mysql CL client NOT found!'
        #Go back and re-run real prepare.
        return $false #so that prepare code is run.
    }
}

function Do_SBPrepare {
	<#
	.SYNOPSIS

	Function to run sysbench.exe with prepare switch.
	#>

    #Prep Sysbench run
    $StopWatch2 = [System.Diagnostics.Stopwatch]::StartNew()
    #Compose and execute SB.Prepare
    $l = 0
    $Null = $ToRun.AddArgument('prepare')
    Write-Host `t"Executing" $ToRun.Commands.Commands.CommandText -foregroundcolor DarkGreen -backgroundcolor white
    Write-Output `t"with params" $ToRun.Commands.Commands.Parameters.value
    Write-Host ''
    do {
        if ($SCRIPT:logfile) { $ToRun.Invoke() | Out-File 'Out.txt' }
        else { $ToRun.Invoke() | Out-Null }
        $l += 1
    } while (!($?) -and ($l -lt [int16]$RMap['NUM_CREATE_DB_ATTEMPTS']))

    if (($?) -and ($l -lt [int16]$RMap['NUM_CREATE_DB_ATTEMPTS'])) {
        Write-Host `t'PREPARE DONE'
    } else {Write-Host `t'PREPARE FAILED'}
        
    $StopWatch2.Stop()
    $CurrentTime = $StopWatch2.Elapsed
    Write-Host `t'Running SB prepare took ' $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
            $CurrentTime.hours, 
            $CurrentTime.minutes, 
            $CurrentTime.seconds))
    $StopWatch2 = $null
    $CurrentTime = $null

    Start-Sleep -Seconds 2
    $ToRun.Stop()
    $ToRun.Dispose()
    $ToRun = $null
}

function Do_SBPrepDump {
	<#
	.SYNOPSIS

	Function to dump data prepared by sysbench using mysqldump tool.
	#>

    #Dump prepared database.
    Write-Host `t'Dumping prepared data.'
    if ($SCRIPT:MySQLServer) { $dd = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer + '\bin\mysqldump.exe'}
    else {$dd = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster + '\bin\mysqldump.exe'}
    if (Test-Path $dd) {
        $cl = $dd + ' -u' + $userToRun.Split('=')[1] + ' -P' + $Port + ' ' + $DBToRun.Split('=')[1]
        invoke-expression $cl | Out-File ($SCRIPT:TarballDir + '\' + $SCRIPT:SBPREPEDDATA) -Encoding UTF8
        return $? #prepared data dumped.
    } else {
        Write-Warning `t'mysqldump CL client NOT found!'
        return $false
    }
}

function SB_WarmUpBP {
	<#
	.SYNOPSIS

	Function to warm-up server before actual sysbench run using MySQL
    c/NET.
	#>

    Write-Host `t'Warming up the buffer pool.'
    #Warm up the innodb buffer pool:
    $z = $DBToRun.TrimStart('--mysql-db=')
    #Allow User Variables=true;
    $ConnectionString = "Server=localhost;Uid=root; Port="+$Port+"; Database="+$z+";"
    $connection = New-Object MySql.Data.MySqlClient.MySqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()

    $connection1 = New-Object MySql.Data.MySqlClient.MySqlConnection
    $connection1.ConnectionString = $ConnectionString
    $connection1.Open()

    $query = 'SHOW TABLES;'
    $command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $connection)

    $reader = $command.ExecuteReader()

    $command1 = New-Object MySql.Data.MySqlClient.MySqlCommand
    $command1.Connection = $connection1
    while ($reader.Read())
    {
        $query = 'select avg(id) from ' + $reader.GetString(0) + ' force key (primary) '
        $command1.CommandText = $query
        $z = $command1.ExecuteScalar()
        if ($reader.GetString(0).Length -ge 8) { Write-Host `t`t$query `t$z }
        else { Write-Host `t`t$query ' '`t$z }

        $query = 'select count(*) from ' + $reader.GetString(0) + ' WHERE  k like "%0%"'
        $command1.CommandText = $query
        $z = $command1.ExecuteScalar()
        if ($reader.GetString(0).Length -ge 8) {Write-Host `t`t$query `t$z }
        else {Write-Host `t`t$query ' '`t$z }
    }
    Start-Sleep -Seconds 1

    $reader.Close();
    $reader.Dispose();
    $reader = $null

    $command.Dispose()
    $connection1.Close()
    $connection1.Dispose()
    $connection.Close()
    $connection.Dispose()
    $ConnectionString = $Null
    $z = $Null
    $query = $Null

}

function SetUp_and_Run_SysbenchTest ([int16] $Port, [string] $PathToSB)
{
	<#
	.SYNOPSIS

	Method to form Sysbench parameters for Cluster/Server and
    run the test. Should be split if possible.
    Checks if TARBALLDIR has file named sysbench.conf. If it does,
    tries to read run-parameters from it. File can have either
    Windows or Unix line endings/comments and it can contain
    both Mikael's parameters and parameters Sysbench understands.
    Translation is governed by $SysbenchMap hashtable.
	#>
    Write-Host `t'ENTER SB PREPARE'
    $t = $SCRIPT:TarballDir + '\sysbench.conf'
    if (Test-Path $t) {
        #Do tyhe prep work.
        Write-Host `t'Provided:' $t
        $RMap = Parse_Sysbench_Conf $t
        #Check important parameters:
        if (!$RMap.Contains('--test')) {
            $testToRun = '--test=oltp'
        } else {
            #Has to be first option
            $testToRun = '--test=' + $RMap['--test']
            $RMap.Remove('--test')
        }
        if (!$RMap.Contains('--mysql-user')) {
            $userToRun = '--mysql-user=root'
        } else {
            $userToRun = '--mysql-user=' + $RMap['--mysql-user']
            $RMap.Remove('--mysql-user')
        }
        if (!$RMap.Contains('--mysql-db')) {
            $DBToRun = '--mysql-db=test'
        } else {
            $DBToRun = '--mysql-db=' + $RMap['--mysql-db']
            $RMap.Remove('--mysql-db')
        }

        # Hash -> List so I can add arguments faster.
        $d = '--mysql-port=' + "$Port"
        $list = New-Object Collections.Generic.List[string]
        $list.Add($testToRun)
        $list.Add($userToRun)
        $list.Add($DBToRun)
        $list.Add($d)
        foreach ($key in $RMap.Keys) { 
            if ($key -match "^--") { 
                $s = $key + '=' + $RMap[$key]
                $list.Add($s)
            }
        } 
        Write-Host `t'END parsing provided Sysbench configuration.'
        
        $IsInnoDB = $false
        #Run preconfigured test phase
        $ToRun = [PowerShell]::Create().AddCommand("$PathToSB" + '\sysbench.exe')
        for ($i = 0; $i -lt $list.Count; $i++) { 
            $Null = $ToRun.AddArgument($list[$i])
            if ($list[$i] -contains '--mysql-table-engine=innodb') { $IsInnoDB = $true }
        }

        if ($RMap.Contains('LOG_FILE')) {
            $SCRIPT:logfile = $RMap['LOG_FILE']
            if ($RMap.Contains('TEST_DESCRIPTION')) {
                Set-Content -Value $RMap['TEST_DESCRIPTION'] -Path $SCRIPT:logfile
                Add-Content $SCRIPT:logfile $list
            } else { Set-Content -Value $list -Path $SCRIPT:logfile }
        } else { $SCRIPT:logfile = $null }

        #Recreate test database.
        SBRecreate_TestDB
        Write-Host ''
        #Check if SB prepared is provided to the script.
        $dd = $SCRIPT:TarballDir + '\' + $SCRIPT:SBPREPEDDATA
        if (Test-Path $dd) {
            if (!(Do_SBLoad)) {
                Do_SBPrepare
                #Dump prepared database.
                if ($SCRIPT:SBDUMPPREPED -contains 'yes') {
                    #$SCRIPT:SBPREPEDDATA
                    if (Do_SBPrepDump) {
                        Write-Host `t'SB prepared data dumped to file.'
                    } else {
                        Write-Host `t'SB prepared data NOT dumped to file.'
                    }
                }
            }
        } else { 
            Do_SBPrepare 
            #Dump prepared database.
            if ($SCRIPT:SBDUMPPREPED -contains 'yes') {
                #$SCRIPT:SBPREPEDDATA
                if (Do_SBPrepDump) {
                    Write-Host `t'SB prepared data dumped to file.'
                } else {
                    Write-Host `t'SB prepared data NOT dumped to file.'
                }
            }
        }
        Write-Host ''

        $StopWatch2 = [System.Diagnostics.Stopwatch]::StartNew()
        SB_WarmUpBP
        $StopWatch2.Stop()
        $CurrentTime = $StopWatch2.Elapsed
        Write-Host `t'END Warming up buffer pool in ' $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
                $CurrentTime.hours, 
                $CurrentTime.minutes, 
                $CurrentTime.seconds))
        $StopWatch2 = $null
        $CurrentTime = $null

        Write-Host ""
        Start-Sleep -Seconds 10

        #Run Sysbench tests
        if ((($RMap.Contains('RUN_AS_HARNESS')) -and ($RMap['RUN_AS_HARNESS'] -ne 'on')) -or
            (!$RMap.Contains('RUN_AS_HARNESS')))
        {
            $ntr = [int16]$RMap['NUM_TEST_RUNS']
            $ToRun = [PowerShell]::Create().AddCommand("$PathToSB" + '\sysbench.exe')
            for ($k = 0; $k -lt $list.Count; $k++) { $Null = $ToRun.AddArgument($list[$k]) }
            $Null = $ToRun.AddArgument('run')
            Write-Host `t"Executing" $ToRun.Commands.Commands.CommandText -foregroundcolor DarkGreen -backgroundcolor white
            Write-Output `t"with params" $ToRun.Commands.Commands.Parameters.value
            Write-Host ''
            for ($i = 0; $i -lt $ntr; $i++) {
                Write-Host `t'Running OLTP test' ($i + 1) '/' $ntr             

                if ($SCRIPT:logfile) { $ToRun.Invoke() | Out-File 'Out.txt' -Append }
                else { $ToRun.Invoke() }

                if ($?) { Write-Host `t'Sysbench run finished.' }
                else { Write-Warning `t'Sysbench run failed.' }
                $p = $i + 1
                
                if ($SCRIPT:logfile) {Parse_SysbenchNew '' "Out.txt" $p $true}

                #Get InnoDB stats after the run:
                if ($IsInnoDB -and $SCRIPT:SHOW_INNODB_STATUS) {
                    $connection = New-Object MySql.Data.MySqlClient.MySqlConnection
                    $ConnectionString = "Server=localhost;Uid=root; Port="+$Port+"; Database=mysql;"
                    $connection.ConnectionString = $ConnectionString
                    $connection.Open()
                    $query = 'SHOW ENGINE INNODB STATUS;'
                    $command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $connection)
                    $reader = $command.ExecuteReader();
                    Write-Host `t`t'Fetching InnoDB stats:'
                    while ($reader.Read())
                    {
                        $reader.GetString(2)
                    }
                    $reader.Close();
                    $reader.Dispose();
                    $reader = $null
                    #Remove later. 1.1 means reporting 10% more in size.
                    $query = 'SELECT CEILING(Total_InnoDB_Bytes*1.1/POWER(1024,3)) RIBPS
                    FROM (SELECT SUM(data_length+index_length) Total_InnoDB_Bytes
                    FROM information_schema.tables WHERE engine="InnoDB") A;'
                    $command.CommandText = $query
                    $z = $command.ExecuteScalar()
                    Write-Host `t`t'Database size' `t$z'GB'
                    $command.Dispose()
                    $connection.Close()
                    $connection.Dispose()
                    $ConnectionString = $Null
                    $z = $Null
                    $query = $Null
                }
 
                if (($i -eq 0) -and ($RMap.Contains('AFTER_INITIAL_RUN')) -and ($ntr -gt 1)) {
                    $l = [int16]$RMap['AFTER_INITIAL_RUN']
                    Write-Host `t'Sleeping '$l' seconds after initial run.'
                    Start-Sleep -Seconds $l

                } else {
                    if ($RMap.Contains('BETWEEN_RUNS')) {
                        $l = [int16]$RMap['BETWEEN_RUNS']
                        if ($i -lt ($ntr-1)) {
                            #NOT last run
                            Write-Host `t'Sleeping '$l' seconds between runs.'
                            Start-Sleep -Seconds $l
                        }
                    }
                }
            }
            $ToRun.Dispose()
            $ToRun = $null
            #end run with config

            if ($SCRIPT:logfile) {
                #Merge log files:
                Get-Content "Out.txt" | Add-Content -Path $SCRIPT:logfile
                Remove-Item "Out.txt"
<# LATER
                #Old_Name
                $position = $logfile.IndexOf(".")
                $de = $logfile.Substring(0, $position)
                $dd = get-date -uformat "%Y-%m-%d@%H-%M-%S"
                #New_Name
                $dd = $de + $dd + '.log'
                Rename-Item -Path $logfile -NewName $dd -Force
                $logfile = $dd
#>
                #Process results:
                if ($RMap.Contains('TEST_DESCRIPTION')) { $TD = $RMap['TEST_DESCRIPTION'] }
                else { $TD = '' }
                Write-Host `t'Processing results'
                Parse_SysbenchNew $TD $SCRIPT:logfile 0 $false
            }
        } else {
            #Run Sysbench as a harness.
            $ToExec="$PathToSB" + '\sysbench.exe'
            Write-Host `t"Executing " $ToExec $list
            Start-Process $ToExec -ArgumentList $list
            $ToExec = $null
            $list = $Null
            return #Leave sysbench running
        }
    } else {
        #Just run default
        Write-Host `t'Sysbench.conf not provided, running with defaults.'
        $d = '--mysql-port=' + "$Port"
        if ($SCRIPT:MySQLServer) {
            #Server defaults
            $i = 0
            do {
                .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test "$d" prepare | Out-Null
                $i += 1
            } while (($LASTEXITCODE -gt 0) -and ($i -le 4))
            if (($LASTEXITCODE -le 0) -or ($l -lt 4)) {
                Write-Host `t'PREPARE DONE'
            } else {Write-Host `t'PREPARE FAILED'}

            Start-Sleep -Seconds 2
            .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test "$d" run
            if ($LASTEXITCODE -eq 0) { Write-Host `t'Sysbench run succeeded.' }
            else { Write-Warning `t'Sysbench run failed.' }
            Start-Sleep -Seconds 2
        } else {
            #Cluster defaults
            $i = 0
            do {
                .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test --mysql-table-engine=NDB  --mysql-engine-trx=yes "$d" prepare | Out-Null
                $i += 1
            } while (($LASTEXITCODE -gt 0) -and ($i -le 4))

            Start-Sleep -Seconds 2
            .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test --mysql-table-engine=NDB --mysql-engine-trx=yes "$d" run
            if ($LASTEXITCODE -eq 0) { Write-Host `t'Sysbench run succeeded.' }
            else { Write-Warning `t'Sysbench run failed.' }
            Start-Sleep -Seconds 2
        }
    }
}

function Parse_DBT2_Conf ([string] $ConfFile)
{#In progress
    $RunMap = @{}
    #Map things, first Linux conf -> Windows conf
    foreach($line in (Get-Content $ConfFile))
    {   
	    $i = $null
	    ## Check if it is variable:
	    if ($line -match "^[a-zA-Z]")
	    {
		    ## So, we parse out K/V pair.
		    $i = $line.Split("=")
		    if ($i[1].Trim('"')) { #Guard against empty string and quoted values
                #There IS a value to Key but watch for "special" ones...
                switch ($i[0])
                {
                    "ZERO_DELAY"   {
                        if ($i[1] -eq 'on') {
                            $RunMap.Add($DBT2Map[$i[0]], 'yes')
                        } else {
                            $RunMap.Add($DBT2Map[$i[0]], 'no')
                        }
                    }
                    "RUN_AS_HARNESS" {
                        if ($i[1] -eq 'yes') {
                            $RunMap.Add($SysbenchMap[$i[0]], 'on')
                        } else {
                            $RunMap.Add($SysbenchMap[$i[0]], 'off')
                        }
                    }
                    default { 
                        if ($DBT2Allowed.Contains($DBT2Map[$i[0]]))
                        {
                            $RunMap.Add($DBT2Map[$i[0]], $i[1].Trim('"')) 
                        }
                    }
                }

		    }
	    }
    }

    #Check general parameters of the test for sanity:
    #'NUM_TEST_RUNS';
    if ($RunMap.Contains('RUN_NUMBER')) {
        try {
            $i = [int16]$RunMap['RUN_NUMBER']
            #No more than 100 runs!
            if (($i -gt 100) -or ($i -le 0)) {
                $RunMap.Remove('RUN_NUMBER')
                $RunMap.Add('RUN_NUMBER', 1)
            }
        } catch {
            $RunMap.Remove('RUN_NUMBER')
        }
    }
    #'BETWEEN_RUNS';
    if ($RunMap.Contains('BETWEEN_RUNS')) {
        try {
            $i = [int16]$RunMap['BETWEEN_RUNS']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('BETWEEN_RUNS')
            }
        } catch {
            $RunMap.Remove('BETWEEN_RUNS')
        }
    }
    #'AFTER_INITIAL_RUN';
    if ($RunMap.Contains('AFTER_INITIAL_RUN')) {
        try {
            $i = [int16]$RunMap['AFTER_INITIAL_RUN']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('AFTER_INITIAL_RUN')
            }
        } catch {
            $RunMap.Remove('AFTER_INITIAL_RUN')
        }
    }
    #'AFTER_SERVER_START';
    if ($RunMap.Contains('AFTER_SERVER_START')) {
        try {
            $i = [int16]$RunMap['AFTER_SERVER_START']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('AFTER_SERVER_START')
            }
        } catch {
            $RunMap.Remove('AFTER_SERVER_START')
        }
    }
    #'BETWEEN_CREATE_DB_TEST';
    if ($RunMap.Contains('BETWEEN_CREATE_DB_TEST')) {
        try {
            $i = [int16]$RunMap['BETWEEN_CREATE_DB_TEST']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('BETWEEN_CREATE_DB_TEST')
            }
        } catch {
            $RunMap.Remove('BETWEEN_CREATE_DB_TEST')
        }
    }
    #'NUM_CREATE_DB_ATTEMPTS';
    if ($RunMap.Contains('NUM_CREATE_DB_ATTEMPTS')) {
        try {
            $i = [int16]$RunMap['NUM_CREATE_DB_ATTEMPTS']
            #No more than 100 runs!
            if (($i -gt 100) -or ($i -le 0)) {
                $RunMap.Remove('NUM_CREATE_DB_ATTEMPTS')
            }
        } catch {
            $RunMap.Remove('NUM_CREATE_DB_ATTEMPTS')
        }
    }
    #'AFTER_SERVER_STOP';
    if ($RunMap.Contains('AFTER_SERVER_STOP')) {
        try {
            $i = [int16]$RunMap['AFTER_SERVER_STOP']
            #No more than 2 min!
            if (($i -gt 120) -or ($i -le 0)) {
                $RunMap.Remove('AFTER_SERVER_STOP')
            }
        } catch {
            $RunMap.Remove('AFTER_SERVER_STOP')
        }
    }
    #'LOG_FILE'    
    if ($RunMap.Contains('LOG_FILE'))
    {
        if (!(Test-Path (Split-Path $RunMap['LOG_FILE'] -Parent))) {
            $RunMap.Remove('LOG_FILE') }
    }
    if ($RunMap.Contains('RUN_AS_HARNESS')) {
        if ( @('on', 'off','yes','no') -notcontains $RunMap['RUN_AS_HARNESS']) {
                $RunMap.Remove('RUN_AS_HARNESS')
        }
    }


    #Check DBT2 parameters of the test for sanity:
    #'--mysql-host';
    if ($RunMap.Contains('-l')) { #--port?
        try {
            $i = [int16]$RunMap['-l']
            if (($i -gt 10000) -or ($i -le 0)) {
                $RunMap.Remove('-l')
            }
        } catch {
            $RunMap.Remove('-l') #auto-determined anyway
        }
    }

    if ($RunMap.Contains('--terminals')) {
        try {
            $i = [int16]$RunMap['--terminals']
            #Max 10000 threads
            if (($i -gt 10000) -or ($i -le 0)) {
                $RunMap.Remove('--terminals')
            }
        } catch {
            $RunMap.Remove('--terminals')
        }
    }

<#    if ($RunMap.Contains('--mysql-table-engine')) {
        if ( @('myisam','innodb','bdb','heap','ndbcluster','federated','ndb') -notcontains  $RunMap['--mysql-table-engine']) {
                $RunMap.Remove('--mysql-table-engine')
        }
    }
    if ($RunMap.Contains('--oltp-dist-type')) {
        if ( @('uniform','gaussian','special') -notcontains  $RunMap['--oltp-dist-type']) {
                $RunMap.Remove('--oltp-dist-type')
        }
    }
#>  

    if ($RunMap.Contains('--time')) {
        try {
            $i = [int16]$RunMap['--time']
            if ($i -le 59) {
                $RunMap.Remove('--time')
            }
        } catch {
            $RunMap.Remove('--time')
        }
    }

    if (!$RunMap.Contains('--run-number')) {
        $RunMap.Add('--run-number', 1)
    }

    if (!$RunMap.Contains('NUM_CREATE_DB_ATTEMPTS')) {
        $RunMap.Add('NUM_CREATE_DB_ATTEMPTS', 3)
    }
    return $RunMap
}

function Generate_DBT2_Data 
{
<#
-w #        warehouse cardinality
-c #        customer cardinality, default 3000
-i #        item cardinality, default 100000
-o #        order cardinality, default 3000
-n #        new-order cardinality, default 900
-d <path>   output path of data files
#>

    if ($RMap.Contains('-w')) { $wc = $RMap['-w'] }
    else { $wc = 1 }
    if ($RMap.Contains('-c')) { $cc = $RMap['-c'] }
    else { $cc = 3000 }
    if ($RMap.Contains('-i')) { $ic = $RMap['-i'] }
    else { $ic = 100000 }
    if ($RMap.Contains('-o')) { $oc = $RMap['-o'] }
    else { $oc = 3000 }
    if ($RMap.Contains('-n')) { $nc = $RMap['-n'] }
    else { $nc = 900 }
    if ($RMap.Contains('-d')) { $PathToData = $RMap['-d'] }
    else {
        #$PathToData = to whereever datagen.exe is \tmp
        $PathToData = "$PathToDBT2" + '\tmp'
    }

    if (!(Test-Path $PathToData)) { mkdir $PathToData } #Has to exist.

    if ($RMap.Contains('NUM_CREATE_DB_ATTEMPTS')) { $Num_Create_DB_Attempts = $RMap['NUM_CREATE_DB_ATTEMPTS'] }
    else { $Num_Create_DB_Attempts = 3 }

    #Run preconfigured test phase
    $ToRun = [PowerShell]::Create().AddCommand("$PathToDBT2" + '\datagen.exe')
    $Null = $ToRun.AddArgument('-w')
    $Null = $ToRun.AddArgument($wc)
    $Null = $ToRun.AddArgument('-c')
    $Null = $ToRun.AddArgument($cc)
    $Null = $ToRun.AddArgument('-i')
    $Null = $ToRun.AddArgument($ic)
    $Null = $ToRun.AddArgument('-o')
    $Null = $ToRun.AddArgument($oc)
    $Null = $ToRun.AddArgument('-n')
    $Null = $ToRun.AddArgument($nc)
    $Null = $ToRun.AddArgument('-d')
    $Null = $ToRun.AddArgument($PathToData)
    $Null = $ToRun.AddArgument('--mysql')

    #Write-Host `t"Executing" $ToRun.Commands.Commands.CommandText $ToRun.Commands.Commands.Parameters.value
    Write-Host `t"Executing" $ToRun.Commands.Commands.CommandText -foregroundcolor DarkGreen -backgroundcolor white
    Write-Output `t"with params" $ToRun.Commands.Commands.Parameters.value
    Write-Host ''
    #Generate DBT2 data
    $l = 0
    do {
        $ToRun.Invoke() | Out-Null
        $l += 1
    } while (($LASTEXITCODE -gt 0) -and ($l -lt $Num_Create_DB_Attempts))
    $ToRun.Stop()
    $ToRun.Dispose()
    $ToRun = $null
    #Check 1st and last exist.
    $l = $PathToData + '\customer.data'
    $m = $PathToData + '\warehouse.data'
    if ((Test-Path $l) -and (Test-Path $m)) { 
        Write-Host `t'GENERATE DATA DONE'
        Start-Sleep -Seconds 2
        return $true
    } else {
        Write-Warning `t'NO DATA GENERATED!'
        Start-Sleep -Seconds 2
        return $false
    }
}

function SetUp_and_Run_DBT2Test ([int16] $Port, [string] $PathToDBT2)
{
	<#
	.SYNOPSIS

	Method to form DBT2 parameters for Cluster/Server and
    run the test. Should be split if possible.
    Checks if TARBALLDIR has file named dbt2.conf. If it does,
    tries to read run-parameters from it. File can have either
    Windows or Unix line endings/comments and it can contain
    both Mikael's parameters and parameters DBT2 understands.
    Translation is governed by $DBT2Map hashtable.
	#>
#NOT DONE YET!!!!!!!!!!!
    $t = $SCRIPT:TarballDir + '\dbt2.conf'
    if (Test-Path $t) {
        #Do tyhe prep work.
        Write-Host `t'Provided:' $t
        $RMap = Parse_DBT2_Conf $t

        #Generate the data:
        if (Generate_DBT2_Data)
        {
            #This part is tested and works!
            #Prepare c/NET classes
            $ConnectionString = "Server=localhost;Uid=root; Port="+$LSrNodePort #+"; Allow User Variables=true;"
            $connection = New-Object MySql.Data.MySqlClient.MySqlConnection
            $connection.ConnectionString = $ConnectionString
            $connection.Open()
            $command = New-Object MySql.Data.MySqlClient.MySqlCommand
            $command.Connection = $connection
            $script = New-Object MySql.Data.MySQLClient.MySqlScript

            #Prepare the database
            $i = $SCRIPT:TarballDir + '\DBT2-database-creation.txt'

            if (!(Test-Path $i)) {} #Major boo-boo...

            $query = Get-Content $i
            $script.Query = $query;
            $script.Connection = $connection;
            $cnt = $script.Execute()
            Write-Host `t"Executed $cnt commands."

            #Now load generated data
            $tbllist= @('customer', 'district', 'history', 'item', 'new_order', 'order_line', 'order', 'stock', 'warehouse')
            foreach ($table in $tbllist) {
                $s = $PathToData + '\' + $table + '.data'
                $s = $s -Replace '\\', '\\'
                if ($table -eq 'order') { $table = 'orders'}
                $query = 'LOAD DATA INFILE "' + $s + '"  INTO TABLE ' + $table + ' FIELDS TERMINATED BY "\t"'
                $command.CommandText = $query
                $cnt = $command.ExecuteNonQuery()
                Write-Host `t"Added $cnt records to $table."
            }

        } else {
            #No data generated... Exit 1?
            #$host.UI.WriteErrorLine("`t No data generated. Exiting.")
            #Exit 1
        }

        #Run client.
        #1. Start of client to create pool of databases connections
        #2. Start of driver to emulate terminals and transactions generation

        #client.exe -u root -l 3306 -f -d mysql -c 20 -h 127.0.0.1 -o PATH_TO_OUTDIR
        #Driver.exe -d 127.0.0.1 -l 10 -wmin 1 -wmax 1 -outdir PATH_TO_OUTDIR
        #----------------------------------#

        #Check important parameters:
        if (!$RMap.Contains('--test')) {
            $testToRun = '--test=oltp'
        } else {
            #Has to be first option
            $testToRun = '--test=' + $RMap['--test']
            $RMap.Remove('--test')
        }
        if (!$RMap.Contains('--mysql-user')) {
            $userToRun = '--mysql-user=root'
        } else {
            $userToRun = '--mysql-user=' + $RMap['--mysql-user']
            $RMap.Remove('--mysql-user')
        }
        if (!$RMap.Contains('--mysql-db')) {
            $DBToRun = '--mysql-db=test'
        } else {
            $DBToRun = '--mysql-db=' + $RMap['--mysql-db']
            $RMap.Remove('--mysql-db')
        }

        # Hash -> List so I can add arguments faster.
        $d = '--mysql-port=' + "$Port"
        $list = New-Object Collections.Generic.List[string]
        $list.Add($testToRun)
        $list.Add($userToRun)
        $list.Add($DBToRun)
        $list.Add($d)
        foreach ($key in $RMap.Keys) { 
            if ($key -match "^--") { 
                $s = $key + '=' + $RMap[$key]
                $list.Add($s)
            }
        } 

        #Run preconfigured test phase
        $ToRun = [PowerShell]::Create().AddCommand("$PathToDBT2" + '\sysbench.exe')
        for ($i = 0; $i -lt $list.Count; $i++) { $Null = $ToRun.AddArgument($list[$i]) }

        if ($RMap.Contains('LOG_FILE')) {
            $logfile = $RMap['LOG_FILE']
            if ($RMap.Contains('TEST_DESCRIPTION')) {
                Set-Content -Value $RMap['TEST_DESCRIPTION'] -Path $logfile
                Add-Content $logfile $list
            } else { Set-Content -Value $list -Path $logfile }
        } else { $logfile = $null }

        #Prep Sysbench run
        $l = 0
        $Null = $ToRun.AddArgument('prepare')
        Write-Host `t"Executing" $ToRun.Commands.Commands.CommandText -foregroundcolor DarkGreen -backgroundcolor white
        Write-Output `t"with params" $ToRun.Commands.Commands.Parameters.value
        Write-Host ''
        do {
            if ($logfile) { $ToRun.Invoke() | Out-File 'Out.txt' }
            else { $ToRun.Invoke() | Out-Null }
            $l += 1
        } while (($LASTEXITCODE -gt 0) -and ($l -lt [int16]$RMap['NUM_CREATE_DB_ATTEMPTS']))

        Write-Host `t'PREPARE DONE'
        Start-Sleep -Seconds 2
        $ToRun.Stop()
        $ToRun.Dispose()
        $ToRun = $null
        
        #Run Sysbench tests
        if (($RMap.Contains('RUN_AS_HARNESS')) -and ($RMap['RUN_AS_HARNESS'] -ne 'on'))
        {
            for ($i = 0; $i -lt [int16]$RMap['NUM_TEST_RUNS']; $i++) {
                Write-Host `t'Running OLTP test' ($i + 1) '/' $RMap['NUM_TEST_RUNS']             
                $ToRun = [PowerShell]::Create().AddCommand("$PathToSB" + '\sysbench.exe')
                for ($k = 0; $k -lt $list.Count; $k++) { $Null = $ToRun.AddArgument($list[$k]) }
                $Null = $ToRun.AddArgument('run')
                Write-Host `t"Executing" $ToRun.Commands.Commands.CommandText -foregroundcolor DarkGreen -backgroundcolor white
                Write-Output `t"with params" $ToRun.Commands.Commands.Parameters.value
                Write-Host ''
                if ($logfile) { $ToRun.Invoke() | Out-File 'Out.txt' -Append }
                else { $ToRun.Invoke() }

                if ($LASTEXITCODE -eq 0) { Write-Host `t'DBT2 run finished.' }
                else { Write-Warning `t'DBT2 run failed.' }

                if (($i -eq 0) -and ($RMap.Contains('AFTER_INITIAL_RUN')) -and ($ntr -gt 1)) {
                    $l = [int16]$RMap['AFTER_INITIAL_RUN']
                    Write-Host `t'Sleeping '$l' seconds after initial run.'
                    Start-Sleep -Seconds $l
                } else {
                    if ($RMap.Contains('BETWEEN_RUNS')) {
                        $l = [int16]$RMap['BETWEEN_RUNS']
                        Write-Host `t'Sleeping '$l' seconds between runs.'
                        Start-Sleep -Seconds $l
                    }
                }
                $ToRun.Stop()
                $ToRun.Dispose()
                $ToRun = $null
            }
            #end run with config

            if ($logfile) {
                #Merge log files:
                Get-Content "Out.txt" | Add-Content -Path $logfile
                Remove-Item "Out.txt"
                #Process results:
                if ($RMap.Contains('TEST_DESCRIPTION')) { $TD = $RMap['TEST_DESCRIPTION'] }
                else { $TD = '' }
                Write-Host `t'Processing results'
                #Parse_SysbenchOLTPResults $TD $logfile
                Parse_SysbenchNew $TD $logfile 0 $false
            }
        } else {
            #Run Sysbench as a harness.
            $ToExec="$PathToDBT2" + '\sysbench.exe'
            Write-Host `t"Executing " $ToExec $list
            Start-Process $ToExec -ArgumentList $list
            $ToExec = $null
            $list = $Null
            return #Leave sysbench running

        }
    } else {
        #Just run default
        Write-Host `t'DBT2.conf not provided, running with defaults.'
        $d = '--mysql-port=' + "$Port"
        if ($SCRIPT:MySQLServer) {
            #Server defaults
            $i = 0
            do {
                .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test "$d" prepare | Out-Null
                $i += 1
            } while (($LASTEXITCODE -gt 0) -and ($i -le 4))

            Start-Sleep -Seconds 2
            .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test "$d" run
            if ($LASTEXITCODE -eq 0) { Write-Host `t'Sysbench run succeeded.' }
            else { Write-Warning `t'Sysbench run failed.' }
            Start-Sleep -Seconds 2
        } else {
            #Cluster defaults
            $i = 0
            do {
                .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test --mysql-table-engine=NDB  --mysql-engine-trx=yes "$d" prepare | Out-Null
                $i += 1
            } while (($LASTEXITCODE -gt 0) -and ($i -le 4))

            Start-Sleep -Seconds 2
            .\sysbench.exe --max-requests=10000 --max-time=20 --db-driver=mysql --test=oltp --mysql-user=root --mysql-db=test --mysql-table-engine=NDB --mysql-engine-trx=yes "$d" run
            if ($LASTEXITCODE -eq 0) { Write-Host `t'Sysbench run succeeded.' }
            else { Write-Warning `t'Sysbench run failed.' }
            Start-Sleep -Seconds 2
        }
    }
}

function IsLocalPortListening([int16] $LPort)
{
	<#
	.SYNOPSIS

	Method to check if local port is available. This is used to determine free
    port for deployment.
	#>

    Try 
    {
        $connection = (New-Object Net.Sockets.TcpClient)
        $connection.Connect("127.0.0.1",$LPort)
        $connection.Close()
        $connection = $null
        return "Listening"
    } Catch {
        $connection.Close()
        $connection = $null
        return "Not listening"
    }
}

function exec_local_job_ex
{
	<#
	.SYNOPSIS

	Method to execute any command as a local background job and verify command was a success.
    Returns JOB variable which can be inspected for properties and stopped/freed later.
    First argument is the array to be processed after adding rest of the arguments from the call.
    To replace exec_local_job completely!
	#>

    Write-Host `t"Executing" $args[1] -foregroundcolor DarkGreen -backgroundcolor white
    Write-Host `t"with params"
    $ToExec=""
    #These are the arguments that go first,
    #like path to and name of executable and such.
    for ( $i = 1; $i -lt $args.Length; $i++)
    {
        $ToExec = ($ToExec,$args[$i]) -join ' '
        if ($i -ge 2) { Write-Host $args[$i]}
    }

    switch ($args[0])
    {
        'SERVERCL' {
            if ($SCRIPT:SERVERCL) {
                $SCRIPT:SERVERCL.Split(" ") | ForEach {
                    $ToExec = ($ToExec,$_) -join ' '
                }
                $SCRIPT:SERVERCL.Split(" ") | ForEach {
                    Write-Host $_ }

            }
            break   #Do not check rest of the conditions!     
         }
        'CLUSTERCL' {
            if ($SCRIPT:CLUSTERCL) {
                $SCRIPT:CLUSTERCL.Split(" ") | ForEach {
                    $ToExec = ($ToExec,$_) -join ' '
                }
                $SCRIPT:CLUSTERCL.Split(" ") | ForEach {
                    Write-Host $_ }
            }
            break   #Do not check rest of the conditions!     
        }
        'INIT'  {
            break   #Do not check rest of the conditions!     
        }
        #Default {}
    }

    $sb = [scriptblock]::Create($ToExec)
    $job = Start-Job -ScriptBlock $sb -ErrorVariable errmsg 2>$null
    
	if ( $errmsg )
	{
		$host.UI.WriteErrorLine("`tFailed command $ToExec with error $errmsg")
        #Go back to script directory.
        $Null = Set-Location -Path $PSScriptRoot
        exit 1
	}

    Start-Sleep -Seconds 2
    if ($job.State -eq 'completed') {
        #There was no error but no success either, ie. job terminated instantly.
        #State checks in main code will do the cleanup.
        $host.UI.WriteErrorLine("`tJob terminated instantly.")
    }
    return $job
}

function exec_local_job 
{
	<#
	.SYNOPSIS

	Method to execute any command as a local background job and verify command was a success.
    Returns JOB variable which can be inspected for properties and stopped/freed later.
    Suited for passing ARRAY of parameters such is defined in $SCRIPT:SERVERCL and $SCRIPT:CLUSTECL
	#>
    
    $ToExec=""
    for ( $i = 0; $i -lt $args.Length; $i++)
    {
        $ToExec = ($ToExec,$args[$i]) -join ' '
        #Write-Host `t"Executing" $args[$i] -foregroundcolor DarkGreen -backgroundcolor white
    }
	Write-Host `t"Executing" $ToExec -foregroundcolor DarkGreen -backgroundcolor white

    $sb = [scriptblock]::Create($ToExec)
    $job = Start-Job -ScriptBlock $sb -ErrorVariable errmsg 2>$null
    
	if ( $errmsg )
	{
		#Write-Warning `t"Failed command $ToExec with error $errmsg"
        $host.UI.WriteErrorLine("`tFailed command $ToExec with error $errmsg")
        #Go back to script directory.
        $Null = Set-Location -Path $PSScriptRoot
        exit 1
	}
    Start-Sleep -Seconds 2
    <#https://msdn.microsoft.com/en-us/library/windows/desktop/system.management.automation.jobstate%28v=vs.85%29.aspx
    Member name	    Description
    AtBreakpoint	Script execution is halted in a debugger stop.This element is introduced in Windows PowerShell 5.0.
    Blocked	        The job is blocked, such as waiting for user input, from running the commands of the pipeline in one or more runspaces. This field is introduced in Windows PowerShell 2.0.
    Completed	    The job has successfully run the commands of the pipeline in all runspaces. This field is introduced in Windows PowerShell 2.0.
    Disconnected	The job is a remote job and has been disconnected from the server. Introduced in Windows PowerShell 3.0.
    Failed	        The job was not successfully able to run the commands of the pipeline. This field is introduced in Windows PowerShell 2.0.
    NotStarted	    The job has not begun to run the commands of the pipeline. This field is introduced in Windows PowerShell 2.0.
    Running	        The job is in the process of running the commands of the pipeline. This field is introduced in Windows PowerShell 2.0.
    Stopped	        The job has been canceled on one or more runspaces. This field is introduced in Windows PowerShell 2.0.
    Stopping	    The job is in the process of stopping the running of the commands of the pipeline. Introduced in Windows PowerShell 3.0.
    Suspended	    The job has suspended the running of the commands of the pipeline. Introduced in Windows PowerShell 3.0.
    Suspending	    The job is in the process of suspending the running of the commands of the pipeline. Introduced in Windows PowerShell 3.0.#>
    if ($job.State -eq 'completed') {
        #There was no error but no success either, ie. job terminated instantly.
        #State checks in main code will do the cleanup.
        $host.UI.WriteErrorLine("`tJob terminated instantly.")
    }
    return $job
}


function Get-BuildEnv
{
	<#
	.SYNOPSIS

	Get build environment.
    Sets $SCRIPT:VSBuildEnv and $SCRIPT:MSBuildEnv dynamically.
    Those variables, in turn, point to proper executables.
	#>
    try {
        #Get VS from environment
        $x = (dir Env:).Name -match "VS[0-9]{1,3}COMNTOOLS"
        if ($X) {
            #Path to VS (defined in environment) Tools dir
            $d = (get-item env:$x).Value
            #Compose full path
            $dd = '""' + "$d" + '\vsvars32.bat""' #VsDevCmd
            if (Test-Path $dd) {
                $SCRIPT:VSBuildEnv = $dd
            } #Else: Something is VERY wrong with environment...    
        }
    
        #Now check for MSBuild
        Push-Location
        Set-Location 'HKLM:\Software\Microsoft\MSBuild\ToolsVersions'
        $Keys = Get-ChildItem .
        $Items = $Keys | Foreach-Object {Get-ItemProperty $_.PsPath }
        ForEach ($Item in $Items) {
            "{0,-35} {1,-10} " -f $Item.PSChildName, $Item.ImagePath}
        $max = 0
        $km = $null
        for ($m = 0; $m -lt $items.Count; $m++) {
            $d = $items[$m].PSPath 
            $d = $d.TrimStart("Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\MSBuild\ToolsVersions\") 
            if ([double]$d -gt $max) {
                $max = [double]$d
                $km = $m
            }
        }
        $SCRIPT:MSBuildEnv = ($items[$km].MSBuildToolsPath, 'MSBuild.exe') -join ''
        Pop-Location
    } Catch {
        #No need to care. IF there is a build tool there is one.
        # If not, not. We can always enforce built binaries for such environment.
        return
    }
}

function Get_CMAKE_Generator
{
	<#
	.SYNOPSIS

	Determine viable CMAKE generator for builds if one is not set globally
    ($SCRIPT:CMAKEGenerator). CMAKE should be in PATH for this to work.
    Visual Studio should be installed for this to work.
	#>

    $GenList = New-Object Collections.Generic.List[string]
    #Try to collect output from CMAKE
    cmake --help | Out-File cmake.txt
    foreach ($line in (Get-Content cmake.txt)) { 
	    if ($line -match "Visual ") {
		    $GenList.Add($line.Split('=')[0].Trim())
	    }
    }
    Remove-Item cmake.txt
    if ($GenList.Count) {
	    #Get Major VS version
        $i = (dir Env:).Name -match "VS[0-9]{1,3}COMNTOOLS"
        if ($i.Count -ge 1) {
            for ($m = 0; $m -lt $i.Count; $m++) {
                #Multiple VS versions, $i is an array
                $i[$m] = [string](($i[$m].TrimEnd("COMNTOOLS")).TrimStart("VS"))
    	        $i[$m] = $i[$m] / 10
    	        #Cut 120 to 12, 90 to 9...
            }
	        #Compose full name
	        $i = 'Visual Studio ' + ($i | Measure -Max).Maximum
        } else {
            Write-Warning `t"No CMAKE and/or no viable CMAKE generator found."
            $GenList = $null
            return $null
        }
        
        for ($m = 0; $m -lt $GenList.Count; $m++)
        {
            if ($GenList[$m] -match $i) {
                $i = $GenList[$m]
        		if ([System.Environment]::Is64BitProcess) { $i = $i + ' Win64' }
                break
            }
        }
        $GenList = $null
        return $i
    } else {
        Write-Warning `t'No CMAKE generators found!'
        $GenList = $null
        return $null
    }
}

function Read-FolderBrowserDialog([string]$Message, [string]$InitialDirectory, [switch]$NoNewFolderButton)
{
	<#
	.SYNOPSIS

	Standard Windows folder browser.
	#>
    
    if ([appdomain]::currentdomain.getassemblies() | ? { $_.fullname -like "system.windows*" }) 
    { #ISE loads this from the start
        #[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $browseForFolderOptions = 0
        if ($NoNewFolderButton) { $browseForFolderOptions += 512 }
 
        $app = New-Object -ComObject Shell.Application
        $folder = $app.BrowseForFolder(0, $Message, $browseForFolderOptions, 17)
        if ($folder) { $selectedDirectory = $folder.Self.Path } else { $selectedDirectory = '' }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($app) > $null
    } else {
        #PS
        #$ret = Get-ChildItem -Directory | Out-GridView -PassThru ?
        $selectedDirectory = ""
        $drvobj = Get-PSDrive -PSProvider 'FileSystem' | Select-Object Root | out-gridview -title "Choose the drive?" -OutputMode Single
        #Unwrap PSObject (as it is hash table)...
        $drv = $drvobj.psobject.properties | Foreach { $_.Value }
        #$drv = now it's string, "G:\"
        $ret = $null
        do
        {
            do
            {
                $ret = Get-Childitem $drv -Attributes Directory | Out-Gridview -title "Select directory" -OutPutMode Single | Select-Object FullName
                $ret = $ret.psobject.properties | Foreach { $_.Value }
                if ($ret) { 
                    if ($drv -eq $ret) {$ret = ""} #Same directory choosen twice. Break. Can't really happen...
                    else {$drv = $ret}
                }
            }
            until (!$ret)
            $selectedDirectory = $drv
        }
        until ($selectedDirectory -ne "")
    }
    return $selectedDirectory
}

function Extract-Archive([string]$InitialDirectory, [string]$ArchiveName, [string]$ArchiveType)
{
	<#
	.SYNOPSIS

	Standard Windows Unzip or 7-zip if installed.
	#>

    if ($ArchiveType -eq 'ZIPBALL') {
        #Guard it? Maybe disk failure can occur?
        $shell_app = new-object -com shell.application
        $zip_file = $shell_app.namespace("$InitialDirectory" + '\' + "$ArchiveName")
        $destination = $shell_app.namespace("$InitialDirectory")
        #unzip the file
        $destination.Copyhere($zip_file.items())
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell_app) > $null
    } else {
        #'TARBALL', use Sharp lib or 7Z
        #$SCRIPT:Can_Do_TB = 1 # Enum; 0 - Can't proc. tarballs, 1 - ICSharp, 2 - 7Zip
        if ($SCRIPT:Can_Do_TB -eq 1) {
            #Use Sharp lib.
            $inFile = "$InitialDirectory" + '\' + "$ArchiveName"
            $outFile = "$InitialDirectory" + '\.' #$inFile.TrimEnd(".tar.gz")

            $inStream = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
            $gzipStream = New-Object ICSharpCode.SharpZipLib.GZip.GZipInputStream($inStream)

            $tarArchive = ([ICSharpCode.SharpZipLib.Tar.TarArchive]::CreateInputTarArchive($gzipStream))

            $tarArchive.ExtractContents($outFile)
            $tarArchive.Close()

            $gzipStream.Close();
            $inStream.Close();
        } else {
            #Use 7-zip
            $inFile = "$InitialDirectory" + '\' + "$ArchiveName"
            $mid_file = $infile.TrimEnd(".gz")
            $outFile = $inFile.TrimEnd(".tar.gz")

            $tmp = "$InitialDirectory" + '\.'
            $res = &7z x $inFile -o"$tmp"
            $res | Select -Last 5
            #$res[7] should be "Everything is Ok" (or [2] id Last 5).
            Sleep -Seconds 2
            Echo "`tExtracting from TAR file."
            if (!(Test-Path $mid_file)) {
                #The TAR archive inside tar.gz is named differently. I should try and extract in "proper" directory.
                Write-Warning "`tUnexpected TAR archive name! Renaming."
                $tmp = dir ("$InitialDirectory"+'\*.tar') | Select Name
                Rename-Item -Path ($InitialDirectory+'\'+$tmp.Name) -NewName $mid_file -Force
            }
            $tmp = &7z l -slt $mid_file -x!*\*
            $i = $tmp.IndexOf("Folder = +") # should be either 13 or 17 I think.
            if (($i -gt 1) -and ($tmp.Count -lt 25)) {#(($tmp[13] -eq "Folder = +") -or ($tmp[17] -eq "Folder = +")) { 
                #Has top-level directory
                #2 options: a) top-level is named after tarballname and b) top-level has different name.
                if  ($tmp[$i-1].TrimStart("Path = ") -eq (Split-Path $outFile -Leaf)) {
                    $tmp = "$InitialDirectory" + '\.'
                    $res = &7z x $mid_file -o"$tmp"
                    $tmp = $res | Select -Last 7
                    $res = $null
                    $tmp
                    #$tmp[1] should be "Everything is Ok"
                    Sleep -Seconds 2
                    Echo "`tDone extracting."
                } else {
                    #Top-level directory inside TAR is named differently from tar.gz file.
                    #This will not work with 7zip...
                    #Final structure will be $InitialDirectory\(Split-Path $outFile -Leaf)\Top_Level_Dir
                    $oldName = $tmp[$i-1].TrimStart("Path = ")
                    Write-Warning ("`tTop level directory inside TAR file has different name than the archive!")
                    $tmp = "$InitialDirectory" + '\.'
                    $res = &7z x $mid_file -o"$tmp"
                    $tmp = $res | Select -Last 7
                    $res = $null
                    $tmp
                    #$tmp[1] should be "Everything is Ok"
                    Echo "`tDone extracting."
                    Sleep -Seconds 4
                    Echo "`tRenaming $oldName to $(Split-Path $outFile -Leaf)"
                    #Should check for "Everything is Ok" line.
                    #Rename to "proper" name.
                    Rename-Item -path ($InitialDirectory+'\'+$oldName) -NewName (Split-Path $outFile -Leaf) -Force
                }
            } else {
                #No top level directory.
                $res = &7z x $mid_file -o"$outFile"
                $res | Select -Last 7
                Echo "`tDone extracting."
                $res = $null
            }
            #Clean up TAR file:
            Remove-Item $mid_file -Force
        }
    }
    return
}

function New-ZipFile {
	<#
	.SYNOPSIS

	Create a new zip file, optionally appending to an existing zip.
	#>

  [CmdletBinding()]
  param(
    # The path of the zip to create
    [Parameter(Position=0, Mandatory=$true)]
    $ZipFilePath,
 
    # Items that we want to add to the ZipFile
    [Parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias("PSPath","Item")]
    [string[]]$InputObject = $Pwd,
 
    # Append to an existing zip file, instead of overwriting it
    [Switch]$Append,
 
    # The compression level (defaults to Optimal):
    #   Optimal - The compression operation should be optimally compressed, even if the operation takes a longer time to complete.
    #   Fastest - The compression operation should complete as quickly as possible, even if the resulting file is not optimally compressed.
    #   NoCompression - No compression should be performed on the file.
    [System.IO.Compression.CompressionLevel]$Compression = "Optimal"
  )
  begin {
    # Make sure the folder already exists
    [string]$File = Split-Path $ZipFilePath -Leaf
    [string]$Folder = $(if($Folder = Split-Path $ZipFilePath) { Resolve-Path $Folder } else { $Pwd })
    $ZipFilePath = Join-Path $Folder $File
    # If they don't want to append, make sure the zip file doesn't already exist.
    if(!$Append) {
      if(Test-Path $ZipFilePath) { Remove-Item $ZipFilePath }
    }
    $Archive = [System.IO.Compression.ZipFile]::Open( $ZipFilePath, "Update" )
  }
  process {
    foreach($path in $InputObject) {
      foreach($item in Resolve-Path $path) {
        # Push-Location so we can use Resolve-Path -Relative
        Push-Location (Split-Path $item)
        # This will get the file, or all the files in the folder (recursively)
        foreach($file in Get-ChildItem $item -Recurse -File -Force | % FullName) {
          # Calculate the relative file path
          $relative = (Resolve-Path $file -Relative).TrimStart(".\")
          # Add the file to the zip
          $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $file, $relative, $Compression)
        }
        Pop-Location
      }
    }
  }
  end {
    $Archive.Dispose()
    Get-Item $ZipFilePath
  }
}

function Determine-ProductByArchiveName ([string] $name)
{
	<#
	.SYNOPSIS

	Method to check type of archives in TARBALL folder.
	#>

    $out = $null
    if ($name -match "^*sysben*") { $out = "sysbench" }
    else {
        if ($name -match "^mysql-cluster.*[7-9]\.[0-9]") { $out = "cluster" }
         else {
            if ($name -match "^mysql-[5]\.[6-9]") { $out = "server" }
            else {if ($name -match "DBT2") { $out = "DBT2" }}
        }
    }
    return $out
}

function Parse_Autobench_Conf
{
	<#
	.SYNOPSIS

	Method to parse autobench.conf and assign global script variables.
	#>
    $fp = pwd
    $fp = $fp.Path + '\autobench.conf'

    Write-Host 'Parsing configuration from' $fp
    if (!(Test-Path $fp)) {
        return $false
    }
    
    foreach($line in (Get-Content $fp))
    {   
	    $i = $null
	    ## Check if it is variable:
	    if ($line -match "^[a-zA-Z]")
	    {
		    ## So, we parse out K/V pair.
		    $i = $line.Split("=")
            try {
		        if ($i[1].Trim('"')) { #Guard against empty string and quoted values
                    #There IS a value to Key but watch for "special" ones...
                    switch ($i[0])
                    {
                        "TARBALL_DIR" {
                            $SCRIPT:TarballDir = $i[1].Trim('"')
                            if (!(Test-Path $SCRIPT:TarballDir)) {
                                $SCRIPT:TarballDir = $null
                            } 
                            #Write-Host 'TARBALLDIR' `t$SCRIPT:TarballDir
                            break
                        }
                        "TEST_DESCRIPTION"  {
                            #Nothing for now.
                            break
                        }
                        "CMAKE_GENERATOR" {
                            if (!($SCRIPT:CMAKEGenerator)) {
                                $SCRIPT:CMAKEGenerator = $i[1].Trim('"')
                            }
                            #Write-Host 'CMAKE generator' $SCRIPT:CMAKEGenerator
                            break
                        }
                        "CMAKEConfigure" {
                            if (!($SCRIPT:CMAKEConfigure)) {
                                $i = $line
                                $i = $i.TrimStart('CMAKEConfigure=')
                                $SCRIPT:CMAKEConfigure = $i
                                Write-Host 'CMAKE configure' `t$SCRIPT:CMAKEConfigure
                            }
                            break
                        }
                        "CLUSTERCL" {
                            if (!($SCRIPT:CLUSTERCL)) {
                                $i = $line
                                $i = $i.TrimStart('CLUSTERCL=')
                                $SCRIPT:CLUSTERCL = $i
                                Write-Host 'Cluster CLine' `t`t$SCRIPT:CLUSTERCL
                            }
                            break
                        }
                        "SERVERCL" {
                            if (!($SCRIPT:SERVERCL)) {
                                $i = $line
                                $i = $i.TrimStart('SERVERCL=')
                                $SCRIPT:SERVERCL = $i
                                Write-Host 'Server  CLine' `t`t$SCRIPT:SERVERCL
                            }
                            break
                        }
                        "CLUSTERNODES" {
                            try {
                                $SCRIPT:CLnodes = [int16]$i[1].Trim('"')
                            } catch {
                                $SCRIPT:CLnodes = 0
                            }
                            Write-Host 'Cluster nodes' `t`t$SCRIPT:CLnodes
                            break
                        }
                        "SYSBENCHTARBALL" {
                            if (!($SCRIPT:Sysbench)) {
                                if (Test-Path ($SCRIPT:TarballDir + '\' + $i[1].Trim('"'))) {
                                    $SCRIPT:Sysbench = $i[1].Trim('"')
                                    if ($SCRIPT:Sysbench -match '.zip') {
                                        $SCRIPT:Sysbench = $SCRIPT:Sysbench.Replace(".zip", "")
                                    }
                                    if ($SCRIPT:Sysbench -match '.tar.gz') {
                                        $SCRIPT:Sysbench = $SCRIPT:Sysbench.Replace(".tar.gz", "")
                                    }
                                    $SCRIPT:Sysbench = $SCRIPT:Sysbench.Trim()
                                } else { $SCRIPT:Sysbench = $null }
                            }
                            Write-Host 'Sysbench tarball' `t$SCRIPT:Sysbench
                            break
                        }
                        "DBT2TARBALL" {
                            if (!($SCRIPT:DBT2)) {
                                if (Test-Path ($SCRIPT:TarballDir + '\' + $i[1].Trim('"'))) {
                                    $SCRIPT:DBT2 = $i[1].Trim('"')
                                    if ($SCRIPT:DBT2 -match '.zip') {
                                        $SCRIPT:DBT2 = $SCRIPT:DBT2.Replace(".zip", "")
                                    }
                                    if ($SCRIPT:DBT2 -match '.tar.gz') {
                                        $SCRIPT:DBT2 = $SCRIPT:DBT2.Replace(".tar.gz", "")
                                    }
                                    $SCRIPT:DBT2 = $SCRIPT:DBT2.Trim()
                                } else { $SCRIPT:DBT2 = $null }
                            }
                            Write-Host 'DBT2 tarball' `t`t$SCRIPT:DBT2
                            break
                        }
                        "MYSQLTARBALL" {
                            if (!($SCRIPT:MySQLServer)) {
                                if (Test-Path ($SCRIPT:TarballDir + '\' + $i[1].Trim('"'))) {
                                    $SCRIPT:MySQLServer = $i[1].Trim('"')
                                    if ($SCRIPT:MySQLServer -match '.zip') {
                                        $SCRIPT:MySQLServer = $SCRIPT:MySQLServer.Replace(".zip", "")
                                    }
                                    if ($SCRIPT:MySQLServer -match '.tar.gz') {
                                        $SCRIPT:MySQLServer = $SCRIPT:MySQLServer.Replace(".tar.gz", "")
                                    }
                                    $SCRIPT:MySQLServer = $SCRIPT:MySQLServer.Trim()
                                } else { $SCRIPT:MySQLServer = $null }
                            }
                            Write-Host 'Server  tarball' `t$SCRIPT:MySQLServer
                            break
                        }
                        "CLUSTERTARBALL" {
                            if (!($SCRIPT:MySQLCluster)) {
                                if (Test-Path ($SCRIPT:TarballDir + '\' + $i[1].Trim('"'))) {
                                    $SCRIPT:MySQLCluster = $i[1].Trim('"')
                                    if ($SCRIPT:MySQLCluster -match '.zip') {
                                        $SCRIPT:MySQLCluster = $SCRIPT:MySQLCluster.Replace(".zip", "")
                                    }
                                    if ($SCRIPT:MySQLCluster -match '.tar.gz') {
                                        $SCRIPT:MySQLCluster = $SCRIPT:MySQLCluster.Replace(".tar.gz", "")
                                    }
                                    $SCRIPT:MySQLCluster = $SCRIPT:MySQLCluster.Trim()
                                } else { $SCRIPT:MySQLCluster = $null }
                            }
                            Write-Host 'Cluster tarball' `t$SCRIPT:MySQLCluster
                            break
                        }
                        "ARCHIVERUN" { #DEFAULT=NO
                            $SCRIPT:ArchiveRun = $i[1].Trim('"')
                            if ( @('yes','no') -notcontains $SCRIPT:ArchiveRun) {
                                $SCRIPT:ArchiveRun = $null
                            } 
                            break
                        }
                        "OPTIONDATAD" { #DEFAULT=COPY_CLEAN
                            $SCRIPT:OPTIONDATAD = $i[1].Trim('"')
                            if ( @('COPY_CLEAN','ALWAYS_CLEAN') -notcontains $SCRIPT:OPTIONDATAD) {
                                $SCRIPT:OPTIONDATAD = $null
                            } 
                            break
                        }
                        "SBDUMPPREPED" { #DEFAULT=YES
                            $SCRIPT:SBDUMPPREPED = $i[1].Trim('"')
                            if ( @('yes','no') -notcontains $SCRIPT:SBDUMPPREPED) {
                                $SCRIPT:SBDUMPPREPED = $null
                            } 
                            break
                        }
                        "SBPREPEDDATA" { #DEFAULT=data_sb.sql
                            $SCRIPT:SBPREPEDDATA = $i[1].Trim('"')
                            break
                        }
                        "SHOW_INNODB_STATUS" { #DEFAULT=YES
                            if ( @('yes','no') -notcontains $i[1].Trim('"')) {
                                $SCRIPT:SHOW_INNODB_STATUS = $false
                            } else { $SCRIPT:SHOW_INNODB_STATUS = $i[1].Trim('"') -contains 'yes' }
                            break
                        }
                   }
		        }
	        } catch {}
        } 
    }
    Write-Host ''
    $fp = $null
    return $true
}

function CleanUp_TarballDir {
	<#
	.SYNOPSIS

    #Clean up results of previous runs.
    #Files/Folders are in form of ndb_data-YYYY-MM-DD@HH-MM-SS
	#>
    Write-Host 'Doing initial cleanup of TARBALL dir.'

    dir ($SCRIPT:TarballDir + '\*') | ForEach {
        if ($_ -match "ndb_data.*@*") {
            Write-Warning `t'Deleting '$_
            Remove-Item $_ -Force -Recurse
        }
    }
    dir ($SCRIPT:TarballDir + '\*') | ForEach {
        if ($_ -match "^mysqld-output-.*@") {
            Write-Warning `t'Deleting '$_
            Remove-Item $_ -Force
        }
    }
    if (Test-Path ($SCRIPT:TarballDir+'\results.csv')) {
        $de = $SCRIPT:TarballDir+'\results.csv'
        Write-Warning `t'Deleting '$de
        Remove-Item $de -Force
    }
    if (Test-Path ($SCRIPT:TarballDir+'\buildlog.txt')) {
        $de = $SCRIPT:TarballDir+'\buildlog.txt'
        Write-Warning `t'Deleting '$de
        Remove-Item $de -Force
    }
    if (Test-Path ($SCRIPT:TarballDir+'\generatelog.txt')) {
        $de = $SCRIPT:TarballDir+'\generatelog.txt'
        Write-Warning `t'Deleting '$de
        Remove-Item $de -Force
    }
    dir ($SCRIPT:TarballDir + '\*') | ForEach {
        if ($_ -match "^runlog.*@") {
            Write-Warning `t'Deleting '$_
            Remove-Item $_ -Force
        }
    }
    #Don't want to bother... Just delete all that have 'number@number' inside...
    dir ($SCRIPT:TarballDir + '\*') | ForEach {
        if ($_ -match "[0-9]@[0-9]") {
            Write-Warning `t'Deleting '$_
            Remove-Item $_ -Force
        }
    }
    Write-Host 'Initial cleanup done.'
    Write-Host '---------------------'
}

function Prepare_ForBuild {
	<#
	.SYNOPSIS

    Check IF and WHAT is to be built.
    Check requirements for building.
    EXIT 1 if requirements not met.
	#>

    #Extract configure phase here for both Server&Cluster to avoid code duplication.
    if ($SCRIPT:MySQLServer) {
        $SCRIPT:CLUSTERCL = $null
        Write-Host `t'ENTER: Compile MySQL server.'
        $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer
    } else {
        $SCRIPT:SERVERCL = $null
        Write-Host `t'ENTER: Compile MySQL cluster.'
        $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster
    }
    Write-Host `t"---------------------------"

    #See if binaries are already compiled.
    pushd
    cd $p
    $SCRIPT:CompileFlag = !(gci -Recurse -Filter "mysqld.exe" -file)
    if (!$CompileFlag) {
        #Skip compile
        Write-Warning `t`t"MySQLd found. No compilation will be done."
        return $p 
    } else {
        #Check for stuff.
        if ((Get-Command "bison.exe"  -ErrorAction SilentlyContinue) -and ($SCRIPT:CMAKEGenerator))
        {
            if (Test-Path 'mybuild') { 
                Write-Warning `t`t'Removing old mybuild directory.'
                Remove-Item 'mybuild' -Force -Recurse
            }
            Write-Host `t`t'Creating fresh mybuild directory.'
            $null = mkdir 'mybuild'
            $null = cd 'mybuild'
            return $p
        } else {
            popd
            if (!($SCRIPT:CMAKEGenerator)) {$host.UI.WriteErrorLine("`t`tNo viable CMAKE generator found. Exiting script.")}
            else { $host.UI.WriteErrorLine("`t`tBison not installed/in path. Exiting script.") }
            return $null
        }
    }
}

function GenerateAndCompile_mysql ([string] $p) {
	<#
	.SYNOPSIS

    Generate the SERVER/CLUSTER build, compile with CMAKE.
	#>

    #Run configure in background async job to display progress.
    #CMAKE -BPath\To\BuildDir -HPath\To\SourceDir
    #ie. cmake -BD:\test\mysql-5.6.23\mybuild -HD:\test\mysql-5.6.23 -G "Visual Studio 12 2013 Win64"
    # -B and -H are necessary since next command opens up NEW shell unaware of paths set in this one.

    $ToRun = [PowerShell]::Create().AddCommand('cmake')
    $dd = '-B' + $p + '\mybuild'
    $d = '-H' + $p
    $Null = $ToRun.AddArgument($dd)
    $Null = $ToRun.AddArgument($d)

    $Null = $ToRun.AddArgument('-G')
    $Null = $ToRun.AddArgument('"'+$SCRIPT:CMAKEGenerator+'"')

    if ($SCRIPT:CMAKEConfigure) {
        $SCRIPT:CMAKEConfigure.Split(" ") | ForEach {$null = $ToRun.AddArgument($_)}
    }
    Write-Host ''
    Write-Host `t`t'Generating build.'
    Write-Host `t`t"Executing" $ToRun.Commands.Commands.CommandText "with params" -foregroundcolor DarkGreen -backgroundcolor white
    foreach ($arg in $ToRun.Commands.Commands.Parameters.value) {
        Write-Host `t`t$arg
    }
    Write-Host ''

    $async = $ToRun.BeginInvoke()
    $i = 0
    $upward = $true
    while (!$async.IsCompleted)
    {
	    if (($i -lt 100) -and ($upward)) {
		    $i += 1
		    $upward = ($i -lt 100)
		    }
	    elseif (($i -gt 0) -and !($upward)) {
		    $i -= 1
		    $upward = ($i -eq 0)
	    }
	    write-progress -activity "Generating files " -Status ' ' -percentcomplete $i;
	    Start-Sleep -m 70
    }
    #Receive-Job here to check.
    $err = $false
    $d = ''
    #$ToRun.EndInvoke($async) | foreach {if ($_.ToString() -match "errors oc") {$err = $true} else {$d = $_}}
    $res1 = $ToRun.EndInvoke($async)
    $s = "$SCRIPT:TarballDir"+'\generatelog.txt'
    $res1 > "$s"

    $res1 | foreach {if ($_.ToString() -match "errors oc") {$err = $true} else {$d = $_}}
    if (!$err) {Write-Host $d}
    else { 
        $host.UI.WriteErrorLine("`t Errors occurred!") 
        $res1 | foreach {$host.UI.WriteErrorLine("`t $_.")}
        #$host.UI.WriteErrorLine("`t $res1[$res1.Count-1].")
    }
    $res1 = $null

    $ToRun.Stop()
    $ToRun.Dispose()
    $ToRun = $null
    $async = $null
    Write-Progress "  " "  " -completed
    if ($err) { return $false }

    Start-Sleep -Seconds 2
    Write-Host `t`t'Done generating build.'
    Write-Host ''

    #Run build in background async job to display progress.
    $ToRun = [PowerShell]::Create().AddCommand('cmake')
    $Null = $ToRun.AddArgument('--build')
    $p = $p + '\mybuild'
    $Null = $ToRun.AddArgument($p)
    $Null = $ToRun.AddArgument('--config')
    $Null = $ToRun.AddArgument('relwithdebinfo')
    $Null = $ToRun.AddArgument('--target')
    $Null = $ToRun.AddArgument('package')
    Write-Host `t`t'Building'
    Write-Host `t`t"Executing" $ToRun.Commands.Commands.CommandText "with params" -foregroundcolor DarkGreen -backgroundcolor white
    foreach ($arg in $ToRun.Commands.Commands.Parameters.value) {
        Write-Host `t`t$arg
    }

    $async = $ToRun.BeginInvoke()
    $i = 0
    $upward = $true
    $act = 'Compiling'
    while (!$async.IsCompleted)
    {
	    if (($i -lt 100) -and ($upward)) {
		    $i += 1
		    $upward = ($i -lt 100)
		    }
	    elseif (($i -gt 0) -and !($upward)) {
		    $i -= 1
		    $upward = ($i -eq 0)
	    }
        #Get latest directory CMAKE touched (if there is any).
        $latest = Get-ChildItem -Path . | ?{ $_.PSIsContainer } | Sort-Object LastAccessTime -Descending | Select-Object -First 1
        #$latest.name == _CPack_Packages -> Packing stage.
        if ($latest) {
            if ($latest -notmatch "Packages") {
                if ($latest -notmatch "CMakeFiles") { $act = 'Working on ' + $latest }
                else {$act = 'Writing ' + $latest} 
            } else { $act = 'Packaging ' }
        } else { $act = '  ' }
        if ($SCRIPT:MySQLServer) {
	        write-progress -activity 'Compiling MySQL server' -Status $act -percentcomplete $i;
        } else {write-progress -activity 'Compiling MySQL cluster' -Status $act -percentcomplete $i}
	    Start-Sleep -m 70
    }

    $res1 = $ToRun.EndInvoke($async) #| Select-Object -Last 5 #For now, just write the result out.
    $err = $true
    $d = ''
    $dd = ''

    $s = "$SCRIPT:TarballDir"+'\buildlog.txt'
    $res1 > "$s"

    $res1 | Select -Last 5 | foreach {if ($_.Trim() -eq "0 Error(s)") {$err = $false}}
    $res1 | Select -Last 5 | foreach {Write-Host $_}
    if ($err) { 
        $host.UI.WriteErrorLine("`t Errors occurred!") 
        $res1 | Where {$_ -match ": error "} | foreach {$host.UI.WriteErrorLine("`t $_.")}
    }
    $res1 = $null

    $ToRun.Stop()
    $ToRun.Dispose()
    $ToRun = $null
    $async = $null
    Write-Progress "  " "  " -completed

    if ($err) { return $false }
    Start-Sleep -Seconds 1
    if ($SCRIPT:MySQLServer) {Write-Host `t`t"Done compiling server."}
    else {Write-Host `t`t"Done compiling cluster."}

    #I need to bypass CPACK zip operations here to speed things up...
    #This is where the new zip file is ($SCRIPT:MySQLServer/mybuild).
    #Get that ZIPBALL and move it to TARBALL directory for extraction.
    Write-Host `t`t'Cleaning up compiling bits.'
    #On Windows, CPACK uses ZIP by default.
    $i = ls *.zip | Where-Object -FilterScript {($_.LastWriteTime -gt (Get-Date).Date)}
    if ($i) { Move-Item $i.Name -Destination ..\..\. }
    else {
        $host.UI.WriteErrorLine("`t`tCan not locate zip file from build...")
        return $false
    }
    cd .. #mybuild -> $SCRIPT:MySQLServer
    cd .. #$SCRIPT:MySQLServer -> TarballDir
    #Remove entire dir with unpacked sources
    sleep 2
    Write-Host `t`t"Removing SOURCE directory."
    if ($SCRIPT:MySQLServer) {Remove-Item -Recurse -Force $SCRIPT:MySQLServer}
    else {Remove-Item -Recurse -Force $SCRIPT:MySQLCluster}

    Write-Host `t`t'Extracting from built zipball.'
    Extract-Archive -InitialDirectory "$SCRIPT:TarballDir" -ArchiveName $i.Name -ArchiveType 'ZIPBALL'

    #Rename Sources.zip to Sources.zi_ as we now have built binary archive.

    if ($SCRIPT:MySQLServer) {$z = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer}
    else {$z = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster}

    if (Test-Path ($z + '.zip')) {
        if ($SCRIPT:MySQLServer) {Rename-Item -Path ($z + '.zip') -NewName ($SCRIPT:MySQLServer + '.zi_')}
        else {Rename-Item -Path ($z + '.zip') -NewName ($SCRIPT:MySQLCluster + '.zi_')}
    } else {
        if (Test-Path ($z + '.tar.gz')) {
            if ($SCRIPT:MySQLServer) {Rename-Item -Path ($z + '.tar.gz') -NewName ($SCRIPT:MySQLServer + '.tar.g_')}
            else {Rename-Item -Path ($z + '.tar.gz') -NewName ($SCRIPT:MySQLCluster + '.tar.g_')}
        }
    }

    if ($SCRIPT:MySQLServer) {$SCRIPT:MySQLServer = $i.BaseName}
    else {$SCRIPT:MySQLCluster = $i.BaseName}
    #Server/Cluster compiled, source dir removed, new path to Server binaries set.
    return $true
}

function Check_SBBuild {
	<#
	.SYNOPSIS

    Check if Sysbench build is needed.
	#>
    Write-Host `t'ENTER: Compile Sysbench:'
    Write-Host `t"------------------------"

    $p = $SCRIPT:TarballDir + '\' + $SCRIPT:Sysbench
    cd $p

    #Check if Sysbench.exe and libmysql.dll are already there
    $i = gci -Recurse -Filter "sysbench.exe" -file
    if ($i) { $i = gci -Recurse -Filter "libmysql.dll" -file }

    if ($i) { 
        Write-Warning `t`t'sysbench.exe & libmysql.dll found. No compilation will be done.' 
        return $false    
    } else { return $true}
}

function Build_SB {
	<#
	.SYNOPSIS

    Build Sysbench.
	#>

    #Sysbench on Windows has to be built from VS cmd line.
    #Set the minimal environment by defining LIB and INCLUDE for MySQL.
    if ($SCRIPT:MySQLServer) {
        $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer
        #Save the location of Server. Already tested above.
        Push-Location $p
    } else {
        if ($SCRIPT:MySQLCluster) {
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster
            #Save the location of Cluster. Already tested above.
            Push-Location $p
        }
    } 

    $i = gci -Recurse -Filter "mysql.h" -file
    if ($i) {
        $d = $i[0].DirectoryName #Does not work in PS without this.
        Write-Host `t`t"Header : "$d
        Set-Content "env:INCLUDE" $i[0].DirectoryName
    } else { Write-Warning `t`t'Could not find mysql.h file!' }

    $i = gci -Recurse -Filter "libmysql.lib" -file
    if ($i) {
        $d = $i[0].DirectoryName #Does not work in PS without this.
        Write-Host `t`t"Library: "$d
        Set-Content "env:LIB" $i[0].DirectoryName
    } else {
        Write-Warning `t`t'Could not find libmysql.lib file!'
        $i = $null
    }

    Pop-Location #Back to Sysbench dir
    if ($i) {
        #Compile

        cd sysbench #One step down the tree
        Start-Sleep -Seconds 1
        if ($SCRIPT:CMAKEGenerator) {
            #Add some checks here...
            cmake -G "$SCRIPT:CMAKEGenerator" 2>$null #Hide configuration errors.
            $lec = $LASTEXITCODE
            Start-Sleep -Seconds 1
            cmake --build . --config Release | Out-Null #Hide compilation output
            $lec = $LASTEXITCODE
            #EXE should be in cd Release!
            #Clean up because of possible re-runs:
            Remove-Item Env:\INCLUDE
            Remove-Item Env:\LIB
            Write-Host `t'END: Compile Sysbench.'
            Write-Host `t'----------------------'
            return ($LASTEXITCODE -eq 0)

        } else {
            Write-Warning `t`t'Unable to compile Sysbench. No viable CMAKE generator installed.'
            return $false
        }
    } else {
        Write-Warning `t`t'Unable to compile Sysbench.'
        return $false
    }
}

function Determine_DataDir {
	<#
	.SYNOPSIS

	Function to determine if datadir is in expected place.
	#>

    switch ($args[0])
    {
        'SERVER' {
            #Path to root of Server dir
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer
            break   #Do not check rest of the conditions!     
         }
        'CLUSTER' {
            #Path to root of Cluster dir
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster
            break   #Do not check rest of the conditions!     
        }
    }
    $dd = $p -Replace '\\', '\\'
    $dd = 'datadir=' + $dd + '\\Data'
    $SCRIPT:Datadir = '--'+$dd
    $dd = $p -Replace '\\', '\\'
    $dd = 'basedir=' + $dd
    $SCRIPT:Basedir = '--'+$dd
    return $p
}

function Get_MGMNodePort {
	<#
	.SYNOPSIS

	Function to determine on which port the Cluster management node
    is listening and change it to first available port above 5000 if
    configured port is taken.
	#>
    switch ($args[0])
    {
        'LOCAL' {
            #Choice for Port. Check if blocked.
            for ($i = 5000; $i -lt 5100; $i++) {
                if (IsLocalPortListening($i) = "Not listening") {
                    $SCRIPT:LMGNodePort = $i
                    break
                }
            }
         }
        'REMOTE' {
            #Not used ATM.
        }
    }
}

function Create_FreshNDBDATA {
	<#
	.SYNOPSIS

	Function to create Config dir and config file for management
    node0.
	#>

    #Hide output of New-Item.
    $d = $p + '\ndb_data'
    if (Test-Path $d) {
        Remove-Item -Force -Recurse $d
        Write-Warning `t'Removed ndb_data left from previous run.'
    }
    New-Item -Path $p -Name ndb_data -ItemType directory | Out-Null
    Write-Host `t'Fresh ndb_data created.'
    Write-Host ''
}

function Set_DATADIR {
    $ver = $null
    $cl = $null
    switch ($args[0])
    {
        'CLUSTER' {
            $ver = ($SCRIPT:MySQLCluster -match "^mysql-cluster-7\.5")
            $cl = 'CLUSTERCL'
            break
         }
        'SERVER' {
            $ver = ($SCRIPT:MySQLServer -match "^mysql-5\.7")
            $cl = 'SERVERCL'
            break
        }
    }

    #After BM run, DATA is removed and DATA_TG is moved to DATA.
    #5.7 does not come with DATA so goes here.
    #5.6 comes with DATA, goes to ELSE.

    $dd = $p + '\data'
    if (!(Test-Path $dd)) {
        $dd = "$p" + '\bin\mysqld'
        # Only IF 5.7
        if ($ver) {
            $df = '--initialize-insecure'
            if ( $cl -eq 'CLUSTERCL') {
                $cl = 'INIT'
                $jobdatad = exec_local_job_ex $cl "$dd" "$df"
            } else { 
                $jobdatad = exec_local_job_ex $cl "$dd" "$df" '--new'
            }
            $null = Wait-Job $jobdatad
            #$null = Receive-Job $jobdatad
            $null = Remove-Job $jobdatad
            $dd = $p + '\data'
            if (Test-Path $dd) {
                if ((Get-ChildItem $dd | Measure-Object).Count -gt 1) {                 
                    Write-Host `n`t"New DATA dir created."
                    Sleep 2
                } else {
                    $host.UI.WriteErrorLine("`tFailed to create DATADIR!")
                    $Null = Set-Location -Path $PSScriptRoot
                    Exit 1
                }
            } else {
                $host.UI.WriteErrorLine("`tFailed to create DATADIR!")
                $Null = Set-Location -Path $PSScriptRoot
                Exit 1
            }

            #Make a copy of datadir for subsequent runs!
            if ($SCRIPT:OPTIONDATAD) {
                switch ($SCRIPT:OPTIONDATAD)
                {
                    'COPY_CLEAN' {
                        Write-Warning `t"Making clean copy of DATA dir."
                        $dd = $p + '\data'
                        $de = $p + '\data_tg'
                        Copy-Item $dd -Destination $de -Recurse
                        Sleep 2
                        Write-Host ''
                    }
                    'ALWAYS_CLEAN' {}
                }
            }

        } else {
            #Error...
            $host.UI.WriteErrorLine("`t No data dir provided. Exiting.")
            #Go back to script directory.
            $Null = Set-Location -Path $PSScriptRoot
            Exit 1
        }
    } else {
        if (!$ver) {
            #It's 5.6.
            $dd = $p + '\data_tg' #Look for clean copy.
            if (Test-Path $dd) {
                Write-Warning `t"Found clean copy of DATA dir."
                $dd = $p + '\data'
                $de = $p + '\data_tg'
                Remove-Item $dd -Force -Recurse
                Copy-Item $de -Destination $dd -Recurse
                Sleep 2
                Write-Host ''
            } else {
                #There is no data_tg but there is data. Let's assume datadir IS clean and copy.
                Write-Warning `t"Making clean copy of DATA dir."
                $dd = $p + '\data'
                $de = $p + '\data_tg'
                Copy-Item $dd -Destination $de -Recurse
                Sleep 2
                Write-Host ''
            }
        }
    } #DATADIR set.
}

function Receive_Mysqld_Job ([bool]$DumpToFile)
{
    if ($DumpToFile) {
        Write-Host `t'Receiving info from mysqld job before shutting down.'
        $Null = popd
        $Null = Set-Location -Path $SCRIPT:TarballDir
<# LATER        
        $dd = get-date -uformat "%Y-%m-%d@%H-%M-%S"
        #New_Name
        $SCRIPT:mysqldoutput = 'mysqld-output-' + $dd + '.txt'
#>
        if ($SCRIPT:MYSQLD_jobRunning) {
            $MYSQLD_job | Receive-Job 2>&1 >> 'mysqld-output.txt'
        } else {
            Write-Warning `t'No MySQLD job to receive from!'
        }
        $Null = popd
    } else {
        if ($SCRIPT:MYSQLD_jobRunning) {
            $null = $MYSQLD_job | Receive-Job 
        } else {
            Write-Warning `t'No MySQLD job to receive from!'
        }
    }
}

function Stop_Mysqld_Job
{
    try {
        if ($SCRIPT:MYSQLD_jobRunning) {
            Write-Host `t'Stopping mysqld job.'
            $MYSQLD_job | Stop-Job
            Remove-Job -Job $MYSQLD_job 
        } else {
            Write-Warning `t'No MySQLD job to stop!'
        }
    } 
    catch [system.exception] {
        Write-Warning `t'Error STOPPING/REMOVING MySQLD job!'
    }
}

#Main script code
Clear-Host
$Null = Set-Location -Path $PSScriptRoot

#New logic: Check for existence of autobench.conf and get most basic setup from there.
#Read autobench.conf, skip $SCRIPT:TarballDir and $SCRIPT:CLnodes if NOT empty.
if (!(Parse_Autobench_Conf)) {
    Write-Warning 'No autobench.conf file provided!'
}

if ([string]::IsNullOrEmpty($SCRIPT:TarballDir) -or !(Test-Path "$SCRIPT:TarballDir")) {
    # IF empty or non-existent path is provided as CL/autobench.conf argument, try fetching via GUI
    $SCRIPT:TarballDir = Read-FolderBrowserDialog -Message "Please select a base directory" -InitialDirectory 'D:' -NoNewFolderButton
}

#TEST-PATH ($SCRIPT:TARBALLDIR)
if ([string]::IsNullOrEmpty($SCRIPT:TarballDir)) {
    $host.UI.WriteErrorLine("You did not select valid base directory!" )
    Exit 1 #Not on command line, not in autobench.conf nothing from folder-browser...
} else { 
    #$SCRIPT:TotProc = [System.Environment]::ProcessorCount #Much faster but tends to ignore HT on big boxes :-/
    $SCRIPT:TotProc = 0
    $SCRIPT:TotProc = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    Write-Host 'Total cores:    '`t$SCRIPT:TotProc
    Write-Host 'TARBALLDIR :    '`t$SCRIPT:TarballDir
    #If CMAKE generator is not set, get one that matches environment from CMAKE.
    if (!($SCRIPT:CMAKEGenerator)) {
        $SCRIPT:CMAKEGenerator = Get_CMAKE_Generator
    }
    Write-Host 'CMAKE generator' `t$SCRIPT:CMAKEGenerator
    Write-Host ''

    if (Test-Path ((pwd).path+'\ICSharpCode.SharpZipLib.dll')) {
      Write-Host "ICSharpCode.SharpZipLib.dll found."
      $SCRIPT:Can_Do_TB = 1 # Enum; 0 - Can't proc. tarballs, 1 - ICSharp, 2 - 7Zip
    }

    $tmp = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($tmp) { 
        Write-Host "7zip found."
        $SCRIPT:Can_Do_TB = 2 # Enum; 0 - Can't proc. tarballs, 1 - ICSharp, 2 - 7Zip
    }

    if ($SCRIPT:Can_Do_TB -eq 0) {
        Write-Warning "No tool for processing TARBALLS found!"
    }

    if ($SCRIPT:Can_Do_TB -eq 1) {
        #Do not know why but it doeas not work with .\IC...
        Write-Warning "Processing TARBALLS with SharpZipLib.dll is not safe. Please install 7zip."
        $i = pwd
        $i = $i.Path + '\ICSharpCode.SharpZipLib.dll'
        [void][system.reflection.Assembly]::LoadFrom($i)
    }

    #Process archives:
    # 1) Determine what archives are there, what (non)empty directories etc.
    $p = "$SCRIPT:TarballDir\*"
    if ($SCRIPT:Can_Do_TB -gt 0) {
        $ZipList = Get-Item $p -Include ('*.zip','*.tar.gz') | Select-Object BaseName -Unique
    } else {$ZipList = Get-Item $p -Include ('*.zip') | Select-Object BaseName -Unique}
    if ($ZipList.Count -le 1) {
        $host.UI.WriteErrorLine("Can't work with single/zero archives!")
        Exit 1
    }

    Write-Host "ENTER Preparation stage"
    Write-Host "-----------------------"
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    for ( $i = 0; $i -lt  $ZipList.Count; $i++) {
        $tmpVar = $ZipList[$i].BaseName #Remove .ext and PATH. This leaves .tar from .tar.gz!
        $tmpVar = $tmpVar.TrimEnd('.tar')
        if (($SCRIPT:MySQLServer -eq $tmpVar) -or 
            ($SCRIPT:MySQLCluster -eq $tmpVar) -or
            ($SCRIPT:Sysbench -eq $tmpVar) -or 
            ($SCRIPT:DBT2 -eq $tmpVar)) {
            #Provided in script or autobench.conf. Skip autodetect.
            #Already trimmed when parsing autobench.conf. No need for .TrimEnd(".zip").TrimEnd(".tar.gz").
            continue
        }
        switch (Determine-ProductByArchiveName -Name $tmpVar)
        {
            "server"   {if (!($SCRIPT:MySQLServer)) {$SCRIPT:MySQLServer = $tmpVar}}
            "cluster"  {if (!($SCRIPT:MySQLCluster)) {$SCRIPT:MySQLCluster = $tmpVar}}
            "sysbench" {if (!($SCRIPT:Sysbench)) {$SCRIPT:Sysbench = $tmpVar}}
            "DBT2"     {if (!($SCRIPT:DBT2)) {$SCRIPT:DBT2 = $tmpVar}}
        } #Exit removing extension from global variable.
    }        
    $tmpVar = $null

    if (($SCRIPT:MySQLServer) -and ($SCRIPT:MySQLCluster))
    {
        Write-Warning 'Found both Server and Cluster tarballs. Please pick one to use.'
        $caption = "Please select the tarball"
        $message = "Select which tarball to use:"
        $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Server", "&Cluster", "&Quit")
        [int]$defaultChoice = 0
        $choiceRTN = $host.ui.PromptForChoice($caption,$message, $choices,$defaultChoice)
        switch($choiceRTN)
        {
            0    { 
                    $SCRIPT:MySQLCluster = $null
                    Write-Host 'Using SERVER tarball ' + $SCRIPT:MySQLServer + '.'
                 }
            1    {
                    $SCRIPT:MySQLServer = $null
                    Write-Host 'Using CLUSTER tarball ' + $SCRIPT:MySQLCluster + '.'
                 }
            2    { 
                    $caption = $null
                    $message = $null
                    $choices = $null
                    $defaultChoice = $null
                    Exit 1
                 }
        }
        $caption = $null
        $message = $null
        $choices = $null
        $defaultChoice = $null
        $choiceRTN = $null
    }

    for ( $i = 0; $i -lt  $ZipList.Count; $i++) {
        $tmpVar = $ZipList[$i].BaseName #Remove .ext and PATH which leaves .tar from .tar.gz.
        $tmpVar = $tmpVar.TrimEnd('.tar')
        if (($SCRIPT:MySQLServer -ne $tmpVar) -and ($SCRIPT:MySQLCluster -ne $tmpVar) -and
            ($SCRIPT:Sysbench -ne $tmpVar) -and ($SCRIPT:DBT2 -ne $tmpVar)) {
            #Extra tarball, skip.   
            continue
        }

        #check if extraction directory exists already and if it's empty
        $p = $SCRIPT:TarballDir + '\' + $ZipList[$i].BaseName
        if ($p) {$p = $p.TrimEnd('.tar.gz')}

        if (Test-Path $p) {
            if ((Get-ChildItem $p | Measure-Object).Count -le 0) { 
                #empty, delete
                Write-Host `t"removing item " $p
                Remove-Item -Force $p
            }
        }

        if (Test-Path $p) {
            #directory not empty, assume already extracted
            $p = $ZipList[$i].BaseName # + '.zip/tar.gz'
            Write-Host `t"skipping   item " $p
        } else {
            #Extract archives.
            Write-Host `t"processing item " $ZipList[$i].BaseName
            $p = $SCRIPT:TarballDir + '\' + $ZipList[$i].BaseName + '.zip'
            if (Test-Path $p) {
                #It's a ZIP
                $p = $ZipList[$i].BaseName + '.zip'
                Extract-Archive -InitialDirectory $SCRIPT:TarballDir -ArchiveName $p -ArchiveType 'ZIPBALL'
            } else {
                if ($SCRIPT:Can_Do_TB -eq 0) {
                    $host.UI.WriteErrorLine("`tCan not process TAR.GZ!")
                    Exit 1
                }
                $p = $SCRIPT:TarballDir + '\' + $ZipList[$i].BaseName + '.gz'
                if (Test-Path $p) {
                    #It's TARBALL
                    $p = $ZipList[$i].BaseName + '.gz'
                    Extract-Archive -InitialDirectory $SCRIPT:TarballDir -ArchiveName $p  -ArchiveType 'TARBALL'
                } else {
                    $host.UI.WriteErrorLine("`tSomeone deleted the archive between populating into the list and extracting!")
                    Exit 1
                }
            }
        }

        Write-Host `t"--"
    } #for * zip files in directory
    #Cleanup
    $ZipList = $null

    #Sanity check
    if (!((($SCRIPT:MySQLCluster) -or ($SCRIPT:MySQLServer)) -and (($SCRIPT:Sysbench) -or ($SCRIPT:DBT2)))) {
        $host.UI.WriteErrorLine("`tYou need to have benchmark and either Cluster or Server!")
        Exit 1
    }
    if (($SCRIPT:MySQLCluster) -and ($SCRIPT:CLnodes -le 0)) {
        $host.UI.WriteErrorLine("`tYou can't have Cluster deployment with 0 nodes!")
        Exit 1
    }

    CleanUp_TarballDir

    [console]::TreatControlCAsInput = $true #Trap CTRL+C for graceful exit.

    #Load MySQL c/NET
    $i = pwd
    $i = $i.Path + '\MySQL.Data.dll'
    [void][system.reflection.Assembly]::LoadFrom($i)
    Write-Host 'MySQL c/NET loaded.'

    $StopWatch.Stop()
    $CurrentTime = $StopWatch.Elapsed
    $StopWatch = $null
    Write-Host 'END Preparation stage in' $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
            $CurrentTime.hours, 
            $CurrentTime.minutes, 
            $CurrentTime.seconds)) 
    Write-Host "---------------------------------"

    Write-Host "ENTER Compilation stage"
    Write-Host "-----------------------"
    #Now check for executables and compile as needed:
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

    $CompileFlag = $false
    $p = Prepare_ForBuild
    if (!($p)) {
        #Go back to script directory.
        $Null = Set-Location -Path $PSScriptRoot
        exit 1
    }

    if ($CompileFlag) {
        if (!(GenerateAndCompile_mysql $p)) {
            $host.UI.WriteErrorLine("`t`tBuild failed.")
            #Go back to script directory.
            $Null = Set-Location -Path $PSScriptRoot
            Exit 1
        } 
    }

    popd #Back to where script is started from
    if ($SCRIPT:MySQLServer) {Write-Host `t'END: compile MySQL server.'}
    else {Write-Host `t'END: compile MySQL cluster.'}
    Write-Host `t"--------------------------"

    if ($SCRIPT:Sysbench) 
    {
        if (Check_SBBuild) { 
            if (!(Build_SB)) {
                #Go back to script directory.
                $Null = Set-Location -Path $PSScriptRoot
                Exit 1
            } 
        }
    }

    if ($SCRIPT:DBT2) { Write-Warning `t'Not compiling DBT2 for now!' }

    $StopWatch.Stop()
    $CurrentTime = $StopWatch.Elapsed
    Write-Host 'END Compilation stage in' $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
            $CurrentTime.hours, 
            $CurrentTime.minutes, 
            $CurrentTime.seconds))
    $StopWatch = $null
    Write-Host "---------------------------------"

    Write-Host "ENTER Deployment stage"
    Write-Host "----------------------"
    #Depoly locally
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    #We need fatal error indicator here cause we'll be starting services and such
    $FatalDeplEr = $false
    
    if ($SCRIPT:MySQLCluster) {
        $p = Determine_DataDir 'CLUSTER'

        #Clean up provided ini files.
        $dd = "$p" + '\my-default.ini'
        if (Test-Path $dd) {Remove-Item -Force $dd}

        $LMGNodePort = $null
        Get_MGMNodePort 'LOCAL' #LOCAL/REMOTE
        $FatalDeplEr = !($LMGNodePort)
        if (!($FatalDeplEr)) {
            Create_FreshNDBDATA
            #IS there a DATADIR provided?
            if ($SCRIPT:OPTIONDATAD) {
                switch ($SCRIPT:OPTIONDATAD)
                {
                    'COPY_CLEAN' {}
                    'ALWAYS_CLEAN' {
                        $dd = $p + '\data'
                        if (Test-Path $dd) {
                            if ($SCRIPT:MySQLCluster -match "^mysql-cluster-7\.5") {
                                Write-Warning `t"Removing existing DATA dir."
                                Remove-Item -Path $dd -Recurse -Force
                            } else { #5.6
                                $de = $p + '\data_tg'
                                if (Test-Path $de) {
                                    $dd = $p + '\data'
                                    Write-Warning `t"Removing existing DATA dir."
                                    Remove-Item -Path $dd -Recurse -Force
                                    Write-Warning `t"Copying clean DATA dir."
                                    Copy-Item $de -Destination $dd -Recurse
                                } else {
                                    Write-Warning `t"Cannot remove existing DATA dir. No replacement found."
                                }
                            }
                        }    
                    }
                }
            }
            Set_DATADIR 'CLUSTER'
        } #Fatal error, no port for mgmt node!

        #Some sanity checks.
        if ($? -and !($FatalDeplEr) -and (Test-Path $p)) {
            $LNodePort = GetSet_Cluster_ini
            $d = 'localhost:' + $LNodePort
            #Test stuff
            if (Test-Path $p)
            {
                if ($LNodePort)
                {
                    $dd = "$p" + '\bin\mysqld.exe'
                    if (Test-Path $dd)
                    {
                        $dd = "$p" + '\bin\mysqladmin.exe'
                        if (Test-Path $dd)
                        {
                            $dd = "$p" + '\ndb_data\config.ini'
                            if (Test-Path $dd) 
                            {
                                $dd = "$p" + '\bin\ndb_mgmd.exe'
                                if (Test-Path $dd) 
                                {
                                    $dd = "$p" + '\bin\ndbmtd.exe'
                                    if (!(Test-Path $dd))
                                    {
                                        Write-Warning `t"Fatal error, can not locate $dd"
                                        $FatalDeplEr = $true
                                    } else {
                                        $dd = $p + '\data'
                                        if (!(Test-Path $dd)) {
                                            Write-Warning `t"Fatal error, no DATA dir."
                                            $FatalDeplEr = $true
                                        }
                                    }
                                } else {
                                    Write-Warning `t"Fatal error, can not locate $dd"
                                    $FatalDeplEr = $true
                                }
                            } else {
                                Write-Warning `t"Fatal error, can not locate $dd"
                                $FatalDeplEr = $true
                            }
                        }else {
                            Write-Warning `t"Fatal error, can not locate $dd"
                            $FatalDeplEr = $true
                        }
                    } else {
                        Write-Warning `t"Fatal error, can not locate $dd"
                        $FatalDeplEr = $true
                    }
                } else {
                    Write-Warning `t"Fatal error, can not locate free port in given range"
                    $FatalDeplEr = $true
                }
            } else {
                Write-Warning `t"Fatal error, can not locate $p"
                $FatalDeplEr = $true
            }
        } else {
            if ($LMGNodePort) { Write-Warning `t'Unable to create ' "$p" '\ndb_data!' }
            else { Write-Warning `t"Fatal error, can not locate free port in given range" }
            $FatalDeplEr = $true
        }

        if (!($FatalDeplEr))
        {
            cd $p
            $dd = "$p" + '\bin\ndb_mgmd'
            $de = "$p" + '\ndb_data\config.ini'
            $df = '--configdir=' + "$p" + '\ndb_data'

            #Start cluster nodes
            Write-Host ''
            $MGMTNode_job = exec_local_job "$dd" '-f' "$de" '--initial' "$df"

            Start-Sleep -Seconds 1
            Write-Host ''
            Write-Host -NoNewline `t"Start Cluster mgmt node "
            $i = 0
            do
            {
                Write-Host -NoNewline "."
                Start-Sleep -Milliseconds 100
                $i += 1
            }
            until (($MGMTNode_job.State -eq 'Running') -or ($i -eq 100)) #10 seconds delay tops.

            if ($MGMTNode_job.State -eq 'Running')
            {
                Write-Host ''
                $dd = "$p" + '\bin\ndbmtd'
                #$D = localhost+nodeport
                for ($i = 0; $i -lt $SCRIPT:CLnodes; $i++) {
                    Write-Host `t'Start cluster data node' ($i+1)
                    $Node_job = exec_local_job "$dd" '-c' "$d"
                    Start-Sleep -Seconds 2
                }
                #Wait for startup to finish
                Start-Sleep -Seconds 5
                Write-Host ''
                $dd = "$p" + '\bin\ndb_mgm'
                $d = 'localhost:' + "$LNodePort"
                $i = 0
                $r = 0
                $nodesStarted = @{}
                $res = & "$dd" "$d" -e 'ALL STATUS'
                if ($res.Count -gt (1)) {
                    do {
                        $r+=1
                        if (($r -gt $res.Count) -or ($r -gt $SCRIPT:CLnodes)) {break}
                        $e = $res[$r].TrimStart('Node ')
                        $e = $e.Split(':')
                        $e = $e[0] #NodeID
                        if (($res[$r] -match "started")) {
                            $nodesStarted.Add($e,'yes')
                        } else {$nodesStarted.Add($e,'no')}

                    } while ($true)
                }

                $i = 0
                $w = 0
                $s = ''
                do {
                    $ndst = $nodesStarted.Clone() #Can not unwrap and change in pipeline...
                    $ndst.getEnumerator() | foreach { $r = $_.key
                        switch ($_.value)
                        {
                            #'yes' { 
                            #    $i += 1
                            #    break 
                            #}
                            'no' {
                                Sleep -Seconds 4
                                $b = [convert]::ToInt32($r, 10)
                                $s = [string]$b + ' STATUS'
                                $res = & "$dd" "$d" -e ''$s''
                                if ($res.Count -gt (1)) {
                                    $e = $res[1].TrimStart('Node ')
                                    $f = 'NodeID ' + $e
                                    Write-Host `t$f
                                    $e = $e.Split(':')
                                    $e = $e[0] #NodeID
                                    if (($res[1] -match "started")) {
                                        $nodesStarted.Set_Item($r,'yes')
                                        Write-Host `t'NodeID' $r 'has started.'
                                        $i += 1
                                    }
                                }
                            }
                        } #SWITCH
                    } #foreach
                    $ndst = $null
                    $w +=1
                    if ($i -eq $SCRIPT:CLnodes) { break } #All nodes started.
                    if ($w -ge 20) {break} #control
                } while ($true)
                $ndst = $null
                $w = $null

                #I could do without this ($i -eq $SCRIPT:CLnodes) but want to display offending node(s).
                $nodesStarted.getEnumerator() | foreach { $r = $_.key
                    switch ($_.value)
                    {
                        'no' { 
                            $FatalDeplEr = $true
                            $host.UI.WriteErrorLine("`tNodeID " + $r + ' has NOT started.')
                            break 
                        }
                    } #SWITCH
                } #foreach
                $nodesStarted = $null
                Write-Host ''

                if (!($FatalDeplEr)) {
                    #Start mysqld
                    $dd = "$p" + '\bin\mysqld'
                    $de = '--port='+$LMGNodePort
                    $df = '--new' 
                    $MYSQLD_job = exec_local_job_ex 'CLUSTERCL' "$dd" "$SCRIPT:Datadir" "$SCRIPT:Basedir" "$df" "$de"
                    #"--ndbcluster"

                    Write-Host ''
                    Write-Host -NoNewline "Starting API node "
                    #PowerShell way for checking.
                    $i = 0
                    do
                    {
                        Write-Host -NoNewline "."
                        Start-Sleep -Milliseconds 100
                        $i += 1
                    }
                    until (($MYSQLD_job.State -eq 'Running') -or ($i -eq 100)) #10 seconds delay tops.

                    Start-Sleep -Seconds 2 #After_Server_start???
                    Write-Host ''
                    #MySQL way for checking.
                    $i = 0
                    do {
                        $d = '-P' + "$LMGNodePort"
                        $dd =  "$p" + '\bin\mysqladmin'
                        & "$dd" -uroot "$d" status 2>$null
                        $i += 1
                        if ($LASTEXITCODE -eq 0) { 
                            $SCRIPT:MYSQLD_jobRunning = $true
                            break
                        }
                        if ($i -le 20) { #40s max.
                          Write-Host -NoNewline "."
                          Start-Sleep -Seconds 2
                        }
                        else {
                            #Error...
                            Write-Warning `t"Tired of waiting on mysqld process"                            $FatalDeplEr = $true
                            break
                        }
                    } while ($true)
                }
                if (!($FatalDeplEr)) {Write-Host `t"MySQL Cluster deployed" }

            } else {
                $FatalDeplEr = $true
                Write-Warning `t"Fatal error, unable to start $dd!"
            }
        } else { Write-Warning `t'Fatal error in deployment prevented tests from running!' }
    } else {
        #Deploy MySQL server locally
        if ($SCRIPT:MySQLServer) {
            $p = Determine_DataDir 'SERVER'

            #Clean up provided ini files.
            $dd = "$p" + '\my-default.ini'
            if (Test-Path $dd) {Remove-Item -Force $dd}

            $LSrNodePort = $null
            #Choice for Port. Check if blocked.
            for ($i = 3300; $i -lt 3500; $i++) {
                if (IsLocalPortListening($i) = "Not listening") {
                    $LSrNodePort = $i
                    break
                }
            }

            #IS there a DATADIR provided?
            if ($SCRIPT:OPTIONDATAD) {
                switch ($SCRIPT:OPTIONDATAD)
                {
                    'COPY_CLEAN' {}
                    'ALWAYS_CLEAN' {
                        $dd = $p + '\data'
                        if (Test-Path $dd) {
                            if ($SCRIPT:MySQLServer -match "^mysql-5\.7") {
                                Write-Warning `t"Removing existing DATA dir."
                                Remove-Item -Path $dd -Recurse -Force
                            } else { #5.6
                                $de = $p + '\data_tg'
                                if (Test-Path $de) {
                                    $dd = $p + '\data'
                                    Write-Warning `t"Removing existing DATA dir."
                                    Remove-Item -Path $dd -Recurse -Force
                                    Write-Warning `t"Copying clean DATA dir."
                                    Copy-Item $de -Destination $dd -Recurse
                                } else {
                                    Write-Warning `t"Cannot remove existing DATA dir. No replacement found."
                                }
                            }
                        }    
                    }
                }
            }
            Write-Host ''
            Set_DATADIR 'SERVER'

            #Test stuff
            if (Test-Path $p)
            {
                if ($LSrNodePort)
                {
                    $dd = "$p" + '\bin\mysqld.exe'
                    if (Test-Path $dd)
                    {
                        $dd = "$p" + '\bin\mysqladmin.exe'
                        if (!(Test-Path $dd))
                        {
                            Write-Warning `t"Fatal error, can not locate $dd"
                            $FatalDeplEr = $true
                        } else {
                            $dd = $p + '\Data'
                            if (!(Test-Path $dd)) {
                                Write-Warning `t"Fatal error, no DATA dir."
                                $FatalDeplEr = $true
                            }
                        }
                    } else {
                        Write-Warning `t"Fatal error, can not locate $dd"
                        $FatalDeplEr = $true
                    }
                } else {
                    Write-Warning `t"Fatal error, can not locate free port in given range"
                    $FatalDeplEr = $true
                }
            } else {
                Write-Warning `t"Fatal error, can not locate $p"
                $FatalDeplEr = $true
            }

            if (!($FatalDeplEr))
            {
                cd $p
                #Start mysqld
                Write-Host ""
                $dd = "$p" + '\bin\mysqld'
                $de = '--port='+$LSrNodePort
                #Start with --no-defaults and add all as command parameters
                $df = '--new' 
                $MYSQLD_job = exec_local_job_ex 'SERVERCL' "$dd" "$SCRIPT:Datadir" "$SCRIPT:Basedir"  "$de" "$df"
                Write-Host ""
                Write-Host -NoNewline "Starting Server "
                #Wait for startup to finish
                $i = 0
                do {
                    $d = '-P' + "$LSrNodePort"
                    $dd =  "$p" + '\bin\mysqladmin'
                    & "$dd" -uroot "$d" status 2>$null
                    $i += 1
                    if ($LASTEXITCODE -eq 0) {
                        $SCRIPT:MYSQLD_jobRunning = $true
                        break
                    }
                    if ($i -le 20) { 
                        Write-Host -NoNewline "."
                        Start-Sleep -Seconds 2
                    }
                    else {
                        #Error...
                        Write-Warning `t"Tired of waiting on mysqld process"                        $FatalDeplEr = $true
                        break
                    }
                } while ($true)
                if (!($FatalDeplEr)) { Write-Host `t"MySQL Server deployed" }
            }
        } else {
            #There is nothing to do... Neither Cluster nor Server are deployed.
            Write-Warning `t"Nothing to do..."
            $FatalDeplEr = $true
            break
        }
    }

    $StopWatch.Stop()
    $CurrentTime = $StopWatch.Elapsed
    Write-Host 'END Deployment stage in' $([string]::Format("{0:d2}:{1:d2}:{2:d2}",
            $CurrentTime.hours, 
            $CurrentTime.minutes, 
            $CurrentTime.seconds))
    $StopWatch = $null
    Write-Host "--------------------------------"
    #Sleep after server is started.
    sleep -Seconds 20

    if (!($FatalDeplEr))
    {
        Write-Host "Run benchmark"
        Write-Host "-------------"`
        #This procedure is checked.
        if ($SCRIPT:Sysbench) {
            #This path is already checked. Both components.
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:Sysbench
            Set-Location $p
            $i = $p + '\sysbench'
            if (Test-Path $i)
            {
                Set-Location $i
                #sysbench.exe is already there?
                $i = gci -Recurse -Filter "sysbench.exe" -file
                if ($i)
                {
                     Set-Location $i[0].DirectoryName
                     $i = gci -Filter "libmysql.dll" -file
                     if ($i) {
                        #Start Sysbench with some params...
                        if ($SCRIPT:MySQLServer) {
                            #Server should be up
                            SetUp_and_Run_SysbenchTest $LSrNodePort $i[0].DirectoryName
                        } else {
                            #Cluster should be up
                            SetUp_and_Run_SysbenchTest $LMGNodePort $i[0].DirectoryName
                        }
                     } else { Write-Warning `t'Cannot locate libmysql.dll!' }
                } else { Write-Warning `t'Cannot locate sysbench.exe!' }
            } else {
                #FATAL: No ...test\sysbenchversion\sysbench directory!
                Write-Warning `t"Cannot locate $i folder!"
            }
        }
        
        if ($SCRIPT:DBT2)
        {
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:DBT2
            Set-Location $p
            if (Test-Path $p)
            {
                #Could be binaries are already there.
                #Client.exe
                #DataGen.exe
                #Driver.exe
                #libmysql.dll
                #Transaction_Test.exe
                $i = gci -Recurse -Filter "DataGen.exe" -file
                if ($i)
                {
                     Set-Location $i[0].DirectoryName
                     $i = gci -Filter "libmysql.dll" -file
                     if ($i) {
                        #Start DBT2 with some params...
                        if ($SCRIPT:MySQLServer) {
                            #Server should be up
                            SetUp_and_Run_DBT2Test $LSrNodePort $i[0].DirectoryName
                        } else {
                            #Cluster should be up
                            SetUp_and_Run_DBT2Test $LMGNodePort $i[0].DirectoryName
                        }
                     } else { Write-Warning `t'Cannot locate libmysql.dll!' }
                } else { Write-Warning `t'Cannot locate DataGen.exe!' }
            } else {
                #FATAL: No ...test\sysbenchversion\sysbench directory!
                Write-Warning `t"Cannot locate $p folder!"
            }
        }

        Write-Host "END Run benchmark"
        Write-Host "-----------------"
    } else { Write-Warning `t'Fatal error in deployment prevented tests from running!' }

    #Place to add other test-runs.


    Write-Host "Clean up"
    Write-Host "--------"
    #Benchmarking processes will run foreground till finished,
    #while Cluster/Server will run in bkgnd so need cleanup.
    if ($host.Name -ne 'ConsoleHost') {$caption = "STOP"} #ISE
    else {$caption = ''} #PS
    $message = "STOP services"
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
    [int]$defaultChoice = 0
    $choiceRTN = $host.ui.PromptForChoice($caption,$message, $choices,$defaultChoice)
    switch($choiceRTN)
    {
        0    { 
                $OUTPUT = 'YES'
                }
        1    {
                $OUTPUT = 'NO'
                }
    }
    $caption = $null
    $message = $null
    $choices = $null
    $defaultChoice = $null
    $choiceRTN = $null
    #Keep the same timestamp label for all resulting files.
    $TSlabel = get-date -uformat "%Y-%m-%d@%H-%M-%S" 

    if ($OUTPUT -eq "YES" )
    {
        $mysqldoutput = $null
        Receive_Mysqld_Job $true

        $OldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        Stop_Mysqld_Job
        $ErrorActionPreference = $OldErrorActionPreference

        if ($SCRIPT:MySQLCluster) {
            #MGMT client command to stop MGMT client AND the data nodes
            #MGMT cluster sh, StartNDB.sh ./ndb_mgm -e 'SHUTDOWN'
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLCluster
            Set-Location $p

            Write-Host `t'Receiving info from mgmt node job before shutting down.'
            #RegEx out pointless info about registry key...
            # NDBMGMT spawns additional jobs!!!
            for ($i = 0; $i -lt $MGMTNode_job.ChildJobs.Count; $i++)
            {   #Ignore eventlog in registry...
                $MGMTNode_job.ChildJobs[$i].Error | Where-Object { $_ -notmatch "EventLog"}
            }

            Receive-Job $MGMTNode_job

            $dd = "$p" + '\bin\ndb_mgm'
            $d = 'localhost:' + "$LNodePort"
            & "$dd" -e SHUTDOWN "$d" 2>$null

            Start-Sleep -Seconds 3

            $MGMTNode_job | Stop-Job
            Remove-Job -Job $MGMTNode_job #|  Where-Object { $_ -notmatch "EventLog"}

            Sleep -Seconds 10

            #Stop NODE processes
            #Get-Process | Where-Object {$_.Name -eq "ndbmtd"} | foreach { $_.Kill() }
            #$script = {Get-Process -name ndbmtd | stop-process -passthru | %{write-host killed pid $_.id}}
            #invoke-command -script $script -computer localhost
            $OldErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "SilentlyContinue"
            $i = Get-Process -name "ndbmtd" | Measure-Object | Select-Object -ExpandProperty Count
            if ($i -eq 0 ) { Write-Host "All data nodes have shut down." }
            else { Write-Host $i 'data nodes are still shutting down.' }
            $ErrorActionPreference = $OldErrorActionPreference

            $p = "$SCRIPT:TarballDir" + '\' + "$SCRIPT:MySQLCluster"
            #reset !!MY!! environment
            $de = "$p" + '\bin\my.cnf'
            if (Test-Path $de) {
                Remove-Item $de
                if ($?) { Write-Warning `t"Removed my.cnf." }
            }
            #Old_Name
            $de = "$p" + '\ndb_data'
            $dd = $TSlabel
            #New_Name
            $dd = 'ndb_data-' + $dd
            Copy-Item $de -Destination $SCRIPT:TarballDir -Recurse -Force
            Rename-Item -Path $SCRIPT:TarballDir'\ndb_data' -NewName $dd -Force

            $OldErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "SilentlyContinue"
            #In case it's still locked...
            Remove-Item -Force -Recurse $de
            if ($?) { Write-Warning `t"Removed old ndb_data." }
            else { Write-Warning `t'Failed to remove old ndb_data.' }
            $ErrorActionPreference = $OldErrorActionPreference

            $de = "$p" + '\data'
            if (Test-Path $de) {
                Remove-Item -Force -Recurse $de
                if ($?) { Write-Warning `t"Removed DATA dir." }
                else { Write-Warning `t"DATA dir NOT removed." }
            }

            if ($SCRIPT:OPTIONDATAD) {
                if ($SCRIPT:OPTIONDATAD -match 'ALWAYS_CLEAN') { $ac = $true }
                else {$ac = $false}
            } else { $ac = $false } #Maybe better to default to Always_Clean?...

            $de = "$p" + '\data'
            $dd = "$p" + '\data_tg'
            if (Test-Path $dd) {
                if (!$ac) {
                    Write-Warning `t"Replacing DATA dir with clean copy."
                    Copy-Item $dd -Destination $de -Recurse
                    Remove-Item -Force -Recurse $dd
                } else {
                    Write-Warning `t"Removing clean DATA dir."
                    Remove-Item -Force -Recurse $dd
                }
            }

        } else {
            #Server cleanup
            $p = $SCRIPT:TarballDir + '\' + $SCRIPT:MySQLServer
            Set-Location $p

            $dd = "$p" + '\bin\mysqladmin'
            $d = '-P' + "$LSrNodePort"
            & "$dd" -uroot "$d" SHUTDOWN 2>$null

            #reset !!MY!! environment
            $de = "$p" + '\bin\my.cnf'
            if (Test-Path $de) {
                Remove-Item $de
                if ($?) { Write-Warning `t"Removed my.cnf." }
            }

            $de = "$p" + '\data'
            if (Test-Path $de) {
                Remove-Item -Force -Recurse $de
                if ($?) { Write-Warning `t"Removed DATA dir." }
                else { Write-Warning `t"DATA dir NOT removed." }
            }

            if ($SCRIPT:OPTIONDATAD) {
                if ($SCRIPT:OPTIONDATAD -match 'ALWAYS_CLEAN') { $ac = $true }
                else {$ac = $false}
            }

            $de = "$p" + '\data'
            $dd = "$p" + '\data_tg'
            if (Test-Path $dd) {
                if (!$ac) {
                    Write-Warning `t"Replacing DATA dir with clean copy."
                    Copy-Item $dd -Destination $de -Recurse
                    Remove-Item -Force -Recurse $dd
                } else {
                    Write-Warning `t"Removing clean DATA dir."
                    Remove-Item -Force -Recurse $dd
                }
            }

        }
        Start-Sleep -Seconds 3
    } else {
        Write-Warning `t"Processes still running"
        #Go back to script directory.
        $Null = Set-Location -Path $PSScriptRoot
        exit 0
    }

    #Once more, do some cleanup. "Job"x means started by me (I do not name jobs).
    Get-Job | Where-Object { ($_.State -eq 'Completed') -and ($_.Name -match "Job") } | Remove-Job

    Write-Host "END Clean up"
    Write-Host "------------"
    
    $Null = Set-Location -Path $SCRIPT:TarballDir #TARBALLDIR
    Write-Host "Saving the console output to file sessiondump.txt."
    #Remove old file.
    if (Test-Path '.\sessiondump.txt') { Remove-Item '.\sessiondump.txt' }
    if ($host.Name -ne 'ConsoleHost')
    {
	    #Running in ISE
	    $psise.CurrentPowerShellTab.ConsolePane.Text >> sessiondump.txt
    } else { 

	    $textBuilder = new-object system.text.stringbuilder
	    # Grab the console screen buffer contents using the Host console API.
	    $bufferWidth = $host.ui.rawui.BufferSize.Width
	    $bufferHeight = $host.ui.rawui.CursorPosition.Y
	    $rec = new-object System.Management.Automation.Host.Rectangle 0,0,($bufferWidth - 1),$bufferHeight
	    $buffer = $host.ui.rawui.GetBufferContents($rec)
	    # Iterate through the lines in the console buffer.
	    for($i = 0; $i -lt $bufferHeight; $i++)
	    {
  		    for($j = 0; $j -lt $bufferWidth; $j++)
  		    {
    			    $cell = $buffer[$i,$j]
    			    $null = $textBuilder.Append($cell.Character)
		    }
  		    $null = $textBuilder.Append("`r`n")
	    }
	    $textBuilder.ToString()  >> sessiondump.txt
    }

    if (Test-Path '.\sessiondump.txt') {
        $de = $SCRIPT:TarballDir + '\sessiondump.txt'
        $dd = $TSlabel
        #New_Name
        $dd = 'sessiondump-' + $dd + '.txt'
        Rename-Item -Path $de -NewName $dd -Force
    }

    if (Test-Path '.\mysqld-output.txt') {
        $de = $SCRIPT:TarballDir + '\mysqld-output.txt'
        $dd = $TSlabel
        #New_Name
        $dd = 'mysqld-output-' + $dd + '.txt'
        Rename-Item -Path $de -NewName $dd -Force
        $mysqldoutput = $dd
    }

    if ($SCRIPT:logfile) {
        if (Test-Path $SCRIPT:logfile) {
            $position = $SCRIPT:logfile.IndexOf(".")
            $de = $SCRIPT:logfile.Substring(0, $position)
            $dd = $TSlabel
            #New_Name
            $dd = $de + '-' + $dd + '.log'
            Rename-Item -Path $SCRIPT:logfile -NewName $dd -Force
        }
    }

    if ($SCRIPT:ArchiveRun) {
        Write-Host 'Preparing the archive of the run.'
        Add-Type -As System.IO.Compression.FileSystem
        #Directories first:
        #Different name format for archive so not to get deleted on restart.
        $dd = $TSlabel
        $dd = $SCRIPT:TarballDir + '\archrun'+ $dd + '.zip'

        dir ($SCRIPT:TarballDir + '\*') | ForEach {
            if ($_.ToString() -match "ndb_data.*@") {
                $de = $_.ToString()
                Write-Host `t'Adding' $de' to the archive of the run.'
                $null = New-ZipFile $dd $de -Append:$true
            }
        }
        # END archiving directories.
        if (Test-Path ($SCRIPT:TarballDir+'\results.csv')) {
            $de = $SCRIPT:TarballDir+'\results.csv'
            Write-Host `t'Adding' $de' to the archive of the run.'
            $null = New-ZipFile $dd $de -Append:$true
        }
        #Archive the rest...
        dir ($SCRIPT:TarballDir + '\*') | ForEach {
            if ($_.ToString() -match "[0-9]@[0-9]") {
                if (!($_ -is [System.IO.DirectoryInfo])) {
                    if (($_.ToString() -match "runlog.*@") -or ($_.ToString() -match "mysqld-output-.*@") -or 
                        ($_.ToString() -match "sessiondump.*@")) {
                        $de = $_.ToString()
                        Write-Host `t'Adding' $de 'to the archive of the run.'
                        $null = New-ZipFile $dd $de -Append:$true
                    }
                }
            }
        }
        Write-Host 'Run archived in' $dd'.'
        #Get-Item $dd
    }
    $Null = Set-Location -Path $SCRIPT:TarballDir #TARBALLDIR
    try { .\results.csv }
    catch { Write-Warning "No results file generated." }

    #if (Test-Path $mysqldoutput) { notepad.exe $mysqldoutput }

    #Go back to script directory.
    $Null = Set-Location -Path $PSScriptRoot
    #Revert to default.
    [console]::TreatControlCAsInput = $false

}