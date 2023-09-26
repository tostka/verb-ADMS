# Get-ADSIComputerByGuid.ps1

#*------v Function Get-ADSIComputerByGuid v------
Function Get-ADSIComputerByGuid {
    <#
    .SYNOPSIS
    Get-ADSIComputerByGuid.ps1 - Dependency-less function to retrieve an AD computer object using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2023-08-30
    FileName    : Get-ADSIComputerByGuid.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ADSI,ActiveDirectory,Computer
    AddedCredit : Ro Yo Mi
    AddedWebsite:	https://serverfault.com/users/171487/ro-yo-mi
    AddedTwitter:	URL
    AddedCredit : François-Xavier Cat
    AddedWebsite:	https://lazywinadmin.github.io/
    AddedTwitter:	@lazywinadmin / https://twitter.com/lazywinadmin
    REVISIONS
    * 9:06 AM 9/26/2023 working (add to vad);  cleanup comment, updated CBH
    * 4:56 PM 8/30/2023 init
    * 6/19/2023 Ro Yo Mi's posted code sample
    * 10/30/2013 lazywinadmin's original post
    .DESCRIPTION
    Get-ADSIComputerByGuid.ps1 - Dependency-less function to retrieve an AD computer object using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    .PARAMETER  GUID
    Guid for computer object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'
    .PARAMETER LDAPserver
    Domain to be searched[-LDAPserver 'sub.domain.com']
    .EXAMPLE
    PS> get-adsicomputerbyguid -GUID nfbn-nden-nban-nbn-ncnedfn5 -LDAPserver sub.domain.com  ; 

    DNShostName                  Description                                       Name
    -----------                  -----------                                       ----
    AAAAAnnnn.AAAAAA.AA.AAAA.AAA DESCRIPTION                                       AAAAAnnnn
    
    Query specified server using it's ADComputer object's guid
    .LINK
    https://github.com/tostka/verb-ADMS
    .LINK
    https://serverfault.com/questions/310529/search-ad-by-guid
    .LINK
    https://lazywinadmin.com/2013/10/powershell-get-domaincomputer-adsi.html
    #>
    [CmdletBinding()]
    PARAM(
      [Parameter(Position=0,ValueFromPipeline=$true, Mandatory=$true, HelpMessage="Guid for computer object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'")]
          [String[]]$GUID,
      [Parameter(Mandatory=$true, HelpMessage="Domain to be searched[-LDAPserver 'sub.domain.com']")]
      $LDAPserver
    ) ;       
    PROCESS{
        FOREACH ($item in $GUID){
            $GetItem  = "GUID=$($item)" ;
            TRY{$DistinguishedName = $([ADSI]"LDAP://$($LDAPserver)/<$($GetItem)>").DistinguishedName} CATCH {$_ | fl * -Force; continue} ;
            if($DistinguishedName){
                TRY{
                    $Searcher = [ADSISearcher] ([ADSI] "LDAP://$($LDAPserver)") ;
                    $Searcher.Filter = "(&(objectCategory=Computer)(DistinguishedName=$($DistinguishedName)))"
                    FOREACH ($Computer in $($Searcher.FindAll())){
                        New-Object -TypeName PSObject -Property @{
                            "Name" = $($Computer.properties.name)
                            "DNShostName"    = $($Computer.properties.dnshostname)
                            "Description" = $($Computer.properties.description)
                        } | write-output ; 
                    } ; 
                } CATCH {$_ | fl * -Force; continue} 
            } else {throw "$($GetItem) failed to return a matching DistinguishedName" }; 
        } ; 
    } ; 
} ; 
#*------^ END Function Get-ADSIComputerByGuid ^------