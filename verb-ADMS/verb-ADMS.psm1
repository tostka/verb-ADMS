﻿# verb-adms.psm1


  <#
  .SYNOPSIS
  verb-ADMS - ActiveDirectory PS Module-related generic functions
  .NOTES
  Version     : 1.0.26.0
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



#*------v get-ADForestDrives.ps1 v------
function get-ADForestDrives {
    <#
    .SYNOPSIS
    get-ADForestDrives() - Get PSDrive PSProvider:ActiveDirectoryobjects currently mounted (for cross-domain ADMS work - ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will list solely those drives. Otherwise get-psDrive's all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module). Returns matching objects.
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-10-23
    FileName    : get-ADForestDrives
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,CrossForest
    AddedCredit : Raimund (fr social.technet.microsoft.com comment)
    AddedWebsite: https://social.technet.microsoft.com/Forums/en-US/a36ae19f-ab38-4e5c-9192-7feef103d05f/how-to-query-user-across-multiple-forest-with-ad-powershell?forum=ITCG
    AddedTwitter:
    REVISIONS
    # 1:05 PM 2/25/2021 init 
    .DESCRIPTION
    get-ADForestDrives() - Get PSDrive PSProvider:ActiveDirectoryobjects currently mounted (for cross-domain ADMS work - ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will remove list solely those drives. Otherwise get-psDrive's all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module). Returns matching objects.
    .OUTPUT
    System.Object[]
    Returns System.Object[] to pipeline, summarizing the Name and credential of PSDrives configured
    .EXAMPLE
    $result = get-ADForestDrives ;
    Simple example
    .EXAMPLE
    if([boolean](get-ADForestDrives)){"XO adms ready"} else { ""XO adms NOT ready"}
    Example if/then
    .LINK
    https://github.com/tostka/verb-adms
    #>
    #Requires -Version 3
    #Requires -Modules ActiveDirectory
    #Requires -RunasAdministrator
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        #$rgxDriveBanChars = '[;~/\\\.:]' ; # ;~/\.:
    }
    PROCESS {
        $error.clear() ;
        if($global:ADPsDriveNames){
            write-verbose "(Leveraging existing `$global:ADPsDriveNames variable found PSDrives`n$(($global:ADPsDriveName|out-string).trim())" ;  
            $tPsD = $global:ADPsDriveNames ; 
            $tPsD | %{
                $retHash = @{
                    Name     = $_.Name ;
                    UserName = $_.UserName ; 
                    Status   = [boolean](test-path -path "$($_.Name):") ; # test actual access
                } ; 
                New-Object PSObject -Property $retHash | write-output ;
            } 
        } else {
            write-verbose "(Reporting on all PSProvider:ActiveDirectory PsDrives, *other* than any existing 'AD'-named drive)" ; 
            $tPsD = Get-PSDrive -PSProvider ActiveDirectory|?{$_.name -ne 'AD'} ; 
        }  ; 
        TRY {
            $tPsD | %{
                $retHash = @{
                    Name     = $_.Name ;
                    UserName = $null # can't discover orig mapping uname fr existing psdrive object;
                    Status   = [boolean](test-path -path "$($_.Name):") ; # test actual access
                } ; 
                New-Object PSObject -Property $retHash | write-output ;
            } ; 
        } CATCH {
            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            #BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            $false | write-output ;
        } ;
    } # PROC-E
    END {} ;
}

#*------^ get-ADForestDrives.ps1 ^------

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

#*------v get-DCLocal.ps1 v------
Function get-DCLocal {
    <#
    .SYNOPSIS
    get-DCLocal - Function to locate a random DC in the local AD site (sub-250ms response)
    .NOTES
    Author: Todd Kadrie
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka

    Additional Credits: Originated in Ben Lye's GetLocalDC()
    Website:	http://www.onesimplescript.com/2012/03/using-powershell-to-find-local-domain.html
    REVISIONS   :
    * 1:01 PM 10/23/2020 moved verb-ex2010 -> verb-adms (better aligned)
    12:32 PM 1/8/2015 - tweaked version of Ben lye's script, replaced broken .NET site query with get-addomaincontroller ADMT module command
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns one DC object, .Name is name pointer
    .EXAMPLE
    C:\> get-dclocal
    #>

    #  alt command: Return one unverified connectivityDC in SITE site:
    # Get-ADDomainController -discover -site "SITE"

    # Set $ErrorActionPreference to continue so we don't see errors for the connectivity test
    $ErrorActionPreference = 'SilentlyContinue'
    # Get all the local domain controllers
    # .Net call below fails in LYN, because LYN'S SITE LISTS NO SERVERS ATTRIBUTE!
    #$LocalDCs = ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()).Servers
    # use get-addomaincontroller to do it
    $Site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name ;
    # gc filter
    #$LocalDCs = Get-ADDomainController -filter {(isglobalcatalog -eq $true) -AND (Site -eq $Site)} ;
    # any dc filter
    $LocalDCs = Get-ADDomainController -filter { (Site -eq $Site) } ;
    # Create an array for the potential DCs we could use
    $PotentialDCs = @()
    # Check connectivity to each DC
    ForEach ($LocalDC in $LocalDCs) {
        #write-verbose -verbose $localdc
        # Create a new TcpClient object
        $TCPClient = New-Object System.Net.Sockets.TCPClient
        # Try connecting to port 389 on the DC
        $Connect = $TCPClient.BeginConnect($LocalDC.Name, 389, $null, $null)
        # Wait 250ms for the connection
        $Wait = $Connect.AsyncWaitHandle.WaitOne(250, $False)
        # If the connection was succesful add this DC to the array and close the connection
        If ($TCPClient.Connected) {
            # Add the FQDN of the DC to the array
            $PotentialDCs += $LocalDC.Name
            # Close the TcpClient connection
            $Null = $TCPClient.Close()
        } # if-E
    } # loop-E
    # Pick a random DC from the list of potentials
    $DC = $PotentialDCs | Get-Random
    #write-verbose -verbose $DC
    # Return the DC
    Return $DC
}

#*------^ get-DCLocal.ps1 ^------

#*------v get-GCFast.ps1 v------
function get-GCFast {

  <#
    .SYNOPSIS
    get-GCFast - function to locate a random sub-100ms response gc in specified domain & optional AD site
    .NOTES
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    Additional Credits: Originated in Ben Lye's GetLocalDC()
    Website:	http://www.onesimplescript.com/2012/03/using-powershell-to-find-local-domain.html
    REVISIONS   :
    * 1:01 PM 10/23/2020 moved verb-ex2010 -> verb-adms (better aligned)
    # 2:19 PM 4/29/2019 add [lab dom] to the domain param validateset & site lookup code, also copied into tsksid-incl-ServerCore.ps1
    # 2:39 PM 8/9/2017 ADDED some code to support labdom.com, also added test that $LocalDcs actually returned anything!
    # 10:59 AM 3/31/2016 fix site param valad: shouln't be sitecodes, should be Site names; updated Site param def, to validate, cleanup, cleaned up old remmed code, rearranged comments a bit
    # 1:12 PM 2/11/2016 fixed new bug in get-GCFast, wasn't detecting blank $site, for PSv2-compat, pre-ensure that ADMS is loaded
    12:32 PM 1/8/2015 - tweaked version of Ben lye's script, replaced broken .NET site query with get-addomaincontroller ADMT module command
    .PARAMETER  Domain
    Which AD Domain [Domain fqdn]
    .PARAMETER  Site
    DCs from which Site name (defaults to AD lookup against local computer's Site)
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns one DC object, .Name is name pointer
    .EXAMPLE
    C:\> get-gcfast -domain dom.for.domain.com -site Site
    Lookup a Global domain gc, with Site specified (whether in Site or not, will return remote site dc's)
    .EXAMPLE
    C:\> get-gcfast -domain dom.for.domain.com
    Lookup a Global domain gc, default to Site lookup from local server's perspective
  #>

  [CmdletBinding()]
  param(
    [Parameter(HelpMessage = 'Target AD Domain')]
    [string]$Domain
    , [Parameter(Position = 1, Mandatory = $False, HelpMessage = "Optional: DCs from what Site name? (default=Discover)")]
    [string]$Site
  ) ;
  $SpeedThreshold = 100 ;
  $ErrorActionPreference = 'SilentlyContinue' ; # Set so we don't see errors for the connectivity test
  $env:ADPS_LoadDefaultDrive = 0 ; $sName = "ActiveDirectory"; if ( !(Get-Module | Where-Object { $_.Name -eq $sName }) ) {
    if ($bDebug) { Write-Debug "Adding ActiveDirectory Module (`$script:ADPSS)" };
    $script:AdPSS = Import-Module $sName -PassThru -ea Stop ;
  } ;
  if (!$Domain) {
    $Domain = (get-addomain).DNSRoot ; # use local domain
    write-host -foregroundcolor yellow   "Defaulting domain: $Domain";
  }
  # Get all the local domain controllers
  if ((!$Site)) {
    # if no site, look the computer's Site Up in AD
    $Site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name ;
    write-host -foregroundcolor yellow   "Using local machine Site: $Site";
  } ;

  # gc filter
  #$LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -and (Site -eq $Site) } ;
  #$LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -and (Site -eq $Site) } ;
  $LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -and (Site -eq $Site) -and (Domain -eq $Domain) } ;
  # any dc filter
  #$LocalDCs = Get-ADDomainController -filter {(Site -eq $Site)} ;

  $PotentialDCs = @() ;
  # Check connectivity to each DC against $SpeedThreshold
  if ($LocalDCs) {
    foreach ($LocalDC in $LocalDCs) {
      $TCPClient = New-Object System.Net.Sockets.TCPClient ;
      $Connect = $TCPClient.BeginConnect($LocalDC.Name, 389, $null, $null) ;
      $Wait = $Connect.AsyncWaitHandle.WaitOne($SpeedThreshold, $False) ;
      if ($TCPClient.Connected) {
        $PotentialDCs += $LocalDC.Name ;
        $Null = $TCPClient.Close() ;
      } # if-E
    } ;
    write-host -foregroundcolor yellow  "`$PotentialDCs: $PotentialDCs";
    $DC = $PotentialDCs | Get-Random ;
    write-output $DC  ;
  }
  else {
    write-host -foregroundcolor yellow  "NO DCS RETURNED BY GET-GCFAST()!";
    write-output $false ;
  } ;
}

#*------^ get-GCFast.ps1 ^------

#*------v get-GCFastXO.ps1 v------
Function get-GCFastXO {
    <#
    .SYNOPSIS
    get-GCFastXO - Cross-Org function to locate a random DC in the local AD site (sub-100ms response), includes speed testing (100ms cutoff)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-10-23
    FileName    : get-GCFastXO.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Concept inspired by Ben Lye's GetLocalDC()
    AddedWebsite: http://www.onesimplescript.com/2012/03/using-powershell-to-find-local-domain.html
    REVISIONS   :
    * 10/23/2020 2:18 PM init
    * 1:01 PM 10/23/2020 moved verb-ex2010 -> verb-adms (better aligned)
    .DESCRIPTION
    get-GCFastXO - Cross-Org function to locate a random DC in the local AD site (sub-100ms response)
    .PARAMETER ADObject 
    ADObject identifier (SamAccountName|UserPrincipalName| DistinguishedName), to be used to determine necessary subdomain
    .PARAMETER Credential
    Credential to use for this connection [-credential [credential obj variable]")][System.Management.Automation.PSCredential]
    .PARAMETER MaxLatency
Maximum latency in ms, to be permitted for returned objects[-MaxLatency 100]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER whatif
    Whatif Flag (DEFAULTED TRUE!) [-whatIf]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns one DC object, .Name is name pointer
    .EXAMPLE
    $dc = get-GCFastXO -TenOrg TOR -subdomain global.ad.toro.com
    Obtain a cross-Org gc using an explicit target subdomain in the specified forest
    .EXAMPLE
    $dc = get-GCFastXO -TenOrg TOR -ADObject SomeSamaccountname
    Obtain a cross-Org gc, resolving the target subdomain in the specified forest, by locating and resolving a specified ADObject (a user account, by querying on it's samaccountname)
    .EXAMPLE
    $dc = get-GCFastXO -TenOrg TOR -ADObject 'OU=ORGUNIT,OU=ORGUNIT,OU=SITE,DC=SUBDOMAIN,DC=ad,DC=DOMAIN,DC=com'
    Obtain a cross-Org gc, resolving the target subdomain in the specified forest, by locating and resolving a specified ADObject (an OU account, by querying on it's DN)
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$FALSE,HelpMessage="TenantTag value, indicating Tenants to connect to[-TenOrg 'TOL']")]
        [ValidateNotNullOrEmpty()]
        $TenOrg = 'TOR',
        [Parameter(ParameterSetName='Query',Position=0,Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="ADObject identifier, to be used to determine necessary subdomain (without this value, a root gc is returned)[-ADObject]")]
        [string]$ADObject,
        [Parameter(ParameterSetName='Static',Position=0,Mandatory=$False,HelpMessage="Forest subdomain for which gc should be returned[-subdomain]")]
        [string]$Subdomain,
        [Parameter(HelpMessage="Credential to use for cloud actions [-credential [credential obj variable]")][System.Management.Automation.PSCredential]
        $Credential,
        [Parameter(ParameterSetName='Static',Position=0,Mandatory=$False,HelpMessage="Maximum latency in ms, to be permitted for returned objects[-MaxLatency 100]")]
        [int]$MaxLatency = 100,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag (DEFAULTED TRUE!) [-whatIf]")]
        [switch] $whatIf=$true
    ) # PARAM BLOCK END

    $verbose = ($VerbosePreference -eq "Continue") ; 

    #*======v FUNCTIONS v======

    #-=-=TEMP SUPPRESS VERBOSE-=-=-=-=-=-=
    # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
    if($VerbosePreference = "Continue"){
        $VerbosePrefPrior = $VerbosePreference ;
        $VerbosePreference = "SilentlyContinue" ;
        $verbose = ($VerbosePreference -eq "Continue") ;
    } ; 
    #*------v  MOD LOADS  v------
    # strings are: "[tModName];[tModFile];tModCmdlet"
    $tMods = @() ;
    #$tMods+="verb-Auth;C:\sc\verb-Auth\verb-Auth\verb-Auth.psm1;get-password" ;
    #$tMods+="verb-logging;C:\sc\verb-logging\verb-logging\verb-logging.psm1;write-log";
    #$tMods+="verb-IO;C:\sc\verb-IO\verb-IO\verb-IO.psm1;Add-PSTitleBar" ;
    #$tMods+="verb-Mods;C:\sc\verb-Mods\verb-Mods\verb-Mods.psm1;check-ReqMods" ;
    #$tMods+="verb-Text;C:\sc\verb-Text\verb-Text\verb-Text.psm1;Remove-StringDiacritic" ;
    #$tMods+="verb-Desktop;C:\sc\verb-Desktop\verb-Desktop\verb-Desktop.psm1;Speak-words" ;
    #$tMods+="verb-dev;C:\sc\verb-dev\verb-dev\verb-dev.psm1;Get-CommentBlocks" ;
    #$tMods+="verb-Network;C:\sc\verb-Network\verb-Network\verb-Network.psm1;Send-EmailNotif" ;
    #$tMods+="verb-Automation.ps1;C:\sc\verb-Automation.ps1\verb-Automation.ps1\verb-Automation.ps1.psm1;Retry-Command" ;
    #$tMods+="verb-AAD;C:\sc\verb-AAD\verb-AAD\verb-AAD.psm1;Build-AADSignErrorsHash";
    $tMods+="verb-ADMS;C:\sc\verb-ADMS\verb-ADMS\verb-ADMS.psm1;load-ADMS";
    #$tMods+="verb-Ex2010;C:\sc\verb-Ex2010\verb-Ex2010\verb-Ex2010.psm1;Connect-Ex2010";
    #$tMods+="verb-EXO;C:\sc\verb-EXO\verb-EXO\verb-EXO.psm1;Connect-Exo";
    #$tMods+="verb-L13;C:\sc\verb-L13\verb-L13\verb-L13.psm1;Connect-L13";
    #$tMods+="verb-Teams;C:\sc\verb-Teams\verb-Teams\verb-Teams.psm1;Connect-Teams";
    #$tMods+="verb-SOL;C:\sc\verb-SOL\verb-SOL\verb-SOL.psm1;Connect-SOL" ;
    #$tMods+="verb-Azure;C:\sc\verb-Azure\verb-Azure\verb-Azure.psm1;get-AADBearToken" ;
    foreach($tMod in $tMods){
      $tModName = $tMod.split(';')[0] ; $tModFile = $tMod.split(';')[1] ; $tModCmdlet = $tMod.split(';')[2] ; 
      $smsg = "( processing `$tModName:$($tModName)`t`$tModFile:$($tModFile)`t`$tModCmdlet:$($tModCmdlet) )" ; 
      if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
      else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
      if($tModName -eq 'verb-Network' -OR $tModName -eq 'verb-Azure'){
          write-host "GOTCHA!" ;
      } ;
      $lVers = get-module -name $tModName -ListAvailable -ea 0 ;
      if($lVers){   $lVers=($lVers | sort version)[-1];   try {     import-module -name $tModName -RequiredVersion $lVers.Version.tostring() -force -DisableNameChecking   } catch {     write-warning "*BROKEN INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;import-module -name $tModDFile -force -DisableNameChecking   } ; 
      } elseif (test-path $tModFile) {
        write-warning "*NO* INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;
        try {import-module -name $tModDFile -force -DisableNameChecking}
        catch {   write-error "*FAILED* TO LOAD MODULE*:$($tModName) VIA $(tModFile) !" ;   $tModFile = "$($tModName).ps1" ;   $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ;   if (Test-Path $sLoad) {       Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;       . $sLoad ;       if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };   } else {       $sLoad = (join-path -path $backInclDir -childpath $tModFile) ;       if (Test-Path $sLoad) {           Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;           . $sLoad ;           if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };       } else {           Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;           exit;       } ;   } ; } ; 
      } ;
      if(!(test-path function:$tModCmdlet)){
          write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet`nfailing through to `$backInclDir .ps1 version" ;
          $sLoad = (join-path -path $backInclDir -childpath "$($tModName).ps1") ;
          if (Test-Path $sLoad) {     Write-Verbose -verbose:$true ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;     . $sLoad ;     if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };     if(!(test-path function:$tModCmdlet)){         write-warning "$((get-date).ToString('HH:mm:ss')):FAILED TO CONFIRM `$tModCmdlet:$($tModCmdlet) FOR $($tModName)" ;     } else {          write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)"     }  
          } else {     Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;     exit; } ; 
      } else {     write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)" } ; 

    } ;  # loop-E
    #*------^ END MOD LOADS ^------
    #-=-=-=-=RE-ENABLE PRIOR VERBOSE-=-=-=-=
    if($VerbosePrefPrior -eq "Continue"){
        $VerbosePreference = $VerbosePrefPrior ;
        $verbose = ($VerbosePreference -eq "Continue") ;
    } ; 

    #*------v Function check-ReqMods  v------
    function check-ReqMods ($reqMods){    $bValidMods=$true ;    $reqMods | foreach-object {        if( !(test-path function:$_ ) ) {          write-error "$((get-date).ToString("yyyyMMdd HH:mm:ss")):Missing $($_) function." ;          $bValidMods=$false ;        }    } ;    write-output $bValidMods ;} ;
    #*------^ END Function check-ReqMods  ^------

    #*======^ END FUNCTIONS ^======

    #*======v SUB MAIN v======
    <#
    if(!$Credential){
        if($Credential= (get-TenantCredentials -TenOrg $TenOrg -UserRole $UserRole -verbose:$($verbose)).cred ){
            #New-Variable -Name cred$($tenorg) -Value $Credential.cred ;
        } else {
            $smsg = "Unable to resolve get-TenantCredentials -TenOrg $($TenOrg) -UserRole $($UserRole)!"
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            throw "Unable to resolve $($tenorg) `$prefCred value!`nEXIT!"
            exit ; 
        } ;
    } ; 
    #>
    # multi-org AD
    <#still needs ADMS mount-ADForestDrives() and set-location code @ 395 (had to recode mount-admforestdrives and debug cred production code & infra-string inputs before it would work; will need to dupe to suspend variant on final completion
    #>

    if(!$global:ADPsDriveNames){
        $smsg = "(connecting X-Org AD PSDrives)" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        $global:ADPsDriveNames = mount-ADForestDrives -verbose:$($verbose) ;
    } ; 
    
    # cross-org ADMS requires switching to the proper forest drive (and use of -server xxx.xxx.com to access subdomains o the forest)
    $pdir = get-location ;
    $rgxDriveBanChars = '[;~/\\\.:]' ; # ;~/\.:,
    $rgxSamAcctName = '^[^\/\\\[\]:;|=,+?<>@”]+$' ; 
    # "^[-A-Za-z0-9]{2,20}$" ; # 2-20chars, alphanum plus dash
    $rgxemailaddr = "^([0-9a-zA-Z]+[-._+&'])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}$" ; 
    $rgxDistName = "^((CN=([^,]*)),)?((((?:CN|OU)=[^,]+,?)+),)?((DC=[^,]+,?)+)$" ; 
    
    if( $tPsd = "$((Get-Variable  -name "$($TenOrg)Meta").value.ADForestName -replace $rgxDriveBanChars):" ){
        if(test-path $tPsd){
            $error.clear() ;
            TRY {
                set-location -Path $tPsd -ea STOP ;
                $objForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() ;
                $doms = @($objForest.Domains | Select-Object Name).name ; 
            
                if($subdomain -AND ($doms -contains $subdomain) ){
                    write-verbose "(using specified -subdomain $($subdomain))" ; 
                    $tdom = $subdomain ; 
                } elseif($ADObject) { 
                    write-verbose "(Resolving ADObject:$($ADObject) to determine target subdomain in AD forest)" ; 
                    $tdom = $null ; 
                    switch -regex ($ADObject){
                        $rgxSamAcctName {
                            $fltr = "SamAccountName -eq '$($ADObject)'" ;
                        } 
                        $rgxemailaddr {
                            $fltr = "UserPrincipalName -eq '$($ADObject)'" ;
                        }
                        $rgxDistName {
                            $fltr = "DistinguishedName -eq '$($ADObject)'" ;
                        } 
                        default {
                            $smsg = "FAILED TO MATCH -ADObject SPEC - $($ADObject) - TO EITHER A SAMACCOUNTNAME OR UPN FORMAT!" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            BREAK ; 
                        }
                    }
                    foreach($dom in $doms){
                        write-verbose "Get-ADObject server:$($dom)" ;
                        if(Get-ADObject -filter $fltr  -Server $dom -ea 0){
                            $tdom = $dom ;
                            $smsg = "(matched $($ADObject) to forest subdomain:$($tdom))" ; 
                            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                            break ;
                        } ;
                    } ;
                } else { 
                    $smsg = "UNABLE TO RESOLVE A TARGET SUBDOMAIN!" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            BREAK ; 
                } ;
            } CATCH {
                $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                set-location $pdir ; # restore dir
                Exit #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {
            $smsg = "UNABLE TO FIND *MOUNTED* AD PSDRIVE $($Tpsd) FROM `$$($TENorg)Meta!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Exit #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ;
    } else {
        $smsg = "UNABLE TO RESOLVE PROPER AD PSDRIVE FROM `$$($TENorg)Meta!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Exit #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ;
    
    if($tdom){
        $pltGAdDc=@{
            server = $tdom ; # no, use the per-user subdomain fqdn
            erroraction='STOP' ;
        } ;
        $smsg = "Get-ADDomainController w`n$(($pltGAdDc|out-string).trim())" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        $domainControllers = (Get-ADDomainController -Filter {isGlobalCatalog -eq $true -AND Site -eq "$((get-adreplicationsite).name)"} @pltGAdDc ).name
        
    } else { 
        $smsg = "FAILED TO RESOLVE A USABLE SUBDOMAIN SPEC FOR THE USER!" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        BREAK ; 
    }
    set-location $pdir ;
    
    $PotentialDCs = @()
    ForEach ($LocalDC in $domainControllers ) {
        $TCPClient = New-Object System.Net.Sockets.TCPClient
        # Try connecting to port 389 on the DC
        $Connect = $TCPClient.BeginConnect($LocalDC, 389, $null, $null)
        # Wait 100ms ($MaxLatency) for the connection
        $Wait = $Connect.AsyncWaitHandle.WaitOne($MaxLatency, $False)
        If ($TCPClient.Connected) {
            $PotentialDCs += $LocalDC
            $Null = $TCPClient.Close()
        } # if-E
    } # loop-E
    $PotentialDCs | Get-Random | Write-Output

}

#*------^ get-GCFastXO.ps1 ^------

#*------v get-GCLocal.ps1 v------
Function get-GCLocal {
    <#
        .SYNOPSIS
    get-GCLocal - Function to locate a random DC in the local AD site (sub-250ms response)
        .NOTES
    Author: Todd Kadrie
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    Additional Credits: Originated in Ben Lye's GetLocalDC()
    Website:	http://www.onesimplescript.com/2012/03/using-powershell-to-find-local-domain.html
    REVISIONS   :
    * 1:01 PM 10/23/2020 moved verb-ex2010 -> verb-adms (better aligned)
    12:32 PM 1/8/2015 - tweaked version of Ben lye's script, replaced broken .NET site query with get-addomaincontroller ADMT module command
        .INPUTS
    None. Does not accepted piped input.
        .OUTPUTS
    Returns one DC object, .Name is name pointer
        .EXAMPLE
    C:\> get-dclocal
    #>

    #  alt command: Return one unverified connectivityDC in SITE site:
    # Get-ADDomainController -discover -site "SITE"

    # Set $ErrorActionPreference to continue so we don't see errors for the connectivity test
    $ErrorActionPreference = 'SilentlyContinue'
    # Get all the local domain controllers
    # .Net call below fails in LYN, because LYN'S SITE LISTS NO SERVERS ATTRIBUTE!
    #$LocalDCs = ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()).Servers
    # use get-addomaincontroller to do it
    $Site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name ;
    # gc filter
    $LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -AND (Site -eq $Site) } ;
    # any dc filter
    #$LocalDCs = Get-ADDomainController -filter {(Site -eq $Site)} ;
    # Create an array for the potential DCs we could use
    $PotentialDCs = @()
    # Check connectivity to each DC
    ForEach ($LocalDC in $LocalDCs) {
        #write-verbose -verbose $localdc
        # Create a new TcpClient object
        $TCPClient = New-Object System.Net.Sockets.TCPClient
        # Try connecting to port 389 on the DC
        $Connect = $TCPClient.BeginConnect($LocalDC.Name, 389, $null, $null)
        # Wait 250ms for the connection
        $Wait = $Connect.AsyncWaitHandle.WaitOne(250, $False)
        # If the connection was succesful add this DC to the array and close the connection
        If ($TCPClient.Connected) {
            # Add the FQDN of the DC to the array
            $PotentialDCs += $LocalDC.Name
            # Close the TcpClient connection
            $Null = $TCPClient.Close()
        } # if-E
    } # loop-E
    # Pick a random DC from the list of potentials
    $DC = $PotentialDCs | Get-Random
    #write-verbose -verbose $DC
    # Return the DC
    Return $DC
}

#*------^ get-GCLocal.ps1 ^------

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
    # 7:05 AM 10/23/2020 added creation of $global:ADPsDriveNames when -Scope is global
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
    -scope:Global: Persists in global environment, also autopopulates `$global:ADPsDriveNames variable (note the normal New-PSDrive '-Persist' variable doesn't work with AD PSProvider)
    .PARAMETER whatIf
    Whatif SWITCH  [-whatIf]
    .OUTPUT
    System.Object[]
    Returns System.Object[] to pipeline, summarizing the Name and credential of PSDrives configured
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
    .EXAMPLE
    $ADPsDriveNames = mount-ADForestDrives ; 
    # cd to AD Contaxt for the Org (target AD PsDrive)
    cd cmwinternal:
    # dump domain subdomains (domain fqdns):
    $cfgRoot = (Get-ADRootDSE).configurationNamingContext ;
    $subroots = (Get-ADObject -filter 'netbiosname -like "*"' -SearchBase "CN=Partitions,$
cfgRoot" -Properties cn,dnsRoot,nCName,trustParent,nETBIOSName).dnsroot
    # query a user in a subdomain of the domain
    get-aduser -id SAMACCOUNTNAME -Server $subroot[0]
    Mount psdrives ; set-location a specific drive ; dump subdomains, and get-aduser a user in a subdomain 
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
            if($scope -eq 'global'){
                $smsg = "(creating/updating `$global:ADPsDriveNames with summary of the new PSdrives)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $global:ADPsDriveNames = New-Object PSObject -Property $retHash 
            } ; 
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

#*------v umount-ADForestDrives.ps1 v------
function unmount-ADForestDrives {
    <#
    .SYNOPSIS
    unmount-ADForestDrives() - Unmount PSDrive objects mounted for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will remove solely those drives. Otherwise removes all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module). Returns $true/$false on pass status.
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-10-23
    FileName    : unmount-ADForestDrives
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,CrossForest
    AddedCredit : Raimund (fr social.technet.microsoft.com comment)
    AddedWebsite: https://social.technet.microsoft.com/Forums/en-US/a36ae19f-ab38-4e5c-9192-7feef103d05f/how-to-query-user-across-multiple-forest-with-ad-powershell?forum=ITCG
    AddedTwitter:
    REVISIONS
    # 7:24 AM 10/23/2020 init 
    .DESCRIPTION
    unmount-ADForestDrives() - Unmount PSDrive objects mounted for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will remove solely those drives. Otherwise removes all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module)
    .PARAMETER whatIf
    Whatif SWITCH  [-whatIf]
    .OUTPUT
    System.Boolean
    .EXAMPLE
    $result = unmount-ADForestDrives ;
    Simple example
    .EXAMPLE
    if(!$global:ADPsDriveNames){
        $smsg = "(connecting X-Org AD PSDrives)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        $global:ADPsDriveNames = mount-ADForestDrives -verbose:$($verbose) ;
    } ; 
    if(($global:ADPsDriveNames|measure).count){
        $smsg = "Confirming ADMS PSDrives:`n$(($global:ADPsDriveNames.Name|%{get-psdrive -Name $_ -PSProvider ActiveDirectory} | ft -auto Name,Root,Provider|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } else { 
        $script:PassStatus += ";ERROR";
        set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + ";ERROR") ;
        $smsg = "Unable to detect POPULATED `$global:ADPsDriveNames!`n(should have multiple values, resolved to $()"
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        throw "Unable to resolve $($tenorg) `$o365Cred value!`nEXIT!"
        exit ;
    } ; 
    Example with supporting/echo code
    .LINK
    https://github.com/tostka/verb-adms
    #>
    #Requires -Version 3
    #Requires -Modules ActiveDirectory
    #Requires -RunasAdministrator
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        #$rgxDriveBanChars = '[;~/\\\.:]' ; # ;~/\.:
    }
    PROCESS {
        $error.clear() ;

        if($global:ADPsDriveNames){
            write-verbose "(Existing `$global:ADPsDriveNames variable found: removing the following *explicit* AD PSDrives`n$(($global:ADPsDriveName|out-string).trim())" ; 
            $tPsD = $global:ADPsDriveNames
        } else {
            write-verbose "(removing all PSProvider:ActiveDirectory PsDrives, *other* than any existing 'AD'-named drive)" ; 
            $tPsD = Get-PSDrive -PSProvider ActiveDirectory|?{$_.name -ne 'AD'} ; 
        }  ; 
        TRY {
            $bRet = $ADPsDriveNames |  Remove-PSDrive -Force -whatif:$($whatif) -verbose:$($verbose) ;
            $true | write-output ;
        } CATCH {
            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            #BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            $false | write-output ;
        } ;
    } # PROC-E
    END {} ;
}

#*------^ umount-ADForestDrives.ps1 ^------

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

Export-ModuleMember -Function get-ADForestDrives,Get-AdminInitials,get-ADRootSiteOUs,get-DCLocal,get-GCFast,get-GCFastXO,check-ReqMods,get-GCLocal,get-SiteMbxOU,load-ADMS,mount-ADForestDrives,Sync-AD,unmount-ADForestDrives,Validate-Password -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1MPKUXzi1j2Sg5o9JSvKafvj
# Yo2gggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRbRPOq
# Sx0iq5l+fmIohZaFYccEMjANBgkqhkiG9w0BAQEFAASBgIqi0ludWTHZrMa0afby
# n6CerLbNMajlwfUxlm0/GKm7K8ql9prEZDwoTA/Z/axHx7mGLQ+J9MSEqPx4Hb6w
# ukCEiDi8IChS4y5i7Er31757Y0szJeoqwosoa2jjeLx0IHt2ysdK34zztPP2PpcT
# DuogO2zqJWxpVj7rDx+OHCOT
# SIG # End signature block
