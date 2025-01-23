﻿# verb-adms.psm1


  <#
  .SYNOPSIS
  verb-ADMS - ActiveDirectory PS Module-related generic functions
  .NOTES
  Version     : 4.2.0.0
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
    $runningInVsCode = $env:TERM_PROGRAM -eq 'vscode' ;

#*======v FUNCTIONS v======




#*------v Convert-ADSIDomainFqdnToNBName.ps1 v------
function Convert-ADSIDomainFqdnToNBName {
    <#
    .SYNOPSIS
    Convert-ADSIDomainFqdnToNBName.ps1 - Convert the ADDomain FQDN to the matching NetbiosName, using ADSI (no-dependancy on Windows)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-11-13
    FileName    : Convert-ADSIDomainFqdnToNBName.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,ADSite,Computer,ADSI
    AddedCredit : Alan Kaplan
    AddedWebsite: https://akaplan.com/author/admin/
    AddedTwitter: 
    REVISIONS
    * 1:28 PM 11/13/2024 init, expanded, added CBH etc to AK's blog post scriptblock
    * 1/30/17: AK's blog post (link below)
    .DESCRIPTION
    Convert-ADSIDomainFqdnToNBName.ps1 - Convert the ADDomain FQDN to the matching NetbiosName, using ADSI (no-dependancy on Windows)
    
    Expansion & wrap of scriptblock demo from Alan Kaplan's blog post:
    [Get the NetBIOS AD Domain Name from the FQDN – Alan's Blog](https://akaplan.com/2017/01/get-the-netbios-ad-domain-name-from-the-fqdn/)
    
    .PARAMETER Name
    Array of System Names to test (defaults to local machine)[-Name SomeBox]
    .EXAMPLE
    $DomNBName = Convert-ADSIDomainFqdnToNBName  -
    Return Netbiosname for specified AD Domain FQDN
    .EXAMPLE
    $DomNBName = Convert-ADSIDomainFqdnToNBName -Name somebox
    Return remote computer DomNBName name
    .LINK
    https://akaplan.com/2017/01/get-the-netbios-ad-domain-name-from-the-fqdn/
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding()]
    PARAM (
        [parameter(ValueFromPipeline=$true,HelpMessage="Array of System Names to test (defaults to local machine)[-Name SomeBox]")]
        [Alias('Domain')]
        [string[]]$DomainFqdn
    ) ; 
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 
    } ;  # BEG-E
    PROCESS {
        foreach($item in $DomainFqdn){
            
			$objRootDSE = [System.DirectoryServices.DirectoryEntry] "LDAP://rootDSE" ; 
			$ConfigurationNC= $objRootDSE.configurationNamingContext ; 
			$Searcher = New-Object System.DirectoryServices.DirectorySearcher  ; 
			$Searcher.SearchScope = "subtree"  ; 
			$Searcher.PropertiesToLoad.Add("nETBIOSName")| Out-Null ; 
			$Searcher.SearchRoot = "LDAP://cn=Partitions,$ConfigurationNC" ; 
			$searcher.Filter = "(&(objectcategory=Crossref)(dnsRoot=$item)(netBIOSName=*))" ; 
			($Searcher.FindOne()).Properties.Item("nETBIOSName") | write-output ; 
        } ;  # loop-E
    } ;  # PROC-E
    END {
        write-verbose "(Convert-ADSIDomainFqdnToNBName:End)" ; 
    } ; 
}

#*------^ Convert-ADSIDomainFqdnToNBName.ps1 ^------


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
    * 2:16 PM 6/24/2024: rem'd out #Requires -RunasAdministrator; sec chgs in last x mos wrecked RAA detection 
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
    ##Requires -RunasAdministrator
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


#*------v Get-ADSIComputerByGuid.ps1 v------
Function Get-ADSIComputerByGuid {
    <#
    .SYNOPSIS
    Get-ADSIComputerByGuid.ps1 - Dependency-less function to retrieve an AD computer object using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2023-08-30
    FileName    : Get-ADSIComputerByGuid.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ADSI,ActiveDirectory,Computer
    AddedCredit : Ro Yo Mi
    AddedWebsite:	https://serverfault.com/users/171487/ro-yo-mi
    AddedTwitter:	URL
    AddedCredit : François-Xavier Cat
    AddedWebsite:	https://lazywinadmin.github.io/
    AddedTwitter:	@lazywinadmin / https://twitter.com/lazywinadmin
    REVISIONS
    * 9:06 AM 9/26/2023 working (add to vad);  cleanup comment, updated CBH
    * 4:56 PM 8/30/2023 init
    * 6/19/2023 Ro Yo Mi's posted code sample
    * 10/30/2013 lazywinadmin's original post
    .DESCRIPTION
    Get-ADSIComputerByGuid.ps1 - Dependency-less function to retrieve an AD computer object using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    .PARAMETER  GUID
    Guid for computer object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'
    .PARAMETER LDAPserver
    Domain to be searched[-LDAPserver 'sub.domain.com']
    .EXAMPLE
    PS> get-adsicomputerbyguid -GUID nfbn-nden-nban-nbn-ncnedfn5 -LDAPserver sub.domain.com  ; 

    DNShostName                  Description                                       Name
    -----------                  -----------                                       ----
    AAAAAnnnn.AAAAAA.AA.AAAA.AAA DESCRIPTION                                       AAAAAnnnn
    
    Query specified server using it's ADComputer object's guid
    .LINK
    https://github.com/tostka/verb-ADMS
    .LINK
    https://serverfault.com/questions/310529/search-ad-by-guid
    .LINK
    https://lazywinadmin.com/2013/10/powershell-get-domaincomputer-adsi.html
    #>
    [CmdletBinding()]
    PARAM(
      [Parameter(Position=0,ValueFromPipeline=$true, Mandatory=$true, HelpMessage="Guid for computer object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'")]
          [String[]]$GUID,
      [Parameter(Mandatory=$true, HelpMessage="Domain to be searched[-LDAPserver 'sub.domain.com']")]
      $LDAPserver
    ) ;       
    PROCESS{
        FOREACH ($item in $GUID){
            $GetItem  = "GUID=$($item)" ;
            TRY{$DistinguishedName = $([ADSI]"LDAP://$($LDAPserver)/<$($GetItem)>").DistinguishedName} CATCH {$_ | fl * -Force; continue} ;
            if($DistinguishedName){
                TRY{
                    $Searcher = [ADSISearcher] ([ADSI] "LDAP://$($LDAPserver)") ;
                    $Searcher.Filter = "(&(objectCategory=Computer)(DistinguishedName=$($DistinguishedName)))"
                    FOREACH ($Computer in $($Searcher.FindAll())){
                        New-Object -TypeName PSObject -Property @{
                            "Name" = $($Computer.properties.name)
                            "DNShostName"    = $($Computer.properties.dnshostname)
                            "Description" = $($Computer.properties.description)
                        } | write-output ; 
                    } ; 
                } CATCH {$_ | fl * -Force; continue} 
            } else {throw "$($GetItem) failed to return a matching DistinguishedName" }; 
        } ; 
    } ; 
}

#*------^ Get-ADSIComputerByGuid.ps1 ^------


