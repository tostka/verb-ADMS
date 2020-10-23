#*------v unmount-ADForestDrives.ps1 v------
function unmount-ADForestDrives {
    <#
    .SYNOPSIS
    unmount-ADForestDrives() - Unmount PSDrive objects mounted for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will remove solely those drives. Otherwise removes all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module). Returns $true/$false on pass status.
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-10-23
    FileName    : unmount-ADForestDrives
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,CrossForest
    AddedCredit : Raimund (fr social.technet.microsoft.com comment)
    AddedWebsite: https://social.technet.microsoft.com/Forums/en-US/a36ae19f-ab38-4e5c-9192-7feef103d05f/how-to-query-user-across-multiple-forest-with-ad-powershell?forum=ITCG
    AddedTwitter:
    REVISIONS
    # 7:24 AM 10/23/2020 init 
    .DESCRIPTION
    unmount-ADForestDrives() - Unmount PSDrive objects mounted for cross-domain ADMS work (ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will remove solely those drives. Otherwise removes all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module)
    .PARAMETER whatIf
    Whatif SWITCH  [-whatIf]
    .OUTPUT
    System.Boolean
    .EXAMPLE
    $result = unmount-ADForestDrives ;
    .LINK
    https://github.com/tostka/verb-adms
    #>
    #Requires -Version 3
    #Requires -Modules ActiveDirectory
    #Requires -RunasAdministrator
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        #$rgxDriveBanChars = '[;~/\\\.:]' ; # ;~/\.:
    }
    PROCESS {
        $error.clear() ;

        if($global:ADPsDriveNames){
            write-verbose "(Existing `$global:ADPsDriveNames variable found: removing the following *explicit* AD PSDrives`n$(($global:ADPsDriveName|out-string).trim())" ; 
            $tPsD = $global:ADPsDriveNames
        } else {
            write-verbose "(removing all PSProvider:ActiveDirectory PsDrives, *other* than any existing 'AD'-named drive)" ; 
            $tPsD = Get-PSDrive -PSProvider ActiveDirectory|?{$_.name -ne 'AD'} ; 
        }  ; 
        TRY {
            $bRet = $ADPsDriveNames |  Remove-PSDrive -Force -whatif:$($whatif) -verbose:$($verbose) ;
            $true | write-output ;
        } CATCH {
            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            #BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            $false | write-output ;
        } ;
    } # PROC-E
    END {} ;
} ; 

#*------^ unmount-ADForestDrives.ps1 ^------