#*------v get-ADForestDrives.ps1 v------
function get-ADForestDrives {
    <#
    .SYNOPSIS
    get-ADForestDrives() - Get PSDrive PSProvider:ActiveDirectoryobjects currently mounted (for cross-domain ADMS work - ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will list solely those drives. Otherwise get-psDrive's all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module). Returns matching objects.
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-10-23
    FileName    : get-ADForestDrives
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,CrossForest
    AddedCredit : Raimund (fr social.technet.microsoft.com comment)
    AddedWebsite: https://social.technet.microsoft.com/Forums/en-US/a36ae19f-ab38-4e5c-9192-7feef103d05f/how-to-query-user-across-multiple-forest-with-ad-powershell?forum=ITCG
    AddedTwitter:
    REVISIONS
    # 1:05 PM 2/25/2021 init 
    .DESCRIPTION
    get-ADForestDrives() - Get PSDrive PSProvider:ActiveDirectoryobjects currently mounted (for cross-domain ADMS work - ADMS relies on set-location 'PsDrive' to shift context to specific forest). If $global:ADPsDriveNames variable exists, it will remove list solely those drives. Otherwise get-psDrive's all -PSProvider ActiveDirectory drives *not* named 'AD' (the default ADMS module drive, created on import of that module). Returns matching objects.
    .OUTPUT
    System.Object[]
    Returns System.Object[] to pipeline, summarizing the Name and credential of PSDrives configured
    .EXAMPLE
    $result = get-ADForestDrives ;
    Simple example
    .EXAMPLE
    if([boolean](get-ADForestDrives)){"XO adms ready"} else { ""XO adms NOT ready"}
    Example if/then
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
            write-verbose "(Leveraging existing `$global:ADPsDriveNames variable found PSDrives`n$(($global:ADPsDriveName|out-string).trim())" ;  
            $tPsD = $global:ADPsDriveNames ; 
            $tPsD | %{
                $retHash = @{
                    Name     = $_.Name ;
                    UserName = $_.UserName ; 
                    Status   = [boolean](test-path -path "$($_.Name):") ; # test actual access
                } ; 
                New-Object PSObject -Property $retHash | write-output ;
            } 
        } else {
            write-verbose "(Reporting on all PSProvider:ActiveDirectory PsDrives, *other* than any existing 'AD'-named drive)" ; 
            $tPsD = Get-PSDrive -PSProvider ActiveDirectory|?{$_.name -ne 'AD'} ; 
        }  ; 
        TRY {
            $tPsD | %{
                $retHash = @{
                    Name     = $_.Name ;
                    UserName = $null # can't discover orig mapping uname fr existing psdrive object;
                    Status   = [boolean](test-path -path "$($_.Name):") ; # test actual access
                } ; 
                New-Object PSObject -Property $retHash | write-output ;
            } ; 
        } CATCH {
            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            #BREAK ; #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            $false | write-output ;
        } ;
    } # PROC-E
    END {} ;
}

#*------^ get-ADForestDrives.ps1 ^------
