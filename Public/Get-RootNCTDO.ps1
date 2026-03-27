# Get-RootNCTDO.ps1


#region GET_ROOTNCTDO ; #*------v Get-RootNCTDO v------
function Get-RootNCTDO{
        <#
        .SYNOPSIS
        Get-RootNCTDO - Returns local machine's Root Naming Context DN (DC=sub,DC=sub,DC=domain,DC=tld)
        .NOTES
        Version     : 0.0.1
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 20250917-0114PM
        FileName    : Get-RootNCTDO.ps1
        License     : (none asserted)
        Copyright   : (none asserted)
        Github      : https://github.com/tostka/verb-io
        Tags        : Powershell,ActiveDirectory,Forest,Domain
        AddedCredit : Michel de Rooij / michel@eightwone.com
        AddedWebsite: http://eightwone.com
        AddedTwitter: URL        
        REVISIONS
        * 8:31 PM 3/26/2026 move from vnet to vad
        * 11:50 AM 10/17/2025 updated CBH, incl output DN example
        * 1:14 PM 9/17/2025 port to vnet from xopBuildLibrary; add CBH, and Adv Function specs
        .DESCRIPTION
        Get-RootNCTDO - Returns local machine's Root Naming Context DN (DC=sub,DC=sub,DC=domain,DC=tld)
                
        .INPUTS
        None, no piped input.
        .OUTPUTS
        System.String local ForestRoot 
        .EXAMPLE ; 
        PS> $NC= Get-RootNC
        PS> $NC; 

            DC=sub,DC=sub,DC=domain,DC=tld

        .LINK
        https://github.org/tostka/verb-Network/
        #>
        [CmdletBinding()]
        [alias('Get-RootNC')]
        PARAM() ;
        return ([ADSI]'').distinguishedName.toString()
    }
#endregion GET_ROOTNCTDO ; #*------^ END Get-RootNCTDO ^------

