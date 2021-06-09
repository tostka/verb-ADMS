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
    #requires -PSEdition Desktop
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