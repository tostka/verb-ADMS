#*------v Function mount-ADForestDrives v------
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
    REVISIONS
    * 10:29 AM 9/3/2020 init, still WIP, haven't fully debugged to function
    .DESCRIPTION
    mount-ADForestDrives() - Collect XXXMeta['ADForestName']'s and mount usable PSDrive objects for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest)
    .OUTPUT
    Returns an object containing the Name and credential os the new PSDrives configured
    .EXAMPLE
    $PsDriveNames=mount-ADForestDrives
    Query and mount AD PSDrives for all Forests configured by XXXMeta.ADForestName variables
    .LINK
    #>
    ##Requires -Version 2.0
    #Requires -Version 3
    #requires -PSEdition Desktop
    #Requires -Modules ActiveDirectory
    #Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("(lyn|bcc|spb|adl)ms6(4|5)(0|1).(china|global)\.ad\.toro\.com")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $DefVaris = $(Get-Variable).Name ;
        #${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;
    }
    PROCESS {
        $error.clear() ;

        $forests = @{} ;
        $objReturn =@{} ;

        $globalMetas = get-variable  | ? {$_.name -match '^\w{3}Meta$' -AND $_.visibility -eq 'Public' -ANd $_.value } ;

        foreach ($globalMeta in $globalMetas) {
            $TenantDom = ($globalMeta.value)['o365_TenantDom'] ;
            # (gv cred*) | %{"$($_.name)`t:`t$($_.value.username)" } ;
            switch ($TenOrg) {
                "TOL" {
                    $prefCred = "credTOLSID" ;
                }
                "TOR" {
                    $prefCred = "credTORSID" ;
                }
                "CMW" {
                    $prefCred = "credCMWSID" ;
                }
                <# no curr onprem grants
                "VEN" {
                    $prefCred = "credO365VENCSID" ;
                    $credType = "CS" ;
                }
                #>
                default {
                    throw "Unrecoginzed `$TenOrg!:$($TenOrg)"
                }
            } ;

            $SIDcred = (Get-Variable -name $($prefCred)).Value ;
            $ForName = (gv -name "$($TenOrg)Meta").value.ADForestName ;
            write-verbose "Processing forest:TAG:$($TenantDom)::$($ForName)::$($SIDcred.username)";

            #$forests.add('forest1.net',(New-Object pscredential('forest1\Administrator', ('Password1' | ConvertTo-SecureString -AsPlainText -Force))) ) ;
            $forests.add($ForName,$SIDcred) ;

        } ; # loop-E

        Import-Module -Name ActiveDirectory ;
        $drives = $forests.Keys | ForEach-Object {
            #$forestShortName = ($_ -split '\.')[0] ;
            # doesn't work for subdom forests (too many periods to split)
            # just rplc . with nothing
            $forestShortName = $_.replace('.','') ;
            TRY {
                $forestDN = (Get-ADRootDSE -Server $forestShortName).defaultNamingContext ;
                $pltNpsD=@{
                    Name=$forestShortName ;
                    Root=$forestDN ;
                    PSProvider='ActiveDirectory' ;
                    Credential =$SIDcred ;
                    Server=$forestShortName ;
                    whatif=$($whatif);
                }
                write-verbose "$((get-date).ToString('HH:mm:ss')):New-PSDrive w`n$(($pltNpsD|out-string).trim())" ;
                #New-PSDrive -Name $forestShortName -Root $forestDN -PSProvider ActiveDirectory -Credential $forests.$_ -Server $forestShortName -whatif $($whatif);
                $bRet = New-PSDrive @pltNpsD ;

            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;


            if ($bRet) {
                $retHash = @{
                    Name     = $bRet.Name ;
                    UserName = $SIDCred ;
                    Status   = $true ;
                }
            } else {
                $retHash = @{
                    Name     = $pltNpsD.Name ;
                    UserName = $SIDCred ;
                    Status = $false  ;
                } ;
            }
            New-Object PSObject -Property $retHash | write-output ;
        } ; # loop-E
    } # PROC-E
    END {
        # clean-up dyn-created vars & those created by a dot sourced script.
        ((Compare-Object -ReferenceObject (Get-Variable).Name -DifferenceObject $DefVaris).InputObject).foreach{ Remove-Variable -Name $_   } ;
    } ;
} #*------^ END Function mount-ADForestDrives ^------
