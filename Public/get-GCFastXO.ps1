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
        catch {   write-error "*FAILED* TO LOAD MODULE*:$($tModName) VIA $(tModFile) !" ;   $tModFile = "$($tModName).ps1" ;   $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ;   if (Test-Path $sLoad) {       Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;       . $sLoad ;       if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };   } else {       $sLoad = (join-path -path $backInclDir -childpath $tModFile) ;       if (Test-Path $sLoad) {           Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;           . $sLoad ;           if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };       } else {           Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;           Break;       } ;   } ; } ; 
      } ;
      if(!(test-path function:$tModCmdlet)){
          write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet`nfailing through to `$backInclDir .ps1 version" ;
          $sLoad = (join-path -path $backInclDir -childpath "$($tModName).ps1") ;
          if (Test-Path $sLoad) {     Write-Verbose -verbose:$true ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;     . $sLoad ;     if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };     if(!(test-path function:$tModCmdlet)){         write-warning "$((get-date).ToString('HH:mm:ss')):FAILED TO CONFIRM `$tModCmdlet:$($tModCmdlet) FOR $($tModName)" ;     } else {          write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)"     }  
          } else {     Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;     Break; } ; 
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
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
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
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
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
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
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
} ; 
#*------^ get-GCFastXO.ps1 ^------