#*------v Function get-ADRootSiteOUs v------
function get-ADRootSiteOUs {
    <#
    .SYNOPSIS
    get-ADRootSiteOUs() - Retrieves the Name ('SiteCode') & DistinguishedName for all first-level Site OUs (filters on ^OU=(\w{3}|PACRIM))
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-10
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 8:24 AM 4/10/2020 init
    .DESCRIPTION
    get-ADRootSiteOUs() - Retrieves the 'Office' Site OUs (filters on ^OU=(\w{3}|PACRIM))
    .OUTPUT
    Returns an object containing the Name and DN of all matching OUs
    .EXAMPLE
    $RootOUs=get-ADRootSiteOUs 
    Retrieve the Name & DN for all OUs
    .LINK
    #>
    [CmdletBinding()]
    PARAM (
        
    ) ;  # PARAM-E
    $verbose = ($VerbosePreference -eq "Continue") ; 
    $error.clear() ;
    $rgxRootSiteOUs='^OU=(\w{3}|PACRIM),DC=global,DC=ad,DC=toro,DC=com' ; 
    TRY {
        $OUs= Get-ADOrganizationalUnit -server global.ad.toro.com  -LDAPFilter '(DistinguishedName=*)' -SearchBase 'DC=global,DC=ad,DC=toro,DC=com' -SearchScope OneLevel |?{$_.DistinguishedName -match $rgxRootSiteOUs} | select Name,DistinguishedName ;
        write-output $OUs
    } CATCH {
        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Continue #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
    } ; 
} #*------^ END Function get-ADRootSiteOUs ^------
