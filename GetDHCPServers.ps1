###Imports ActiveDirectory Module
###Depending on your version of Powershell, you might have to google how to get this module imported perhaps with a different cmdlet
###Download and install RSAT to acquire module availability

import-module activedirectory
###Determines how many days a server can be inactive before the script ignores it. 
###Example, 30 below means only servers that have communicated with the domain controller in the last 30 days will be executed by this loop
$daysinactive = 30
###Variable uses $daysinactive to determine the lastlogondate being used
$time = (Get-Date).Adddays(-($DaysInactive)) 
###Creates an empty array to insert data into
$Array = @()
###Defines which machines are filtered out, example *server* will capture all windows servers.  Remove this filter to scan all machines
$computers = (Get-ADComputer -Filter {OperatingSystem -like '*server*'} -properties lastlogondate) 
#$computers = (Get-ADComputer -Filter {name -like '*dvpmgt03*'} -properties lastlogondate) 

###Loops trhough all $computers returned to the computers variable
Foreach ($Computer in $computers)
{
    
    ###if the server/machine has logged in later than $time (30 days in this case) then the following logic is applied
    if ($Computer.lastlogondate -gt $time)
        {
        ###defines the headers of your table, these can be anything you want
        $LoopArray = "" | Select servername, DHCP, ServerOS
        #$Objects is the return of the DHCP Select on the remote machine
        $Objects=invoke-command -computername $Computer.name -ScriptBlock {& cmd.exe /C ipconfig /all | findstr "DHCP Server"}
        #$Strings is the removal of CMD returned headers that are unneeded, removes 39 characters from the beginning of the output
        $strings =$objects.substring(39)
        #$AllStrings captures all the lines of the DHCP output individually
        $AllStrings += $strings
        #$FilterItems filters out anything that is NOT an IP address
        $FilterItems=$AllStrings -like '*.*.*.*' 
        #Simplifies computer name for later use
        $Computername=$Computer.name
        #Determines how many rows to show out of the DHCP returned array
        $LoopArray.DHCP=$FilterItems[0..1] 
        #Populates Server name into Servername Loop Array field
        $LoopArray.servername=$Computername
        ###Populates the OS version of the Windows server
        $LoopArray.serverOS=(Get-WMIObject -computer $Computer.name win32_operatingsystem).name
        ###Adds the return of the values above to the array outside of the loop
        $Array+=$LoopArray
        Write-host "Interrogating $Computername"
        }
    else
    {
        Write-host "Ignoring $Computername"
    }
}

###Outputs all array values when script has completed, with the header information into a excel type grid
$Array|out-gridview
