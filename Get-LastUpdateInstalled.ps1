<#
    .SYNOPSIS
    This script shows how long it has been since the last time windows updates were installed.

    .DESCRIPTION
    This script finds the installation date of the last update run and outputs an error if it has been more than 45 days.  It accepts a list or a single.

    When run, it will ask for a regular user account and a domain admin account (called "-a" in this script).  It will try the regular user account first, then the domain admin account if the regular account fails.

    .EXAMPLE
    Get-LastUpdateInstalled -ServerList comp1,comp2,comp3
#>
Function Get-LastUpdateInstalled()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$ServerList
        )

    $Creds = Get-Credential -Message "Enter basic account"
    $AdminCreds = Get-Credential -Message "Enter -a account"
    $List = $ServerList.split(",").Trim(" ")

    foreach ($Server in $List)
    {
        $LastInstalledHotfix = $null
        $TodayDate = $null
        $TodayDateFormatted = $null
        $LastInstalledHotfixFormatted = $null
        try {
            $Session = new-pssession -ComputerName $Server -Credential $Creds -ErrorAction SilentlyContinue
            $LastInstalledHotfix = Invoke-Command -Session $Session {get-hotfix | select InstalledOn | sort InstalledOn -Descending | select -First 1}
            $TodayDate = get-date -Format g
            $TodayDateFormatted = [datetime]$TodayDate
            $LastInstalledHotfixFormatted = [datetime]$LastInstalledHotfix.InstalledOn
        }
        catch {
            try {
                $Session = new-pssession -ComputerName $Server -Credential $AdminCreds -ErrorAction SilentlyContinue
                $LastInstalledHotfix = Invoke-Command -Session $Session {get-hotfix | select InstalledOn | sort InstalledOn -Descending | select -First 1}
                $TodayDate = get-date -Format g
                $TodayDateFormatted = [datetime]$TodayDate
                $LastInstalledHotfixFormatted = [datetime]$LastInstalledHotfix.InstalledOn
            }
            catch {
                Write-Output "Can't connect to $Server"
            }
        }


        $DateDiff = $TodayDateFormatted - $LastInstalledHotfixFormatted
        $NumDays = $DateDiff.Days
        If ($NumDays -gt 45)
        {
            Write-Output "Updates not run on $Server in $NumDays days"
        }
        Else
        {
            Write-Output "$Server up to date"
        }
    }
}
