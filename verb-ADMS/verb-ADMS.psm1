﻿# verb-adms.psm1


  <#
  .SYNOPSIS
  verb-ADMS - ActiveDirectory PS Module-related generic functions
  .NOTES
  Version     : 1.0.7.0
  Author      : Todd Kadrie
  Website     :	https://www.toddomation.com
  Twitter     :	@tostka
  CreatedDate : 12/26/2019
  FileName    : verb-ADMS.psm1
  License     : MIT
  Copyright   : (c) 12/26/2019 Todd Kadrie
  Github      : https://github.com/tostka
  AddedCredit : REFERENCE
  AddedWebsite:	REFERENCEURL
  AddedTwitter:	@HANDLE / http://twitter.com/HANDLE
  REVISIONS
  * 12/26/2019 - 1.0.0.0
  # 11:51 AM 5/6/2019 Sync-AD():moved from tsksid-incl-ServerApp.ps1
  # 1:23 PM 1/8/2019 load-ADMS:add an alias to put in verb-noun name match with other variants
  # 11:33 AM 11/1/2017 initial vers
  .DESCRIPTION
  verb-ADMS - ActiveDirectory PS Module-related generic functions
  .PARAMETER  PARAMNAME
  PARAMDESC
  .PARAMETER  Mbx
  Mailbox identifier [samaccountname,name,emailaddr,alias]
  .PARAMETER  Computer
  Computer Name [-ComputerName server]
  .PARAMETER  ServerFqdn
  Server Fqdn (24-25char) [-serverFqdn lynms650.global.ad.toro.com)] 
  .PARAMETER  Server
  Server NBname (8-9chars) [-server lynms650)]
  .PARAMETER  SiteName
  Specify Site to analyze [-SiteName (USEA|GBMK|AUSYD]
  .PARAMETER  Ticket
  Ticket # [-Ticket nnnnn]
  .PARAMETER  Path
  Path [-path c:\path-to\]
  .PARAMETER  File
  File [-file c:\path-to\file.ext]
  .PARAMETER  String
  2-30 char string [-string 'word']
  .PARAMETER  Credential
  Credential (PSCredential obj) [-credential ]
  .PARAMETER  Logonly
  Run a Test no-change pass, and log results [-Logonly]
  .PARAMETER  FORCEALLPINS
  Reset All PINs (boolean) [-FORCEALLPINS:True]
  .PARAMETER Whatif
  Parameter to run a Test no-change pass, and log results [-Whatif switch]
  .PARAMETER ShowProgress
  Parameter to display progress meter [-ShowProgress switch]
  .PARAMETER ShowDebug
  Parameter to display Debugging messages [-ShowDebug switch]
  .INPUTS
  None
  .OUTPUTS
  None
  .EXAMPLE
  .EXAMPLE
  .LINK
  https://github.com/tostka/verb-ADMS
  #>


$script:ModuleRoot = $PSScriptRoot ;
$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem $script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======



#*------v Get-AdminInitials.ps1 v------
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

#*------^ Get-AdminInitials.ps1 ^------

#*------v get-SiteMbxOU.ps1 v------
function get-SiteMbxOU {
    <#
    .SYNOPSIS
    get-SiteMbxOU() - passed a Toro 3-letter site code, it returns the OU dn for that site's Email-related SecGrps (directly below Site ou)
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-03
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 10:57 AM 4/3/2020 cleanup to modularize, added verbose sup, updated CBH
    # 2:51 PM 3/6/2017 add -Resource param to steer to 'Email Resources'
    # 12:36 PM 2/27/2017 fixed to cover breaks frm AD reorg OU name changes, Generics are all now in a single OU per site
    # 11:56 AM 3/31/2016 port to get-SiteMbxOU; validated that latest round of updates are still functional; minor cleanup
    * 11:31 AM 3/16/2016 debugged to function.
    * 1:34 PM 3/15/2016 adapted SecGrp OU lookup to MailContact OU
    * 11:05 AM 10/7/2015 initial vers
    .DESCRIPTION
    get-SiteMbxOU() - passed a standard 3-letter site code, it returns the OU dn for that site's Email-related SecGrps (directly below Site ou)
    .PARAMETER  SiteCode
    Toro 3-letter site code
    .PARAMETER  Generic
    Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).
    .PARAMETER  Resource
    Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]
    .EXAMPLE
    $OU=get-SiteMbxOU -Sitecode SITE
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU
    .LINK
    #>
    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$True,HelpMessage="Specify the Toro 3-letter site code upon which to Query[LYN]")]
        [string[]]$Sitecode
        ,[parameter(Mandatory=$false,HelpMessage="Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).[-Generic]")]
        [string[]]$Generic
        ,[parameter(Mandatory=$false,HelpMessage="Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]")]
        [string[]]$Resource
    ) ;  # PARAM-E
    $verbose = ($VerbosePreference -eq "Continue") ; 
    if($Generic){
        $FindOU="^OU=Generic Email Accounts"
    } elseif($Resource){
        $FindOU="^OU=Email Resources"
    } else {
        $FindOU="^OU=Users"
    } ;
    $error.clear() ;
    TRY {
        $OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU).*,OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
        If($OUPath -isnot [string]){      # post-verification to ensure we've got a single OU spec
            write-error "$( (get-date).ToString("HH:mm:ss") ):WARNING AD OU SEARCH SITE:$($InputSplat.SiteCode), FindOU:$($FindOU), FAILED TO RETURN A SINGLE OU...";
            $OUPath | select distinguishedname ;
            write-error "$((get-date).ToString('HH:mm:ss')):EXITING!";
            Exit ;
        } ;
        write-output $OUPath
    } CATCH {
        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
    } ; 
}