#*------v Get-ADSIObjectByGuid.ps1 v------
Function Get-ADSIObjectByGuid {
    <#
    .SYNOPSIS
    Get-ADSIObjectByGuid.ps1 - Dependency-less function to retrieve an AD object - computer|group|contact - using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2023-08-30
    FileName    : Get-ADSIComputerByGuid.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ADSI,ActiveDirectory,Computer
    AddedCredit : Ro Yo Mi
    AddedWebsite:	https://serverfault.com/users/171487/ro-yo-mi
    AddedTwitter:	URL
    AddedCredit : François-Xavier Cat
    AddedWebsite:	https://lazywinadmin.github.io/
    AddedTwitter:	@lazywinadmin / https://twitter.com/lazywinadmin
    REVISIONS
    10:12 AM 9/26/2023 working (add to vad); CBH working now (refactored 3x) ; pulled filter on mailcontact, uncommented the mailcontact block; updated CBH & examples
    * 11:26 AM 8/31/2023 init: validated all but -type:mailcontact works (documented msExchRecipientDisplayType is blank, on *all* xop MailContacts; can't filter that attrib at all, and get hits; default back to type:group wo the filtering for recipients)
    * 6/19/2023 Ro Yo Mi's posted code sample
    * 10/30/2013 lazywinadmin's original post
    .DESCRIPTION
    Get-ADSIObjectByGuid.ps1 - Dependency-less function to retrieve an AD object - computer|group|contact - using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    I use this so that I can specify objects in code by storing their fairly obscure guid in scripts, and then resolve the guid back to the full object details, for connectivy.
    
        -type mailbox filters 'OR' on the following 'mailbox' recipient variants: 
        Usermailbox|Sharedmailbox|RoomMailbox|RemoteMailUser|EquipmentMailbox|RemoteUserMailbox|RemoteRoomMailbox|RemoteEquipmentMailbox|RemoteSharedMailbox
    
        (same token, if local Exchange Mgmt Shell support can store recipients using the underlying Exchange guid, and use (get-recipient xxx).primarysmtpaddress to retrive the matching object's email address for specifying Notification addreses
        But this works with or without Exch/EXO connectivity, and has no module dependancy, as long as you locally load the code from this function)

    Properties returned per object type:
        - computer : 
        distinguishedname,description,name,whencreated,dnshostname,displayname,objectclass,objectCategory

        - group|distributiongroup :
        distinguishedname,description,name,whencreated,mailnickname,msexchrecipientdisplaytype,
        msexchrequireauthtosendto,mail,msexchhidefromaddresslists,objectclass,objectCategory,proxyaddresses,
        grouptype,info,whencreated,cn,managedby,member,displayname 

        - contact
        distinguishedname,description,name,givenname,sn,memberof,targetaddress,whencreated,
        mailnickname,mail,objectclass,objectCategory,proxyaddresses,whencreated,cn,displayname

        - user|mailbox:
        distinguishedname,description,name,whencreated,mailnickname,msexchrecipientdisplaytype,
        msexchremoterecipienttype,mail,objectclass,objectCategory,proxyaddresses,department,
        msexchwhenmailboxcreated,title,targetaddress,givenname,memberof,streetaddress,samaccountname,
        userprincipalname,countrycode,showinaddressbook,physicaldeliveryofficename,employeetype,initials,
        lastlogon,useraccountcontrol,postalcode,displayname,msexchrecipientdisplaytype,employeetype,
        initials,lastlogon,useraccountcontrol,postalcode,displayname,msexchrecipientdisplaytype,name,
        telephonenumber,mailnickname,employeenumber

    .PARAMETER  GUID
    Guid for AD object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'
    .PARAMETER LDAPserver
    Domain to be searched[-LDAPserver 'sub.domain.com']
    .PARAMETER GUID
    Guid for AD object to be returned (the AD guid, not any assoicated Exchange guid)[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne']
    .PARAMETER Type
    Type: LDAP objectCategory (or keyword for Computer|group|contact|user|mailbox|distributiongroup) for the target object[-Type 'computer']
    .PARAMETER LDAPserver
    Domain to be searched[-LDAPserver 'sub.domain.com'
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -guid 'nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn' -Type computer -LDAPserver SUB.DOM.DOMAIN.COM -verbose  ; 

    distinguishedname : {CN=SERVER,OU=OU,OU=SITE,DC=SUB,DC=DOM,DC=DOMAIN,DC=com}
    description       : {DESCRIPTIONTEXT}
    name              : {SERVER}
    whencreated       : {7/1/2014 3:27:24 PM}
    dnshostname       : {SERVER.SUB.DOM.DOMAIN.COM}
    displayname       : {SERVER$}
    objectclass       : {top, person, organizationalPerson, user...}
    objectCategory    : {CN=Computer,CN=Schema,CN=Configuration,DC=DOM,DC=DOMAIN,DC=COM}
    
    Demo resolving a guid to the full computer object.
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne' -Type 'user' -LDAPserver 'SUB.DOMAIN.COM' -verbose ;
    Query user object on guid
    PS> Get-ADSIObjectByGuid -guid nccenen-n-n-bfaa-cnadnea -Type mailbox -LDAPserver global.ad.toro.com
    Query a mail recipient
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -guid nfbn-nden-nban-nbn-ncnedfn -Type computer -LDAPserver SUB.DOM.DOMAIN.COM -verbose  ; 
    Query computer on guid
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -guid nffaencd-en-nan-anfc-nfnenan -Type contact -LDAPserver SUB.DOM.DOMAIN.COM
    Query contact on guid
    .LINK
    https://github.com/tostka/verb-ADMS
    .LINK
    https://serverfault.com/questions/310529/search-ad-by-guid
    .LINK
    https://lazywinadmin.com/2013/10/powershell-get-domaincomputer-adsi.html
    #>
    
    [CmdletBinding()]
    PARAM(
        [Parameter(Position=0,ValueFromPipeline=$true, Mandatory=$true, HelpMessage="Guid for AD object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne']")]
            [system.guid]$guid,
        [Parameter(Position=1, Mandatory=$true, HelpMessage="Type: LDAP objectCategory (or keyword for Computer|group|contact|user|mailbox|distributiongroup) for the target object[-Type 'computer']")]
            [ValidateSet('Computer','group','contact','user','mailbox','distributiongroup','mailcontact')]            
            [String[]]$Type,
        [Parameter(Mandatory=$true, HelpMessage="Domain to be searched[-LDAPserver 'sub.domain.com'")]
            $LDAPserver
    ) ;  
    BEGIN{
        <#
         LDAP filter Syntax:
         <filter>=(<attribute><operator><value>)
         or
         (<operator><filter1><filter2>)
         Operators
         = 	Equal to
         ~= 	Approximately equal to
         <= 	Lexicographically less than or equal to
         >= 	Lexicographically greater than or equal to
         & 	AND
         | 	OR
         ! 	NOT
			        to NOT something, lead it with a !(NOT), and enclose the structure with paras:
		 	        (&(mail=*)(!(objectClass=contact))) == "objects with some mail value and NOT objectClass=contact"
         Wildcards: 
         Get all entries: (objectClass=*)
         Get entries containing "bob" somewhere in the common name: (cn=*bob*)
         Get entries with a common name greater than or equal to "bob": (cn>='bob')
         Get all users with an e-mail attribute: (&(objectClass=user)(email=*))
         Get all entries without an e-mail attribute: (!(email=*))
         Get all user entries with an e-mail attribute and a surname equal to "smith":
 	        (&(sn=smith)(objectClass=user)(email=*))
         Get all user entries with a common name that starts with "andy","steve", or "margaret":
         (&(objectClass=user) | (cn=andy*)(cn=steve)(cn=margaret))
         (|(sAMAccountName=TransFloBillingMbx)(sAMAccountName=SQLservernotif))
         AD SYNTAX NOTES ::
         -----------------------------------------------------------
         User Type	objectClass		
 				        objectCategory	sAMAccountType	
         -----------------------------------------------------------
         User		top; person; organizationalPerson; user	
 				        Person			805306368	
 							
         Contact		top; person; organizationalPerson; contact
 				        Person			<none>
 											
         inetOrgPerson top; person; organizationalPerson; user; inetOrgPerson
 				        Person			805306368
 
         Computer	top; person; organizationalPerson; user; computer;
 				        Computer		805306369

         DL			group
					        group			268435457

         Dynamic DL	msExchDynamicDistributionList
					        ms-Exch-Dynamic-Distribution-List <none>

         PF			publicFolder
					        ms-Exch-Public-Folder <none>
        #>
        <#
         Underlying AD object range of recipient-related values: 

        [Exchange RecipientTypes | GetPS.dev](https://getps.dev/blog/exchange-recipienttypes/)
        November 16, 2020 · 4 min read    
        ### msExchRecipientDisplayType

        |DisplayName|Name|Value|
        |---|---|---|
        |ACL able Mailbox User|ACLableMailboxUser|1073741824|
        |Security Distribution Group|SecurityDistributionGroup|1043741833|
        |Equipment Mailbox|EquipmentMailbox|8|
        |Conference Room Mailbox|ConferenceRoomMailbox|7|
        |Remote Mail User|RemoteMailUser|6|
        |Private Distribution List|PrivateDistributionList|5|
        |Organization|Organization|4|
        |Dynamic Distribution Group|DynamicDistributionGroup|3|
        |Public Folder|PublicFolder|2|
        |Distribution Group|DistrbutionGroup|1|
        |Mailbox User|MailboxUser|0|
        |Synced Universal Security Group as Universal Security Group|SyncedUSGasUSG|-1073739511|
        |ACL able Synced Universal Secuirty Group as Contact|ACLableSyncedUSGasContact|-1073739514|
        |ACL able Synced Remote Mail User|ACLableSyncedRemoteMailUser|-1073740282|
        |ACL able Synced Mailbox User|ACLableSyncedMailboxUser|-1073741818|
        |Synced Universal Security Group as Contact|SyncedUSGasContact|-2147481338|
        |Synced Universal Security Group as Universal Distribution Group|SyncedUSGasUDG|-2147481343|
        |Synced Equipment Mailbox|SyncedEquipmentMailbox|-2147481594|
        |Synced Conference Room Mailbox|SyncedConferenceRoomMailbox|-2147481850|
        |Synced Remote Mail User|SyncedRemoteMailUser|-2147482106|
        |Synced Dynamic Distribution Group|SyncedDynamicDistributionGroup|-2147482874|
        |Synced Public Folder|SyncedPublicFolder|-2147483130|
        |Synced Universal Distribution Group as Contact|SyncedUDGasContact|-2147483386|
        |Synced Universal Distribution Group as Universal Distribution Group|SyncedUDGasUDG|-2147483391|
        |Synced Mailbox User|SyncedMailboxUser|-2147483642|


        ### msExchRecipientTypeDetails
        |DisplayName|Name|Value|
        |---|---|---|
        |Team Mailbox|TeamMailbox|137438953472|
        |Remote Shared Mailbox|RemoteSharedMailbox|34359738368|
        |Remote Equipment Mailbox|RemoteEquipmentMailbox|17179869184|
        |Remote Equipment Mailbox (IncorrectValue)|RemoteEquipmentMailbox|17173869184|
        |Remote Room Mailbox|RemoteRoomMailbox|8589934592|
        |Remote User Mailboxï¿½ï¿½ï¿½ï¿½ï¿½|RemoteUserMailbox|2147483648|
        |Role Group|RoleGroup|1073741824|
        |Discovery Mailbox|DiscoveryMailbox|536870912|
        |Room List|RoomList|268435456|
        |Linked User|LinkedUser|33554432|
        |Mailbox Plan|MailboxPlan|16777216|
        |Arbitration Mailbox|ArbitrationMailbox|8388608|
        |Microsoft Exchange|MicrosoftExchange|4194304|
        |Disabled User|DisabledUser|2097152|
        |Non-Universal Group|NonUniversalGroup|1048576|
        |Universal Security Group|UniversalSecurityGroup|524288|
        |Universal Distribution Group|UniversalDistributionGroup|262144|
        |Contact|Contact|131072|
        |User|User|65536|
        |Cross-Forest Mail Contact|MailForestContact|32768|
        |System Mailbox|SystemMailbox|16384|
        |System Attendant Mailbox|SystemAttendantMailbox|8192|
        |Public Folder|Public Folder|4096|
        |Dynamic Distribution Group|DynamicDistributionGroup|2048|
        |Mail-Enabled Universal Security Group|MailUniversalSecurityGroup|1024|
        |Mail-Enabled Non-Universal Distribution Group|MailNonUniversalGroup|512|
        |Mail-Enabled Universal Distribution Group|MailUniversalDistributionGroup|256|
        |Mail User|MailUser|128|
        |Mail Contact|MailContact|64|
        |Equipment Mailbox|EquipmentMailbox|32|
        |Room Mailbox|RoomMailbox|16|
        |Legacy Mailbox|LegacyMailbox|8|
        |Shared Mailbox|SharedMailbox|4|
        |Linked Mailbox|LinkedMailbox|2|
        |User Mailbox|UserMailbox|1|

        ### msExchRecipientTypeDetails 
        |1|UserMailbox|
        |---|---|
        |2|LinkedMailbox|
        |4|SharedMailbox|
        |16|RoomMailbox|
        |32|EquipmentMailbox|
        |128|MailUser|
        |2147483648|RemoteUserMailbox|
        |8589934592|RemoteRoomMailbox|
        |17179869184|RemoteEquipmentMailbox|
        |34359738368|RemoteSharedMailbox|
        #>  
        switch ($type){
            'computer'{
                write-verbose "Type:computer specified" ; 
                # "(&(objectCategory=$($type))(DistinguishedName=$($DistinguishedName)))"
                $filterType = "(objectCategory=computer)" ; 
                $prps= 'distinguishedname','description','name','whencreated','dnshostname','displayname','objectclass','objectCategory' | select -unique ; ; 
            }
            'group'{
                write-verbose "Type:group specified" ; 
                $filterType = "(objectCategory=group)" ; 
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchrequireauthtosendto','mail','msexchhidefromaddresslists','objectclass','objectCategory','proxyaddresses',
                    'grouptype','info','whencreated','cn','managedby','member','displayname' | select -unique ; ;
            }
            'distributiongroup'{
                write-verbose "Type:distributiongroup specified (mail-enabled variant of group)" ; 
                <# DL MailUniversalDistributionGroup have msExchRecipientDisplayType : 1
                Security Distribution Group	SecurityDistributionGroup	1043741833
                #>
                #$filterType = "(objectCategory=group)" ; 
                $filterType = "(objectCategory=group)(|(msExchRecipientDisplayType=1)(msExchRecipientDisplayType=1043741833))"
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchrequireauthtosendto','mail','msexchhidefromaddresslists','objectclass','objectCategory','proxyaddresses',
                    'grouptype','info','whencreated','cn','managedby','member','displayname' | select -unique ; ;
            }
            'contact'{
                write-verbose "Type:contact specified" ;
                $filterType = "(objectCategory=contact)" 
                $prps= 'distinguishedname','description','name','givenname','sn','memberof','targetaddress','whencreated',
                    'mailnickname','mail','objectclass','objectCategory','proxyaddresses','whencreated','cn','displayname' | select -unique ; ;
                # missing: ,'msexchrecipientdisplaytype','msexchhidefromaddresslists''managedby',
            }
            # 2:14 PM 8/31/2023 disable: none of the 'MailContacts' have a functional msExchRecipientDisplayType set. Still unsure how to differentiate a Mailcontact from an AD.Contact, disable this block, until we have a better fiter
            # 9:19 AM 9/26/2023 actually, it still returns the proper target obj, wo the msExchRecipientDisplayType filter: objectCategory=contact & guid are sufficient to isolate the single object
            'mailcontact'{
                write-verbose "Type:contact specified (mailcontact-specific *not* supported at this point, no working msExchRecipientDisplayType value to target)" ;
                # MailContacts: msExchRecipientDisplayType            : 6
                #$filterType = "(objectCategory=contact)" 
                #$filterType = "(&(objectCategory=contact)(msExchRecipientDisplayType=6))" ; # Mailcontacts have blank msExchRecipientDisplayType, drop the filter
                $filterType = "(&(objectCategory=contact))" ; 
                # msExchRecipientDisplayType=6 consistently fails to match, go to populated
                $filterType = "(&(objectCategory=contact)(msExchRecipientDisplayType=*))" ; 
                # even * fails -> none of the 'MailContacts' have a functional msExchRecipientDisplayType set. Still unsure how to differentiate a Mailcontact from an AD.Contact, disable this block, until we have a better fiter
                $prps= 'distinguishedname','description','name','givenname','sn','memberof','targetaddress','whencreated',
                    'mailnickname','mail','objectclass','objectCategory','proxyaddresses','whencreated','cn','displayname' | select -unique ; ;
                # missing: ,'msexchrecipientdisplaytype','msexchhidefromaddresslists''managedby',
            }
            #
            'user'{
                write-verbose "Type:user specified" ; 
                <# - objectClass=user is slower/unindexed and returns computer objects
                   - objectCategory=Person is a faster indexed field than the unindexed objectClass, 
                	    but returns user, inetOrgPerson & contacts
                   - just want to find user and inetOrgPerson objects and not have contacts and/or computers returned?
                    use: (&(objectClass=user)(objectCategory=Person))
                #>
                # "(&(objectCategory=$($type))(DistinguishedName=$($DistinguishedName)))"
                $filterType = "&(objectClass=user)(objectCategory=Person)" ;
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchremoterecipienttype','mail','objectclass','objectCategory','proxyaddresses','department',
                    'msexchwhenmailboxcreated','title','targetaddress','givenname','memberof','streetaddress','samaccountname',
                    'userprincipalname','countrycode','showinaddressbook','physicaldeliveryofficename','employeetype','initials',
                    'lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','employeetype',
                    'initials','lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','name',
                    'telephonenumber','mailnickname','employeenumber' | select -unique ; 
            } ; 
            'mailbox'{
                write-verbose "Type:mailbox specified (mail-enabled variant of user)" ; 
                <# 
                AD - Spot *real* Exchange-managed objects (vs ADDistributionGroups, ADContacts, ADUsers w mail populated):
                Dl's have msExchRecipientDisplayType : 1
                OnPrem user mbxs: msExchRecipientDisplayType : 1073741824
                Remotemailboxes: msExchRecipientDisplayType : -2147483642
                   Note: they no longer have homemdb
                MailContacts: msExchRecipientDisplayType            : 6
                All Exchange-maintained objects have msExchRecipientDisplayType set. AD-objects 'faking' it won't. 
                (&(objectClass=user)(mail=*)(!(extensionAttribute2=*)))
                # or
                (|(msExchRecipientDisplayType=1073741824)(msExchRecipientDisplayType=-2147483642))

                # dump types: 
                get-recipient -filter {recipienttypedetails -eq 'UserMailbox'} -ResultSize 1 | select -expand samaccountname | %{get-aduser -id $_ -prop * | fl msExchRecipientDisplayType}

                Usermailbox  has msExchRecipientDisplayType  1073741824
                Sharedmailbox " 0
                RoomMailbox 7 
                RemoteMailUser 6
                EquipmentMailbox 8
                RemoteUserMailbox " -2147483642
                RemoteRoomMailbox has msExchRecipientDisplayType -2147481850
                RemoteEquipmentMailbox "  -2147481594
                RemoteSharedMailbox " -2147483642

                #>
                #$filterType = "&(objectClass=user)(objectCategory=Person)" ;
                # (&(objectClass=user)(mail=*))
                #$filterType = "&(objectClass=user)(mail=*)(|(msExchRecipientDisplayType=1073741824)(msExchRecipientDisplayType=-2147483642))"
                # add other variant msExchRecipientDisplayType's to the list
                $filterType = "&(objectClass=user)(mail=*)(|(msExchRecipientDisplayType=1073741824)(msExchRecipientDisplayType=0)(msExchRecipientDisplayType=6)(msExchRecipientDisplayType=7)(msExchRecipientDisplayType=8)(msExchRecipientDisplayType=-2147483642)(msExchRecipientDisplayType=-2147481850)(msExchRecipientDisplayType=-2147481594))"
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchremoterecipienttype','mail','objectclass','objectCategory','proxyaddresses','department',
                    'msexchwhenmailboxcreated','title','targetaddress','givenname','memberof','streetaddress','samaccountname',
                    'userprincipalname','countrycode','showinaddressbook','physicaldeliveryofficename','employeetype','initials',
                    'lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','employeetype',
                    'initials','lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','name',
                    'telephonenumber','mailnickname','employeenumber' | select -unique ; 
            }
        } ;
    } ;     
    PROCESS{
        <# Old LDAP/LDP/dsquery filtering notes:
        try to hybrid mbxs & dl's: ((class=user OR group) AND mail non-null) returned 11k items...
        set FILTER="(&(|(objectClass=user)(objectClass=group))(mail=*))"
        - mail-enabled users: (&(objectClass=user)(mail=*)) 
        -  this one returns all mail-enabled groups (dl's)
            set FILTER="(&(mail=*)(objectClass=group))"
        -  filter on displayname
            "(&(displayName=LASTNAME, FNAME))"
            (&(mail= Todd.Kadrie@Rbcdain.com))
            Primarysmtpaddress in the string
            (&(proxyAddresses=SMTP:*user@mydomain.com*))
        - LDAP - DL ManagedBy Search
            (managedBy=distinguishedNameOfPerson)
        - * If you wanted a list of Computers, showing their location, operatingSystem, operatingSystemVersion, and operatingSystemServicePack, use:
            dsquery * domainroot -filter "(&(objectCategory=Computer)(objectClass=User))" -attr distinguishedName location operatingSystem operatingSystemVersion operatingSystemServicePack -limit 0
        - set FIELDS="DN, displayName, info, mail, mailNickname, managedBy, name, proxyAddresses, sAMAccountName, sAMAccounttype, showInAddressbook, msExchRequireAuthToSendTo, description"
            "DN, displayName, sAMAccountName, proxyAddresses"
            "DN, employeeID, givenName, initials, sn, proxyAddresses, sAMAccountName"
            "DN, employeeID, givenName, initials, sn, proxyAddresses, sAMAccountName, employeeID, objectClass"
             for dl's or groups:
            "DN, displayName, info, mail, mailNickname, managedBy, name, proxyAddresses, sAMAccountName, sAMAccounttype, showInAddressbook, msExchRequireAuthToSendTo, description"
            "DN, employeeID, givenName, initials, sn, proxyAddresses, sAMAccountName, physicalDeliveryOfficeName, employeeID, telephoneNumber, title, homeMTA, msExchHomeServerName, description"

        -  query filter on 3 attributes:
             (&(&(objectClass=user)(objectClass=top))(objectClass=person))
             For 4 attributes, this would be:
             (&(&(&(objectClass=top)(objectClass=person))(objectClass=organizationalPerson))(objectClass=user))
        -  objectClass=user is slower/unindexed and returns computer objects
             objectCategory=Person is a faster indexed field than the unindexed objectClass, 
            		but returns user, inetOrgPerson & contacts
             just want to find user and inetOrgPerson objects and not have contacts and/or computers returned?
             use: (&(objectClass=user)(objectCategory=Person))
             or qry against the sAMAccounttype directly (same effect, also indexed, and very specific):
             		(sAMAccountType=805306368)

             only objects of inetOrgPerson class you can use the following filter.
            	(&(objectClass=inetOrgPerson)(objectCategory=Person))

             user objects without returning inetOrgPersons you need to specifically exclude inetOrgPerson
            	(&(sAMAccountType=805306368)(!(objectClass=inetOrgPerson)))

             in general searches that use the logical NOT operator (such as the one above) should be avoided 
            	unless there is no alternative.  This is because it can cause the query processor to return objects to 
            	which you do not have access or specific attributes that do not have a value.

             For more efficient searches start at the lowest point in the AD hierarchy that will give you the 
            	result you are looking for
        #>

        FOREACH ($item in $GUID){
            $GetItem  = "GUID=$($item)" ;
            write-verbose "LDAP://$($LDAPserver)/<$($GetItem)>..." ; 
            TRY{$DistinguishedName = $([ADSI]"LDAP://$($LDAPserver)/<$($GetItem)>").DistinguishedName} CATCH {$_ | fl * -Force; continue} ;
            if($DistinguishedName){
                TRY{
                    $Searcher = [ADSISearcher] ([ADSI] "LDAP://$($LDAPserver)") ;
                    #(&(objectCategory=$($type))(DistinguishedName=$($DistinguishedName)))
                    $fltr = "(&($($filterType))(DistinguishedName=$($DistinguishedName)))"
                    $Searcher.Filter = $fltr ; 
                    write-verbose "`$Searcher.Filter:`n$($Searcher.Filter)" ; 
                    FOREACH ($object in $($Searcher.FindAll())){
                        if($host.version.major -ge 3){$hsh = [ordered]@{'dummy' = $null} } 
                        else { $hsh = @{'dummy' = $null} ; } ; 
                        if($hsh.Contains('dummy')){$hsh.remove('dummy')} ; 
                        write-verbose "cycling & adding `$prps" ; 
                        $prps |foreach-object{
                            $hsh.add($_,$object.properties[$_]) 
                        } ; 
                        write-verbose "returning PSObject to pipeline" ; 
                        New-Object -TypeName PSObject -Property $hsh | write-output ;
                    } ; 
                } CATCH {$_ | fl * -Force; continue} 
            } else {throw "$($GetItem) failed to return a matching DistinguishedName" }; 
        } ; 
    } ; 
}

#*------^ Get-ADSIObjectByGuid.ps1 ^------


#*------v get-ADSiteLocal.ps1 v------
function get-ADSiteLocal {
    <#
    .SYNOPSIS
    get-ADSiteLocal.ps1 - Return the local computer's AD Site name.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-08-16
    FileName    : get-ADSiteLocal.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,ADSite,Computer
    AddedCredit : 
    AddedWebsite: 
    AddedTwitter: 
    REVISIONS
    * 10:03 AM 9/14/2022 init
    .DESCRIPTION
    get-ADSiteLocal.ps1 - Return the local computer's AD Site name
    Simple wrap of the 
    [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name ;
    for local machine, or 'nltest /server:$Item /dsgetsite 2' for remote machines
    .PARAMETER Name
    Array of System Names to test (defaults to local machine)[-Name SomeBox]
    .EXAMPLE
    $ADSite = get-ADSiteLocal 
    Return local computer ADSite name
    .EXAMPLE
    $ADSite = get-ADSiteLocal -Name somebox
    Return remote computer ADSite name
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding()]
    PARAM (
        [parameter(ValueFromPipeline=$true,HelpMessage="Array of System Names to test (defaults to local machine)[-Name SomeBox]")]
        [string[]]$Name = $env:COMPUTERNAME
    )
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 
    } ;  # BEG-E
    PROCESS {
        foreach($item in $Name){
            
            if($item -eq $env:ComputerName){
                
               $bNonWin = $false ; 
                if( (get-variable isWindows -ea 0) -AND $isWindows){
                    write-verbose "(`$isWindows:$($IsWindows))" ; 
                }elseif( (get-variable isWindows -ea 0) -AND -not($isWindows)){
                    write-verbose "(`$isWindows:$($IsWindows))" ; 
                    $smsg = "$($env:computername) IS *NOT* A WINDOWS COMPUTER!`nThis command is unsupported without Windows..." ; 
                    write-warning $smsg 
                    throw $smsg ; 
                    Break ; 
                } else{
                    switch ([System.Environment]::OSVersion.Platform){
                        'Win32NT' {
                            write-verbose "$($env:computername) detects as a windows computer)" ; 
                            $bNonWin = $false ; 
                        }
                        default{
                          # Linux/Unix returns 'Unix'
                          $bNonWin = $true ; 
                        } ;
                    } ; 
                } ; 
                if($bNonWin){
                    $smsg = "$($env:computername) IS *NOT* A WINDOWS COMPUTER!`nThis command is unsupported without Windows..." ; 
                    write-warning $smsg 
                    throw $smsg ; 
                    Break ; 
                } ; 
                write-host "(retrieving local computer AD Site name...)" ; 
                TRY{
                    [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name | write-output ; 
                } CATCH {$smsg = $_.Exception.Message ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    Continue ;
                } ;
            
            } else { 
                # there's fancier ways to do it, but the nltest works across revs
                if(get-command nltest){
                    write-verbose "(using legacy nltest /server:$($Item) /dsgetsite 2...)" ; 
                    $site = nltest /server:$Item /dsgetsite 2>$null
                    if($LASTEXITCODE -eq 0){ $site[0] | write-output } 
                    else {
                        $smsg = "nltest non-zero `$LASTEXITCODE:$($LASTEXITCODE): UNABLE to determine remote machine's ADSite!" ; 
                        write-warning $smsg 
                        throw $smsg ; 
                        Continue ; 
                    } ; 
                } else {
                    $smsg = "UNABLE to locate local nltest dependancy!" ; 
                    write-warning $smsg 
                    throw $smsg ; 
                    Break ; 
                } ;  ; 
            } ;  
        } ;  # loop-E
        
    } ;  # PROC-E
    END {
        write-verbose "(get-ADSiteLocal:End)" ; 
    } ; 
}

#*------^ get-ADSiteLocal.ps1 ^------


#*------v get-ADUserDetailsTDO.ps1 v------
Function get-ADUserDetailsTDO {
        <#
        .SYNOPSIS
        get-ADUserDetailsTDO - Uses ADSI LDAP to retrieve AD User information  (wo need for full ActiveDirectory powershell module)
        .NOTES
        Version     : 2.0.5
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 2015-09-03
        FileName    : get-ADUserDetailsTDO.ps1
        License     : (none-asserted)
        Copyright   : (none-asserted)
        Github      : https://github.com/tostka/verb-adms
        Tags        : Powershell, ActiveDirectory, User, Accounts, Security.Principal. SecurityIdentifier
        AddedCredit : Ed Wilson
        AddedWebsite: https://devblogs.microsoft.com/scripting/use-powershell-to-translate-a-users-sid-to-an-active-directory-account-name/
        AddedTwitter: URL
        REVISIONS
        * 2:42 PM 5/29/2024 pulled -samaccountname default to $env:username, and shifted it to an example (keep from resolving, when -SID is specified); added explicit w-o's (rplc'd shell closing Exits); extended CBH); removed extraneous output formatting new-underling()
            ren'd UserToSid-SidToUser.ps1 -> get-ADUserDetailsTDO; ren'd Get-UserToSid() -> _resolve-ADSamAccountNameToSID, Get-SidToUser() -> _resolve-ADSidToSamAccountName()
        #10/12/2010 - posted version
        .DESCRIPTION
        get-ADUserDetailsTDO - Uses ADSI LDAP to retrieve AD User information  (wo need for full ActiveDirectory powershell module)

        Extension of samples from on old ScriptingGuy post from 2010.
        I've extended the basic SamAccountName <-> SID queries demo'd to include ADUser equiv lookup & return, and UPN & SamAccName return. 

        .PARAMETER Domain
        AD Domain hosting the target user [-Domain MyDom]
        .PARAMETER SamAccountName
        AD SamAccountName for the target user [-SamAccountName LnameFI]
        .PARAMETER SID
        AD Account SID value for target user [-SID S-n-n-nn-nnnnnnnnnn-nnnnnnnnn-nnnnnnnnnn-nnnnn]
        .PARAMETER returnADUser
        Switch to return the resolved user's ADUser properties [-returnADUser]
        .PARAMETER returnUPN
        Switch to return the resolved user's UserPrincipalName [-returnUPN]
        .PARAMETER returnSamAccountName
        Switch to return the resolved user's SamAccountName [-returnSamAccountName]
        .INPUTS
        [string]
        .OUTPUTS
        [string] UPN or SamAccountname
        [pscustomobject] AD User properties         
        .EXAMPLE
        PS> $ADUser = get-ADUserDetailsTDO  -samaccountname “mytestuser”
        Resolves the user samaccountname to the matching AD User details
        .EXAMPLE
        PS> $ADUser = get-ADUserDetailsTDO  -samaccountname $env:USERNAME
        Resolves the username environment variable as samaccountname to the matching AD User details
        .EXAMPLE
        PS> $ADUser = get-ADUserDetailsTDO  -sid “S-1-5-21-1877799863-120120469-1066862428-500”
        Resolves the user SID to the matching AD User details
        .EXAMPLE
        PS> $UPN = get-ADUserDetailsTDO  -samaccountname “mytestuser” -returnUPN
        Resolves the user samaccountname to the matching AD User UserPrincipalName, assigns return to a variable
        .EXAMPLE
        PS> $SamaccountName = get-ADUserDetailsTDO  -samaccountname “mytestuser” -returnSamAccountName
        Resolves the user samaccountname to the matching AD User returnSamAccountName, assigns return to a variable
        .LINK
        https://devblogs.microsoft.com/scripting/use-powershell-to-translate-a-users-sid-to-an-active-directory-account-name/
        .LINK
        https://github.com/tostka/verb-ADMS
        #>
        [CmdletBinding()]
        #[Alias('Get-ExchangeServerInSite')]
        PARAM(
            [Parameter(HelpMessage="AD Domain hosting the target user [-Domain MyDom]")]
                [string]$domain = $env:USERDOMAIN, 
            [Parameter(Position=0,ValueFromPipeline=$true,HelpMessage="AD SamAccountName for the target user [-samaccountname LnameFI]")]
                [Alias('user')]
                [string]$SamAccountName, 
            [Parameter(HelpMessage="AD Account SID value for target user [-SID S-n-n-nn-nnnnnnnnnn-nnnnnnnnn-nnnnnnnnnn-nnnnn]")]
                [string]$sid,
            [Parameter(HelpMessage="Switch to return the resolved user's ADUser properties [-returnADUser]")]
                [switch]$returnADUser,
            [Parameter(HelpMessage="Switch to return the resolved user's UserPrincipalName [-returnUPN]")]
                [switch]$returnUPN,
            [Parameter(HelpMessage="Switch to return the resolved user's SamAccountName [-returnSamAccountName]")]
                [switch]$returnSamAccountName
        ) ; 
        BEGIN{
            ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
            $Verbose = ($VerbosePreference -eq 'Continue') ;
            $rPSBoundParameters = $PSBoundParameters ; 
            $PSParameters = New-Object -TypeName PSObject -Property $rPSBoundParameters ;
            write-verbose "`$rPSBoundParameters:`n$(($rPSBoundParameters|out-string).trim())" ;
            #region BANNER ; #*------v BANNER v------
            $sBnr="#*======v $(${CmdletName}): $($SamAccountName,$sid) v======" ;
            $smsg = $sBnr ;
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
            #endregion BANNER ; #*------^ END BANNER ^------
        } ;  # BEG-E
        PROCESS{
            TRY{
                if(-not $SID -and $SamAccountName){
                    $smsg = "Translate SamAccountname $($SamAccountname) to SID" ; 
                    write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"
                    $ntAccount = new-object System.Security.Principal.NTAccount($domain, $SamAccountName) ; 
                    $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier]) ; 
                } ; 
                write-host "Resolve SID to ADUser information (slow [adsi]LDAP:// query...)";
                $account = [adsi]"LDAP://<SID=$($sid)>" ;
                if( $returnUPN){
                    $account.Properties["UserPrincipalName"] | Write-Output
                }elseif($returnSamAccountName){
                    $account.Properties["SamAccountName"] | Write-Output
                }elseif($returnADUser -OR -not ($returnUPN -OR $returnSamAccountName)){
                    $adout = $($account | select-object *) ; 
                    <# empty object/no-matches return: Test .guid populated 
                    AuthenticationType :
                    Children           :
                    Guid               :
                    ObjectSecurity     :
                    Name               :
                    NativeGuid         :
                    NativeObject       :
                    Parent             :
                    Password           :
                    Path               :
                    Properties         :
                    SchemaClassName    :
                    SchemaEntry        :
                    UsePropertyCache   :
                    Username           :
                    Options            :
                    Site               :
                    Container          : 
                    #>
                    if($null -eq $adout.Guid ){
                        
                        $smsg = "No matching AD Object returned for:`n$(($PSParameters|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } else {
                        $smsg = "return resolved ADUser properties to pipeline" ; 
                        write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                        $adout | write-output ;                     
                    } ; 
                };
            } CATCH [System.Management.Automation.MethodInvocationException]{
                $ErrTrapd=$Error[0] ;
                switch -Regex ($ErrTrapd.exception){
                    'Some\sor\sall\sidentity\sreferences\scould\snot\sbe\stranslated\.'{
                        $smsg = "Unable to resolve -SamAccountName '$($SamAccountName)' to an SID" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        break ; 
                    } 
                    default {
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    }
                } ; 
            } CATCH {
                #$ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #
                <# full trap
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $smsg = $ErrTrapd.Exception.Message ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
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
                #>
            } ; 
            
        } ;  # PROC-E
        END{
            $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; 
    }

#*------^ get-ADUserDetailsTDO.ps1 ^------


#*------v get-ADUserViaUPN.ps1 v------
function get-ADUserViaUPN {
    <#
    .SYNOPSIS
    get-ADUserViaUPN - get-ADUser wrapper that implements a -UserPrincipalName parameter, and proper -EA STOP error return (like the -Identity parameter). 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-02-03
    FileName    : get-ADUserViaUPN
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell, ActiveDirectory, UserPrincipalName
    REVISIONS
    * 2:16 PM 6/24/2024: rem'd out #Requires -RunasAdministrator; sec chgs in last x mos wrecked RAA detection 
    * 10:57 AM 2/3/2022 init
    .DESCRIPTION
    get-ADUserViaUPN - get-ADUser wrapper that implements proper -EA STOP error return when using -filter {UPN -eq 'someupn@domain'}. 
    Issue is that the get-AD* ActiveDirectory module cmdlets completely fail to implement a variety of standard features of other powershell modules. 
     -Identity has no support for UserPrincipalName lookup (the modern authentication identifier). 
        instead, the standard supported approach is to use the -filter cmdlet to run a filtered search: 
        -filter "userprincipalname -eq 'UPN@domain.com'"
        or, with variables:
        -filter "userprincipalname -eq '$($UPN)'"
     -But, unlike failures to lookup using the -identity parameter, use of the necessary -Filter parameter fails to generate a Try/Catch-able error even when using -ErrorAction 'STOP'. 
     -This makes it a challenge to detect lookup failures. So this wrapper function aims to shim in the missing bits, to provide a get-aduser cmdlet that at least *somewhat* emulates proper -userprinicpalname parameter suppor. 
     
    The wrapper function passes through the following stock get-aduser parameters:
        [string] Partition,
        [String[]] Properties,
        [Int32] ResultPageSize,
        [string] SearchBase,
        [string] SearchScope    

    Note -Properties does *not* implement wild-card resolution: only a comma-delimited or array list of full property names are supported in this wrapper. (get-aduser must do natively resolution of the wildcards to the underlying full properties list on the target objects, and attempts to pass through wildcards intact results in errors). 
    
    The following parameter help is cribbed from the underlying get-ADUser cmdlet...
    
    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER Partition <String>
    Specifies the distinguished name of an Active Directory partition. The distinguished name must be one of the naming contexts on the current directory server. The cmdlet searches this partition to find the object defined by the Identity parameter.

    The following two examples show how to specify a value for this parameter.

    -Partition "CN=Configuration,DC=EUROPE,DC=TEST,DC=CONTOSO,DC=COM"

    -Partition "CN=Schema,CN=Configuration,DC=EUROPE,DC=TEST,DC=CONTOSO,DC=COM"

    In many cases, a default value will be used for the Partition parameter if no value is specified.  The rules for determining the default value are given below.  Note that rules listed first are evaluated first and once a default value can be
    determined, no further rules will be evaluated.

    In AD DS environments, a default value for Partition will be set in the following cases:  - If the Identity parameter is set to a distinguished name, the default value of Partition is automatically generated from this distinguished name.

    - If running cmdlets from an Active Directory provider drive, the default value of Partition is automatically generated from the current path in the drive.

    - If none of the previous cases apply, the default value of Partition will be set to the default partition or naming context of the target domain.

    In AD LDS environments, a default value for Partition will be set in the following cases:

    - If the Identity parameter is set to a distinguished name, the default value of Partition is automatically generated from this distinguished name.

    - If running cmdlets from an Active Directory provider drive, the default value of Partition is automatically generated from the current path in the drive.

    - If the target AD LDS instance has a default naming context, the default value of Partition will be set to the default naming context.  To specify a default naming context for an AD LDS environment, set the msDS-defaultNamingContext property of the
    Active Directory directory service agent (DSA) object (nTDSDSA) for the AD LDS instance.

    - If none of the previous cases apply, the Partition parameter will not take any default value.
    .PARAMETER Properties
    Specifies the properties of the output object to retrieve from the server. Use this parameter to retrieve properties that are not included in the default set.

    Specify properties for this parameter as a comma-separated list of names. To display all of the attributes that are set on the object, specify * (asterisk).

    To specify an individual extended property, use the name of the property. For properties that are not default or extended properties, you must specify the LDAP display name of the attribute.

    To retrieve properties and display them for an object, you can use the Get-* cmdlet associated with the object and pass the output to the Get-Member cmdlet. The following examples show how to retrieve properties for a group where the Administrator's
    group is used as the sample group object.

    Get-ADGroup -Identity Administrators | Get-Member

    To retrieve and display the list of all the properties for an ADGroup object, use the following command:

    Get-ADGroup -Identity Administrators -Properties *| Get-Member

    The following examples show how to use the Properties parameter to retrieve individual properties as well as the default, extended or complete set of properties.

    To retrieve the extended properties "OfficePhone" and "Organization" and the default properties of an ADUser object named "SaraDavis", use the following command:

    GetADUser -Identity SaraDavis  -Properties OfficePhone,Organization

    To retrieve the properties with LDAP display names of "otherTelephone" and "otherMobile", in addition to the default properties for the same user, use the following command:

    GetADUser -Identity SaraDavis  -Properties otherTelephone, otherMobile |Get-Member
    .PARAMETER ResultPageSize
    Specifies the number of objects to include in one page for an Active Directory Domain Services query.

    The default is 256 objects per page.

    The following example shows how to set this parameter.

    -ResultPageSize 500  
    .PARAMETER SearchBase <String>
    Specifies an Active Directory path to search under.

    When you run a cmdlet from an Active Directory provider drive, the default value of this parameter is the current path of the drive.

    When you run a cmdlet outside of an Active Directory provider drive against an AD DS target, the default value of this parameter is the default naming context of the target domain.

    When you run a cmdlet outside of an Active Directory provider drive against an AD LDS target, the default value is the default naming context of the target LDS instance if one has been specified by setting the msDS-defaultNamingContext property of
    the Active Directory directory service agent (DSA) object (nTDSDSA) for the AD LDS instance.  If no default naming context has been specified for the target AD LDS instance, then this parameter has no default value.

    The following example shows how to set this parameter to search under an OU.

    -SearchBase "ou=mfg,dc=noam,dc=corp,dc=contoso,dc=com"

    When the value of the SearchBase parameter is set to an empty string and you are connected to a GC port, all partitions will be searched. If the value of the SearchBase parameter is set to an empty string and you are not connected to a GC port, an
    error will be thrown.

    The following example shows how to set this parameter to an empty string.   -SearchBase ""
    
    .PARAMETER SearchScope <ADSearchScope>
    Specifies the scope of an Active Directory search. Possible values for this parameter are:

    Base or 0

    OneLevel or 1

    Subtree or 2

    A Base query searches only the current path or object. A OneLevel query searches the immediate children of that path or object. A Subtree query searches the current path or object and all children of that path or object.

    The following example shows how to set this parameter to a subtree search.
    .PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to, by providing one of the following values for a corresponding domain name or directory server. The service may be any of the following:  Active Directory Lightweight Domain
    Services, Active Directory Domain Services or Active Directory Snapshot instance.

    Domain name values:

    Fully qualified domain name

    Examples: corp.contoso.com

    NetBIOS name

    Example: CORP

    Directory server values:

    Fully qualified directory server name

    Example: corp-DC12.corp.contoso.com

    NetBIOS name

    Example: corp-DC12

    Fully qualified directory server name and port

    Example: corp-DC12.corp.contoso.com:3268

    The default value for the Server parameter is determined by one of the following methods in the order that they are listed:

    -By using Server value from objects passed through the pipeline.

    -By using the server information associated with the Active Directory PowerShell provider drive, when running under that drive.

    -By using the domain of the computer running Powershell.

    The following example shows how to specify a full qualified domain name as the parameter value.

    -Server "corp.contoso.com"
    
    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER outputObject
    Object output switch [-outputObject]
    .EXAMPLE
    PS> $gadu = get-ADUserViaUPN -UserPrincipalName UPN@DOMAIN.COM -verbose -prop description,title ; 
    Lookup ADUser object filtering on UPN, specifying two properties, verbose, and assign result to a variable   
    .EXAMPLE
    PS> $gadu = get-ADUserViaUPN -UserPrincipalName UPN@DOMAIN.COM  ; 
    Lookup ADUser object filtering on UPN, default behaivior (without -properties specification) is to return all properties of the located object.  
    .LINK
    https://github.com/tostka/verb-AAD
    #>
    #Requires -Version 3
    #Requires -Modules verb-AAD, ActiveDirectory
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    ## [OutputType('bool')] # optional specified output type
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="UserPrincipalName [-UserPrincipalName xxx@toro.com]")]
        [Alias('UPN')]
        $UserPrincipalName,
        [string] $Partition,
        [String[]] $Properties,
        [Int32] $ResultPageSize,
        [string] $SearchBase,
        [string] $SearchScope
        #[Parameter(HelpMessage="Object output switch [-outputObject]")]
        #[switch] $outputObject
    ) # PARAM BLOCK END

    BEGIN { 
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ; 
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
        } else {
            #$smsg = "Data received from parameter input: '$($InputObject)'" ; 
            $smsg = "(non-pipeline - param - input)" ; 
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
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

                $sBnr="#*======v UPN: $($UPN): v======" ;
                write-verbose "$((get-date).ToString('HH:mm:ss')):`n$($sBnr)" ;
                #$hReports = [ordered]@{} ; 
                
                    # AD abberant -filter syntax: Get-ADUser -Filter 'sAMAccountName -eq $SamAc'
                    $filter = "userprincipalname -eq '$($UPN)'" ;
                    $pltGADU=[ordered]@{
                        filter= $filter ;
                        #Properties = 'DisplayName' ;
                        ErrorAction= 'STOP' 
                    } ;
                    # [string] $Partition,
                    if($Partition){$pltGADU.add('Partition',$Partition)} ;
                    #[String[]] $Properties,
                    if($Properties){
                        if($properties -match '\*'){
                            $smsg = "Asterisk (*) detected in -properties specification:" ; 
                            $smsg += "`nFull partial-property name wild card property conversion is not implemented in this wrapper."
                            $smsg += "`nPlease specify full property names in a comma-deliminted list" ; 
                            $smsg += "`n(or use default *no* -property behavior:return *all* properties of located object)"
                            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
                            break ; 
                        } ; 
                        $pltGADU.add('Properties',$Properties) ; 
                    } else {
                        # if properties unspecified, pull *everything*, like every other blanking module in existence!
                        $smsg = "(no -properties specified: returning *all* properties, like a sensible module would)" ; 
                        write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
                        $pltGADU.add('Properties','*') ; 
                    }  ;
                    #[Int32] $ResultPageSize,
                    if($ResultPageSize){$pltGADU.add('ResultPageSize',$ResultPageSize)} ;
                    #[string] $SearchBase,
                    if($SearchBase){$pltGADU.add('SearchBase',$SearchBase)} ;
                    #[ADSearchScope] $SearchScope,                    
                    if($SearchScope){$pltGADU.add('SearchScope',$SearchScope)} ;
                    $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                    write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ;
                    $ADUser = $null ; 
                    Try {
                        $ADUser = get-aduser @pltGADU ; 
                        # if it won't trigger test & throw 
                        if($AdUser){
                            $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
                        } else { 
                            $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                            write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
                            #throw $smsg  ; 
                            # try to throw a stock ad not-found error (emulate it)
                            throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] "$($smsg)"
                        } ; 
                    # doesn't work natively -filter doesn't generate a catchable error, even with -ea STOP, this block never triggers
                    } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        $smsg = "No GET-ADUSER match found for -filter:$($filter)" ; 
                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;      
                        Write-Error $smsg ;
                        Continue ; 
                    # reworking extended vers of above
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                        
                        Continue ;
                    } ; 
                    #
                write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):`n$($sBnr.replace('=v','=^').replace('v=','^='))`n" ;
            
            # convert the hashtable to object for output to pipeline
            #$Rpt += New-Object PSObject -Property $hReports ;
            if($ADUser){
                $ADUser| write-output ;
            } ; 
        
        } ; # loop-E

    } ;  # PROC-E
    END {
        
    } ;  # END-E
}

