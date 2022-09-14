#*------v Function get-ADSiteLocal v------
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
} ; 
#*------^ END Function get-ADSiteLocal ^------