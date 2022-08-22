#This variable contains black list username
$black_list = "deepj"

#This variable is used to set a uptime threashold
$uplimit = 2

#this variables gets todays date to put it in log file name
$todaysdate = Get-Date -Format "ddmmyyyy"

#this variable contains locatio where log file is to be created
$logloc = "C:\Log_" + $todaysdate + ".txt"


#this function will return a array of hostname taken from a file
function get_hostlist {
    param([String]$path)
    [string[]]$arrayFromFile = Get-Content -Path '$path'
    return $arrayFromFile
}

#This function is used to create a log file
function create_LOG {
    param([String]$path)
    New-Item $path
    echo "Log File created"
    echo "----------------"
}
#This function is used to insert data into log file
function Add_log([String]$file, [String]$data) {
    echo "----------------"    
    echo "Adding content to"+$file+"."
    Add-Content $file -Value "$data"
    echo "----------------"

}
#This function returns true of a device in the network is pingable else it returns false
function test_conn {
    param($computername)
    return (test-connection $computername -count 1 -quiet)
}


#this function will get uptime of a computer
function Uptime {
    [CmdletBinding()]
    param ([string]$ComputerName)

    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computername
    $diff = $os.ConvertToDateTime($os.LocalDateTime) – $os.ConvertToDateTime($os.LastBootUpTime)
    $diff.Days


}

#This function checks which user is logged on a system
function loggedin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [string[]]$computername
    )

    foreach ($pc in $computername) {
        $logged_in = (gwmi win32_computersystem -COMPUTER $pc).username
        $name = $logged_in.split("\")[1]
        $name
    }
}

#Main function that calls everyother functions
function startfun {
    param([String]$path)
    echo "reading hostlist"
    $host_list = get_hostlist $path
    echo "creating logfile"
    New-Item $logloc
    echo "Starting loop"
    foreach ($cn in $host_list) {
        $res = Get-LoggedIn $cn
        #this will add a hosts name in the log if its not pingable
        if ($res -eq $false) {
            $temp = "Connection prob to " + $cn
            Add_log -file "$logloc" -data $temp
        }
        #this will add a hosts name in the log if a blacklisted device is logedin
        $BL = loggedin $cn
        if ($BL -eq $black_list) {
            $temp2 = "Blacklist user " + $black_list + " connected at " + $cn
            Add_log -file "$logloc" -data $temp2
        }
        #This will add a hosts name if its logon time is more than a given amount
        $ut = Uptime $cn
        if ($ut -ge $uplimit) {
            $temp3 = "Logon time exceded of " + $cn
            Add_log -file "$logloc" -data $temp3
        }
    }
}

startfun -path "C:\hostlist.txt"