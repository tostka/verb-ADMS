#*------v Function Get-AdminInitials v------
function Get-AdminInitials {
    <#
    .SYNOPSIS
    Get-AdminInitials - simple function to retrieve the admin's initials from the current environment's UserName e-vari (uses ADMS to resolve samaccountname to name value from AD)
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 10:32 AM 4/3/2020 Get-AdminInitials:1.01: added to verb-adms, updated CBH
    # 11:02 AM 6/13/2019 fixed S- SID rename
    # 11:28 AM 3/31/2016 validated that latest round of updates are still functional
    vers: 2:35 PM 3/15/2016: fixed, was returning only the middle initial in ISE
    vers: 12:35 PM 12/18/2015: added a psv2 compat version
    vers: 10:47 AM 10/6/2015 added pshelp
    vers: 11:06 AM 8/12/2015 thrown together
    .DESCRIPTION
    Get-AdminInitials - simple function to retrieve the admin's initials from the current environment's UserName e-vari (uses ADMS to resolve samaccountname to name value from AD)
    .EXAMPLE
    $AdminInits=get-AdminInitials ;
    Assign current logon to the vari $AdminInits
    .LINK
    #>
    # split & concat the first letter of each name in AD user 'Name' value.
    ((get-aduser $($env:username)).name.split(" ")|%{$_.replace("S-","").substring(0,1)}) -join "" | write-output ;
}
#*------^ END Function Get-AdminInitials ^------