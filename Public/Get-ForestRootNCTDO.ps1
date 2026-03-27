# Get-ForestRootNCTDO.ps1


#region GET_FORESTROOTNCTDO ; #*------v Get-ForestRootNCTDO v------
function Get-ForestRootNCTDO{
        <#
        .SYNOPSIS
        Get-ForestRootNCTDO - Returns local machine's ForestRoot DN (DC=sub,DC=dom,DC=tld)
        .NOTES
        Version     : 0.0.1
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 20250917-0114PM
        FileName    : Get-ForestRootNCTDO.ps1
        License     : (none asserted)
        Copyright   : (none asserted)
        Github      : https://github.com/tostka/verb-io
        Tags        : Powershell,ActiveDirectory,Forest,Domain
        AddedCredit : Michel de Rooij / michel@eightwone.com
        AddedWebsite: http://eightwone.com
        AddedTwitter: URL        
        REVISIONS
        * 8:34 PM 3/26/2026 move vnet -> vad
        * 10:42 AM 10/17/2025 updated CBH to indicate format of the DN returned.
        * 1:14 PM 9/17/2025 port to vnet from xopBuildLibrary; add CBH, and Adv Function specs
        .DESCRIPTION
        Get-ForestRootNCTDO - Returns local machine's ForestRoot DN (DC=sub,DC=dom,DC=tld)
                
        .INPUTS
        None, no piped input.
        .OUTPUTS
        System.String local ForestRoot 
        .EXAMPLE ; 
        PS> $FRNC= Get-ForestRootNCTDO
        PS> $FRNC ; 

            DC=sub,DC=dom,DC=tld

        .LINK
        https://github.org/tostka/verb-Network/
        #>
        [CmdletBinding()]
        [alias('Get-ForestRootNC')]
        PARAM() ;
        return ([ADSI]'LDAP://RootDSE').rootDomainNamingContext.toString()
    }
#endregion GET_FORESTROOTNCTDO ; #*------^ END Get-ForestRootNCTDO ^------