#*------^ get-ADUserViaUPN.ps1 ^------


#*------v Get-ComputerADSiteName.ps1 v------
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
}

#*------^ Get-ComputerADSiteName.ps1 ^------


#*------v Get-ComputerADSiteSummary.ps1 v------
Function Get-ComputerADSiteSummary {
    <#
    .SYNOPSIS
    Get-ComputerADSiteSummary - Used to get the Active Directory subnet and the site it is assigned to for a remote Windows computer/IP address
    .NOTES
    Version     : 1.1.1
    Author      : gbdixg/GD
    Website     : write-verbose.com
    Twitter     : @writeverbose / http://twitter.com/writeverbose
    CreatedDate : 2024-03-13
    FileName    : Get-ComputerADSiteSummary.ps1
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,Site,Computer
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.com
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 12:24 PM 3/13/2024 ren:Find-ADSite -> Get-ComputerADSiteSummary  1.1.1 updated CBH; tagged outputs w explicit w-o 
    * 11/12/23 v1.1 - current posted GitHub Gist version
    .DESCRIPTION
    Get-ComputerADSiteSummary - Used to get the Active Directory subnet and the site it is assigned to for a Windows computer/IP address
     Requires only standard user read access to AD and can determine the ADSite for a local or remote computer

     Shay Levy also demo's a much simplified variant for obtaining remote computer AD SiteName by leveraging the nltest cmdline util:

    function Get-ComputerADSite($ComputerName){
	    $site = nltest /server:$ComputerName /dsgetsite 2>$null ; 
	    if($LASTEXITCODE -eq 0){ $site[0] } ; 
    }

    .PARAMETER  IPAddress
    Specifies the IP Address for the subnet/site lookup in as a .NET System.Net.IPAddress
    When this parameter is used, the computername is not specified.
    .PARAMETER  Computername
    Specifies a computername for the subnet/site lookup.
    The computername is resolved to an IP address before performing the subnet query.
    Defaults to %COMPUTERNAME%
    When this parameter is used, the IPAddress and IP are not specified.
    .PARAMETER  DC
    A specific domain controller in the current users domain for the subnet query
    If not specified, standard DC locator methods are used.
    .PARAMETER  AllMatches
    A switch parameter that causes the subnet query to return all matching subnets in AD
    This is not normally used as the default behaviour (only the most specific match is returned) is usually prefered.
    This switch will include "catch-all" subnets that may be defined to accomodate missing subnets
    .PARAMETER showDebug
    Debugging Flag [-showDebug]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    System.Object summary of IPAddress, Subnet and AD SiteName
    .EXAMPLE
    PS>Get-ComputerADSiteSummary -ComputerName PC123456789

        ComputerName      : PC123456789
        IPAddress         : 162.26.192.151
        ADSubnetName      : 162.26.192.128/25
        ADSubnetDesc      : 3rd Floor Main Road Office
        ADSiteName        : EULON01
        ADSiteDescription : London
    Demo's resolving computername to Site details
    .EXAMPLE
    PS>$SiteSummary = get-computeradsitesummary -IPAddress 192.168.5.15
    Demos resolving IP address to AD Site summary, and assigning return to a variable.
    .LINK
    https://write-verbose.com/2019/04/13/Get-ComputerADSiteSummary/
    .LINK
    https://gist.github.com/gbdixg/5cd6ea0c984278b08b36260ada0e3f9c
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding(DefaultParameterSetName = "byHost")]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, ParameterSetName = "byHost")]
            [string]$ComputerName = $Env:COMPUTERNAME,
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, Mandatory = $True, ParameterSetName = "byIPAddress")]
            [System.Net.IPAddress]$IPAddress,
        [Parameter(Position = 1)]
            [string]$DC,
        [Parameter()]
            [switch]$AllMatches
    )
    PROCESS {
        switch ($pscmdlet.ParameterSetName) {
            "byHost" {
                TRY {
                    $Resolved = [system.net.dns]::GetHostByName($Computername)
                    [System.Net.IPAddress]$IP = ($Resolved.AddressList)[0] -as [System.Net.IPAddress]
                }CATCH{
                    Write-Warning "$ComputerName :: Unable to resolve name to an IP Address"
                    $IP = $Null
                }
            }
            "byIPAddress" {
                TRY {
                    $Resolved = [system.net.dns]::GetHostByAddress($IPAddress)
                    $ComputerName = $Resolved.HostName
                } CATCH {
                    # Write-Warning "$IP :: Could not be resolved to a hostname"
                    $ComputerName = "Unable to resolve"
                }
                $IP = $IPAddress
            }

        }#switch
    
        if($PSBoundParameters.ContainsKey("DC")){
            $DC+="/"
        }

        if ($IP) {
            # The following maths loops over all the possible subnet mask lengths
            # The masks are converted into the number of Bits to allow conversion to CIDR format
            # The script tries to lookup every possible range/subnet bits combination and keeps going until it finds a hit in AD

            [psobject[]]$MatchedSubnets = @()

            For ($bit = 30 ; $bit -ge 1; $bit--) {
                [int]$octet = [math]::Truncate(($bit - 1 ) / 8)
                $net = [byte[]]@()

                for ($o = 0; $o -le 3; $o++) {
                    $ba = $ip.GetAddressBytes()
                    if ($o -lt $Octet) {
                        $Net += $ba[$o]
                    } ELSEIF ($o -eq $octet) {
                        $factor = 8 + $Octet * 8 - $bit
                        $Divider = [math]::pow(2, $factor)
                        $value = $divider * [math]::Truncate($ba[$o] / $divider)
                        $Net += $value
                    } ELSE {
                        $Net += 0
                    }
                } #Next

                #Format network in CIDR notation
                $Network = [string]::join('.', $net) + "/$bit"

                # Try to find this Network in AD Subnets list
                Write-Verbose "Trying : $Network"
                TRY{
                    $de = New-Object System.DirectoryServices.DirectoryEntry("LDAP://" + $DC + "rootDSE")
                    $Root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DC$($de.configurationNamingContext)")
                    $ds = New-Object System.Directoryservices.DirectorySearcher($root)
                    $ds.filter = "(CN=$Network)"
                    $Result = $ds.findone()
                }CATCH{
                    $Result = $null
                }

                if ($Result) {
                    write-verbose "AD Site found for $IP"

                    # Try to split out AD Site from LDAP path
                    $SiteDN = $Result.GetDirectoryEntry().siteObject
                    $SiteDe = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$SiteDN")
                    $ADSite = $SiteDe.Name[0]
                    $ADSiteDescription = $SiteDe.Description[0]

                    $MatchedSubnets += [PSCustomObject][Ordered]@{
                        ComputerName = $ComputerName
                        IPAddress    = $IP.ToString()
                        ADSubnetName = $($Result.properties.name).ToString()
                        ADSubnetDesc = "$($Result.properties.description)"
                        ADSiteName       = $ADSite
                        ADSiteDescription = $ADSiteDescription
                    }
                    $bFound = $true
                }#endif
            }#next

        }#endif
        if ($bFound) {

            if ($AllMatches) {
                # output all the matched subnets
                $MatchedSubnets | write-output ;
            } else {

                # Only output the subnet with the largest mask bits
                [Int32]$MaskBits = 0 # initial value

                Foreach ($MatchedSubnet in $MatchedSubnets) {

                    if ($MatchedSubnet.ADSubnetName -match "\/(?<Bits>\d+)$") {
                        [Int32]$ThisMaskBits = $Matches['Bits']
                        Write-Verbose "ThisMaskBits = '$ThisMaskBits'"

                        if ($ThisMaskBits -gt $MaskBits) {
                            # This is a more specific subnet
                            $OutputSubnet = $MatchedSubnet
                            $MaskBits = $ThisMaskBits

                        } else {
                            Write-Verbose "No match"
                        }
                    } else {
                        Write-Verbose "No match"
                    }
                }
                $OutputSubnet | write-output ;
            }#endif
        } else {

            Write-Verbose "AD Subnet not found for $IP"
            if ($IP -eq $null) {$IP = ""} # required to prevent exception on ToString() below

            New-Object -TypeName PSObject -Property @{
                ComputerName = $ComputerName
                IPAddress    = $IP.ToString()
                ADSubnetName = "Not found"
                ADSubnetDesc = ""
                ADSiteName   = ""
                ADSiteDescription = ""
            } | write-output  ; 
        }#end if
    }#process
}

