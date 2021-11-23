#*------v Function find-SiteRoleOU v------
function find-SiteRoleOU {
    <#
    .SYNOPSIS
    find-SiteRoleOU() - passed a 3-letter site code, or child domain name, it returns the child OU dn for that site/domain's Email-related roles.
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
    * 12:17 PM 11/23/2021 port over and expand get-SiteMbxOU to cover range of Email-related role OU's, via lookup, keyed from a starting point: Site root OU, or child domain root. 
    * 10:57 AM 4/3/2020 cleanup to modularize, added verbose sup, updated CBH
    # 2:51 PM 3/6/2017 add -Resource param to steer to 'Email Resources'
    # 12:36 PM 2/27/2017 fixed to cover breaks frm AD reorg OU name changes, Generics are all now in a single OU per site
    # 11:56 AM 3/31/2016 port to find-SiteRoleOU; validated that latest round of updates are still functional; minor cleanup
    * 11:31 AM 3/16/2016 debugged to function.
    * 1:34 PM 3/15/2016 adapted SecGrp OU lookup to MailContact OU
    * 11:05 AM 10/7/2015 initial vers
    .DESCRIPTION
    find-SiteRoleOU() - passed a 3-letter site code, or child domain name, it returns the child OU dn for that site/domain's Email-related roles.
    - Role keywords, and traditional locations: 
      -DistributionGroup : OU=Distribution Groups,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Shared (Mbxs): OU=Generic Email Accounts,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Resource (Mbxs) (Room/Equipment): OU=Email Resources,OU=XXX,...,DC=xxxx,DC=com
      -PermissionGroup: OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -Contact: OU=Email Contacts,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
      -User (Mbxs): OU=Users,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
    .PARAMETER  SiteCode
    Toro 3-letter site code
    .PARAMETER  Generic
    Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).
    .PARAMETER  Resource
    Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]
    .EXAMPLE
    $OU=find-SiteRoleOU -Sitecode SITE
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU
    .LINK
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("(lyn|bcc|spb|adl)ms6(4|5)(0|1).(china|global)\.ad\.toro\.com")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
## [OutputType('bool')] # optional specified output type
<# #-=-=-=MUTUALLY EXCLUSIVE PARAMS OPTIONS:-=-=-=-=-=
# designate a default paramset, up in cmdletbinding line
[CmdletBinding(DefaultParameterSetName='SETNAME')]
  # * set blank, if none of the sets are to be forced (eg optional mut-excl params)
  # * force exclusion by setting ParameterSetName to a diff value per exclusive param

# example:single $Computername param with *multiple* ParameterSetName's, and varying Mandatory status per set
    [Parameter(ParameterSetName='LocalOnly', Mandatory=$false)]
    $LocalAction,
    [Parameter(ParameterSetName='Credential', Mandatory=$true)]
    [Parameter(ParameterSetName='NonCredential', Mandatory=$false)]
    $ComputerName,
    # $Credential as tied exclusive parameter
    [Parameter(ParameterSetName='Credential', Mandatory=$false)]
    $Credential ;    
    # effect: 
    -computername is mandetory when credential is in use
    -when $localAction param (w localOnly set) is in use, neither $Computername or $Credential is permitted
    write-verbose -verbose:$verbose "ParameterSetName:$($PSCmdlet.ParameterSetName)"
    Can also steer processing around which ParameterSetName is in force:
    if ($PSCmdlet.ParameterSetName -eq 'LocalOnly') {
        return "some localonly stuff" ; 
    } ;     
#-=-=-=-=-=-=-=-=
#>
    [CmdletBinding(DefaultParameterSetName='Site')]
    PARAM (
        [parameter(ParameterSetName='Site',Mandatory=$True,HelpMessage="SITE OU name below which to Query[ABC]")]
        [Alias('RootOU')]
        [string]$SiteOUName,
        [parameter(ParameterSetName='Domain',Mandatory=$True,HelpMessage="Specify the domain fqdn below which to which to Query[-domain childdom.domain.org.com]")]
        [string]$Domain,
        [parameter(Mandatory=$True,HelpMessage="OU Role to find (Shared|Resource|DistributionGroup|PermissionGroup|Contact|User)[-Role Shared]")]
        [ValidateSet('Shared','Resource','DistributionGroup','PermissionGroup','Contact','User')]
        [string]$Role
        #[parameter(ParameterSetName='Domain',Mandatory=$True,HelpMessage="Specify the alternative domain fqdn to use where the preferred domain lacks access permissions for current account[-FallbackDomain domain.org.com]")]
        #[string]$FallbackDomain
    ) ;  
    $verbose = ($VerbosePreference -eq "Continue") ; 
    #$FallbackRoot = 'cmw.internal' # domain used for object storage, when current acocunt lacks local permissions
    $nested = $false ; # whether there are intervening OUs above $findOU
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
        -User (Mbxs): OU=Users,OU=SITE,DC=CHILDDOM,DC=DOMAIN,DC=ORG,DC=com
        DW equiv: OU=User Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        #>
        # if the FindOU is *not* directly below the site OU, append a .*
        'Shared'{$FindOU='^OU=Generic Email Accounts' ; $nested = $false ;}
        'Resource'{$FindOU="^OU=Email Resources" ; $nested = $false ;}
        'DistributionGroup'{$FindOU='^OU=Distribution Groups' ; $nested = $false ;}
        'PermissionGroup'{$FindOU='^OU=Email Access,OU=SEC Groups,OU=Managed Groups' ; $nested = $true ;}
        'Contact'{$FindOU='^OU=Email Contacts' ; $nested = $false ;}
        'User'{$FindOU='^OU=Users' ; $nested = $false ;}
        default {
            $smsg = "Unrecognized -Role:$($Rold). Please specify one of:`n(Shared|Resource|DistributionGroup|PermissionGroup|Contact|User) " ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            Break ; 
        }
    } ; 
    $error.clear() ;
    TRY {
        if($SiteOUName){
            $domain = (Get-ADDomain -Current LoggedOnUser).DNSRoot ; 
            $smsg = "`$domain:$($domain)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $DomDN =  (get-addomain -id $domain -ea 'STOP').DistinguishedName ;
            $smsg = "`$DomDN:$($DomDN)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $stack =@() ; 
            $stack += "$($FindOU)" ; 
            #$stack += '.*' ;
            $stack += "OU=$($SiteOUName)" ; 
            $stack += "$($DomDN)$" ; 
            $DNFilter = $stack -join ',' ; 
            $smsg = "`$DNFilter:$($DNFilter)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            #$OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU).*,OU=$($SiteOUName),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
            #$OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU),.*,OU=$($SiteOUName),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
            $OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $domain | ?{ $_.distinguishedname -match $DNFilter } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ; 
        } elseif($Domain){
            $smsg = "`$domain:$($domain)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $DomDN =  (get-addomain -id $domain -ea 'STOP').DistinguishedName ;
            $smsg = "`$DomDN:$($DomDN)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $stack =@() ; 
            $stack += "$($FindOU)" ; 
            $stack += '.*' ;
            $stack += "$($DomDN)$" ; 
            $DNFilter = $stack -join ',' ; 
            $smsg = "`$DNFilter:$($DNFilter)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            #$OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $domain | ?{ $_.distinguishedname -match "^$($FindOU),.*,$($DomDN)$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ; 
            $OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $domain | ?{ $_.distinguishedname -match $DNFilter } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ; 
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
