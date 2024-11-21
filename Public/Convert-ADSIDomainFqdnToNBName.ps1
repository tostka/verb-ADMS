# Convert-ADSIDomainFqdnToNBName.ps1

#*------v Function Convert-ADSIDomainFqdnToNBName v------
function Convert-ADSIDomainFqdnToNBName {
    <#
    .SYNOPSIS
    Convert-ADSIDomainFqdnToNBName.ps1 - Convert the ADDomain FQDN to the matching NetbiosName, using ADSI (no-dependancy on Windows)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-11-13
    FileName    : Convert-ADSIDomainFqdnToNBName.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,ADSite,Computer,ADSI
    AddedCredit : Alan Kaplan
    AddedWebsite: https://akaplan.com/author/admin/
    AddedTwitter: 
    REVISIONS
    * 1:28 PM 11/13/2024 init, expanded, added CBH etc to AK's blog post scriptblock
    * 1/30/17: AK's blog post (link below)
    .DESCRIPTION
    Convert-ADSIDomainFqdnToNBName.ps1 - Convert the ADDomain FQDN to the matching NetbiosName, using ADSI (no-dependancy on Windows)
    
    Expansion & wrap of scriptblock demo from Alan Kaplan's blog post:
    [Get the NetBIOS AD Domain Name from the FQDN – Alan's Blog](https://akaplan.com/2017/01/get-the-netbios-ad-domain-name-from-the-fqdn/)
    
    .PARAMETER Name
    Array of System Names to test (defaults to local machine)[-Name SomeBox]
    .EXAMPLE
    $DomNBName = Convert-ADSIDomainFqdnToNBName  -
    Return Netbiosname for specified AD Domain FQDN
    .EXAMPLE
    $DomNBName = Convert-ADSIDomainFqdnToNBName -Name somebox
    Return remote computer DomNBName name
    .LINK
    https://akaplan.com/2017/01/get-the-netbios-ad-domain-name-from-the-fqdn/
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding()]
    PARAM (
        [parameter(ValueFromPipeline=$true,HelpMessage="Array of System Names to test (defaults to local machine)[-Name SomeBox]")]
        [Alias('Domain')]
        [string[]]$DomainFqdn
    ) ; 
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
        foreach($item in $DomainFqdn){
            
			$objRootDSE = [System.DirectoryServices.DirectoryEntry] "LDAP://rootDSE" ; 
			$ConfigurationNC= $objRootDSE.configurationNamingContext ; 
			$Searcher = New-Object System.DirectoryServices.DirectorySearcher  ; 
			$Searcher.SearchScope = "subtree"  ; 
			$Searcher.PropertiesToLoad.Add("nETBIOSName")| Out-Null ; 
			$Searcher.SearchRoot = "LDAP://cn=Partitions,$ConfigurationNC" ; 
			$searcher.Filter = "(&(objectcategory=Crossref)(dnsRoot=$item)(netBIOSName=*))" ; 
			($Searcher.FindOne()).Properties.Item("nETBIOSName") | write-output ; 
        } ;  # loop-E
    } ;  # PROC-E
    END {
        write-verbose "(Convert-ADSIDomainFqdnToNBName:End)" ; 
    } ; 
} ; 
#*------^ END Function Convert-ADSIDomainFqdnToNBName ^------
