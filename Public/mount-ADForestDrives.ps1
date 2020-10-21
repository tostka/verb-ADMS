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
    # 3:02 PM 10/21/2020 debugged to function - connects fr TOR into TOR,TOL & CMW wo errors fr laptop, updated/expanded CBH examples; fixed missing break in OP_SIDAcct test
    # 7:59 AM 10/19/2020 added pretest before import-module
    4:11 PM 9/8/2020 building into verb-ADMS ; debugged through to TOR function, need fw access open on ports, to remote forest dc's: 5985 (default HTTP min), 5986 (HTTPS), 80 (pre-win7 http variant), 443 (pre-win7 https variant), 9389 (AD Web Svcs)
    * 10:29 AM 9/3/2020 init, still WIP, haven't fully debugged to function
    .DESCRIPTION
    mount-ADForestDrives() - Collect XXXMeta['ADForestName']'s and mount usable PSDrive objects for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest)
    Borrowed concept of a pre-configured array of $forests from Raimund's post.
    .PARAMETER TorOnly
    Switch to limit test to local 'TOR' forest [-TorOnly]
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
    $result ;
    Query and mount AD PSDrives for all Forests configured by XXXMeta.ADForestName variables, then run get-aduser for the administrator account
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
                Stop
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
                $pltNpsD=@{
                    Name=($forestShortName -replace $rgxDriveBanChars) ;
                    Root=$forestDN ;
                    PSProvider='ActiveDirectory' ;
                    Credential =$forests[$forestShortName].cred ; 
                    Server=$forestShortName ;
                    whatif=$($whatif);
                }
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