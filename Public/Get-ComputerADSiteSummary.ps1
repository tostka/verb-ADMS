# Get-ComputerADSiteSummary.ps1 

#*------v Function Get-ComputerADSiteSummary v------
Function Get-ComputerADSiteSummary {
    <#
    .SYNOPSIS
    Get-ComputerADSiteSummary - Used to get the Active Directory subnet and the site it is assigned to for a remote Windows computer/IP address
    .NOTES
    Version     : 1.1.1
    Author      : gbdixg/GD
    Website     : write-verbose.com
    Twitter     : @writeverbose / http://twitter.com/writeverbose
    CreatedDate : 2024-03-13
    FileName    : Get-ComputerADSiteSummary.ps1
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,Site,Computer
    AddedCredit : Todd Kadrie
    AddedWebsite: http://www.toddomation.com
    AddedTwitter: @tostka / http://twitter.com/tostka
    REVISIONS
    * 12:24 PM 3/13/2024 ren:Find-ADSite -> Get-ComputerADSiteSummary  1.1.1 updated CBH; tagged outputs w explicit w-o 
    * 11/12/23 v1.1 - current posted GitHub Gist version
    .DESCRIPTION
    Get-ComputerADSiteSummary - Used to get the Active Directory subnet and the site it is assigned to for a Windows computer/IP address
     Requires only standard user read access to AD and can determine the ADSite for a local or remote computer

     Shay Levy also demo's a much simplified variant for obtaining remote computer AD SiteName by leveraging the nltest cmdline util:

    function Get-ComputerADSite($ComputerName){
	    $site = nltest /server:$ComputerName /dsgetsite 2>$null ; 
	    if($LASTEXITCODE -eq 0){ $site[0] } ; 
    }

    .PARAMETER  IPAddress
    Specifies the IP Address for the subnet/site lookup in as a .NET System.Net.IPAddress
    When this parameter is used, the computername is not specified.
    .PARAMETER  Computername
    Specifies a computername for the subnet/site lookup.
    The computername is resolved to an IP address before performing the subnet query.
    Defaults to %COMPUTERNAME%
    When this parameter is used, the IPAddress and IP are not specified.
    .PARAMETER  DC
    A specific domain controller in the current users domain for the subnet query
    If not specified, standard DC locator methods are used.
    .PARAMETER  AllMatches
    A switch parameter that causes the subnet query to return all matching subnets in AD
    This is not normally used as the default behaviour (only the most specific match is returned) is usually prefered.
    This switch will include "catch-all" subnets that may be defined to accomodate missing subnets
    .PARAMETER showDebug
    Debugging Flag [-showDebug]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    System.Object summary of IPAddress, Subnet and AD SiteName
    .EXAMPLE
    PS>Get-ComputerADSiteSummary -ComputerName PC123456789

        ComputerName      : PC123456789
        IPAddress         : 162.26.192.151
        ADSubnetName      : 162.26.192.128/25
        ADSubnetDesc      : 3rd Floor Main Road Office
        ADSiteName        : EULON01
        ADSiteDescription : London
    Demo's resolving computername to Site details
    .EXAMPLE
    PS>$SiteSummary = get-computeradsitesummary -IPAddress 192.168.5.15
    Demos resolving IP address to AD Site summary, and assigning return to a variable.
    .LINK
    https://write-verbose.com/2019/04/13/Get-ComputerADSiteSummary/
    .LINK
    https://gist.github.com/gbdixg/5cd6ea0c984278b08b36260ada0e3f9c
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding(DefaultParameterSetName = "byHost")]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, ParameterSetName = "byHost")]
            [string]$ComputerName = $Env:COMPUTERNAME,
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, Mandatory = $True, ParameterSetName = "byIPAddress")]
            [System.Net.IPAddress]$IPAddress,
        [Parameter(Position = 1)]
            [string]$DC,
        [Parameter()]
            [switch]$AllMatches
    )
    PROCESS {
        switch ($pscmdlet.ParameterSetName) {
            "byHost" {
                TRY {
                    $Resolved = [system.net.dns]::GetHostByName($Computername)
                    [System.Net.IPAddress]$IP = ($Resolved.AddressList)[0] -as [System.Net.IPAddress]
                }CATCH{
                    Write-Warning "$ComputerName :: Unable to resolve name to an IP Address"
                    $IP = $Null
                }
            }
            "byIPAddress" {
                TRY {
                    $Resolved = [system.net.dns]::GetHostByAddress($IPAddress)
                    $ComputerName = $Resolved.HostName
                } CATCH {
                    # Write-Warning "$IP :: Could not be resolved to a hostname"
                    $ComputerName = "Unable to resolve"
                }
                $IP = $IPAddress
            }

        }#switch
    
        if($PSBoundParameters.ContainsKey("DC")){
            $DC+="/"
        }

        if ($IP) {
            # The following maths loops over all the possible subnet mask lengths
            # The masks are converted into the number of Bits to allow conversion to CIDR format
            # The script tries to lookup every possible range/subnet bits combination and keeps going until it finds a hit in AD

            [psobject[]]$MatchedSubnets = @()

            For ($bit = 30 ; $bit -ge 1; $bit--) {
                [int]$octet = [math]::Truncate(($bit - 1 ) / 8)
                $net = [byte[]]@()

                for ($o = 0; $o -le 3; $o++) {
                    $ba = $ip.GetAddressBytes()
                    if ($o -lt $Octet) {
                        $Net += $ba[$o]
                    } ELSEIF ($o -eq $octet) {
                        $factor = 8 + $Octet * 8 - $bit
                        $Divider = [math]::pow(2, $factor)
                        $value = $divider * [math]::Truncate($ba[$o] / $divider)
                        $Net += $value
                    } ELSE {
                        $Net += 0
                    }
                } #Next

                #Format network in CIDR notation
                $Network = [string]::join('.', $net) + "/$bit"

                # Try to find this Network in AD Subnets list
                Write-Verbose "Trying : $Network"
                TRY{
                    $de = New-Object System.DirectoryServices.DirectoryEntry("LDAP://" + $DC + "rootDSE")
                    $Root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DC$($de.configurationNamingContext)")
                    $ds = New-Object System.Directoryservices.DirectorySearcher($root)
                    $ds.filter = "(CN=$Network)"
                    $Result = $ds.findone()
                }CATCH{
                    $Result = $null
                }

                if ($Result) {
                    write-verbose "AD Site found for $IP"

                    # Try to split out AD Site from LDAP path
                    $SiteDN = $Result.GetDirectoryEntry().siteObject
                    $SiteDe = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$SiteDN")
                    $ADSite = $SiteDe.Name[0]
                    $ADSiteDescription = $SiteDe.Description[0]

                    $MatchedSubnets += [PSCustomObject][Ordered]@{
                        ComputerName = $ComputerName
                        IPAddress    = $IP.ToString()
                        ADSubnetName = $($Result.properties.name).ToString()
                        ADSubnetDesc = "$($Result.properties.description)"
                        ADSiteName       = $ADSite
                        ADSiteDescription = $ADSiteDescription
                    }
                    $bFound = $true
                }#endif
            }#next

        }#endif
        if ($bFound) {

            if ($AllMatches) {
                # output all the matched subnets
                $MatchedSubnets | write-output ;
            } else {

                # Only output the subnet with the largest mask bits
                [Int32]$MaskBits = 0 # initial value

                Foreach ($MatchedSubnet in $MatchedSubnets) {

                    if ($MatchedSubnet.ADSubnetName -match "\/(?<Bits>\d+)$") {
                        [Int32]$ThisMaskBits = $Matches['Bits']
                        Write-Verbose "ThisMaskBits = '$ThisMaskBits'"

                        if ($ThisMaskBits -gt $MaskBits) {
                            # This is a more specific subnet
                            $OutputSubnet = $MatchedSubnet
                            $MaskBits = $ThisMaskBits

                        } else {
                            Write-Verbose "No match"
                        }
                    } else {
                        Write-Verbose "No match"
                    }
                }
                $OutputSubnet | write-output ;
            }#endif
        } else {

            Write-Verbose "AD Subnet not found for $IP"
            if ($IP -eq $null) {$IP = ""} # required to prevent exception on ToString() below

            New-Object -TypeName PSObject -Property @{
                ComputerName = $ComputerName
                IPAddress    = $IP.ToString()
                ADSubnetName = "Not found"
                ADSubnetDesc = ""
                ADSiteName   = ""
                ADSiteDescription = ""
            } | write-output  ; 
        }#end if
    }#process
}
#*------^ END Function Get-ComputerADSiteSummary ^------