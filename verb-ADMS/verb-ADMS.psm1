﻿# verb-adms.psm1


  <#
  .SYNOPSIS
  verb-ADMS - ActiveDirectory PS Module-related generic functions
  .NOTES
  Version     : 2.1.0.0
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



#*------v find-SiteRoleOU.ps1 v------
function find-SiteRoleOU {
    <#
    .SYNOPSIS
    find-SiteRoleOU() - Given a -Role specification, and SearchBase OU, locates and returns DN for standardized storage OU's for common mail objects. Through use of the 'Any' -Role, and -TargetName specification, can locate specific named OUs anywhere in the hierarchy. 
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-03
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 12:37 PM 12/2/2021 ren $SiteOUName to $SearchBase, flipped param to support the OU below with search should be run, in form of either the OU Name, or a full DN; added nesting support and a loop to try the search with and wo wildcard between SearchBase OU and the FindOU
    * 12:17 PM 11/23/2021 port over and expand get-SiteMbxOU to cover range of Email-related role OU's, via lookup, keyed from a starting point: Site root OU, or child domain root. 
    * 10:57 AM 4/3/2020 cleanup to modularize, added verbose sup, updated CBH
    # 2:51 PM 3/6/2017 add -Resource param to steer to 'Email Resources'
    # 12:36 PM 2/27/2017 fixed to cover breaks frm AD reorg OU name changes, Generics are all now in a single OU per site
    # 11:56 AM 3/31/2016 port to find-SiteRoleOU; validated that latest round of updates are still functional; minor cleanup
    * 11:31 AM 3/16/2016 debugged to function.
    * 1:34 PM 3/15/2016 adapted SecGrp OU lookup to MailContact OU
    * 11:05 AM 10/7/2015 initial vers
    .DESCRIPTION
    find-SiteRoleOU() - Given a -Role specification, and SearchBase OU, locates and returns DN for standardized storage OU's for common mail objects. Through use of the 'Any' -Role, and -TargetName specification, can locate specific named OUs anywhere in the hierarchy. 
    - Role keywords, and traditional locations: 
      -DistributionGroup : OU=Distribution Groups,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Shared (Mbxs): OU=Generic Email Accounts,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Resource (Mbxs) (Room/Equipment): OU=Email Resources,OU=XXX,...,DC=xxxx,DC=com
      -PermissionGroup: OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Contact: OU=Email Contacts,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Users (Mbxs): OU=Users,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Any : used with the -TargetName spec to search for the named DN anywhere below the specified SearchBase
    .PARAMETER SearchBase
    Site OU name below which to Query[ABC]
    .PARAMETER Domain
    Specify the domain fqdn below which to which to Query[-domain childdom.domain.org.com]
    .PARAMETER Role
    OU Role to find (Shared|Resource|DistributionGroup|PermissionGroup|Contact|Users)[-Role Shared]
    .PARAMETER  TargetName
    Optional parameter used with the -Role Any option, to search for any specified OU in the SearchBase or Domain[-TargetName 'Exchange Servers'].
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    System.String containing DN of resolved OU (can be an array where multiple matches are found, results should be checked)
    .EXAMPLE
    $OU=find-SiteRoleOU -SearchBase SITE -Role Shared
    Retrieve the DN OU path for the 'Shared mailbox' storage OU, somewhere below the Searchbase, specified as a the OU name (directly below the tree root).
    .EXAMPLE
    $tOU = find-SiteRoleOU -Domain 'childdom.childdom.company.tld'' -Role Any -TargetName 'Exchange Servers' -verbose 
    Retrieve DN for the Users mailbox OU within the specified Domain (specified as a domain DN), with verbose output
    .EXAMPLE
    $OU = find-SiteRoleOU -SearchBase 'OU=OUNAME,DC=CHILDDOM,DC=CHILDDOM,DC=COMPANY,DC=TLD' -Role Any -TargetName 'Exchange Servers' -verbose 
    Demos use of the '-Role Any' and -TargetName params, to return the DN for for *any* specified OU name, path for the 'Exchange Servers' OU, somewhere below the Searchbase, specified as a DN
    .LINK
    https://github.com/tostka/verb-adms
    #>
    #Requires -Modules ActiveDirectory
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [OutputType('System.String')] # optional specified output type
    [CmdletBinding(DefaultParameterSetName='Site')]
    PARAM (
        [parameter(ParameterSetName='Site',Mandatory=$True,HelpMessage="SITE OU name below which to Query[ABC]")]
        [Alias('RootOU')]
        [string]$SearchBase,
        [parameter(ParameterSetName='Domain',Mandatory=$True,HelpMessage="Specify the domain fqdn below which to which to Query[-domain childdom.domain.org.com]")]
        [ValidatePattern("(?=^.{1,254}$)(^(?:(?!\d+\.|-)[a-zA-Z0-9_\-]{1,63}(?<!-)\.?)+(?:[a-zA-Z]{2,})$)")]
        [string]$Domain,
        [parameter(Mandatory=$True,HelpMessage="OU Role to find (Shared|Resource|DistributionGroup|PermissionGroup|Contact|Users|Any)[-Role Shared]")]
        [ValidateSet('Shared','Resource','DistributionGroup','PermissionGroup','Contact','Users','Any')]
        [string]$Role,
        [parameter(HelpMessage="Optional parameter used with the -Role Any option, to search for any specified OU in the SearchBase or Domain.")]
        [string]$TargetName
    ) ;  
    $verbose = ($VerbosePreference -eq "Continue") ; 
    
    # configurable constants that drive policy role OU locations:
    $SharedOU='^OU=Generic Email Accounts' ;
    $ResourceOU="^OU=Email Resources" ;
    $DistributionGroup='^OU=Distribution Groups' 
    $PermissionGroupOU='^OU=Email Access,OU=SEC Groups,OU=Managed Groups' ;
    $ContactOU='^OU=Email Contacts' ;
    $UsersOU='^OU=Users' ;
    
    # rgx to detect DN-style SearchBase
    $rgxDistName = "^((CN=([^,]*)),)?((((?:CN|OU)=[^,]+,?)+),)?((DC=[^,]+,?)+)$" ;

    if($TargetName -AND ($Role -ne 'ANY')){
        $smsg = "-TargetName specified wo use of the required -Role Any specification" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        throw $smsg ;
        Break ; 
    } ; 

    switch ($Role){
        <# -DistributionGroup : OU=Distribution Groups,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
        DW equiv:OU=Distribution Groups,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        -Shared (Mbxs): OU=Generic Email Accounts,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
        DW equiv:OU=Generic Email Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        -Resource (Mbxs) (Room/Equipment): OU=Email Resources,OU=XXX,...,DC=xxxx,DC=com
        DW equiv:OU=Email Resources,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal # doesn't exist yet
        -PermissionGroup: OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
        DW equiv: OU=Email Access,OU=Security Groups,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        -Contact: OU=Email Contacts,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
        # they've curr got them in users, should be:
        DW equiv: OU=Email Contacts,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal # doesn't exist yet
        -Users (Mbxs): OU=Users,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
        DW equiv: OU=User Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        #>

        'Shared'{$FindOU=$SharedOU ;}
        'Resource'{$FindOU=$ResourceOU ;}
        'DistributionGroup'{$FindOU=$DistributionGroup ;}
        'PermissionGroup'{$FindOU=$PermissionGroupOU }
        'Contact'{$FindOU=$ContactOU;}
        'Users'{$FindOU=$UsersOU ;}
        'Any' {
            # this represents a purely generic search for *any* named OU below SearchBase, requires the optional TargetName to specify target OU name
            if($TargetName){
                $FindOU = $TargetName ; 
            } else {
                $smsg = "Missing required -TargetName parameter spec. Required for use of the -Role Any option. " ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                throw $smsg ;
                Break ; 
            }  ; 
        } ; 
        default {
            $smsg = "Unrecognized -Role:$($Rold). Please specify one of:`n(Shared|Resource|DistributionGroup|PermissionGroup|Contact|Users) " ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            Break ; 
        }
    } ; 
    $error.clear() ;
    TRY {
        if($SearchBase){
            $domain = (Get-ADDomain -Current LoggedOnUser).DNSRoot ; 
            $smsg = "`$domain:$($domain)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $DomDN =  (get-addomain -id $domain -ea 'STOP').DistinguishedName ;
            $smsg = "`$DomDN:$($DomDN)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            # loop it with & wo wildcard delimter (covers both cases, takes 1st that returns a DN)
            foreach($nested in @($false,$true)){
                $stack =@() ; 
                $stack += "OU=$($FindOU)" ; 
                if($SearchBase -match $rgxDistName){
                    if($nested){
                        $stack += '.*' ;
                        $smsg = "(doing Nested .* OU search)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } else { 
                        $smsg = "(doing un-Nested .* OU search)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } ; 
                    # it's a DN, use it's elements as the base, reversed
                    $stack += $SearchBase.split(',') ; 
                } else { 
                    # it's an OU name, resolve the OU
                    if($nested){
                        $stack += '.*' ;
                        $smsg = "(doing Nested .* OU search)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } else { 
                        $smsg = "(doing un-Nested .* OU search)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } ; 
                    $stack += "OU=$($SearchBase)" ; 
                    $stack += "$($DomDN)$" ; 
                } 
            
                $DNFilter = $stack -join ',' ; 
                $smsg = "`$DNFilter:$($DNFilter)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                #$OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU).*,OU=$($SearchBase),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
                #$OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU),.*,OU=$($SearchBase),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
                $OUPath = Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $domain |
                     ?{ $_.distinguishedname -match $DNFilter } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | 
                     select distinguishedname
                if($OUPath){
                    $OUPath = $OUPath.distinguishedname.tostring() ; 
                    Break ;
                } ; 
            } ; 
        } elseif($Domain){
            $smsg = "`$domain:$($domain)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $DomDN =  (get-addomain -id $domain -ea 'STOP').DistinguishedName ;
            $smsg = "`$DomDN:$($DomDN)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            foreach($nested in @($false,$true)){
                $stack =@() ; 
                $stack += "$($FindOU)" ; 
                if($nested){
                    $stack += '.*' ;
                    $smsg = "(doing Nested .* OU search)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } else { 
                    $smsg = "(doing un-Nested .* OU search)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ; 
                $stack += "$($DomDN)$" ; 
                $DNFilter = $stack -join ',' ; 
                $smsg = "`$DNFilter:$($DNFilter)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                #$OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $domain | ?{ $_.distinguishedname -match "^$($FindOU),.*,$($DomDN)$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ; 
                $OUPath = Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $domain | 
                    ?{ $_.distinguishedname -match $DNFilter } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | 
                    select distinguishedname ;
                if($OUPath){
                    $OUPath = $OUPath.distinguishedname.tostring() ; 
                    Break ;
                } ;
            } ;  
        } ;
        If($OUPath -isnot [string]){      
            # post-verification to ensure we've got a single OU spec
            $smsg = "WARNING AD OU SEARCH SITE:$($InputSplat.SiteCode), FindOU:$($FindOU), FAILED TO RETURN A SINGLE OU...";
            $smsg += "`n$(($OUPath.distinguishedname|out-string).trim())" ; 
            $smsg = "" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            Break  ;
        } ;
        write-output $OUPath
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #-=-record a STATUSWARN=-=-=-=-=-=-=
        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
        #-=-=-=-=-=-=-=-=
        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ; 
}

#*------^ find-SiteRoleOU.ps1 ^------

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
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,OrganizationalUnit
    REVISIONS
    * 12:18 PM 8/4/2021 hybrided in useful bits from maintain-exroomlists.ps1:getADSiteOus()
    * 8:24 AM 4/10/2020 init
    .DESCRIPTION
    get-ADRootSiteOUs() - Retrieves the 'Office' Site OUs (filters on ^OU=(\w{3}|GOODOFFICE))
    ..PARAMETER  Regex
    OU DistinguishedName regex, to identify 'Site' OUs [-Regex [regularexpression]]
    .PARAMETER RegexBanned
    OU DistinguishedName regex, to EXCLUDE non-legitimate 'Site' OUs [-RegexBanned [regularexpression]]
    .PARAMETER domain
    Domain to be searched for root Site OUs [-domain domain.fqdn.com]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .OUTPUT
    Returns an object containing the Name and DN of all matching OUs
    .EXAMPLE
    $RootOUs=get-ADRootSiteOUs 
    Retrieve the Name & DN for all OUs
    .LINK
    #>
    #Requires -Modules ActiveDirectory
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, HelpMessage = "OU DistinguishedName regex, to identify 'Site' OUs [-ADUser [regularexpression]]")]
        [ValidateNotNullOrEmpty()][string]$Regex = '^OU=(\w{3}|PACRIM),DC=global,DC=ad,DC=toro((lab)*),DC=com$',
        [Parameter(Position = 0, HelpMessage = "OU DistinguishedName regex, to EXCLUDE non-legitimate 'Site' OUs [-RegexBanned [regularexpression]]")]
        [ValidateNotNullOrEmpty()][string]$RegexBanned = '^OU=(BCC|EDC|NC1|NDS|TAC),DC=global,DC=ad,DC=toro((lab)*),DC=com$',
        [Parameter(HelpMessage = "Domain to be searched for root Site OUs [-domain domain.fqdn.com]")]
        [string] $domain='global.ad.toro.com',
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug
    ) # PARAM BLOCK END
    $verbose = ($VerbosePreference -eq "Continue") ; 
    $error.clear() ;
    TRY {
        $pltGAdo=[ordered]@{
            server=$domain ;
            LDAPFilter='(DistinguishedName=*)' ;
            SearchBase=(get-addomain $domain).distinguishedname ; 
            SearchScope='OneLevel' ; 
        } ; 
        $smsg = "Get-ADOrganizationalUnit w`n$(($pltGAdo|out-string).trim())" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $OUs= Get-ADOrganizationalUnit @pltGAdo | ?{($_.distinguishedname -match $Regex) -AND ($_.distinguishedname -notmatch $RegexBanned) } |
            sort distinguishedname | select Name,DistinguishedName ;
        write-output $OUs ; 
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #-=-record a STATUSWARN=-=-=-=-=-=-=
        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
        #-=-=-=-=-=-=-=-=
        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
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
    * 3:19 PM 6/9/2021 fixed spurious if test w = v -eq (which was flipping to verbose); rev'd all echos to write-verbose only (silent op)
    * 11:40 AM 5/14/2021 added -ea 0 to the gv tests (suppresses not-found error when called without logging config)
    * 9:04 AM 5/5/2021 added a detailed EXAMPLE for BP to splice whole shebang into other scripts
    * 12:07 PM 5/4/2021 it's got a bug in the output: something prior to the last write-output is prestuffing an empty item into the pipeline. Result is an array of objects coming out for $domaincontroller. Workaround, till can locate the source, is to post-filter returns for length, in the call: $domaincontroller = get-GCFastXO -TenOrg $TenOrg -ADObject @($Rooms)[0] -verbose:$($verbose) |?{$_.length} ; added the workaround to the examples
    * 11:18 AM 4/5/2021 retooled again, not passing to pipeline ;  added ForestWide param, to return a root forest dom gc with the appended 3268 port
    * 3:37 PM 4/1/2021 fixed enhcodeing char damage in $rgxSamAcctName, fixed type-conv error (EXch) for returns from get-addomaincontroller ;
    * 3:32 PM 3/24/2021 added if/then use of Site on discovery ; implemented multi-domain forestwide GC search - but watchout using anything but eml/UPN - overlapping samaccountname used in mult domains will fail to return single hit; added sanity-checking of forest to context. tossed out adreplicationsite, wasn't returning dcs
    * 9:55 AM 3/17/2021 switched forest lookup to get-adforest (ActiveDirectory module) - native above ignores adpsdrive context (always pulls TOR)
    * 10/23/2020 2:18 PM init
    * 1:01 PM 10/23/2020 moved verb-ex2010 -> verb-adms (better aligned)
    .DESCRIPTION
    get-GCFastXO - Cross-Org function to locate a random DC in the local AD site (sub-100ms response)
    .PARAMETER ADObject
    ADObject identifier (SamAccountName|UserPrincipalName| DistinguishedName), to be used to determine necessary subdomain
    .PARAMETER ForestWide
    Switch to return a Forest Wide GC (a root dom gc specifying port 3268)[-ForestWide]
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
    $dc = get-GCFastXO -TenOrg TOR -subdomain global.ad.toro.com |?{$_.length} ;
    Obtain a cross-Org gc using an explicit target subdomain in the specified forest
    .EXAMPLE
    $dc = get-GCFastXO -TenOrg TOR -ADObject SomeSamaccountname |?{$_.length} ;
    Obtain a cross-Org gc, resolving the target subdomain in the specified forest, by locating and resolving a specified ADObject (a user account, by querying on it's samaccountname)
    .EXAMPLE
    $dc = get-GCFastXO -TenOrg TOR -ADObject 'OU=ORGUNIT,OU=ORGUNIT,OU=SITE,DC=SUBDOMAIN,DC=ad,DC=DOMAIN,DC=com' |?{$_.length} ;
    Obtain a cross-Org gc, resolving the target subdomain in the specified forest, by locating and resolving a specified ADObject (an OU account, by querying on it's DN)
    .EXAMPLE
    $gcw = get-GCFastXO -TenOrg cmw -ForestWide -showDebug -Verbose |?{$_.length} ;
    get-aduser -id someuser -server $gcw ;
    Obtain a ForestWide root domain gc (which includes the necessary hard-coded port '3268') and can then can be queried for an object in *any subdomain* in the forest, though it has a small subset of all ADObject properties). Handy for locating the hosting subdomain, and suitable dc, so that the full ADObject can be queried targeting a suitable subdomain dc.
    .EXAMPLE
    $ADMTLoaded = load-ADMS ;
    if(!$global:ADPsDriveNames){
        $smsg = "(connecting X-Org AD PSDrives)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        $global:ADPsDriveNames = mount-ADForestDrives -verbose:$($verbose) ;
    } ;
    $domaincontroller = $null ;
    pushd ;
    if( $tPsd = "$((Get-Variable  -name "$($TenOrg)Meta").value.ADForestName -replace $rgxDriveBanChars):" ){
        if(test-path $tPsd){
            $error.clear() ;
            TRY {
                set-location -Path $tPsd -ea STOP ;
                $objForest = get-adforest ;
                $doms = @($objForest.Domains) ;
                if(($doms|?{$_ -ne $objforest.name}|measure).count -eq 1){
                    $subdom = $doms|?{$_ -ne $objforest.name} ;
                    $domaincontroller = get-gcfastxo -TenOrg $TenOrg -Subdomain $subdom -verbose:$($verbose) |?{$_.length} ;
                    $smsg = "get-gcfastxo:returned $($domaincontroller)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } else {
                    enable-forestview ;
                    $domaincontroller = $null ;
                } ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg= "Failed to exec cmd because: $($ErrTrapd)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $statusdelta = ";ERROR";
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                popd ;
                BREAK ;
            } ;
        } else {
            $smsg = "UNABLE TO FIND *MOUNTED* AD PSDRIVE $($Tpsd) FROM `$$($TENorg)Meta!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR }
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $statusdelta = ";ERROR";
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
            BREAK ;
        } ;
    } else {
        $smsg = "UNABLE TO RESOLVE PROPER AD PSDRIVE FROM `$$($TENorg)Meta!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR }
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $statusdelta = ";ERROR";
        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
        BREAK ;
    } ;
    popd ;
    Detailed example demoing cross-domain dc pull, leveraging psData
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
        [Parameter(ParameterSetName='Forest',Position=0,Mandatory=$False,HelpMessage="Switch to return a Forest Wide GC (a root dom gc specifying port 3268)[-ForestWide]")]
        [switch]$ForestWide,
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
    if($VerbosePreference -eq "Continue"){
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
      else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
      if($tModName -eq 'verb-Network' -OR $tModName -eq 'verb-Azure'){
          write-verbose "GOTCHA!" ;
      } ;
      $lVers = get-module -name $tModName -ListAvailable -ea 0 ;
      if($lVers){   $lVers=($lVers | sort version)[-1];   try {     import-module -name $tModName -RequiredVersion $lVers.Version.tostring() -force -DisableNameChecking   } catch {     write-warning "*BROKEN INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;import-module -name $tModDFile -force -DisableNameChecking   } ;
      } elseif (test-path $tModFile) {
        write-warning "*NO* INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;
        try {import-module -name $tModDFile -force -DisableNameChecking}
        catch {   write-error "*FAILED* TO LOAD MODULE*:$($tModName) VIA $(tModFile) !" ;   $tModFile = "$($tModName).ps1" ;   $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ;   if (Test-Path $sLoad) {       Write-Verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;       . $sLoad ;       if ($showdebug) { Write-Verbose "Post $sLoad" };   } else {       $sLoad = (join-path -path $backInclDir -childpath $tModFile) ;       if (Test-Path $sLoad) {           Write-Verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;           . $sLoad ;           if ($showdebug) { Write-Verbose "Post $sLoad" };       } else {           Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;           Break;       } ;   } ; } ;
      } ;
      if(!(test-path function:$tModCmdlet)){
          write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet`nfailing through to `$backInclDir .ps1 version" ;
          $sLoad = (join-path -path $backInclDir -childpath "$($tModName).ps1") ;
          if (Test-Path $sLoad) {     Write-Verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;     . $sLoad ;     if ($showdebug) { Write-Verbose "Post $sLoad" };     if(!(test-path function:$tModCmdlet)){         write-warning "$((get-date).ToString('HH:mm:ss')):FAILED TO CONFIRM `$tModCmdlet:$($tModCmdlet) FOR $($tModName)" ;     } else {          write-verbose "(confirmed $tModName loaded: $tModCmdlet present)"     }
          } else {     Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;     Break; } ;
      } else {     write-verbose "(confirmed $tModName loaded: $tModCmdlet present)" } ;

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
            else{ write-verbose -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            throw "Unable to resolve $($tenorg) `$prefCred value!`nEXIT!"
            Break ;
        } ;
    } ;
    #>
    # multi-org AD
    <#still needs ADMS mount-ADForestDrives() and set-location code @ 395 (had to recode mount-admforestdrives and debug cred production code & infra-string inputs before it would work; will need to dupe to suspend variant on final completion
    #>

    if(!$global:ADPsDriveNames){
        $smsg = "(connecting X-Org AD PSDrives)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; } ; } ;
        $global:ADPsDriveNames = mount-ADForestDrives -verbose:$($verbose) ;
    } ;

    # cross-org ADMS requires switching to the proper forest drive (and use of -server xxx.xxx.com to access subdomains o the forest)
    $pdir = get-location ;
    #push-location ;
    $rgxDriveBanChars = '[;~/\\\.:]' ; # ;~/\.:,
    $rgxSamAcctName = '^[^\/\\\[\]:;|=,+?<>@?]+$' ;
    # "^[-A-Za-z0-9]{2,20}$" ; # 2-20chars, alphanum plus dash
    $rgxemailaddr = "^([0-9a-zA-Z]+[-._+&'])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}$" ;
    $rgxDistName = "^((CN=([^,]*)),)?((((?:CN|OU)=[^,]+,?)+),)?((DC=[^,]+,?)+)$" ;

    if( $tPsd = "$((Get-Variable  -name "$($TenOrg)Meta").value.ADForestName -replace $rgxDriveBanChars):" ){
        if(test-path $tPsd){
            $error.clear() ;
            TRY {
                set-location -Path $tPsd -ea STOP ;
                # even with psdrive context, keeps flipping forest, FORCE IT
                #$objForest = get-adforest ; # ad mod get-adforest vers ;
                $objForest = get-adforest -Identity (Get-Variable  -name "$($TenOrg)Meta").value.ADForestName -verbose:$($verbose) ;
                $doms = @($objForest.Domains) ; # ad mod get-adforest vers ;
                if($subdomain -AND ($doms -contains $subdomain) ){
                    write-verbose "(using specified -subdomain $($subdomain))" ;
                    $tdom = $subdomain ;
                } elseif($ADObject) {
                    <# prior looping subdomains search
                    $objForest = get-adforest ; # ad mod get-adforest vers ;
                    $doms = @($objForest.Domains) ; # ad mod get-adforest vers ;
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
                        } ;
                        foreach($dom in $doms){
                            write-verbose "Get-ADObject server:$($dom)" ;
                            if(Get-ADObject -filter $fltr  -Server $dom -ea 0){
                                $tdom = $dom ;
                                $smsg = "(matched $($ADObject) to forest subdomain:$($tdom))" ;
                                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                                else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                                break ;
                            } ;
                        } ;
                    };
                    #>
                    # instead do a forest-wide GC search (contains a limited set of attribs of all objs in forest, but good for locating nested obj)
                    $fltr = $null ;
                    $GcFwide = "$((Get-ADDomainController -domain $objForest.name -Discover -Service GlobalCatalog).hostname):3268" ;
                    $pltGADO=[ordered]@{server=$GcFwide; Properties='*'; ErrorAction='Stop' ;} ;
                    switch -regex ($ADObject){
                        $rgxSamAcctName {
                            $bSamacctname ;
                            $fltr = "SamAccountName -eq '$($ADObject)'" ;
                            # could use -identity, but it fails on multiple matches
                            $smsg = "SAMACCOUNT NAME SPECIFIED: WARNING:can return *mult* objects searching non-forest-uniques like samaccountnames!" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
                    } ;
                    if($fltr){
                        $pltGADO.add('filter',$fltr) ;
                    } ;
                    $smsg = "Get-ADObject w`n$(($pltGADO|out-string).trim())"
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    if($adObj = Get-ADObject @pltGADO){
                        # can return *mult* objects searching non-forest-uniques like samaccountnames!
                        if($bSamacctname){
                            if($adObj -is [system.array]){
                                $smsg = "FAILED TO MATCH *SINGLE* -ADObject SPEC (MULT RETURNS)- $($ADObject) - SWITCH UPN OR DN -ADOBJECT FORMAT!" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                BREAK ;
                            } ;
                        } else {

                        } ;
                        <# varis whether 3 or 4, need to walk
                        if($adObj.distinguishedname.split(',')[-3] -match 'OU=.*'){
                            # root dom
                            $tdom = (get-adforest).name ;
                        } else {
                            $tdom = $adObj.distinguishedname.split(',')[-3..-1].replace('DC=','') -join '.' ;
                        } ;
                        <#
                        $smsg = "($($ADObject) is homed in $($tdom) domain" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        # Get-ADDomainController technically returns  an ARRAY, force the first element, regardless, to ensure a system.string is output
                        $sgc = (Get-ADDomainController -domainname $tdom -discover).hostname[0] ;
                        $smsg = "returning GC:$($sgc))" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #>

                        $tdom = ($adObj.distinguishedname.split(',')|?{$_ -match 'DC=.*'}).replace('DC=','') -join '.' ;


                    } else {
                        write-warning "$((get-date).ToString('HH:mm:ss')):Unable to resolve specified identifier" ;
                        $smsg = "Unable to resolve specified identifier" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        BREAK ;

                    } ;

                } elseif($ForestWide){
                    $GcFwide = "$((Get-ADDomainController -domain $objForest.name -Discover -Service GlobalCatalog).hostname):3268"
                } else {
                    write-warning "$((get-date).ToString('HH:mm:ss')):NEITHER -SUBDOMAIN OR -ADOBJECT SPECIFIED!" ;
                    $smsg = "Unable to resolve specified identifier" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    BREAK ;
                } ;

            } CATCH {
                $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                set-location $pdir ; # restore dir
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;

        } else {
            $smsg = "UNABLE TO RESOLVE PROPER AD PSDRIVE FROM `$$($TENorg)Meta!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ;

    } else {
        $smsg = "UNABLE TO RESOLVE AD PSDRIVE NAME FROM `$$($TENorg)Meta.value.ADForestName!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ;

    if($tdom){
        $pltGAdDc=@{
            server = $tdom ; # no, use the per-user subdomain fqdn
            erroraction='STOP' ;
        } ;
        $smsg = "Get-ADDomainController w`n$(($pltGAdDc|out-string).trim())" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        $contextSite = (get-adreplicationsite).name
        if(($objForest | select -expand sites) -contains $contextsite){
            #$domainControllers = (Get-ADDomainController -Filter {isGlobalCatalog -eq $true -AND Site -eq "$((get-adreplicationsite).name)"} @pltGAdDc ).name
            #if($domainControllers = (Get-ADDomainController -Filter {isGlobalCatalog -eq $true -AND Site -eq "$($contextSite)"} @pltGAdDc ).name){
            if($domainControllers = (Get-ADDomainController -Filter {isGlobalCatalog -eq $true -AND Site -eq "$($contextSite)"} @pltGAdDc | select -expand hostname)){
                # used site
                $smsg = "(Site-specific DCs ($(($domaincontrollers|measure).count)): Get-ADDomainController -Filter {isGlobalCatalog -eq `$true -AND Site -eq $($contextSite)})" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } else {
                # siteless
                #$domainControllers = (Get-ADDomainController -Filter {isGlobalCatalog -eq $true } @pltGAdDc ).name
                $domainControllers = (Get-ADDomainController -Filter {isGlobalCatalog -eq $true } @pltGAdDc | select -expand hostname) ;
                $smsg = "(Failed through to Siteless DCs ($(($domaincontrollers|measure).count)): Get-ADDomainController -Filter {isGlobalCatalog -eq `$true})" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;

        } else {
            $smsg = "MISMATCH BETWEEN `$contextSite:$($contextSite) and `$objForest!:$($objForest.Name)!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ;
    } elseif($ForestWide -AND $GcFwide) {
        $smsg = "(-ForestWide specified: returning a root domain $($objForest.name) gc, with explicit forest-wide port 3268)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        [string]$finalDC = $GcFwide ;
    } else {
        $smsg = "FAILED TO RESOLVE A USABLE SUBDOMAIN SPEC FOR THE USER!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        BREAK ;
    }
    set-location $pdir ;
    #pop-location ;

    if($ForestWide -AND $GcFwide) {
        # single gc, no test
    } else {
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
        # after shifting to get-addomaincontroller (which outputs an array obj), ending up with some type of 2-element return, fails with ex10 cmdlets as -domaincontroller, need to coerce it into a single populated string item
        [string]$finalDC = $PotentialDCs | Get-Random  ;
        #$PotentialDCs | Get-Random | Write-Output
    } ;
    $finalDC| Write-Output ;
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

#*------v grant-ADGroupManagerUpdateMembership.ps1 v------
function grant-ADGroupManagerUpdateMembership {
    <#
    .SYNOPSIS
    grant-ADGroupManagerUpdateMembership - For a specified ADGroup, add '[x]Manager can update membership list' (visible in ADUC on the gorup's Managed-By tab)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-29
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,Permissions,Groups
    REVISIONS
    * 2:08 PM 11/30/2021 validated functional ; pulled verb-adms req, added alt to use get-addomaincontroller if verb-adms:get-gcfast() isn't avail
    * 3:18 PM 11/29/2021 initial vers
    .DESCRIPTION
    grant-ADGroupManagerUpdateMembership - For a specified ADGroup, add '[x]Manager can update membership list' (visible in ADUC on the gorup's Managed-By tab)
    This function is an alternative *ADMS*-native powershell approach, to the standard Exchange Mgmt Shell option:    
    #-=-=-=-=-=-=-=-=
    $grp=Get-DistributionGroup -id $group -domainc $dc;
    $pltAADP=[ordered]@{ User=$Manager ; AccessRights='WriteProperty' ; Properties='Member' ; domaincontroller=$dc ; ErrorAction = 'STOP' ; whatif=$($whatif) ; } ;
    $grp | Add-ADPermission @pltAADP ;
    $ADPerms = $grp | Get-ADPermission -domainc $dc | ? {($_.Properties -match 'Member') -AND ($_.AccessRights -eq 'WriteProperty') -AND ($_.User -notlike 'AD\Exchange*')} ; 
    #-=-=-=-=-=-=-=-=
    (which throsw cryptic Access Denied errors, in my enviro, and I don't have time to chase undocumented low level AD perm errors). 
    For me, the ADMS approach works either way. I'm moving ahead on the subject. 
    .PARAMETER  User
    Samaccountname/GUID/DN for user to be granted ManagedBy and 'Manager can update membership list'
    .PARAMETER  group
    AD identifyer (name,DN,guid) for ADGroup/DistribGroup to be configured with the updated permission
    .PARAMETER .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif]
    .EXAMPLE
    grant-ADGroupManagerUpdateMembership -user 'someuser' -group 'group X' -verbose ;
    Configure the permissions for 'someuser' on the 'group X' group, with verbose output
    .LINK
    #>
    #Requires -Modules ActiveDirectory
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    ## [OutputType('bool')] # optional specified output type

    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$True,HelpMessage="Samaccountname/GUID/DN for user to be granted ManagedBy and 'Manager can update membership list'")]
        ##[Alias('XXX')]
        [string]$User,
        [parameter(Mandatory=$True,HelpMessage="AD identifyer (name,DN,guid) for ADGroup/DistribGroup to be configured with the updated permission")]
        [string]$group,
        [Parameter(HelpMessage="Switch to return the ACL object to the pipeline (rather than `$true/`$false)[-ReturnObject]")]
        [switch] $ReturnObject,
        [Parameter(HelpMessage="Whatif switch [-whatIf]")]
        [switch] $whatIf
    ) ;  
    
    $verbose = ($VerbosePreference -eq "Continue") ;
    # constants
    $propsACL = 'ActiveDirectoryRights','InheritanceType','ObjectType','AccessControlType','IdentityReference','IsInherited' ; 
    $SelfMembershipGuid = [guid]'bf9679c0-0de6-11d0-a285-00aa003049e2' ;
    $rights = [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty -bOR [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight ;
    $ACLType = [System.Security.AccessControl.AccessControlType]::Allow  ;
    
    $error.clear() ;
    TRY {
        if(get-command get-gcfast){
            # use my verb-adms mod function if avail (validates speed)
            $dc = get-gcfast -Verbose:$($VerbosePreference -eq "Continue") ;         
        } else { 
            # use default adms option
            #$dc = (GET-ADDomaincontroller -discover).hostname
            $dc = (Get-ADDomainController -Filter  {isGlobalCatalog -eq $true -AND Site -eq "$((get-adreplicationsite).name)"}).hostname| Get-Random ; 
        } ; 
        $pltGADU=[ordered]@{
            identity = $user ;
            server=$dc; ErrorAction='STOP'; 
            #whatif=$($whatif);
        } ; 
        $smsg = "Get-ADUser w`n$(($pltGADU|out-string).trim())" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        $grantee = Get-ADUser @pltGADU ;
        
        $granteeSID = [System.Security.Principal.SecurityIdentifier]$grantee.sid ; 
        
        $domNBName = (Get-ADDomain (($grantee.distinguishedName.Split(',') |?{$_ -like 'DC=*'}) -join ',')).NetBIOSName ; 
        
        $pltGADG=[ordered]@{
            identity = $group ;
            properties = '*' ; 
            server=$dc; ErrorAction='STOP'; 
            #whatif=$($whatif);
        } ; 
        $smsg = "Get-ADGroup w`n$(($pltGADG|out-string).trim())" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        $tgroup = Get-ADGroup @pltGADG ;
        
        if ($tgroup.Managedby -AND ( ($tgroup.Managedby| get-recipient -ea 'STOP').distinguishedname -eq $grantee.distinguishedname )){
            $smsg = "$($grantee) is currrent ManagedBy of target DG`n$($tgroup.managedby)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } else { 
            $smsg = "NOTE!: $($grantee) is *not* currrent ManagedBy of target DG!`n$($tgroup.managedby)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            
            $pltSADG=[ordered]@{
                identity = $tgroup.DistinguishedName ;
                Replace=@{managedBy=$grantee.DistinguishedName} ;
                server=$dc; ErrorAction='STOP';
                whatif=$($whatif);
            } ;
 
            $smsg = "$((get-date).ToString('HH:mm:ss')):Make User ManagedBy of Group:" ; 
            $smsg += "`nSet-ADGroup w`n$(($pltSADG|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            Set-ADGroup @pltSADG ; 
            $smsg = "Get-ADGroup w`n$(($pltGADG|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $tgroup = Get-ADGroup @pltGADG ;
            $smsg = "POST Group: `n$(($tgroup|ft -a name,managedby | out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;
        
        $ACLrule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($granteeSID, $rights, $ACLType, $SelfMembershipGuid) ;
        
        if(test-path -path 'AD:'){
            $aclPath = "AD:\$($tgroup.distinguishedName)" ; 
            $acl = Get-Acl $aclPath ;

            if($grantACL = ($acl).Access |?{$_.objecttype -eq $SelfMembershipGuid -AND $_.InheritanceType -eq 'None' -AND $_.IdentityReference -eq "$($domNBName)\$($grantee.SamAccountName)"}){ 
                $smsg = "Found EXISTING matching ACL for user and perms:`n$(($grantACL | fl $propsACL|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            } else { 
                $acl.AddAccessRule($ACLrule)  ;
                $pltSACL=[ordered]@{
                    acl=$acl ;
                    path=$aclPath ;  
                    ErrorAction='STOP'; whatif=$($whatif);
                } ;
                $smsg = "Set-Acl w`n$(($pltSACL|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            
                Set-Acl @pltSACL ; 
                if(-not $whatif){
                $acl = Get-Acl $aclPath ;
                if($grantACL = ($acl).Access |?{$_.objecttype -eq $SelfMembershipGuid -AND $_.InheritanceType -eq 'None' -AND $_.IdentityReference -eq "$($domNBName)\$($grantee.SamAccountName)"}){ 
                    $smsg = "Updated matching ACL w`n$(($grantACL | fl $propsACL|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } else { 
                    $smsg = "Unable to locate Updated matching ACL w`n" ; 
                    $smsg += "`n| ?{$_.objecttype -eq $SelfMembershipGuid -AND $_.InheritanceType -eq 'None' -AND $_.IdentityReference -eq '$($domNBName)\$($grantee.SamAccountName)'} ; "
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ; 
                } else { 
                    $smsg = "(-whatif: skipping verifications)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } ; 
        } else { 
            $smsg = "Missing 'AD:' PsDrive!" 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            throw $smsg ;
        } ; 

        if($ReturnObject){
            $smsg = "(-ReturnObject specified: returning applied ACL object to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $grantACL | write-output ; 
        } else { 
            $smsg = "(returning `$true to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $true | write-output ; 
        } ; 

    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #-=-record a STATUSWARN=-=-=-=-=-=-=
        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
        #-=-=-=-=-=-=-=-=
        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $false | write-output ; 
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ; 
}

#*------^ grant-ADGroupManagerUpdateMembership.ps1 ^------

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
    * 9:18 AM 7/26/2021 added add-PSTitleBar ADMS tag, w verbose supp; moved connect-ad alias into function alias spec
    * 2:10 PM 6/9/2021 add verbose support 
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
    .EXAMPLE
    if(connect-ad){write-host 'connected'}else {write-warning 'unable to connect'}  ;
    Variant capturing & testing returned (returns true|false), using the alias name (if don't cap|eat return, you'll get a 'True' in console
    #>
    [CmdletBinding()]
    [Alias('connect-AD')]
    PARAM(
        [Parameter(HelpMessage="Specifies an array of cmdlets that this cmdlet imports from the module into the current session. Wildcard characters are permitted[-Cmdlet get-aduser]")]
        [ValidateNotNullOrEmpty()]$Cmdlet
    ) ;
    $Verbose = ($VerbosePreference -eq 'Continue') ;
    # focus specific cmdlet loads to SPEED them UP!
    $tMod = "ActiveDirectory" ;
    $ModsReg=Get-Module -Name $tMod -ListAvailable ;
    $ModsLoad=Get-Module -name $tMod ;
    $pltAD=@{Name=$tMod ; ErrorAction="Stop"; Verbose = ($VerbosePreference -eq 'Continue') } ;
    if($Cmdlet){$pltAD.add('Cmdlet',$Cmdlet) } ;
    if ($ModsReg) {
        if (!($ModsLoad)) {
            $env:ADPS_LoadDefaultDrive = 0 ;
            import-module @pltAD;
            Add-PSTitleBar 'ADMS' -verbose:$($VerbosePreference -eq "Continue") ;
            return $TRUE;
        } else {
            return $TRUE;
        } # if-E ;
    } else {
        Write-Error {"$((get-date).ToString('HH:mm:ss')):($env:computername) does not have AD Mgmt Tools installed!";};
        return $FALSE
    } # if-E ;
}

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
    # 3:34 PM 6/9/2021 rev'd all echos to write-verbose only (silent op)
    # 12:24 PM 3/19/2021 added -NoTOL to suppress inaccessible TOL forest (until network opens up the blocked ports) ;  flipped userroles to array SID,ESVC,LSVC, trying to get it to *always* pull working acct (failing in CMW)
    # 3:07 PM 3/18/2021 swapped overlapping vari names with prefixed $l[name] variants, also set to $script:Name scopes, to ensure no clashing. 
    # 7:05 AM 10/23/2020 added creation of $global:ADPsDriveNames when -Scope is global
    # 12:39 PM 10/22/2020 fixed lack of persistence - can't use -persist, have to use Script or Global scope or created PSD evaps on function exit context.
    # 3:02 PM 10/21/2020 debugged to function - connects fr TOR into TOR,TOL & CMW wo errors fr laptop, updated/expanded CBH examples; fixed missing break in OP_SIDAcct test
    # 7:59 AM 10/19/2020 added pretest before import-module
    4:11 PM 9/8/2020 building into verb-ADMS ; debugged through to TOR function, need fw access open on ports, to remote forest dc's: 5985 (default HTTP min), 5986 (HTTPS), 80 (pre-win7 http variant), 443 (pre-win7 https variant), 9389 (AD Web Svcs)
    * 10:29 AM 9/3/2020 init, still WIP, haven't fully debugged to function
    .DESCRIPTION
    mount-ADForestDrives() - Collect XXXMeta['ADForestName']'s and mount usable PSDrive objects for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest)
    Borrowed concept of a pre-configured array of $lforests from Raimund's post.
    .PARAMETER TorOnly
    Switch to limit test to local 'TOR' forest [-TorOnly]
    .PARAMETER NoTOL
    Switch to exclude TOL forest from creations (defaults true) [-NoTOL]
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
    Set-Location -Path "$(($ADForestDrive |?{$_.Name -eq (gv -name "$($lTenOrg)Meta").value.ADForestName.replace('.','')).Name):" ;
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
    ##requires -PSEdition Desktop
    #Requires -Modules ActiveDirectory
    #Requires -RunasAdministrator
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage = "Switch to limit test to local 'TOR' forest [-TorOnly]")]
        [switch] $TorOnly,
        [Parameter(HelpMessage = "Switch to exclude TOL forest from creations (defaults true) [-NoTOL]")]
        [switch] $NoTOL=$true,
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

        $script:lforests = @{} ;

        $globalMetas = get-variable  | Where-Object {$_.name -match '^\w{3}Meta$' -AND $_.visibility -eq 'Public' -ANd $_.value } ;

        if ($TorOnly){
            write-verbose "-torOnly specified, restricting config to TOR forest only"
            $globalMetas = $globalMetas | Where-Object { $_.value.o365_Prefix -eq 'TOR' } ;
        } elseif($NoTOL){
             write-verbose "-NoTOL specified, excluding TOL forest from processing"
            $globalMetas = $globalMetas | Where-Object { $_.value.o365_Prefix -ne 'TOL' } ;
        }

        # predetect context/role:
        foreach ($globalMeta in $globalMetas) {
            
            $smsg = "(checking:$(($globalMeta.value)['o365_Prefix']):acct context)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
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
            else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } else { 
                throw "Unrecognized local logon: $($env:userdomain)\$($env:username)!" ; 
        } ; 

        foreach ($globalMeta in $globalMetas) {

            $script:lTenOrg = $script:lLegacyDomain = $script:prefCred = $null ;
            $lTenOrg = ($globalMeta.value)['o365_Prefix'] ;
            if($lTenOrg -eq 'VEN'){
                #Stop
            } ;
            
            if($lLegacyDomain = ($globalMeta.value)['legacyDomain']){
                <#
                switch ($lTenOrg) {
                    "TOL" {$prefCred = "credTOLSID" }
                    "TOR" {$prefCred = "credTORSID" }
                    "CMW" {$prefCred = "credCMWSID" }
                    # no curr onprem grants
                    "VEN" {$prefCred = "" }
                    default {
                        throw "Unrecoginzed `$lTenOrg!:$($lTenOrg)"
                    }
                } ;
                #>
                # use $prefCred=get-HybridOPCredentials -TenOrg $lTenOrg -verbose -userrole SID ;
                # use $prefCred=get-TenantCredentials -TenOrg $lTenOrg -verbose -userrole SID ;
            
            
                $adminCred = $ForName = $null ;
                #$adminCred=get-HybridOPCredentials -TenOrg $lTenOrg -verbose -userrole $userRole ; 
                $adminCred=get-HybridOPCredentials -TenOrg $lTenOrg -verbose:$($Verbose) -UserRole @('SID','ESVC','LSVC') ; 
                if($adminCred){
                    #$adminCred = (Get-Variable -name $($prefCred)).Value ;
                    $lforestsName = (Get-Variable  -name "$($lTenOrg)Meta").value.ADForestName ;
                    $smsg = "Processing forest:$($lTenOrg):$($lLegacyDomain)::$($lforestsName)::$($adminCred.username)";
                    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    $lforests.add($lforestsName,$adminCred) ;
                }else {
                    $smsg = "*SKIP*:Processing forest:$($lTenOrg):::(UNCONFIGURED)";
                    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                } ;
            } else { 
                 $smsg = "*SKIP*:Processing forest:$($lTenOrg):::(no `$$($lTenOrg)Meta.LegacyDomain value configured)"; ; 
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } ; 
 
        } ; # loop-E

        if(-not(get-module ActiveDirectory)){
            # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
            if($VerbosePreference -eq "Continue"){
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

        foreach ($lforestshortName in $lforests.keys) {
        #foreach ($forest in $lforests) {
            TRY {
                $forestDN = (Get-ADRootDSE -Server $lforestshortName).defaultNamingContext ;
                <# New-PSDrive -Name -PSProvider -Root -Description -Scope -Persist
                use -Persist, or it will immediately close
                from within scripts, to have it persist outside of the script use -scope global
                #>

                # another expl: New-PSDrive -Name "RemoteAD" -PSProvider ActiveDirectory -root $Root -server $server -Scope Script
                # Note Scope is Script.  If not set, disappears outside of function.  Can set to Global

                $pltNpsD=@{
                    Name=($lforestshortName -replace $rgxDriveBanChars) ;
                    Root=$forestDN ;
                    PSProvider='ActiveDirectory' ;
                    Credential =$lforests[$lforestshortName].cred ; 
                    Server=$lforestshortName ;
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
                else{ write-verbose  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $bRet = New-PSDrive @pltNpsD ;
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;


            if ($bRet) {
                $retHash = @{
                    Name     = $bRet.Name ;
                    UserName = $lforests[$lforestshortName].cred.username ;
                    Status   = $true ;
                }
            } else {
                $retHash = @{
                    Name     = $pltNpsD.Name ;
                    UserName = $lforests[$lforestshortName].cred.username ;
                    Status = $false  ;
                } ;
            }
            if($scope -eq 'global'){
                $smsg = "(creating/updating `$global:ADPsDriveNames with summary of the new PSdrives)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $global:ADPsDriveNames = New-Object PSObject -Property $retHash 
            } ; 
            New-Object PSObject -Property $retHash | write-output ;
        } ; # loop-E
    } # PROC-E
    END {} ;
}

#*------^ mount-ADForestDrives.ps1 ^------

#*------v resolve-ADRightsGuid.ps1 v------
function resolve-ADRightsGuid {
    <#
    .SYNOPSIS
    resolve-ADRightsGuid() - Resolve a given get-ACL guid value to it's Name
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    AddedCredit : Faris Malaeb
    AddedWebsite:	https://devblogs.microsoft.com/powershell-community/understanding-get-acl-and-ad-drive-output/
    AddedTwitter:	URL
    CreatedDate : 2021-11-29
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,Permissions
    REVISIONS
    * 1:51 PM 11/29/2021 validated functional; init vers, adapted from demo code by Faris Malaeb [Understanding Get-ACL and AD Drive Output - PowerShell Community - devblogs.microsoft.com/](https://devblogs.microsoft.com/powershell-community/understanding-get-acl-and-ad-drive-output/)
    .DESCRIPTION
    resolve-ADRightsGuid() - Resolve a given get-ACL guid value to it's Name
    Queries the AD: AD psdrive provider under the SchemaNamingContext & Extended-Rights, then loops past the set finding the matching guid, and returning the resolved guid name value
    .PARAMETER  guid
    AD Rights guid value to be looked up against AD SchemaNamingContext & Extended-Rights 
    .EXAMPLE
    $guidName =resolve-ADRightsGuid -guid 'bf9679c0-0de6-11d0-a285-00aa003049e2' 
    Resolve the guid above to it's matching Name ('Self-Membership")
    .EXAMPLE
    # a random function that updates an ACL and  returns the acl as an object
    $aclret = grant-ADGroupManagerUpdateMembership -User SAMACCTNAME -group 'ADGROUPNAME' -verbose -returnobject ; 
    # resolve the returned acl guid ('ObjectType' prop) to it's matching name. 
    $guidname = resolve-adrightsguid -guid ($aclret.ObjectType) -verbose ;
    Example demoing a returned ACL guid, resolved to it's matching name
    .LINK
    https://devblogs.microsoft.com/powershell-community/understanding-get-acl-and-ad-drive-output/
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
## [OutputType('bool')] # optional specified output type

    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$True,HelpMessage="AD Rights guid value to be looked up against AD SchemaNamingContext & Extended-Rights ")]
        [guid]$guid
    ) ;  
    $verbose = ($VerbosePreference -eq "Continue") ; 

    $error.clear() ;
    TRY {
        $GetADObjectParameter=@{   
            SearchBase=(Get-ADRootDSE).SchemaNamingContext ;
            LDAPFilter='(SchemaIDGUID=*)' ;
            Properties=@("Name", "SchemaIDGUID") ;
        } ;
        write-verbose "Get-ADObject w`n$(($GetADObjectParameter |out-string).trim())" ;
        $SchGUID=Get-ADObject @GetADObjectParameter ;

        $ADObjExtPar=@{
            SearchBase="CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" ;
            LDAPFilter='(ObjectClass=ControlAccessRight)' ;
            Properties=@("Name", "RightsGUID") ;
        } ;
        write-verbose "Get-ADObject w`n$(($ADObjExtPar|out-string).trim())" ;
        $SchExtGUID=Get-ADObject @ADObjExtPar ;
        # loop the returns to find the first match
        foreach($rightsguid in @($SchGUID,$SchExtGUID)){
            if($guidobj = $rightsguid| ?{$_.rightsguid -eq $guid.tostring()}){
                $guidobj.name | write-output    ;
                break ; 
            } ;
        } ;
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #-=-record a STATUSWARN=-=-=-=-=-=-=
        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
        #-=-=-=-=-=-=-=-=
        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ; 
}

#*------^ resolve-ADRightsGuid.ps1 ^------

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

#*------v test-AADUserSync.ps1 v------
function test-AADUserSync {
    <#
    .SYNOPSIS
    test-AADUserSync - Check AD->AzureAD user sync status 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 3:37 PM 1/28/2022 fixed error, due to un-instantiated $rpt (needed to be an explicit array, forgot to declare at top). 
    * 3:00 PM 1/26/2022 init
    .DESCRIPTION
    test-AADUserSync - Check AD->AzureAD user sync status 

    -outputObject param returns a summary psobject to the pipeline:
    MSOLimmutableid : UC7OxxxxxxxxxxxxxxxR6g==
    MSOLguid        : 8cce2xxxxxxxxxxxxxxxxxxxxxxxxad391ea
    ADimmutableId   : UC7OxxxxxxxxxxxxxxxR6g==
    ADguid          : 8cce2xxxxxxxxxxxxxxxxxxxxxxxxad391ea
    isAADUserSynced    : True

    otherwise a boolean is returned, corresponding to the isAADUserSynced value

    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER showDebug
    Debugging Flag [-showDebug]
    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER outputObject
    Object output switch [-outputObject]
    .EXAMPLE
    PS> test-AADUserSync -UserPrincipalName UPN@DOMAIN.COM ; 
    Lookup AzureAD Licensing on UPN
    .EXAMPLE
    PS> $results = test-AADUserSync -UserPrincipalName UPN@DOMAIN.COM -outputObject ; 
        if($results.AADUserSynced){ 
            write-host -foregroundcolor green "ADUser:$($UPN) is AAD synced" 
        } else {
            write-warning "ADUser:$($UPN) is *NOT* AAD synced" 
        } ; 
    Example returning an object and testing post-status on object
    .EXAMPLE
    PS> if(test-AADUserSync -UserPrincipalName (get-exomailbox USER@DOMAIN.COM).userprincipalname{ 
        write-host -foregroundcolor green "ADUser:$($UPN) is AAD synced" 
        } else {
            write-warning "ADUser:$($UPN) is *NOT* AAD synced" 
        } ; 
    Lookup AzureAD Licensing on UPN, leveraging EXO mbx lookup to resolve, and test returned boolean
    .EXAMPLE
    PS> test-AADUserSync -UserPrincipalName USER@DOMAIN.COM 
    Single user test
    .EXAMPLE
    PS> $mdtable = @"
|Users|User_Name|Failed_assignements|Top_reasons_for_failure|
|---|---|---|---|
|FName LName|UPN@DOMAIN.com|1/1| Non-unique proxy address in Exchange Online|
|FName LName|email@DOMAIN.com|1/1| Non-unique proxy address in Exchange Online|
"@ ; 
    $users = $mdtable | convertfrom-markdowntable  ; 
    $results = test-AADUserSync -UserPrincipalName $users.user_name -outputObject -verbose ;
    $results | %{write-host "`n===" ; $_ } ; 
    Markdown table fed array test, with delimited output 
    .LINK
    https://github.com/tostka/verb-AAD
    #>
    ##Requires -Version 2.0
    #Requires -Version 3
    ##requires -PSEdition Desktop
    ##requires -PSEdition Core
    ##Requires -PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    ##Requires -Modules ActiveDirectory, AzureAD, MSOnline, ExchangeOnlineManagement, MicrosoftTeams, SkypeOnlineConnector, Lync,  verb-AAD, verb-ADMS, verb-Auth, verb-Azure, VERB-CCMS, verb-Desktop, verb-dev, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Mods, verb-Network, verb-L13, verb-SOL, verb-Teams, verb-Text, verb-logging
    ##Requires -Modules ActiveDirectory, AzureAD, MSOnline, ExchangeOnlineManagement, verb-AAD, verb-ADMS, verb-Auth, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Network, verb-Text
    #Requires -Modules MSOnline, verb-AAD, ActiveDirectory, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Network, verb-Text
    #Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    ## [OutputType('bool')] # optional specified output type


    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="UserPrincipalName [-UserPrincipalName xxx@toro.com]")][Alias('UPN')]
        $UserPrincipalName,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Object output switch [-outputObject]")]
        [switch] $outputObject
    ) # PARAM BLOCK END

    BEGIN { 
        $rgxEmployeeNumberProper = '^([0-9]{3,8})$' # 3-8 digit integer
        $rgxEmployeeNumberSamAcct = '^([A-Za-z0-9]{6,7})$' # 6-7 digit alphanum, likely is a samacctname in Employeenumber
        $rgxEmployeeNumberSamAcctSpaces = '^[\sA-Za-z0-9]{6,7}$' # 6-7 digit alphanum w spaces -> likely is a samacctname in Employeenumber w leading/trailing \s (trim it)
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } else {
            #$smsg = "Data received from parameter input: '$($InputObject)'" ; 
            $smsg = "(non-pipeline - param - input)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ; 
        # call func with $PSBoundParameters and an extra (includes Verbose)
        #call-somefunc @PSBoundParameters -anotherParam
    
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array - 
        #   param, iterated as $array=[pipe element n] through the entire inbound stack. 
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).
    
        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per 
        #   Process{} iteration (as process only brings in a single element of the pipe per pass) 
        
        [array]$Rpt = @() ; 
        $1stConn = $true ; 
        foreach($UPN in $UserPrincipalName) {
            # dosomething w $item
        
            # put your real processing in here, and assume everything that needs to happen per loop pass is within this section.
            # that way every pipeline or named variable param item passed will be processed through. 

            # if these are driven by ADConnect fails, it's almost guaranteed that the referred UPN exists in o365. But it may not onprem.

            if(gcm -name connect-msol){
                $sBnr="#*======v UPN: $($UPN): v======" ;
                write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):`n$($sBnr)" ;
                $hReports = [ordered]@{} ; 
                $Error.Clear() ; 
                Try {
                    if($showDebug){write-host  "$((get-date).ToString("HH:mm:ss")):connect-msol"; } ;
                    if($1stConn) { connect-msol ; $1stConn = $false }
                    else {connect-msol -silent} ; 
                    $pltgmu=[ordered]@{UserPrincipalName=$UPN  ;ErrorAction= 'STOP' } ;
                    $smsg = "get-msoluser w`n$(($pltgmu|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $msolu = $null ; 
                    $msolu = get-msoluser @pltgmu ; 
                    #$MSOLimmutableid=$null ; 
                    #$MSOLimmutableid=$msolu.ImmutableId ;
                    $MSOLguid=New-Object -TypeName guid (,[System.Convert]::FromBase64String($msolu.ImmutableId)) ;
                    $smsg = "(adding `$hReports.MSOLimmutableid, `$hReports.MSOLguid, and `$hReports.MSOLDname)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('MSOLimmutableid',$msolu.ImmutableId) ; 
                    $hReports.add('MSOLguid',$MSOLguid) ; 
                    $hReports.add('MSOLDname',$msolu.displayname) ; 

                } Catch {
                    Write-warning "Failed to exec cmd because: $($Error[0])" ;
                    Break ; 
                }  ;
        
                #$Error.Clear() ; 
                #Try {
                    $ADguid=$null ; 
                    # AD abberant -filter syntax: Get-ADUser -Filter 'sAMAccountName -eq $SamAc'
                    $filter = "userprincipalname -eq '$($UPN)'" ;
                    $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                    $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $ADUser = $null ; 
                    Try {
                        $ADUser = get-aduser @pltGADU ; 
                        # if it won't trigger test & throw 
                        if($AdUser){
                            $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        } else { 
                            $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            #throw $smsg  ; 
                            # try to throw a stock ad not-found error (emulate it)
                            throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] "$($smsg)"
                        } ; 
                    # doesn't work natively -filter doesn't generate a catchable error, even with -ea STOP, this block never triggers
                    } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        # Do stuff if not found
                        $smsg = "No GET-ADUSER match found for -filter:$($filter)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;      
                        # triage the UPN provided, trim to pre-strip leading/trailing \s's
                        $potEmployeeNumber,$UPNDomain = $UPN.split('@').trim() ;   
                        switch -Regex ($potEmployeeNumber){
                            $rgxEmployeeNumberProper {
                                # '^([0-9]{3,8})$' # 3-8 digit integer# 3-8 digit integer
                                $filter = "employeenumber -eq '$($potEmployeeNumber)'" ;
                                $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                #$pltGADU=[ordered]@{filter= "'employeenumber -eq $($potEmployeeNumber)'" ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ADUser = $null ; 
                                Try {
                                    $ADUser = get-aduser @pltGADU ; 
                                    # if it won't trigger test & throw 
                                    if($AdUser){
                                        $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    } else { 
                                        $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                        throw $smsg  ; 
                                    } ; 
                                } Catch {
                                   $smsg = "$(pltGADU.filter) *not* found";
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    throw $smsg 
                                    continue ; 
                                };
                            }
                            $rgxEmployeeNumberSamAcct {
                                # '^([A-Za-z0-9]{7,6})$' # 6-7 digit alphanum, likely is a samacctname in Employeenumber
                                $filter = "samaccountname -eq '$($potEmployeeNumber)'" ;
                                $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                #$pltGADU=[ordered]@{filter= "'samaccountname -eq $($potEmployeeNumber)'" ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ADUser = $null ; 
                                Try {
                                    $ADUser = get-aduser @pltGADU ; 
                                    # if it won't trigger test & throw 
                                    if($AdUser){
                                        $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    } else { 
                                        $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                        throw $smsg  ; 
                                    } ; 
                                } Catch {
                                   $smsg = "$(pltGADU.filter) *not* found";
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    throw $smsg 
                                    continue ; 
                                };
                            }
                            $rgxEmployeeNumberSamAcctSpaces {
                                # '^[\sA-Za-z0-9]{7,6}$' # 6-7 digit alphanum w spaces -> likely is a samacctname in Employeenumber w leading/trailing \s (trim it)
                                # shouldn't get here (stip ??? ) but leave it defined.
                                $potEmployeeNumber = $potEmployeeNumber.trim() ; # retrim, see if it will clear
                                $filter = "samaccountname -eq '$($potEmployeeNumber)'" ;
                                $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                #$pltGADU=[ordered]@{filter= "'samaccountname -eq $($potEmployeeNumber)'" ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ADUser = $null ; 
                                Try {
                                    $ADUser = get-aduser @pltGADU ; 
                                    # if it won't trigger test & throw 
                                    if($AdUser){
                                        $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    } else { 
                                        $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                        throw $smsg  ; 
                                    } ; 
                                }  Catch {
                                   $smsg = "$(pltGADU.filter) *not* found";
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    throw $smsg 
                                    continue ; 
                                };

                            } 
                            default {
                                $smsg = "Unrecognized EmployeeNumber scheme!" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                throw $smsg 
                                continue; 
                            } 
                        } ; # Switch-E
                        
                    #} ;                       
                    <#} Catch {
                        $smsg = "Failed to exec cmd because: $($Error[0])" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Break ; 
                    }  ;
                    #>
                    # reworking extended vers of above
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #-=-record a STATUSWARN=-=-=-=-=-=-=
                        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                        #-=-=-=-=-=-=-=-=
                        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                    } ; 
                    #

                    $ADguid=[guid]$ADUser.objectguid ;
                    $ADimmutableId = [System.Convert]::ToBase64String($ADguid.ToByteArray()) ;
                    $smsg = "(adding `$hReports.ADimmutableId, `$hReports.ADguid, and `$hReports.ADDname)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('ADimmutableId',$ADimmutableId) ; 
                    $hReports.add('ADguid',$ADguid) ; 
                    $hReports.add('ADDname',$ADUser.displayname) ; 
                <#} Catch {
                    $smsg = "Failed to exec cmd because: $($Error[0])" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    Break ; 
                }  ;
                #>
        
                if(($msolu.ImmutableId -eq $ADimmutableId) -AND ($ADguid.guid -eq $MSOLguid.guid)){
                    #write-host -foregroundcolor green "`n$((get-date).ToString('HH:mm:ss')):`n===$($tUPN) AD->AAD sync is INTACT:`n`n`$msolu.ImmutableId:`t$($msolu.ImmutableId) `nMATCHES converted `n`$ADimmutableId:`t`t$($ADimmutableId)`n`nAND `$ADguid.guid:`t$($ADguid.guid) `nMATCHES converted `n`$MSOLguid.guid:`t`t$($MSOLguid.guid)`n" ; 
                    $smsg = "`n$((get-date).ToString('HH:mm:ss')):`n===$($tUPN) AD->AAD sync is INTACT:"
                    $smsg += "`n`n`$msolu.ImmutableId:`t$($msolu.ImmutableId) `nMATCHES converted `n`$ADimmutableId:`t`t$($ADimmutableId)"
                    $smsg += "`n`nAND `$ADguid.guid:`t$($ADguid.guid) `nMATCHES converted `n`$MSOLguid.guid:`t`t$($MSOLguid.guid)`n" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $smsg = "(adding `$hReports.isAADUserSynced:`$true)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('isAADUserSynced',$true) ; 
                } else {
                    #write-host -foregroundcolor red "`n$((get-date).ToString('HH:mm:ss')):`n===$(tUPN) AD->AAD sync is BROKEN:`n`n`$msolu.ImmutableId:`t($($msolu.ImmutableId)) `nDOES NOT MATCH converted `n`$ADimmutableId:`t`t($($ADimmutableId))`n`nAND `$ADguid.guid:`t($($ADguid.guid)) `nDOES NOT MATCH converted `n`$MSOLguid.guid:`t`t($($MSOLguid.guid))`n" ; 
                    $smsg = "`n$((get-date).ToString('HH:mm:ss')):`n===$(tUPN) AD->AAD sync is BROKEN:" ; 
                    $smsg += "`n`n`$msolu.ImmutableId:`t($($msolu.ImmutableId)) `nDOES NOT MATCH converted `n`$ADimmutableId:`t`t($($ADimmutableId))" ; 
                    $smsg += "`n`nAND `$ADguid.guid:`t($($ADguid.guid)) `nDOES NOT MATCH converted `n`$MSOLguid.guid:`t`t($($MSOLguid.guid))`n" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $smsg = "(adding `$hReports.isAADUserSynced:`$false)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('isAADUserSynced',$false) ; 
                } ; 
        
                write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):`n$($sBnr.replace('=v','=^').replace('v=','^='))`n" ;
        
            } else {
                write-warning "Current profile lacks underlying connect-msol()" ; 
            } ; 
            
            # convert the hashtable to object for output to pipeline
            $Rpt += New-Object PSObject -Property $hReports ;
            
        
        } ; # loop-E

    } ;  # PROC-E
    END {
        if($outputObject){
            $smsg = "(Returning summary object to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
            $Rpt | Write-Output ; 
        } else {
            $smsg = "(Returning isAADUserSyncd boolean to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
            $Rpt.isAADUserSynced | write-output ; 
        }  
    } ;  # END-E
}

#*------^ test-AADUserSync.ps1 ^------

#*------v test-ADUserEmployeeNumber.ps1 v------
function test-ADUserEmployeeNumber {
    <#
    .SYNOPSIS
    test-ADUserEmployeeNumber - Check ADUser.employeenumber against TOR standards
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 1:09 PM 1/27/2022 shifted input from aduser to string empnum; added examples
    * 3:00 PM 1/26/2022 init
    .DESCRIPTION
    test-ADUserEmployeeNumber - Check an Emmployeenumber string against policy standards

    Fed an EmployeeNumber string, it will evaluate the value against current business rules

    .PARAMETER EmployeeNumber
    EmployeeNumber string [-EmployeeNumber '123456']
    .INPUT
    System.String    
    .OUTPUT
    System.Boolean
    .EXAMPLE
    PS> test-ADUserEmployeeNumber -ADUser UPN@DOMAIN.COM ; 
    Lookup AzureAD Licensing on UPN
    .EXAMPLE
    PS> $EN = $ADUserObject.employeenumber
        $results = test-ADUserEmployeeNumber -employeenumber $EN -verbose ; 
        if($results){ 
            write-host -foregroundcolor green "$($EN) is a legitimate employenumber" ;
        } else {
            write-warning "$($EN) is *NOT* a legitimate ADUser employenumber" ;
        } ; 
    Example returning an object and testing post-status on object
    .EXAMPLE
    PS> if(test-ADUserEmployeeNumber -employeenumber ($ADUsers.employeenumber | get-random -Count 30) -verbose){ 
            write-host -foregroundcolor green "legitimate employenumber" 
        } else {
            write-warning "*NOT* a legitimate ADUser employenumber" 
        } ; 
    Example that pulls 30 random employeenumbers from a variable containing a set of users
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    ##Requires -Version 2.0
    #Requires -Version 3
    ##requires -PSEdition Desktop
    ##requires -PSEdition Core
    ##Requires -PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    ##Requires -Modules ActiveDirectory, AzureAD, MSOnline, ExchangeOnlineManagement, MicrosoftTeams, SkypeOnlineConnector, Lync,  verb-AAD, verb-ADMS, verb-Auth, verb-Azure, VERB-CCMS, verb-Desktop, verb-dev, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Mods, verb-Network, verb-L13, verb-SOL, verb-Teams, verb-Text, verb-logging
    ##Requires -Modules ActiveDirectory, AzureAD, MSOnline, ExchangeOnlineManagement, verb-AAD, verb-ADMS, verb-Auth, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Network, verb-Text
    ##Requires -Modules MSOnline, verb-AAD, ActiveDirectory, verb-ADMS, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Network, verb-Text
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [OutputType('bool')] # optional specified output type
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="EmployeeNumber string [-EmployeeNumber '123456']")]
        $EmployeeNumber,
        [Parameter(HelpMessage="Object output switch [-outputObject]")]
        [switch] $outputObject
    ) # PARAM BLOCK END

    BEGIN { 
        $rgxEmailAddr = "^([0-9a-zA-Z]+[-._+&'])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,63}$" ;
        # added support for . fname lname delimiter (supports pasted in dirname of email addresses, as user)
        $rgxDName = "^([a-zA-Z]{2,}(\s|\.)[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)" ;
        #"^([a-zA-Z]{2,}\s[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)" ;
        $rgxObjNameNewHires = "^([a-zA-Z]{2,}(\s|\.)[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)_[a-z0-9]{10}"  # Name:Fname LName_f4feebafdb (appending uniqueness guid chunk)
        $rgxSamAcctNameTOR = "^\w{2,20}$" ; # up to 20k, the limit prior to win2k
        $rgxEmployeeID = 
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } else {
            #$smsg = "Data received from parameter input: '$($InputObject)'" ; 
            $smsg = "(non-pipeline - param - input)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ; 
        # call func with $PSBoundParameters and an extra (includes Verbose)
        #call-somefunc @PSBoundParameters -anotherParam
    
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array - 
        #   param, iterated as $array=[pipe element n] through the entire inbound stack. 
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).
    
        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per 
        #   Process{} iteration (as process only brings in a single element of the pipe per pass) 
        
        #$1stConn = $true ; 
        $isLegit = $false ; 
        foreach($EN in $EmployeeNumber){
            $smsg = "$($EN):" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            switch -regex ($EN.length){
                '(9|10)' {
                    write-warning "$($EN): 10-digit is an illegimate employeenumber length!" ;
                    $isLegit = $false ; 
                } 
                '(8|5)' {
                    if($EN -match '^[0-9]+$'){
                        write-verbose "$($EN): 5|8-digit integer mainstream employeenumber" ;
                        $isLegit = $true ; 
                    } else {
                        write-warning "$($EN): 8|5-digit:non-integer 5|8-char is an illegimate employeenumber length!" 
                        $isLegit = $false ; 
                    } ; 
                }
                '(7|6)' {
                    if($EN -match '^[0-9]+$') {
                        write-verbose "$($EN): 7|6-digit integer mainstream employeenumber" ;        
                        $isLegit = $true ; 
                    } elseif($EN -match '^[A-Za-z0-9]+$') {
                        write-warning "$($EN): 7|6-digit non-integer: likely has SamaccountName stuffed in employeenumber!" ;  
                        $isLegit = $false ; 
                    } elseif($EN -match '^[A-Za-z0-9\s]+$') {
                        write-warning "$($EN): 7|6-digit non-integer w \s: likely has leading/trailing \s char!" ;  
                        $isLegit = $false ; 
                    } else {
                        write-warning "7|6-digit:outlier undefined condition!"  ;
                        $isLegit = $false ; 
                    } ;      
                } ; 
                '(3|4)' {
                    if($EN -match '^[0-9]+$') {
                        write-verbose "$($EN): 3|4-digit integer mainstream employeenumber" ;     
                        $isLegit = $true ; 
                    } else {
                        write-warning "$($EN): 3|4-digit:outlier undefined condition!"  ;
                        $isLegit = $false ; 
                    } ;  
                } ; 
                default {
                    write-warning "$($EN.length):-digit:outlier undefined condition!"
                    $isLegit = $false ; 
                } ; 
            } ; 
            if($outputObject){
                <#           
                $oobj = [ordered]@{
                    EmployeeNumber=$EN ; 
                    isEmployeeNumber = $($isLegit) ; 
                } ; 
                #>
                $smsg = "(Returning summary object to pipeline)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
                #[psobject]$oobj | write-output ;
                #$cObj = [pscustomobject] @{EmployeeNumber=$EN ;isEmployeeNumber = $($isLegit) ; } ;
                #$oObj | write-output ; 
                [pscustomobject] @{EmployeeNumber=$EN ;isEmployeeNumber = $($isLegit) ; } | write-output ;
            } else { 
                $smsg = "(Returning boolean to pipeline)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
                $isLegit | write-output ; 
            } ; 
        } ; 

    } ;  # PROC-E
    END {
        

    } ;  # END-E
}

#*------^ test-ADUserEmployeeNumber.ps1 ^------

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

Export-ModuleMember -Function find-SiteRoleOU,get-ADForestDrives,Get-AdminInitials,get-ADRootSiteOUs,get-DCLocal,get-GCFast,get-GCFastXO,check-ReqMods,get-GCLocal,get-SiteMbxOU,grant-ADGroupManagerUpdateMembership,load-ADMS,mount-ADForestDrives,resolve-ADRightsGuid,Sync-AD,test-AADUserSync,test-ADUserEmployeeNumber,unmount-ADForestDrives,Validate-Password -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdtTS2tCXqeOz5BIVIfKfajcD
# S6egggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSf728U
# Ziw+p/Pe0KqNRz313hbSSTANBgkqhkiG9w0BAQEFAASBgJNFKJxgfCmBRZFJcALM
# S4a1pytWgRIcQ46OzKxp0S00H5i/ZPqOqXC2e3K1uNazPgcL6B6k8rok1dwLI3a4
# nvdEvS8G4X2vEMp4QkqBylJiGYB5K+oQUjlLSqdvDylo4Ze8pIYDRiZ3BhlZZL+z
# U4O6mr9S0Rg5m+wgV6+hbNMt
# SIG # End signature block
