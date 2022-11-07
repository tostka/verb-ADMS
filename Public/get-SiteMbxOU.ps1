#*------v Function get-SiteMbxOU v------
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
    * 10:57 AM 4/3/2020 cleanup to modularize, added verbose sup, updated CBH
    # 2:51 PM 3/6/2017 add -Resource param to steer to 'Email Resources'
    # 12:36 PM 2/27/2017 fixed to cover breaks frm AD reorg OU name changes, Generics are all now in a single OU per site
    # 11:56 AM 3/31/2016 port to get-SiteMbxOU; validated that latest round of updates are still functional; minor cleanup
    * 11:31 AM 3/16/2016 debugged to function.
    * 1:34 PM 3/15/2016 adapted SecGrp OU lookup to MailContact OU
    * 11:05 AM 10/7/2015 initial vers
    .DESCRIPTION
    get-SiteMbxOU() - passed a standard 3-letter site code, it returns the OU dn for that site's Email-related SecGrps (directly below Site ou)
    .PARAMETER  SiteCode
    Toro 3-letter site code
    .PARAMETER  Generic
    Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).
    .PARAMETER  Resource
    Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]
    .EXAMPLE
    $OU=get-SiteMbxOU -Sitecode SITE
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU
    .LINK
    #>
    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$True,HelpMessage="Specify the Toro 3-letter site code upon which to Query[LYN]")]
        [string[]]$Sitecode
        ,[parameter(Mandatory=$false,HelpMessage="Switch parameter indicating Generic Mbx OU (defaults Non-generic/Users OU).[-Generic]")]
        [string[]]$Generic
        ,[parameter(Mandatory=$false,HelpMessage="Switch parameter indicating Resource Mbx OU (defaults Non-generic/Users OU).[-Resource]")]
        [string[]]$Resource
    ) ;  # PARAM-E
    $verbose = ($VerbosePreference -eq "Continue") ; 
    if($Generic){
        $FindOU="^OU=Generic Email Accounts"
    } elseif($Resource){
        $FindOU="^OU=Email Resources"
    } else {
        $FindOU="^OU=Users"
    } ;
    $error.clear() ;
    TRY {
        $OUPath = (Get-ADObject -filter { ObjectClass -eq 'organizationalunit' } | ?{ $_.distinguishedname -match "^$($FindOU).*,OU=$($SiteCode),.*,DC=ad,DC=toro((lab)*),DC=com$" } | ?{($_.distinguishedname -notmatch ".*(Computers|Test),.*")} | select distinguishedname).distinguishedname.tostring() ;
        If($OUPath -isnot [string]){      # post-verification to ensure we've got a single OU spec
            write-error "$( (get-date).ToString("HH:mm:ss") ):WARNING AD OU SEARCH SITE:$($InputSplat.SiteCode), FindOU:$($FindOU), FAILED TO RETURN A SINGLE OU...";
            $OUPath | select distinguishedname ;
            write-error "$((get-date).ToString('HH:mm:ss')):EXITING!";
            Exit ;
        } ;
        write-output $OUPath
    } CATCH {
        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
    } ; 
} #*------^ END Function get-SiteMbxOU ^------