#*------^ Get-ComputerADSiteSummary.ps1 ^------


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
    Version     : 2.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-01-23
    FileName    : get-GCFast.ps1
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Originated in Ben Lye's GetLocalDC()
    AddedWebsite: http://www.onesimplescript.com/2012/03/using-powershell-to-find-local-domain.html
    AddedTwitter: URL
    REVISIONS   :
    * 2:39 PM 1/23/2025 added -exclude (exclude array of dcs by name), -ServerPrefix (exclude on leading prefix of name) params, added expanded try/catch, swapped out w-h etc for wlt calls
    * 3:38 PM 3/7/2024 SPB Site:Spellbrook no longer has *any* GCs: coded in a workaround and discvoer domain-wide filtering for CN=EDC.* gcs (as spb servers use EDCMS8100 AS LOGONDC)
    * 1:01 PM 10/23/2020 moved verb-ex2010 -> verb-adms (better aligned)
    # 2:19 PM 4/29/2019 add [lab dom] to the domain param validateset & site lookup code, also copied into tsksid-incl-ServerCore.ps1
    # 2:39 PM 8/9/2017 ADDED some code to support labdom.com, also added test that $LocalDcs actually returned anything!
    # 10:59 AM 3/31/2016 fix site param valad: shouln't be sitecodes, should be Site names; updated Site param def, to validate, cleanup, cleaned up old remmed code, rearranged comments a bit
    # 1:12 PM 2/11/2016 fixed new bug in get-GCFast, wasn't detecting blank $site, for PSv2-compat, pre-ensure that ADMS is loaded
    12:32 PM 1/8/2015 - tweaked version of Ben lye's script, replaced broken .NET site query with get-addomaincontroller ADMT module command
    .DESCRIPTION
    get-GCFast - function to locate a random sub-100ms response gc in specified domain & optional AD site
    .PARAMETER  Domain
    Which AD Domain [Domain fqdn]
    .PARAMETER  Site
    DCs from which Site name (defaults to AD lookup against local computer's Site)
    .PARAMETER Exclude
    Array of Domain controller names in target site/domain to exclude from returns (work around temp access issues)
    .PARAMETER ServerPrefix
    Prefix string to filter for, in returns (e.g. 'ABC' would only return DCs with name starting 'ABC')
    .PARAMETER SpeedThreshold
    Threshold in ms, for AD Server response time(defaults to 100ms)
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns one DC object, .Name is name pointer
    .EXAMPLE
    PS> get-gcfast -domain dom.for.domain.com -site Site
    Lookup a Global domain gc, with Site specified (whether in Site or not, will return remote site dc's)
    .EXAMPLE
    PS> get-gcfast -domain dom.for.domain.com
    Lookup a Global domain gc, default to Site lookup from local server's perspective
    .EXAMPLE    
    PS> if($domaincontroller = get-gcfast -Exclude ServerBad -Verbose){
    PS>     write-warning "Changing DomainControler: Waiting 20seconds, for RelSync..." ;
    PS>     start-sleep -Seconds 20 ;
    PS> } ; 
    Demo acquireing a new DC, excluding a caught bad DC, and waiting before moving on, to permit ADRerplication from prior dc to attempt to ensure full sync of changes. 
    PS> get-gcfast -ServerPrefix ABC -verbose
    Demo use of -ServerPrefix to only return DCs with servernames that begin with the string 'ABC'
    .EXAMPLE
    PS> $adu=$null ;
    PS> $Exit = 0 ;
    PS> Do {
    PS>     TRY {
    PS>         $adu = get-aduser -id $rmbx.DistinguishedName -server $domainController -Properties $adprops -ea 0| select $adprops ;
    PS>         $Exit = $DoRetries ;
    PS>     }CATCH [System.Management.Automation.RuntimeException] {
    PS>         if ($_.Exception.Message -like "*ResourceUnavailable*") {
    PS>             $ErrorTrapped=$Error[0] ;
    PS>             $smsg = "Failed to exec cmd because: $($ErrorTrapped.Exception.Message )" ;
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
    PS>             else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    PS>             # re-quire a new DC
    PS>             $badDC = $domaincontroller ; 
    PS>             $smsg = "PROBLEM CONTACTING $(domaincontroller)!:Resource unavailable: $($ErrorTrapped.Exception.Message)" ; 
    PS>             $smsg += "get-GCFast() an alterate DC" ; 
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
    PS>             else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    PS>             if($domaincontroller = get-gcfast -Exclude $$badDC -Verbose){
    PS>                 write-warning "Changing DomainController:($($badDC)->$($domaincontroller)):Waiting 20seconds, for ReplSync..." ;
    PS>                 start-sleep -Seconds 20 ;
    PS>             } ;                             
    PS>         }else {
    PS>             throw $Error[0] ;
    PS>         } ; 
    PS>     } CATCH {
    PS>         $ErrorTrapped=$Error[0] ;
    PS>         Start-Sleep -Seconds $RetrySleep ;
    PS>         $Exit ++ ;
    PS>         $smsg = "Failed to exec cmd because: $($ErrorTrapped)" ;
    PS>         $smsg += "`nTry #: $Exit" ;
    PS>         if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
    PS>         else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>         If ($Exit -eq $DoRetries) {
    PS>             $smsg =  "Unable to exec cmd!" ;
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
    PS>             else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>         } ;
    PS>         Continue ;
    PS>     }  ;
    PS> } Until ($Exit -eq $DoRetries) ;
    Retry demo that includes aquisition of a new DC, excluding a caught bad DC, and waiting before moving on, to permit ADRerplication from prior dc to attempt to ensure full sync of changes. 
    .LINK
    https://github.com/tostka/verb-adms
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, Mandatory = $False, HelpMessage = "Optional: DCs from what Site name? (default=Discover)")]
            [string]$Site,
        [Parameter(HelpMessage = 'Target AD Domain')]
            [string]$Domain,
        [Parameter(HelpMessage = 'Array of Domain controller names in target site/domain to exclude from returns (work around temp access issues)')]
            [string[]]$Exclude,
        [Parameter(HelpMessage = "Prefix string to filter for, in returns (e.g. 'ABC' would only return DCs with name starting 'ABC')")]
            [string]$ServerPrefix,
        [Parameter(HelpMessage = 'Threshold in ms, for AD Server response time(defaults to 100ms)')]
            $SpeedThreshold = 100
    ) ;
    $Verbose = $($PSBoundParameters['Verbose'] -eq $true)
    $SpeedThreshold = 100 ;
    $rgxSpbDCRgx = 'CN=EDCMS'
    $ErrorActionPreference = 'SilentlyContinue' ; # Set so we don't see errors for the connectivity test
    $env:ADPS_LoadDefaultDrive = 0 ; 
    $sName = "ActiveDirectory"; 
    TRY{
        if ( -not(Get-Module | Where-Object { $_.Name -eq $sName }) ) {
            $smsg = "Adding ActiveDirectory Module (`$script:ADPSS)" ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $script:AdPSS = Import-Module $sName -PassThru -ea Stop ;
        } ;
        if (-not $Domain) {
            $Domain = (get-addomain -ea Stop).DNSRoot ; # use local domain
            $smsg = "Defaulting domain: $Domain";
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        }
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ; 
    
    # Get all the local domain controllers
    if ((-not $Site)) {
        # if no site, look the computer's Site Up in AD
        TRY{
            $Site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name ;
            $smsg = "Using local machine Site: $($Site)";
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
    } ;

    # gc filter
    #$LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -and (Site -eq $Site) } ;
    # ISSUE: ==3:26 pm 3/7/2024: NO LOCAL SITE DC'S IN SPB
    # os: LOGONSERVER=\\EDCMS8100
    TRY{
        $LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -and (Site -eq $Site) -and (Domain -eq $Domain) } -ErrorAction STOP
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ; 
    if( $LocalDCs){
        $smsg = "`Discovered `$LocalDCs:`n$(($LocalDCs|out-string).trim())" ; 
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } elseif($Site -eq 'Spellbrook'){
        $smsg = "Get-ADDomainController -filter { (isglobalcatalog -eq `$true) -and (Site -eq $($Site)) -and (Domain -eq $($Domain)}"
        $smsg += "`nFAILED to return DCs, and `$Site -eq Spellbrook:" 
        $smsg += "`ndiverting to $($rgxSpbDCRgx) dcs in entire Domain:" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        TRY{
            $LocalDCs = Get-ADDomainController -filter { (isglobalcatalog -eq $true) -and (Domain -eq $Domain) } -EA STOP | 
                ?{$_.ComputerObjectDN -match $rgxSpbDCRgx } 
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
    } ; 
  
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
        if($Exclude){
            $smsg = "-Exclude specified:`n$((($exclude -join ',')|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            foreach($excl in $Exclude){
                $PotentialDCs = $PotentialDCs |?{$_ -ne $excl} ; 
            } ; 
        } ; 
        if($ServerPrefix){
            $smsg = "-ServerPrefix specified: $($ServerPrefix)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            $PotentialDCs = $PotentialDCs |?{$_ -match "^$($ServerPrefix)" } ; 
            
        }
        write-host -foregroundcolor yellow  
        $smsg = "`$PotentialDCs: $PotentialDCs";
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        $DC = $PotentialDCs | Get-Random ;

        $smsg = "(returning random domaincontroller from result to pipeline:$($DC)" ; 
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        $DC | write-output  ;
    } else {
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
    * 12:57 PM 8/22/2023 test before calling Add-PSTitleBar (for PRY/dep-less support)
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
            if(get-command Add-PSTitleBar -ea 0){
                Add-PSTitleBar 'ADMS' -verbose:$($VerbosePreference -eq "Continue") ;
            } ; 
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
    * 2:16 PM 6/24/2024: rem'd out #Requires -RunasAdministrator; sec chgs in last x mos wrecked RAA detection
    * 1:08 PM 1/31/2022 trimmed requires, dropping rem'd entries
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
    #Requires -Modules ActiveDirectory
    ##Requires -RunasAdministrator
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
    <#
    .SYNOPSIS
    Triggers a replication between Domain Controllers (DCs).
    .NOTES
    Version: 1.0.0
    Author: [Your Name]
    CreatedDate: [Creation Date]
    FileName: Sync-AD.ps1
    Source: Adapted from dsoldow's script at https://github.com/dsolodow/IndyPoSH/blob/master/Profile.ps1
    .DESCRIPTION
    The `Sync-AD` function allows you to trigger a replication between specified Domain Controllers (DCs). This function can be customized further for reusability. It uses the `repadmin` tool to perform the replication.
    .PARAMETER DestinationDC
    The destination Domain Controller for the replication. Defaults to 'centralDC'.
    .PARAMETER SourceDC
    The source Domain Controller for the replication. Defaults to 'localDC'.
    .PARAMETER DirectoryPartition
    The directory partition to replicate. Defaults to 'YourDomainName'.
    .EXAMPLE
    PS C:\> Sync-AD -DestinationDC 'centralDC' -SourceDC 'localDC' -DirectoryPartition 'YourDomainName'
    This command triggers a replication from 'localDC' to 'centralDC' for the specified directory partition.
    .LINK
    https://github.com/dsolodow/IndyPoSH/blob/master/Profile.ps1
    #>
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
    * 2:16 PM 6/24/2024: rem'd out #Requires -RunasAdministrator; sec chgs in last x mos wrecked RAA detection 
    * 12:16 PM 2/3/2022 requires block was triggering nesting error, so stripped back from abso minimum
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
    #Requires -Version 3
    #Requires -Modules MSOnline, verb-AAD, ActiveDirectory
    ##Requires -RunasAdministrator
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
    #Requires -Version 3
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
    * 2:16 PM 6/24/2024: rem'd out #Requires -RunasAdministrator; sec chgs in last x mos wrecked RAA detection
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
    ##Requires -RunasAdministrator
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
Function test-Password{
    <#
    .SYNOPSIS
    test-Password - Validate Password complexity, to Base AD Complexity standards
    .NOTES
    Version     : 1.0.2
    Author      : Shay Levy & commondollars
    Website     :	http://scriptolog.blogspot.com/2008/01/validating-password-strength.html
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-03
    FileName    : test-Password.ps1
    License     : (none specified)
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 10:20 AM 9/26/2023 ren & alias orig, for verb compliance: Validate-Password -> test-password
    * 2:02 PM 8/2/2023 w revised req's: reset minLen to 14; added param & test for testComplexity (defaults false)
    * 11:43 AM 4/6/2016 hybrid of Shay Levy's 2008 post, and CommonDollars's 2013 code
    .DESCRIPTION
    test-Password - Validate Password complexity, to Base AD Complexity standards
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
    .PARAMETER TestComplexity
    Switch to test Get-ADDefaultDomainPasswordPolicy ComplexityEnabled specs (Defaults false: requires a mix of Uppercase, Lowercase, Digits and Nonalphanumeric characters)[-TestComplexity]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Outputs $true/$false to pipeline
    .EXAMPLE
    [Reflection.Assembly]::LoadWithPartialName("System.Web")|out-null ;
    Do { $password = $([System.Web.Security.Membership]::GeneratePassword(8,2)) } Until (test-Password -pwd $password ) ;
    Pull and validate passwords in a Loop until an AD Complexity-compliant password is returned.
    .EXAMPLE
    if (test-Password -pwd "password" -minLength 10
    Above validates pw: Contains at least 10 characters, 2 upper case characters (default), 2 lower case characters (default), 3 numbers, and at least 3 special characters
    .LINK
    http://scriptolog.blogspot.com/2008/01/validating-password-strength.html
    #>
    [CmdletBinding()]
    [Alias('Validate-Password')]
    PARAM(
        [Parameter(Mandatory=$True,HelpMessage="Password to be tested[-Pwd 'string']")]
        [ValidateNotNullOrEmpty()]
        [string]$pwd,
        [Parameter(HelpMessage="Minimum permissible Password Length (defaults to 14)[-minLen 10]")]
        [int]$minLen=14,
        [Parameter(HelpMessage="Switch to test Get-ADDefaultDomainPasswordPolicy ComplexityEnabled specs (Defaults false: requires a mix of Uppercase, Lowercase, Digits and Nonalphanumeric characters)[-TestComplexity]")]
        [switch]$TestComplexity=$false
    ) ;
    $IsGood=0 ;
    if($pwd.length -lt $minLen) {write-output $false; return} ;
    if($TestComplexity){
        if(([regex]"[A-Z]").Matches($pwd).Count) {$isGood++ ;} ;
        if(([regex]"[a-z]").Matches($pwd).Count) {$isGood++ ;} ;
        if(([regex]"[0-9]").Matches($pwd).Count) {$isGood++ ;} ;
        if(([regex]"[^a-zA-Z0-9]" ).Matches($pwd).Count) {$isGood++ ;} ;
        If ($isGood -ge 3){ write-output $true ;  } else { write-output $false} ;
    } else { 
        write-verbose "complexity test skipped" ; 
        write-output $true ;
    } ; 
}

#*------^ Validate-Password.ps1 ^------


#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function Convert-ADSIDomainFqdnToNBName,find-SiteRoleOU,get-ADForestDrives,Get-AdminInitials,get-ADRootSiteOUs,Get-ADSIComputerByGuid,Get-ADSIObjectByGuid,get-ADSiteLocal,get-ADUserDetailsTDO,get-ADUserViaUPN,Get-ComputerADSiteName,Get-ComputerADSiteSummary,get-DCLocal,get-GCFast,get-GCFastXO,check-ReqMods,get-GCLocal,get-SiteMbxOU,grant-ADGroupManagerUpdateMembership,load-ADMS,mount-ADForestDrives,resolve-ADRightsGuid,Sync-AD,test-AADUserSync,test-ADUserEmployeeNumber,unmount-ADForestDrives,test-Password -Alias *




# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3tm1KlO3b6kcOG6viHPnmzVj
# TdOgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQh9I5H
# 3yvWqZUmYpASzbIFxi/LmjANBgkqhkiG9w0BAQEFAASBgE/y7trIaZHrv/qOe6o0
# B8GhXXxPKk4d1jedzD5ih9qFJIj0oy00EVI9gdl8XxtnYGBaIYFQHYiJa23Dg3rM
# NQNVOECOmtcVpkZ1kUxmCdnoA41y8T/9pXH3rPh2aTvt8RIc4JsrAgmckccBCn1v
# T9U03bjHGnhxnufejL6gtYqs
# SIG # End signature block
