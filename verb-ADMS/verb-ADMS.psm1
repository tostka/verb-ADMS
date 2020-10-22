﻿# verb-adms.psm1


  <#
  .SYNOPSIS
  verb-ADMS - ActiveDirectory PS Module-related generic functions
  .NOTES
  Version     : 1.0.17.0
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

#*------v get-ADRootSiteOUs.ps1 v------
function get-ADRootSiteOUs {
    <#
    .SYNOPSIS
    get-ADRootSiteOUs() - Retrieves the Name ('SiteCode') & DistinguishedName for all first-level Site OUs (filters on ^OU=(\w{3}|PACRIM))
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-10
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 8:24 AM 4/10/2020 init
    .DESCRIPTION
    get-ADRootSiteOUs() - Retrieves the 'Office' Site OUs (filters on ^OU=(\w{3}|PACRIM))
    .OUTPUT
    Returns an object containing the Name and DN of all matching OUs
    .EXAMPLE
    $RootOUs=get-ADRootSiteOUs 
    Retrieve the Name & DN for all OUs
    .LINK
    #>
    [CmdletBinding()]
    PARAM (
        
    ) ;  # PARAM-E
    $verbose = ($VerbosePreference -eq "Continue") ; 
    $error.clear() ;
    $rgxRootSiteOUs='^OU=(\w{3}|PACRIM),DC=global,DC=ad,DC=toro,DC=com' ; 
    TRY {
        $OUs= Get-ADOrganizationalUnit -server global.ad.toro.com  -LDAPFilter '(DistinguishedName=*)' -SearchBase 'DC=global,DC=ad,DC=toro,DC=com' -SearchScope OneLevel |?{$_.DistinguishedName -match $rgxRootSiteOUs} | select Name,DistinguishedName ;
        write-output $OUs
    } CATCH {
        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Continue #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
    } ; 
}

#*------^ get-ADRootSiteOUs.ps1 ^------

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