#*------^ get-SiteMbxOU.ps1 ^------

#*------v load-ADMS.ps1 v------
function load-ADMS {
    <#
    .SYNOPSIS
    load-ADMS - Checks local machine for registred AD MS, and loads if not loaded
    .NOTES
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    * 9:57 AM 11/26/2019 added $Cmdlet param, and ADPS_LoadDefaultDrive suppression evari, to speed up or permit selective loads of targeted cmdlests, stipped down the 'load every module' code to just target the single mod
    # 1:23 PM 1/8/2019 load-ADMS:add an alias to put in verb-noun name match with other variants
    vers: 10:23 AM 4/15/2015 fmt doc cleanup
    vers: 10:43 AM 1/14/2015 fixed return & syntax expl to true/false
    vers: 10:20 AM 12/10/2014 moved commentblock into function
    vers: 11:40 AM 11/25/2014 adapted to Lync
    ers: 2:05 PM 7/19/2013 typo fix in 2013 code
    vers: 1:46 PM 7/19/2013
    .DESCRIPTION
    load-ADMS - Checks local machine for registred AD MS, and loads if not loaded
    .INPUTS
    None.
    .OUTPUTS
    Outputs $True/False load-status
    .EXAMPLE
    $ADMTLoaded = load-ADMS ; Write-Debug "`$ADMTLoaded: $ADMTLoaded" ;
    .EXAMPLE
    $ADMTLoaded = load-ADMS -Cmdlet get-aduser,get-adcomputer ; Write-Debug "`$ADMTLoaded: $ADMTLoaded" ;
    Load solely the specified cmdlets from ADMS
    .EXAMPLE
    # load ADMS
    $reqMods+="load-ADMS".split(";") ;
    if( !(check-ReqMods $reqMods) ) {write-error "$((get-date).ToString("yyyyMMdd HH:mm:ss")):Missing function. EXITING." ; exit ;}  ;
    write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):(loading ADMS...)" ;
    load-ADMS | out-null ;
    #load-ADMS -cmdlet get-aduser,Set-ADUser,Get-ADGroupMember,Get-ADDomainController,Get-ADObject,get-adforest | out-null ;
    Demo a load from the verb-ADMS.ps1 module, with opt specific -Cmdlet set
    #>
    PARAM(
        [Parameter(HelpMessage="Specifies an array of cmdlets that this cmdlet imports from the module into the current session. Wildcard characters are permitted[-Cmdlet get-aduser]")]
        [ValidateNotNullOrEmpty()]$Cmdlet
    ) ;
    # focus specific cmdlet loads to SPEED them UP!
    $tMod = "ActiveDirectory" ;
    $ModsReg=Get-Module -Name $tMod -ListAvailable ;
    $ModsLoad=Get-Module -name $tMod ;
    $pltAD=@{Name=$tMod ; ErrorAction="Stop" } ;
    if($Cmdlet){$pltAD.add('Cmdlet',$Cmdlet) } ;
        if ($ModsReg) {
        if (!($ModsLoad)) {
            $env:ADPS_LoadDefaultDrive = 0 ;
            import-module @pltAD;
            return $TRUE;
        } else {
            return $TRUE;
        } # if-E ;
    } else {
        Write-Error {"$((get-date).ToString('HH:mm:ss')):($env:computername) does not have AD Mgmt Tools installed!";};
        return $FALSE
    } # if-E ;
} #*----------^END Function load-ADMS ^----------
# 1:23 PM 1/8/2019 load-ADMS:add an alias to put in verb-noun name match with other variants
if(!(get-alias | Where-Object{$_.name -like "connect-ad"})) {Set-Alias 'connect-ad' -Value 'load-ADMS' ; }

