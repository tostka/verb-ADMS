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
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
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
        OU=Generic Email Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=AUG,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Email Access,OU=Security Groups,OU=Groups,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=AUG,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Resources,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=AUG,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com

        DIT:
        ,OU=Generic Email Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Email Access,OU=Security Groups,OU=People,OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Resources,OU=User Accounts,OU=People,OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com

        CMW has:
        zippo


        HAM:
        OU=Email Access,OU=Security Groups,OU=Groups,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=HAM,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Generic Email Accounts,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=HAM,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Resources,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=HAM,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com

        INT:
        OU=Generic Email Accounts,OU=INT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        => ADDED rESOURCES 5:38 PM 4/9/2026
        OU=Resources,OU=INT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        => ADDED Email Access, 5:41 PM 4/9/2026
        Email Access,OU=Global Groups,OU=INT,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com

        RAD:
        OU=Email Access,OU=Security Groups,OU=Groups,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=RAD,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        OU=Generic Email Accounts,OU=Generic Users,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=RAD,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        => Add Resources 5:45 PM 4/9/2026
        OU=Resources,OU=User Accounts,OU=Users and Groups,OU=_TTC_Sync_CMW_NoSync,OU=RAD,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com

        SUB: 
        _TTC_Sync_CMW_NoSync tree is EMPTY
        => THEY'RE UP IN DW!
        OnPremisesDistinguishedName   : CN=C4C Subsite KY,OU=Contact Center,OU=SAP,OU=Special Accounts,OU=_TTC_Sync_CMW_NoSync,DC=ditchwitch,DC=cmw,DC=internal
        SHAREDMAILBOX
        there's no users using the domain:
        ▒▒▒▒▒ [PS]:D:\scripts $ get-xorecipient -filter {primarysmtpaddress -like '*@subsite.com'} -RecipientType usermailbox

        ▒▒▒▒▒ [PS]:D:\scripts $ get-xorecipient -filter {primarysmtpaddress -like '*@subsite.com'}

        VPI:
        OU=Generic Email Accounts,OU=VD,OU=VPI,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        => added OU=Email Access 5:59 PM 4/9/2026
        OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=VD,OU=VPI,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com
        => Add Resources 6:01 PM 4/9/2026
        Resources
        OU=Resources,OU=VD,OU=VPI,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com

    .PARAMETER  SiteCode
    Toro 3-letter site code
    .PARAMETER  Generic
    Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).
    .PARAMETER  Resource
    Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]
    .OUTPUT
    [system.string] Returns a OU DN 
    .EXAMPLE
    $OU=get-SiteMbxOU -Sitecode SITE
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU
    .LINK
    #>
    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$false,HelpMessage="Specify the Toro 3-letter site code upon which to Query[LYN]")]
            [string[]]$Sitecode,
        [parameter(Mandatory=$false,HelpMessage="a Model DN to use to locate the resource in the same Site tree[DN]")]
            [string[]]$modelDistinguishedName,
        [parameter(Mandatory=$false,HelpMessage="Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).[-Generic]")]
            [switch]$Generic,
        [parameter(Mandatory=$false,HelpMessage="Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]")]
            [switch]$Resource
        #,
        #[Parameter(HelpMessage = "Optional domaincontroller (skips discovery)[-domaincontroller 'Dc1']")]
        #    [string]$domaincontroller
    ) ;  # PARAM-E
    # OU that's used when can't find any baseuser for the owner's OU, default to a random shared from ($ADSiteCodeUS) (avoid crapping out):
    $FallBackBaseUserOU = "$($DomTORfqdn)/$($ADSiteCodeUS)/Generic Email Accounts" ;
    # 3:46 PM 4/3/2026 add Migrations OU variant support
    $rgxOUMigrations = ',OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com$' ;
    $rgxMigationsSite = ',OU=(\w+),OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com$' ;
    $verbose = ($VerbosePreference -eq "Continue") ; 
    if($Generic -AND $resource ){
        $smsg = "-Generic -AND -Resource *BOTH* SPECIFIED: THEY ARE MUTUALLY EXCLUSIVE!" ; 
        $smsg += "`nSPECIFY ONE OR THE OTHER, NOT *BOTH*!" ;
        WRITE-WARNING $SMSG; 
        THROW $SMSG
        RETURN ;
    } ; 
    <# OUs don't move, don't need latest DC data
    if (!$domaincontroller) {
        if($env:userdomain -eq 'CMW'){
            $domaincontroller = get-addomaincontroller | select -expand hostname ;
        }else{
            $pltGDC = @{} ;
            if ($DCExclude) { $pltGDC.add('Exclude', $DCExclude) };
            if ($DCServerPrefix) { $pltGDC.add('ServerPrefix', $DCServerPrefix) };
            if ($pltgdc.GetEnumerator().name) { $domaincontroller = get-gcfast @pltgdc } else { $domaincontroller = get-gcfast } ;
        } ;
    } ;
    #>
    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):using common `$domaincontroller:$($domaincontroller)" ;
    $moveTargets = @() ;
    # lift from add-MailboxAccessGrant revision
    if ($env:USERDOMAIN -eq $TORMeta['legacyDomain']) {
        if($modelDistinguishedName -match $rgxOUMigrations){
            #$FindOU = "OU=Email\sAccess," ;
            if($Generic){
                $FindOU="OU=Generic Email Accounts" # 5:18 PM 4/9/2026 confirmed DIT
            } elseif($Resource){
                $FindOU="OU=Resources"
            } else {
                $FindOU="OU=Generic Users"
            } ;
            # MIGHT HAVE TO TEST A SERIES, IF LF REALLY MANGLED THE PATHS ACROSS DIVISIONS!
        }ELSE{
            #$FindOU = "OU=Email\sAccess,OU=SEC\sGroups,OU=Managed\sGroups,";
            if($Generic){
                $FindOU="OU=Generic Email Accounts"
            } elseif($Resource){
                $FindOU="^OU=Email Resources"
            } else {
                $FindOU="OU=Users"
            } ;
        }
    } ELSEif ($env:USERDOMAIN -eq $TOLMeta['legacyDomain']) {
        # CN=Lab-SEC-Email-Thomas Jefferson,OU=Email Access,OU=SEC Groups,OU=Managed Groups,OU=LYN,DC=SUBDOM,DC=DOMAIN,DC=DOMAIN,DC=com
        if($Generic){
            $FindOU="^OU=Generic Email Accounts"
        } elseif($Resource){
            $FindOU="^OU=Email Resources"
        } else {
            $FindOU="^OU=Users"
        } ;
    } else {
        throw "UNRECOGNIZED USERDOMAIN:$($env:USERDOMAIN)" ;
    } ;
    $error.clear() ;
    TRY {
        if($SiteCode -AND -not $modelDistinguishedName){
            # prior
            $OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU).*,OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
        }elseif($SiteCode -AND $modelDistinguishedName){            
            if($modelDistinguishedName -match $rgxOUMigrations){
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $($DomainController) | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=$($SiteCode),.*,OU=_MIGRATIONS,DC=global,DC=ad,DC=toro,DC=com$" } | Select-Object distinguishedname).distinguishedname.tostring() ;
                #OU=Email\sAccess,.*OU=_TTC_Sync_CMW_NoSync,OU=DIT,OU=_MIGRATIONS,
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $($DomainController) | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=_TTC_Sync_CMW_NoSync,OU=$($SiteCode),OU=_MIGRATIONS," } | Select-Object distinguishedname).distinguishedname.tostring() ;
                $OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=_TTC_Sync_CMW_NoSync,OU=$($SiteCode),OU=_MIGRATIONS," } | Select-Object distinguishedname).distinguishedname.tostring() ;
            }else{
                #$OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } -server $($DomainController) | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | Select-Object distinguishedname).distinguishedname.tostring() ;
                $OUdn = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | Where-Object { $_.distinguishedname -match "^$($FindOU).*OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | Select-Object distinguishedname).distinguishedname.tostring() ;
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