#*------v mount-ADForestDrives.ps1 v------
function mount-ADForestDrives {
    <#
    .SYNOPSIS
    mount-ADForestDrives() - Collect XXXMeta['ADForestName']'s and mount usable PSDrive objects for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest)
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-09-03
    FileName    : mount-ADForestDrives
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,CrossForest
    AddedCredit : Raimund (fr social.technet.microsoft.com comment)
    AddedWebsite: https://social.technet.microsoft.com/Forums/en-US/a36ae19f-ab38-4e5c-9192-7feef103d05f/how-to-query-user-across-multiple-forest-with-ad-powershell?forum=ITCG
    AddedTwitter:
    REVISIONS
    # 12:39 PM 10/22/2020 fixed lack of persistence - can't use -persist, have to use Script or Global scope or created PSD evaps on function exit context.
    # 3:02 PM 10/21/2020 debugged to function - connects fr TOR into TOR,TOL & CMW wo errors fr laptop, updated/expanded CBH examples; fixed missing break in OP_SIDAcct test
    # 7:59 AM 10/19/2020 added pretest before import-module
    4:11 PM 9/8/2020 building into verb-ADMS ; debugged through to TOR function, need fw access open on ports, to remote forest dc's: 5985 (default HTTP min), 5986 (HTTPS), 80 (pre-win7 http variant), 443 (pre-win7 https variant), 9389 (AD Web Svcs)
    * 10:29 AM 9/3/2020 init, still WIP, haven't fully debugged to function
    .DESCRIPTION
    mount-ADForestDrives() - Collect XXXMeta['ADForestName']'s and mount usable PSDrive objects for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest)
    Borrowed concept of a pre-configured array of $forests from Raimund's post.
    .PARAMETER TorOnly
    Switch to limit test to local 'TOR' forest [-TorOnly]
    .PARAMETER Scope
    New PSDrive Scope specification [Script|Global] (defaults Global, no scope == disappears on script exit) [-Scope Script]")]
    -scope:Script: PSDrive persists for life of script run (Minimum, otherwise the PSDrive evaporates outside of creating function)
    -scope:Global: Persists in global environment (note the normal -Persist variable doesn't work with AD PSProvider
    .PARAMETER whatIf
    Whatif SWITCH  [-whatIf]
    .OUTPUT
    Returns objects to pipeline, containing the Name and credential of PSDrives configured
    .EXAMPLE
    $ADPsDriveNames = mount-ADForestDrives ;
    $result = $ADPsDriveNames | ForEach-Object {
        write-verbose "Querying Forest via PsDrive:$($_.Name) w Cred:$($_.Username)"
        Set-Location -Path "$($_.Name):" ;
        Get-ADUser -Identity administrator ;
    } ;
    # cleanup the drives & dump results
    $ADPsDriveNames |  Remove-PSDrive -Force ;
    Query and mount AD PSDrives for all Forests configured by XXXMeta.ADForestName variables, then run get-aduser for the administrator account
    .EXAMPLE
    $ADPsDriveNames = mount-ADForestDrives ; 
    $global:ADPsDriveNames |%{"==$($_.name):`t($($_.username))" ; test-path "$($_.name):" } ; 
    if($ADForestDrives){$ADForestDrives.Name| Remove-PSDrive -Name $_.Name -Force } ;
    Mount psdrives, then validate & echo their access, then remove the PSdrives
    .EXAMPLE
    # to access AD in a remote forest: resolve the ADForestName to the equiv PSDriveName, and use Set-Location to change context to the forest
    Set-Location -Path "$(($ADForestDrive |?{$_.Name -eq (gv -name "$($TenOrg)Meta").value.ADForestName.replace('.','')).Name):" ;
    get-aduser -id XXXX ; 
    #... 
    # at end of script, cleanup the mappings:
    if($ADForestDrives){$ADForestDrives.Name| Remove-PSDrive -Name $_.Name -Force } ;
    .EXAMPLE
    # to access AD in a remote forest: use the returned PSDrive name for the proper forest with Set-Location to change context to the forest
    Set-Location -Path adtorocom ;
    get-aduser -id XXXX ; 
    .LINK
    https://github.com/tostka/verb-adms
    #>
    #Requires -Version 3
    #requires -PSEdition Desktop
    #Requires -Modules ActiveDirectory
    #Requires -RunasAdministrator
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage = "Switch to limit test to local 'TOR' forest [-TorOnly]")]
        [switch] $TorOnly,
        [Parameter(HelpMessage = "New PSDrive Scope specification [Script|Global] (defaults Global, no scope == disappears on script exit) [-TorOnly]")]
        [ValidateSet('Script','Global')]
        [string] $Scope='Global',
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        $rgxDriveBanChars = '[;~/\\\.:]' ; # ;~/\.:
    }
    PROCESS {
        $error.clear() ;

        $forests = @{} ;

        $globalMetas = get-variable  | Where-Object {$_.name -match '^\w{3}Meta$' -AND $_.visibility -eq 'Public' -ANd $_.value } ;

        if ($TorOnly){
            write-verbose "-torOnly specified, restricting config to TOR forest only"
            $globalMetas = $globalMetas | Where-Object { $_.value.o365_Prefix -eq 'TOR' } ;
        }

        # predetect context/role:
        foreach ($globalMeta in $globalMetas) {
            $smsg = "(checking:$(($globalMeta.value)['o365_Prefix']):acct context)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            if($globalMeta.value.OP_ESvcAcct){
                #if($env:username -eq $globalMeta.value.OP_ESvcAcct.split('\')[1]) {
                if("$($env:userdomain)\$($env:username)" -eq $globalMeta.value.OP_ESvcAcct) {
                    $userRole = 'ESvc' ; 
                    break ; 
                } 
            } ;
            if($globalMeta.value.OP_LSvcAcct){
                #if("$($env:userdomain)\$($env:username)" -eq "$($globalMeta.value.OP_LSvcAcct.split('\')[1]) {
                if("$($env:userdomain)\$($env:username)" -eq $globalMeta.value.OP_LSvcAcct) {
                    # script is running under svc acct UserRoles
                    $userRole = 'LSvc' ; 
                    break ; 
                } ;
            } ;
            if($globalMeta.value.OP_SIDAcct){
                #if($env:username -eq $globalMeta.value.OP_SIDAcct.split('\')[1] ){
                if("$($env:userdomain)\$($env:username)" -eq $globalMeta.value.OP_SIDAcct){
                    $userRole = 'SID' ; 
                    break ; 
                } ; 
            } ; 
        } ;  # loop-E

        if($userrole){
            $smsg = "($($env:username): Detected `$UserRole:$($UserRole))" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } else { 
                throw "Unrecognized local logon: $($env:userdomain)\$($env:username)!" ; 
        } ; 

        foreach ($globalMeta in $globalMetas) {

            $TenOrg = $legacyDomain = $prefCred = $null ;
            $TenOrg = ($globalMeta.value)['o365_Prefix'] ;
            if($TenOrg -eq 'VEN'){
                #Stop
            } ;
            
            if($legacyDomain = ($globalMeta.value)['legacyDomain']){
                <#
                switch ($TenOrg) {
                    "TOL" {$prefCred = "credTOLSID" }
                    "TOR" {$prefCred = "credTORSID" }
                    "CMW" {$prefCred = "credCMWSID" }
                    # no curr onprem grants
                    "VEN" {$prefCred = "" }
                    default {
                        throw "Unrecoginzed `$TenOrg!:$($TenOrg)"
                    }
                } ;
                #>
                # use $prefCred=get-HybridOPCredentials -TenOrg $TenOrg -verbose -userrole SID ;
                # use $prefCred=get-TenantCredentials -TenOrg $TenOrg -verbose -userrole SID ;
            
            
                $adminCred = $ForName = $null ;
                $adminCred=get-HybridOPCredentials -TenOrg $TenOrg -verbose -userrole $userRole ; 
                if($adminCred){
                    #$adminCred = (Get-Variable -name $($prefCred)).Value ;
                    $ForestSName = (Get-Variable  -name "$($TenOrg)Meta").value.ADForestName ;
                    $smsg = "Processing forest:$($TenOrg):$($legacyDomain)::$($ForestSName)::$($adminCred.username)";
                    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    $forests.add($ForestSName,$adminCred) ;
                }else {
                    $smsg = "*SKIP*:Processing forest:$($TenOrg):::(UNCONFIGURED)";
                    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                } ;
            } else { 
                 $smsg = "*SKIP*:Processing forest:$($TenOrg):::(no `$$($TenOrg)Meta.LegacyDomain value configured)"; ; 
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } ; 
 
        } ; # loop-E

        if(-not(get-module ActiveDirectory)){
            # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
            if($VerbosePreference = "Continue"){
                $VerbosePrefPrior = $VerbosePreference ;
                $VerbosePreference = "SilentlyContinue" ;
                $verbose = ($VerbosePreference -eq "Continue") ;
            } ; 
            Import-Module -Name ActiveDirectory -Verbose:($VerbosePreference -eq 'Continue') ; 
            # reenable VerbosePreference:Continue, if set, during mod loads 
            if($VerbosePrefPrior -eq "Continue"){
                $VerbosePreference = $VerbosePrefPrior ;
                $verbose = ($VerbosePreference -eq "Continue") ;
            } ; 
        } ; 

        foreach ($forestShortName in $forests.keys) {
        #foreach ($forest in $forests) {
            TRY {
                $forestDN = (Get-ADRootDSE -Server $forestShortName).defaultNamingContext ;
                <# New-PSDrive -Name -PSProvider -Root -Description -Scope -Persist
                use -Persist, or it will immediately close
                from within scripts, to have it persist outside of the script use -scope global
                #>

                # another expl: New-PSDrive -Name "RemoteAD" -PSProvider ActiveDirectory -root $Root -server $server -Scope Script
                # Note Scope is Script.  If not set, disappears outside of function.  Can set to Global

                $pltNpsD=@{
                    Name=($forestShortName -replace $rgxDriveBanChars) ;
                    Root=$forestDN ;
                    PSProvider='ActiveDirectory' ;
                    Credential =$forests[$forestShortName].cred ; 
                    Server=$forestShortName ;
                    #Persist=$true ; # throws error: Error Message: When you use the Persist parameter, the root must be a file system location on a remote computer.
                    Scope=$Scope ;
                    whatif=$($whatif);
                }

                #Remove drive if it pre-exists
                if (Test-Path "$($pltNpsD.Name):"){
                    if((get-location).path -like "$($pltNpsD.Name):*"){
                        set-location c: ;   
                    } ; 
                    Remove-PSDrive $pltNpsD.Name ;
                };

                $smsg = "Creating AD Forest PSdrive:`nNew-PSDrive w`n$(($pltNpsD|out-string).trim())" ;
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $bRet = New-PSDrive @pltNpsD ;
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;


            if ($bRet) {
                $retHash = @{
                    Name     = $bRet.Name ;
                    UserName = $forests[$forestShortName].cred.username ;
                    Status   = $true ;
                }
            } else {
                $retHash = @{
                    Name     = $pltNpsD.Name ;
                    UserName = $forests[$forestShortName].cred.username ;
                    Status = $false  ;
                } ;
            }
            New-Object PSObject -Property $retHash | write-output ;
        } ; # loop-E
    } # PROC-E
    END {} ;
}

#*------^ mount-ADForestDrives.ps1 ^------

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

Export-ModuleMember -Function Get-AdminInitials,get-ADRootSiteOUs,get-SiteMbxOU,load-ADMS,mount-ADForestDrives,Sync-AD,Validate-Password -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlUlZn1s22fHPkPPfEvD/2RgB
# dgqgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTfZOPM
# K4pDOZxgYAiEj/ZjOmK7eDANBgkqhkiG9w0BAQEFAASBgEt2iXlN/13U3pg6a2zW
# dSgCvL5zRs2fSATYVYNlhYnll7UoFNl5DXgLZRaFWN3AuOFHd3coOebn4C1Z7UuL
# dvSJ/stAwMShRf4Ay+Kv9AC4YOXRyTLNpDafcF6h4GlQzE3KCllFNBNqvVyrNun/
# cmbcCjn1l/WgHzQf0PsNSs5A
# SIG # End signature block
