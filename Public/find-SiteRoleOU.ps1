#*------v Function find-SiteRoleOU v------
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
}  ; 
#*------^ END Function find-SiteRoleOU ^------
