#*----------------v Function get-GCFast v----------------
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
#*----------------^ END Function get-GCFast ^----------------