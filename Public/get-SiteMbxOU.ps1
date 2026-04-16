#*------v Function get-SiteMbxOU v------

#region GET_SITEMBXOU ; #*------v get-SiteMbxOU v------
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
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 9:31 AM 4/16/2026 add: example for resolving variant types; uses constants at 
        top for the standardized RootOU & MigrOU names; has to use SiteCode switching 
        to resolve oddball variants for Migration OU entities that don't comply with standards.
        Full analyzed and broke out where all DGs, Smbxs; RmMbxs; EqMbxs & SecGrps are parented - added Examples for dumping histo grams for future analysis
        It's as accurate as I can make it at current time - pre TON migration. Added 
        Alias 'get-SiteRoleOU', as it now does DG/SecGrp & Contact OU resolution. Even 
        pulls an approximate 'Users' equiv (which is frequently *above* where  It's as accurate as I can make it at current time - pre TON migration. Added 
        Alias 'get-SiteRoleOU', as it now does DG/SecGrp & Contact OU resolution. Even 
        pulls an approximate 'Users' equiv (which is frequently *above* where wacky admins actually stuff users - migr tree is 100% anarchy for organization
    * 3:33 PM 4/10/2026 full recode replaced get-adobject with get-adorganizationalunit, and scoping/SearchBase to avoid need to poll all OUs in org for post-filtering; much faster
        Also added -Type in addition to the back-comapt -generic -resource; added -Security as well, to use for resolving OUs for hosting Security group objects for mail access.
        Added demo/test block to run the Migrations OU's and valdiate they have existing OUs and logic works (CMW & SUB are both borked - have no users, no OUs).
    * 6:05 PM 4/9/2026 complete-recoding to accomodate bananas non-standard/unmanaged Migrations OU Shared/Room-Eqiu & SecGrp OU names: Went through all Migrations OU roots and created missing OUs to suit
        added -modelDistinguishedName to even have a shot at resolving (short of running a canned list of SiteCodes, that will ahve to dyn accommodate mergers over time)
    * 10:57 AM 4/3/2020 cleanup to modularize, added verbose sup, updated CBH
    # 2:51 PM 3/6/2017 add -Resource param to steer to 'Email Resources'
    # 12:36 PM 2/27/2017 fixed to cover breaks frm AD reorg OU name changes, Generics are all now in a single OU per site
    # 11:56 AM 3/31/2016 port to get-SiteMbxOU; validated that latest round of updates are still functional; minor cleanup
    * 11:31 AM 3/16/2016 debugged to function.
    * 1:34 PM 3/15/2016 adapted SecGrp OU lookup to MailContact OU
    * 11:05 AM 10/7/2015 initial vers
    .DESCRIPTION
    get-SiteMbxOU() - passed a standard 3-letter site code, it returns the OU dn for that site's Email-related SecGrps (directly below Site ou)

    Migrations "standards" as of poll manually run for Shared|Room\Equip & Email Access SecGrp homing:

    AUG has 
        OU=Generic Email Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=AUG,OU=_MIGRATIONS,$($DomainRoot)
        OU=Email Access,OU=Security Groups,OU=Groups,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=AUG,OU=_MIGRATIONS,$($DomainRoot)
        OU=Resources,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=AUG,OU=_MIGRATIONS,$($DomainRoot)

        DIT:
        ,OU=Generic Email Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,$($DomainRoot)
        OU=Email Access,OU=Security Groups,OU=People,OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,$($DomainRoot)
        OU=Resources,OU=User Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,$($DomainRoot)

        CMW has:
        zippo


        HAM:
        OU=Email Access,OU=Security Groups,OU=Groups,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=HAM,OU=_MIGRATIONS,$($DomainRoot)
        OU=Generic Email Accounts,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=HAM,OU=_MIGRATIONS,$($DomainRoot)
        OU=Resources,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=HAM,OU=_MIGRATIONS,$($DomainRoot)

        INT:
        OU=Generic Email Accounts,OU=INT,OU=_MIGRATIONS,$($DomainRoot)
        => ADDED rESOURCES 5:38 PM 4/9/2026
        OU=Resources,OU=INT,OU=_MIGRATIONS,$($DomainRoot)
        => ADDED Email Access, 5:41 PM 4/9/2026
        Email Access,OU=Global Groups,OU=INT,OU=_MIGRATIONS,$($DomainRoot)

        RAD:
        OU=Email Access,OU=Security Groups,OU=Groups,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=RAD,OU=_MIGRATIONS,$($DomainRoot)
        OU=Generic Email Accounts,OU=Generic Users,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=RAD,OU=_MIGRATIONS,$($DomainRoot)
        => Add Resources 5:45 PM 4/9/2026
        OU=Resources,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=RAD,OU=_MIGRATIONS,$($DomainRoot)

        SUB: 
        _TTC_Sync_CMW_NoSync tree is EMPTY
        => THEY'RE UP IN DW!
        OnPremisesDistinguishedName   : CN=C4C Subsite KY,OU=Contact Center,OU=SAP,OU=Special Accounts,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        SHAREDMAILBOX
        there's no users using the domain:
        ▒▒▒▒▒ [PS]:D:\scripts $ get-xorecipient -filter {primarysmtpaddress -like '*@subsite.com'} -RecipientType usermailbox

        ▒▒▒▒▒ [PS]:D:\scripts $ get-xorecipient -filter {primarysmtpaddress -like '*@subsite.com'}

        VPI:
        OU=Generic Email Accounts,OU=VD,OU=VPI,OU=_MIGRATIONS,$($DomainRoot)
        => added OU=Email Access 5:59 PM 4/9/2026
        OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=VD,OU=VPI,OU=_MIGRATIONS,$($DomainRoot)
        => Add Resources 6:01 PM 4/9/2026
        Resources
        OU=Resources,OU=VD,OU=VPI,OU=_MIGRATIONS,$($DomainRoot)


    .PARAMETER  SiteCode
    Toro 3-letter site code
    .PARAMETER Type
    Optional Type of OU to resolve (Generic|Resource|PermissionGroup|DistributionGroup|Contact - alternative to older explicit parameters)[-type Resource]
    .PARAMETER Generic
    Switch parameter indicating Generic mailboxes OU (defaults Generic Email Accounts OU).[-Generic]
    .PARAMETER Resource
    Switch parameter indicating Resource mailboxes OU (defaults Email Resources OU).[-Resource]
    .PARAMETER PermissionGroup
    Switch parameter indicating PermissionGroup Group OU (defaults Email Access OU).[-PermissionGroup]
    .PARAMETER DistributionGroup
    Switch parameter indicating DistributionGroup OU (defaults Distribution Groups OU).[-DistributionGroup]
    .PARAMETER Contact
    Switch parameter indicating Contact OU (defaults Email Contacts OU).[-Contact]
    .PARAMETER Users
    Switch parameter indicating Users OU (defaults Non-generic/Users OU).[-Users]
    .PARAMETER domaincontroller
    Optional domaincontroller (skips discovery)[-domaincontroller 'Dc1']
    .OUTPUT
    [system.string] Returns a OU DN 
    .EXAMPLE
    $OU=get-SiteMbxOU -Sitecode SITE -Generic
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU
    .EXAMPLE
    $MAILBOXou = get-sitembxou -Sitecode AAA -modelDistinguishedName 'OU=Aaaaaa Aaaaaaa,OU=Aaaaa Aaaaa,OU=Aaaa Aaaaaaaa,OU=Aaaaaa,OU=_AAA_Aaaa_AAA_AaAaaa,OU=AAA,OU=_AAAAAAAAAA,DC=aaaaaa,DC=aa,DC=aaaa,DC=aaa' -type Generic ; 
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU, resolving a SiteCode and modelDistinguishedName (to differentiat variant root)
    PS> $pltGSmbx = [ordered]@{
    PS>     Sitecode = $SiteCode ;
    PS> } ; 
    PS> if ($ownermbx.DistinguishedName -match $rgxOUMigrations) {
    PS>     $pltGSmbx.add('modelDistinguishedName',$ownermbx.DistinguishedName)
    PS> }else{
    PS>     $pltGSmbx.add('modelDistinguishedName',$ownermbx.DistinguishedName)
    PS> } ; 
    PS> If($InputSplat.NonGeneric) {
    PS>     if($pltGSmbx.keys -contains 'generic'){$pltGSmbx.remove('Generic')}
    PS> } elseIf($Room -OR $Equipement) {
    PS>     $pltGSmbx.add('Resource',$true) ;
    PS> } else {
    PS>     $pltGSmbx.add('Generic',$true ) ;
    PS> } ;
    PS> if ( $MbxSplat.OrganizationalUnit = (Get-SiteMbxOU @pltGSmbx)   ) {
    PS> } else { Cleanup ; BREAK ;};
    Demo mailbox OU call from verb-ex2010\new-mailboxShared
    .EXAMPLE
    PS> 'AUG','CMW','DIT','HAM','INT','RAD','SUB','VPI' | %{
    PS>     $thiscode = $_ ; 
    PS>     $pltWHTtl = get-colorcombo -Combo 34 ; 
    PS>     $pltWHtype = get-colorcombo -Combo 40 ; 
    PS>     $pltWHResult = get-colorcombo -Combo 46 ; 
    PS>     $pltWHGen = get-colorcombo -Combo 66 ; 
    PS>     $pltWHRes = get-colorcombo -Combo 36 ; 
    PS>     $pltWHSec = get-colorcombo -Combo 17 ; 
    PS>     write-host @pltWHTtl "`n`n==Site:$($thiscode):" ;
    PS>     switch($thisCode){
    PS>         'AUG'{ $mDN = "OU=AUG,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"} 
    PS>         'CMW'{ $mDN = "OU=CMW,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"} 
    PS>         'DIT'{ $mDN = "OU=DIT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"} 
    PS>         'HAM'{ $mDN = "OU=HAM,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"}
    PS>         'INT'{ $mDN = "OU=INT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"} 
    PS>         'RAD'{ $mDN = "OU=RAD,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"} 
    PS>         'SUB'{ $mDN = "OU=SUB,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"} 
    PS>         'VPI'{ $mDN = "OU=VPI,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com"}  
    PS>     }
    PS>     $pltGSMx = [ordered]@{Sitecode = $thisCode ;modelDistinguishedName = $mDN ; type = $null ; verbose = $true } ; 
    PS>     foreach($type in @('Generic','Resource','PermissionGroup')){
    PS>       $pltGSMx.type = $type ; 
    PS>       switch($type){
    PS>           'Generic'{$pltW = $pltWHGen}
    PS>           'Resource'{$pltW = $pltWHRes}
    PS>           'PermissionGroup'{$pltW = $pltWHSec}
    PS>       } ; 
    PS>       write-host @pltW "Site:$($thiscode):$((get-date).ToString('HH:mm:ss')):get-sitembxou w`n$(($pltGSMx|out-string).trim())" ;     
    PS>       write-host @pltWHResult "`n=>`n$((get-sitembxou @pltGSMx|out-string).trim())" ; 
    PS>     } ; 
    PS> } ; 
    PS> 
    Test code to check function across range of Migrations OUs & site codes (for presence of target OUs)
    .EXAMPLE
    PS> get-recipient -filter {recipienttypedetails -eq 'RemoteRoomMailbox'} | ?{$_.primarysmtpaddress -like '*@ditchwitch.com' } |select dist*
    Code to poll RemoteMailbox Names distribution for a given brand domain
    .EXAMPLE
    PS> get-recipient -filter {recipienttypedetails -eq 'RemoteRoomMailbox'} | select @{Name="ParentOU";Expression={ ($_.distinguishedname.tostring() -split '(?<!\\),' | select -skip 1) -join "," } } | group ParentOU |  sort name | ft -a count,name
    Code to poll RemoteMailbox ParentOU distribution for cloud Room mailboxes
    .EXAMPLE
    PS> $allOUs = Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server global.ad.toro.com
    PS> $allOUs |?{$_.DistinguishedName  -match 'OU=Resources,.*OU=\w{3},OU=_MIGRATIONS,'}  | ft -a
    Gathers all OUOs in the domain for analysis, with post filtering target OU trees
    .EXAMPLE
    PS> $rootous = Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase "DC=global,DC=ad,DC=toro,DC=com" -SearchScope onelevel
    PS> $SiteRootOUs = @() ; 
    PS> $SiteRootOUs += Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase "DC=global,DC=ad,DC=toro,DC=com" -SearchScope onelevel |?{$_.distinguishedname -match '^OU=\w{3},' -OR $_.distinguishedname -match '^OU=PACRIM'} ; 
    PS> $SiteRootOUs += Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase "OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com" -SearchScope onelevel |?{$_.distinguishedname -match '^OU=\w{3},'} ; 
    PS> $siterootous.distinguishedname ; 
    Gather all Root OUs
    .EXAMPLE
    $sitecodes = @() ; $siterootous.distinguishedname | %{ $_ | ?{$_ -match 'OU=(\w{3,6})'} | out-null ; $sitecodes += $matches[1]} ;
    Build dyn syntecodes list
    .EXAMPLE
    PS> $allmc = get-mailcontact -resultsize unlimited ; 
    PS> $allmc |  select @{Name="ParentOU";Expression={($_.distinguishedname.tostring() -split '(?<!\\),' | select -skip 1) -join "," } }  | group parentOU |  sort name | ft -a count,name ; 
    Code to sample distribution of MailContact OUs
    .EXAMPLE
    PS> $alladu = get-aduser -filter * -ResultSetSize $null
    PS> $alladu |  select @{Name="ParentOU";Expression={($_.distinguishedname.tostring() -split '(?<!\\),' | select -skip 1) -join "," } }  | group parentOU |  
    PS>     ?{$_.parentOU -notmatch 'OU=New|Disabled|Generic|Email|Resource|Kiosk|Shared|System|Test|Other|Computers'} sort name | 
    PS>     ft -a count,name ; 
    Code to sample distribution of ADUser OUs (filter out non-working user standards (no onboarding/disabled etc))
    .EXAMPLE
    PS> $alldg = get-distributiongroup -ResultSize unlimited ;
    PS> $alldg  |  select @{Name="ParentOU";Expression={($_.distinguishedname.tostring() -split '(?<!\\),' | select -skip 1) -join "," } }   | group parentOU |  sort name | ft -a count,name ;
    Code to sample distribution of DistributionGroup OUs
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')]
    [Alias('get-SiteRoleOU')]
    PARAM (
        [parameter(Mandatory=$false,HelpMessage="Specify the Toro 3-letter site code upon which to Query[LYN]")]
            [string[]]$Sitecode,
        [parameter(Mandatory=$false,HelpMessage="a Model DN to use to locate the resource in the same Site tree[DN]")]
            [string[]]$modelDistinguishedName,
        [parameter(ParameterSetName = 'Type',Mandatory=$false,HelpMessage="Optional Type of OU to resolve (alternative to older explicit parameters[-type Resource]")]
            [AllowEmptyString()][AllowNull()]
            [ValidateSet('Generic','Resource','PermissionGroup','DistributionGroup','Contact','Users','')]
            [string]$Type,
        [parameter(ParameterSetName = 'Generic', Mandatory=$true,HelpMessage="Switch parameter indicating Generic mailboxes OU (defaults Generic Email Accounts OU).[-Generic]")]
            [switch]$Generic,
        [parameter(ParameterSetName = 'Resource', Mandatory=$true,HelpMessage="Switch parameter indicating Resource mailboxes OU (defaults Email Resources OU).[-Resource]")]
            [switch]$Resource,        
        [parameter(ParameterSetName = 'PermissionGroup', Mandatory=$true,HelpMessage="Switch parameter indicating PermissionGroup Group OU (defaults Email Access OU).[-PermissionGroup]")]
            [switch]$PermissionGroup,
        [parameter(ParameterSetName = 'DistributionGroup', Mandatory=$true,HelpMessage="Switch parameter indicating DistributionGroup OU (defaults Distribution Groups OU).[-DistributionGroup]")]
            [switch]$DistributionGroup,
        [parameter(ParameterSetName = 'Contact', Mandatory=$true,HelpMessage="Switch parameter indicating Contact OU (defaults Email Contacts OU).[-Contact]")]
            [switch]$Contact,
        [parameter(ParameterSetName = 'Users', Mandatory=$true,HelpMessage="Switch parameter indicating Users OU (defaults Non-generic/Users OU).[-Users]")]
            [switch]$Users,
        [Parameter(HelpMessage = "Optional domaincontroller (skips discovery)[-domaincontroller 'Dc1']")]
            [string]$domaincontroller
    ) ;  # PARAM-E    
    #region CONSTANTS_LOCAL ; #*------v CONSTANTS_LOCAL v------
    # OU that's used when can't find any baseuser for the owner's OU, default to a random shared from ($ADSiteCodeUS) (avoid crapping out):
    $DomainRoot = "DC=$($domtorfqdn -replace "\.",',DC=')" ; 
    $FallBackBaseUserOU = "$($DomTORfqdn)/$($ADSiteCodeUS)/Generic Email Accounts" ;
    # 3:46 PM 4/3/2026 add Migrations OU variant support
    $rgxOUMigrations = ",OU=_MIGRATIONS,$($DomainRoot)$" ;
    $rgxMigationsSite = ",OU=(\w+),OU=_MIGRATIONS,$($DomainRoot)$" ;
    $srchBaseMigrations = "OU=_MIGRATIONS,$($DomainRoot)" ; 
    $srchBaseRoot = "$($DomainRoot)"  ; 
    $RootAddOUNames = @('PACRIM') ; 
    [regex]$rgxRootAddOUNames = ('(' + (($RootAddOUNames |%{[regex]::escape($_)}) -join '|') + ')') ;
    $rgxSiteOUNames = '^OU=\w{3},' ; 
    # CONSTANTS THAT SPEC DEFAULT OUS: ROOT OU'S
    $SharedRootOU = "OU=Generic Email Accounts"
    $ResourceRootOU="^OU=Email Resources"
    $PermissionGroupRootOU="OU=Email Access"
    $DistributionGroupRootOU='^OU=Distribution Groups'
    $ContactRootOU='^OU=Email Contacts'
    $UsersRootOU='^OU=Users'
    # MIGRATION ROOT SPECS
    $SharedMigrOU = "OU=Generic Email Accounts"
    $ResourceMigrOU="OU=Resources"
    $PermissionGroupMigrOU="OU=Email Access"
    $DistributionGroupMigrOU='^OU=Distribution Groups' # cmw is exempted in code
    $ContactMigrOU='^OU=Email Contacts'
    #$UsersMigrOU='^OU=Users' # EXEMPTIONS FOR EVERY SITE, THEY'RE COMPLETELY UNMANAGED/UNSTANDARDIZED!


    #endregion CONSTANTS_LOCAL ; #*------^ END CONSTANTS_LOCAL ^------
    # for backward  compat preserve the explicit switches, but boil them down into a Type that's used with switch blocks
    if(-not $type -AND ($Generic -OR $Resource -OR $PermissionGroup)){
        $Type = "" 
        if($Generic){$Type = 'Generic'}
        elseif($Resource){$Type = 'Resource'}
        elseif($PermissionGroup){$Type = 'PermissionGroup'}
        elseif($DistributionGroup){$Type = 'DistributionGroup'}
        elseif($Contact){$Type = 'Contact'}
        else {$Type = 'Generic'}
    } ;
    if(-not $type -AND -not ($Generic -OR $Resource -OR $PermissionGroup)){
        write-warning "NONE OF EITHER: -TYPE -GENERIC -RESOURCE OR -PermissionGroup SPECIFIED!" ; 
        RETURN ; 
    }
    $verbose = ($VerbosePreference -eq "Continue") ; 
    if (!$domaincontroller) {
        if($env:userdomain -eq 'CMW'){
            $domaincontroller = get-addomaincontroller | select -expand hostname ;
        }else{
            $pltGDC = @{} ;
            if ($DCExclude) { $pltGDC.add('Exclude', $DCExclude) };
            if ($DCServerPrefix) { $pltGDC.add('ServerPrefix', $DCServerPrefix) };
            if((gcm get-gcfast).parameters.keys -contains 'silent'){$pltGDC.add('silent', $true) };
            if ($pltgdc.GetEnumerator().name) { $domaincontroller = get-gcfast @pltgdc } else { $domaincontroller = get-gcfast } ;
        } ;
    } ;
    write-verbose "Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase $($srchBaseRoot)" 
    $SiteRootOUs += Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase $srchBaseRoot -SearchScope onelevel -server $domaincontroller|
        ?{$_.distinguishedname -match $rgxSiteOUNames -OR $_.distinguishedname -match $rgxRootAddOUNames} ; 
    write-verbose "Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase $($srchBaseMigrations)"
    $SiteMigrOUs += Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase $srchBaseMigrations -SearchScope onelevel -server $domaincontroller |
        ?{$_.distinguishedname -match $rgxSiteOUNames}  ; 
    $AllSiteOUDns = $(@($SiteRootOUs.distinguishedname);@($SiteMigrOUs.distinguishedname)) ; 
    $AllSiteCodes = @() ; 
    $AllSiteOUDns | %{ $_ | ?{$_ -match 'OU=(\w{3,6})'} | out-null ; $AllSiteCodes += $matches[1]} ;
    if($AllSiteCodes -contains $SiteCode){
        $smsg = "validated $($siteCode) is a valid/supported value" ; 
        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }else{
        $smsg = "$($siteCode) IS *NOT* A VALID/SUPPORTED EXISTING SITECODE VALUE!" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        THROW $SMSG ; 
        RETURN ; 
    }

    if ($env:USERDOMAIN -eq $TORMeta['legacyDomain']) {
        if($modelDistinguishedName -match $rgxOUMigrations){
            write-verbose "resolving FindOU on Migrations Sites" ; 
            switch($type){                
                'Generic' {
                    #$SharedMigrOU = "OU=Generic Email Accounts" # 5:18 PM 4/9/2026 confirmed DIT
                    $FindOU=$SharedMigrOU
                }
                'Resource' {
                    #$ResourceMigrOU="OU=Resources"
                    $FindOU=$ResourceMigrOU
                }
                'PermissionGroup' {
                    #$PermissionGroupMigrOU="OU=Email Access"
                    $FindOU=$PermissionGroupMigrOU
                }
                'DistributionGroup' {                    
                    switch ($SiteCode){
                        'CMW'{
                            $FindOU="OU=Distribution"
                        }
                        default {
                            #$DistributionGroupMigrOU='^OU=Distribution Groups'
                            $FindOU=$DistributionGroupMigrOU
                        }
                    }
                }
                'Contact' {
                    #$ContactMigrOU='^OU=Email Contacts'
                    $FindOU=$ContactMigrOU
                }
                'Users' {
                    switch($siteCode){
                        'AUG'{
                            #$UsersMigrOU='^OU=Users'
                            #$FindOU=$UsersMigrOU ;
                            $FindOU='^OU=User Accounts' ; 
                        }
                        'DIT'{
                            #$UsersMigrOU='^OU=Users'
                            #$FindOU=$UsersMigrOU ;
                            $FindOU='^OU=People' ; 
                        }
                        'HAM'{
                            #$UsersMigrOU='^OU=Users'
                            #$FindOU=$UsersMigrOU ;
                            $FindOU='^OU=User Accounts' ; 
                        }
                        'INT'{
                            #$UsersMigrOU='^OU=Users'
                            #$FindOU=$UsersMigrOU ;
                            $FindOU='^OU=Departments' ; 
                        }
                        'RAD'{
                            #$UsersMigrOU='^OU=Users'
                            #$FindOU=$UsersMigrOU ;
                            $FindOU='^User Accounts' ; 
                        }
                        'VPI'{
                            #$UsersMigrOU='^OU=Users'
                            #$FindOU=$UsersMigrOU ;
                            $FindOU='^OU=VD' ; 
                        }
                        DEFAULT{
                            $FindOU='^OU=Users' ; 
                        }
                    }
                }
                default{
                    $FindOU="OU=Generic Email Accounts"
                } ;
            }
            <#
            #$FindOU = "OU=Email\sAccess," ;
            if($Generic){
                $FindOU="OU=Generic Email Accounts" # 5:18 PM 4/9/2026 confirmed DIT
            } elseif($Resource){
                $FindOU="OU=Resources"
            } elseif($Shared){
                $FindOU="OU=Generic Email Accounts"
            } elseif($PermissionGroup){
                $FindOU="OU=Email Access,"
            } else {
                $FindOU="OU=Generic Email Accounts"
            } ;
            # MIGHT HAVE TO TEST A SERIES, IF LF REALLY MANGLED THE PATHS ACROSS DIVISIONS!
            #>
        }ELSE{
            write-verbose "resolving FindOU on root Sites" ; 
            switch($type){
                'Generic' {
                    #$SharedRootOU = "OU=Generic Email Accounts"
                    $FindOU=$SharedRootOU
                }
                'Resource' {
                    #$ResourceRootOU="^OU=Email Resources"
                    $FindOU=$ResourceRootOU
                }                
                'PermissionGroup' {
                    #$PermissionGroupRootOU="OU=Email Access"
                    $FindOU=$PermissionGroupRootOU
                } 
                 'DistributionGroup' {
                    #$DistributionGroupRootOU='^OU=Distribution Groups' 
                    $FindOU=$DistributionGroupRootOU
                } 
                'Contact' {
                    #$ContactRootOU='^OU=Email Contacts' 
                    $FindOU=$ContactRootOU
                } 
                'Users' {
                    #$UsersRootOU='^OU=Users' 
                    $FindOU=$UsersRootOU ; 
                }
                default{
                    $FindOU=$UsersRootOU
                } ;
            }
            <#
            #$FindOU = "OU=Email\sAccess,OU=SEC\sGroups,OU=Managed\sGroups,";
            if($Generic){
                $FindOU="OU=Generic Email Accounts"
            } elseif($Resource){
                $FindOU="^OU=Email Resources"
            } else {
                $FindOU="OU=Users"
            } ;
            #>
        }
    } ELSEif ($env:USERDOMAIN -eq $TOLMeta['legacyDomain']) {
        # CN=Lab-SEC-Email-Thomas Jefferson,OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=LYN,DC=SUBDOM,DC=DOMAIN,DC=DOMAIN,DC=com
        switch($type){
            'Generic' {
                $FindOU="^OU=Generic Email Accounts"
            }
            'Resource' {
                $FindOU="^OU=Email Resources"
            }
                
            'Shared' {
                $FindOU="OU=Generic Email Accounts"
            }
            'PermissionGroup' {
                $FindOU="OU=Email Access,"
            } 
             'DistributionGroup' {
                    $FindOU="OU=Email Access"
            } 
            'Contact' {
                $FindOU="OU=Email Access"
            } 
            default{
                $FindOU="^OU=Users"
            } ;
        }
        <#
        if($Generic){
            $FindOU="^OU=Generic Email Accounts"
        } elseif($Resource){
            $FindOU="^OU=Email Resources"
        } else {
            $FindOU="^OU=Users"
        } ;
        #>
    } else {
        throw "UNRECOGNIZED USERDOMAIN:$($env:USERDOMAIN)" ;
    } ;
    $error.clear() ;
    TRY {
        if($SiteCode -AND -not $modelDistinguishedName){
            write-verbose "Running -SiteCode:$($Sitecode) root-only lookup (no migrations tree resolution supported)" ; 
            $OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU).*,OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
        }elseif($SiteCode -AND $modelDistinguishedName){
            write-verbose "Running expanded modelDN + SiteCode:$($Sitecode) lookup (with migrations tree resolution supported)" ; 
            if($modelDistinguishedName -match $rgxOUMigrations){
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $($DomainController) | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=$($SiteCode),.*,OU=_MIGRATIONS,$($DomainRoot)$" } | Select-Object distinguishedname).distinguishedname.tostring() ;
                #OU=Email\sAccess,.*OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $($DomainController) | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=_TTC_Sync_CMW_NoSync,OU=$($SiteCode),OU=_MIGRATIONS," } | Select-Object distinguishedname).distinguishedname.tostring() ;
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=_TTC_Sync_CMW_NoSync,OU=$($SiteCode),OU=_MIGRATIONS," } | Select-Object distinguishedname).distinguishedname.tostring() ;
                # -SearchScope onelevel 
                if($RootSrch = Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase "OU=$($SiteCode),$($srchBaseMigrations)" -server $domaincontroller){
                    write-verbose "Running SiteCode: $($SiteCode) FindOU: $($FindOU)`n^$($FindOU).*OU=_TTC_Sync_CMW_NoSync,OU=$($SiteCode),OU=_MIGRATIONS,"
                    if($OuDN = $RootSrch | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=_TTC_Sync_CMW_NoSync,OU=$($SiteCode),OU=_MIGRATIONS," }){
                        $OuDN = $OuDN.distinguishedname.tostring() ; 
                    }elseif($OuDN = $RootSrch | Where-Object { $_.distinguishedname -match "^$($FindOU).*,OU=$($SiteCode),OU=_MIGRATIONS," }){
                        # some migrations OUs don't have objects below ,OU=_TTC_Sync_CMW_NoSync, check from root
                        $OuDN = $OuDN.distinguishedname.tostring() ;                     
                    }else{
                        $smsg = "UNABLE TO RESOLVE TARGET: -FINDOU:$($FindOU) in scope: OU=$($SiteCode),$($srchBaseMigrations)" ; 
                        write-warning $smsg ; 
                        throw $smsg ; 
                    }
                }else{
                    $smsg = "UNABLE TO RESOLVE TARGET -scope: OU=$($SiteCode),$($srchBaseMigrations)~" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                } ; 
            }else{
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $($DomainController) | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | Select-Object distinguishedname).distinguishedname.tostring() ;
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | Select-Object distinguishedname).distinguishedname.tostring() ;
                # -SearchScope onelevel 
                if($RootSrch = Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase "OU=$($SiteCode),$($srchBaseRoot)" -server $domaincontroller){
                    write-verbose "Running SiteCode: $($SiteCode) FindOU: $($FindOU)`n^$($FindOU).OU=$($SiteCode),OU=_MIGRATIONS,"
                    if($OuDN = $RootSrch | Where-Object { $_.distinguishedname -match "^$($FindOU).OU=$($SiteCode),OU=_MIGRATIONS," }){
                        $OuDN = $OuDN.distinguishedname.tostring() ; 
                    }else{
                        $smsg = "UNABLE TO RESOLVE TARGET: -FINDOU:$($FindOU) in scope: OU=$($SiteCode),$($srchBaseMigrations)~" ; 
                        write-warning $smsg ; 
                        throw $smsg ; 
                    }
                }else{
                    $smsg = "UNABLE TO RESOLVE TARGET -scope: OU=$($SiteCode),$($srchBaseMigrations)~" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                } ; 
            }
        } ; 
        if($OUdn){
            If($OUdn -isnot [string]){      # post-verification to ensure we've got a single OU spec
                $smsg = "AD OU SEARCH SITE:$($InputSplat.SiteCode), FindOU:$($FindOU), FAILED TO RETURN A SINGLE OU..."
                $smsg += "`n(may have to specify a -modelDistinguishedName, for MIGRATIONS ou SUBTREES)" ;
                write-warning $smsg ; 
                $OUdn | select distinguishedname ;
                write-error "$((get-date).ToString('HH:mm:ss')):EXITING!";
                return ;
            } else{
                $OUdn | write-output  ; 
            } ; 
        }else{
            $false | write-output 
        }     
    } CATCH {
        $ErrTrapd=$Error[0] ;
        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
    } ;
    
} 
#endregion GET_SITEMBXOU ; #*------^ END get-SiteMbxOU ^------
