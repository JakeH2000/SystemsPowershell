###Imports ActiveDirectory Module
###Depending on your version of Powershell, you might have to google how to get this module imported perhaps with a different cmdlet
import-module activedirectory

###Determines how many days a server can be inactive before the script ignores it. 
###Example, 30 below means only servers that have communicated with the domain controller in the last 30 days will be executed by this loop
$daysinactive = 30
###Variable uses $daysinactive to determine the lastlogondate being used
$time = (Get-Date).Adddays(-($DaysInactive)) 
###Creates an empty array to insert data into
$sqls = @()
###Defines which machines are filtered out, example *server* will capture all windows servers.  Remove this filter to scan all machines
$computers = (Get-ADComputer -Filter {OperatingSystem -like '*server*'} -properties lastlogondate) 

###Loops trhough all $computers returned to the computers variable
Foreach ($a in $computers)
{
    
    ###if the server/machine has logged in later than $time (30 days in this case) then the following logic is applied
    if ($a.lastlogondate -gt $time)
        {
        ###defines the headers of your table, these can be anything you want
        $sql = "" | Select servername, installed, IPaddress, ServerOS
        ###Populates header value "Installed", returns the version of SQL installed
        $sql.installed= get-wmiobject -computer $a.name -class win32_product| select-string -inputobject {$_.name} -pattern "Database Engine Services"
        ###Populates header value "Servername" with the servers name from active directory
        $sql.servername=$a.name
        ###Populates the IP address information from the server by using test-connection to return the servers IP based on the return of test connection
        $sql.ipaddress=(test-connection $a.name -count 1|select ipv4address).ipv4address
        ###Populates the OS version of the Windows server
        $sql.serverOS=(Get-WMIObject -computer $a.name win32_operatingsystem).name
        ###Adds the return of the values above to the array outside of the loop
        $sqls+=$sql
        }
}

###Outputs all array values when script has completed, with the header information into a excel type grid
$sqls|out-gridview