#*------^ load-ADMS.ps1 ^------

#*------v Sync-AD.ps1 v------
Function Sync-AD { 
    # let's you trigger a replication between DCs. This function needs further tweaks for re-usability
    # from dsoldow's https://github.com/dsolodow/IndyPoSH/blob/master/Profile.ps1
    [CmdletBinding()]
    Param (
    [parameter(Mandatory = $false,Position=0)] [String]$DestinationDC = 'centralDC',
    [parameter(Mandatory = $false,Position=1)] [String]$SourceDC = 'localDC',
    [parameter(Mandatory = $false,Position=2)] [String]$DirectoryPartition = 'YourDomainName'
    ) ; 
    Get-AdminCred ; 
    Start-Process -Credential $admin -FilePath repadmin -ArgumentList "/replicate $DestinationDC $SourceDC $DirectoryPartition" -WindowStyle Hidden ; 
}

#*------^ Sync-AD.ps1 ^------

#*------v Validate-Password.ps1 v------
Function Validate-Password{
    <#
    .SYNOPSIS
    Validate-Password - Validate Password complexity, to Base AD Complexity standards
    .NOTES
    Version     : 1.0.2
    Author      : Shay Levy & commondollars
    Website     :	http://scriptolog.blogspot.com/2008/01/validating-password-strength.html
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-03
    FileName    : Function Validate-Password.ps1
    License     : (none specified)
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 11:43 AM 4/6/2016 hybrid of Shay Levy's 2008 post, and CommonDollars's 2013 code
    .DESCRIPTION
    Validate-Password - Validate Password complexity, to Base AD Complexity standards
    Win2008's 2008's stnd: Passwords must contain characters from 3 of the following 4 cats:
    * English uppercase characters (A through Z).
    * English lowercase characters (a through z).
    * Base 10 digits (0 through 9).
    * Non-alphabetic characters (for example, !, $, #, %).
    (also samaccountname must not appear within the pw, and displayname split on spaces, commas, semi's etc cannot appear as substring of pw - neither tested with this code)
    .PARAMETER  pwd
    Password to be tested
    .PARAMETER  minLength
    Minimum permissible Password Length
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Outputs $true/$false to pipeline
    .EXAMPLE
    [Reflection.Assembly]::LoadWithPartialName("System.Web")|out-null ;
    Do { $password = $([System.Web.Security.Membership]::GeneratePassword(8,2)) } Until (Validate-Password -pwd $password ) ;
    Pull and validate passwords in a Loop until an AD Complexity-compliant password is returned.
    .EXAMPLE
    if (Validate-Password -pwd "password" -minLength 10
    Above validates pw: Contains at least 10 characters, 2 upper case characters (default), 2 lower case characters (default), 3 numbers, and at least 3 special characters
    .LINK
    http://scriptolog.blogspot.com/2008/01/validating-password-strength.html
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,HelpMessage="Password to be tested[-Pwd 'string']")]
        [ValidateNotNullOrEmpty()]
        [string]$pwd,
        [Parameter(HelpMessage="Minimum permissible Password Length (defaults to 8)[-minLen 10]")]
        [int]$minLen=8
    ) ;
    $IsGood=0 ;
    if($pwd.length -lt $minLen) {write-output $false; return} ;
    if(([regex]"[A-Z]").Matches($pwd).Count) {$isGood++ ;} ;
    if(([regex]"[a-z]").Matches($pwd).Count) {$isGood++ ;} ;
    if(([regex]"[0-9]").Matches($pwd).Count) {$isGood++ ;} ;
    if(([regex]"[^a-zA-Z0-9]" ).Matches($pwd).Count) {$isGood++ ;} ;
    If ($isGood -ge 3){ write-output $true ;  } else { write-output $false} ;
}

#*------^ Validate-Password.ps1 ^------

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function Get-AdminInitials,get-SiteMbxOU,load-ADMS,Sync-AD,Validate-Password -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxsqBSJapCU+IkDshMaoM0lNF
# Z8qgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTUgD8/
# oh1JrjKeYh20kjfZZgEz5zANBgkqhkiG9w0BAQEFAASBgKdcTbl5aBScedxqCuTv
# 2T+nhvxXTmOvXvtxmmEKT0Laj7dUz5gyZ3glrFVdxyUgHNmm/TRgMgxpCiblTr94
# I0+85qrFmQsSIWOwGamSf6QldZEEOqKGwUxT3SP8CQs4PZZBRrBgHPysGAl79ULn
# 9GlHXXvsieePQXrUqMl9lP2s
# SIG # End signature block
