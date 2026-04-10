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
    Optional Type of OU to resolve (alternative to older explicit -Generic,-Resource,-Shared,-Security parameters[-type Resource]
    .PARAMETER  Generic
    Switch parameter indicating Generic mailboxes OU (defaults Non-generic/Users OU).[-Generic]
    .PARAMETER  Resource
    Switch parameter indicating Resource mailboxes OU (defaults Non-generic/Users OU).[-Resource]
    .PARAMETER Security
    Switch parameter indicating SEcurity Group OU (defaults Non-generic/Users OU).[-Security]
    .OUTPUT
    [system.string] Returns a OU DN 
    .EXAMPLE
    $OU=get-SiteMbxOU -Sitecode SITE -Generic
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU
    .EXAMPLE
    $MAILBOXou = get-sitembxou -Sitecode AAA -modelDistinguishedName 'OU=Aaaaaa Aaaaaaa,OU=Aaaaa Aaaaa,OU=Aaaa Aaaaaaaa,OU=Aaaaaa,OU=_AAA_Aaaa_AAA_AaAaaa,OU=AAA,OU=_AAAAAAAAAA,DC=aaaaaa,DC=aa,DC=aaaa,DC=aaa' -generic:$false -resource:$true
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU, resolving a SiteCode and modelDistinguishedName (to differentiat variant root)
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
    PS>     foreach($type in @('Generic','Resource','Security')){
    PS>       $pltGSMx.type = $type ; 
    PS>       switch($type){
    PS>           'Generic'{$pltW = $pltWHGen}
    PS>           'Resource'{$pltW = $pltWHRes}
    PS>           'Security'{$pltW = $pltWHSec}
    PS>       } ; 
    PS>       write-host @pltW "Site:$($thiscode):$((get-date).ToString('HH:mm:ss')):get-sitembxou w`n$(($pltGSMx|out-string).trim())" ;     
    PS>       write-host @pltWHResult "`n=>`n$((get-sitembxou @pltGSMx|out-string).trim())" ; 
    PS>     } ; 
    PS> } ; 
    PS> 
    Test code to check function across range of Migrations OUs & site codes (for presence of target OUs)
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')]
    PARAM (
        [parameter(Mandatory=$false,HelpMessage="Specify the Toro 3-letter site code upon which to Query[LYN]")]
            [string[]]$Sitecode,
        [parameter(Mandatory=$false,HelpMessage="a Model DN to use to locate the resource in the same Site tree[DN]")]
            [string[]]$modelDistinguishedName,
        [parameter(ParameterSetName = 'Type',Mandatory=$false,HelpMessage="Optional Type of OU to resolve (alternative to older explicit -Generic,-Resource,-Shared,-Security parameters[-type Resource]")]
            [AllowEmptyString()][AllowNull()]
            [ValidateSet('Generic','Resource','Security','')]
            [string]$Type,
        [parameter(ParameterSetName = 'Generic', Mandatory=$true,HelpMessage="Switch parameter indicating Generic mailboxes OU (defaults Non-generic/Users OU).[-Generic]")]
            [switch]$Generic,
        [parameter(ParameterSetName = 'Resource', Mandatory=$true,HelpMessage="Switch parameter indicating Resource mailboxes OU (defaults Non-generic/Users OU).[-Resource]")]
            [switch]$Resource,        
        [parameter(ParameterSetName = 'Security', Mandatory=$true,HelpMessage="Switch parameter indicating SEcurity Group OU (defaults Non-generic/Users OU).[-Security]")]
            [switch]$Security,
        [Parameter(HelpMessage = "Optional domaincontroller (skips discovery)[-domaincontroller 'Dc1']")]
            [string]$domaincontroller
    ) ;  # PARAM-E    
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

    # for backward  compat preserve the explicit switches, but boil them down into a Type that's used with switch blocks
    if(-not $type -AND ($Generic -OR $Resource -OR $Security)){
        $Type = "" 
        if($Generic){$Type = 'Generic'}
        elseif($Resource){$Type = 'Resource'}
        elseif($Security){$Type = 'Security'}
        else {$Type = 'Generic'}
    } ;
    if(-not $type -AND -not ($Generic -OR $Resource -OR $Security)){
        write-warning "NONE OF EITHER: -TYPE -GENERIC -RESOURCE OR -SECURITY SPECIFIED!" ; 
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
                    $FindOU="OU=Generic Email Accounts" # 5:18 PM 4/9/2026 confirmed DIT
                }
                'Resource' {
                    $FindOU="OU=Resources"
                }                
                'Security' {
                    $FindOU="OU=Email Access"
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
            } elseif($Security){
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
                    $FindOU="OU=Generic Email Accounts"
                }
                'Resource' {
                    $FindOU="^OU=Email Resources"
                }                
                'Security' {
                    $FindOU="OU=Email Access"
                } 
                default{
                    $FindOU="OU=Users"
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
            'Security' {
                $FindOU="OU=Email Access,"
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
