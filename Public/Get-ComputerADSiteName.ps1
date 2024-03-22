# Get-ComputerADSiteName.ps1

#*------v Function Get-ComputerADSiteNameName v------
function Get-ComputerADSiteName{
    <#
    .SYNOPSIS
    Get-ComputerADSiteName - Return Active Directory site name for a remote Windows computer name (leverages the OS nltest command)
    .NOTES
    Version     : 0.1.2
    Author      : Shay Levy
    Website     : https://powershellmagazine.com/2013/04/23/pstip-get-the-ad-site-name-of-a-computer/
    Twitter     : @ShayLevy
    CreatedDate : 2024-03-13
    FileName    : Get-ComputerADSiteName.ps1
    License     : (nond asserted)
    Copyright   : (nond asserted)
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,Site,Computer
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.comgci 
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 9:22 AM 3/13/2024 1.1.1 updated: add CBH, expand error handling, validate nltest is avail, tagged outputs w explicit w-o
    * 11/12/23 v1.1 - PowershellMagazine.com posted article 
    .DESCRIPTION
    Get-ComputerADSiteName - Return Active Directory site name for a remote Windows computer name (leverages the OS nltest command)

    Minor tweaking - add CBH, expand error handling, validate nltest is avail -  to Shay Levy's simple function for obtaining remote computer AD SiteName by leveraging the nltest cmdline util

    [#PSTip Get the AD site name of a computer](https://powershellmagazine.com/2013/04/23/pstip-get-the-ad-site-name-of-a-computer/)

    Stripped down portable/pastable copy (no CBH, e.g. Shay Levy's stripped down exmple w minor upgrades from this func; still pasteable into other scripts wo tweaking)

        ```Powershell
        function Get-ComputerADSiteName{
            [CmdletBinding()]
            Param(
                [Parameter(Position = 0, ValueFromPipeline = $true,HelpMessage="Computername for site lookup")]
                    [string]$ComputerName = $Env:COMPUTERNAME        
            ) ; 
            BEGIN { TRY{get-command nltest -ea STOP | out-null}CATCH{write-warning "missing dependnant nltest util!" ; break }} ;
            PROCESS {
                write-verbose $ComputerName ;
	            $site = nltest /server:$ComputerName /dsgetsite 2>$null ; 
	            if($LASTEXITCODE -eq 0){$site[0].trim() | write-output } else {write-warning "Unable to run  nltest /server:$($ComputerName) /dsgetsite successfully" } ; 
            } ; 
        } ; 

        ```
       
    .PARAMETER  Computername
    Computername for site lookup
    Defaults to %COMPUTERNAME%
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    String AD SiteName
    .EXAMPLE
    PS>Get-ComputerADSiteName -ComputerName PC123456789
        
        EULON01

    Demo resolution of computername to sitename
    .EXAMPLE
    'Server1','Server2' | Get-ComputerADSiteName -verbose

        VERBOSE: Server1
        Site1
        VERBOSE: Server2
        Site2

    Demo resolution of array of computernames through pipeline, with verbose output
    .LINK
    https://powershellmagazine.com/2013/04/23/pstip-get-the-ad-site-name-of-a-computer/
    .LINK
    https://gist.github.com/gbdixg/5cd6ea0c984278b08b36260ada0e3f9c
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $true,HelpMessage="Computername for site lookup")]
            [string]$ComputerName = $Env:COMPUTERNAME        
    ) ; 
    BEGIN { TRY{get-command nltest -ea STOP | out-null}CATCH{write-warning "missing dependnant nltest util!" ; break }} ;
    PROCESS {
        write-verbose $ComputerName ;
	    $site = nltest /server:$ComputerName /dsgetsite 2>$null ; 
	    if($LASTEXITCODE -eq 0){$site[0].trim() | write-output } else {write-warning "Unable to run  nltest /server:$($ComputerName) /dsgetsite successfully" } ; 
    } ; 
}; 
#*------^ END Function Get-ComputerADSiteName ^------