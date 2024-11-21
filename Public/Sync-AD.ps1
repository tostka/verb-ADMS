# 11:51 AM 5/6/2019 Sync-AD():moved from tsksid-incl-ServerApp.ps1
#*------v Function Sync-AD v------
Function Sync-AD { 
    <#
    .SYNOPSIS
    Triggers a replication between Domain Controllers (DCs).
    .NOTES
    Version: 1.0.0
    Author: [Your Name]
    CreatedDate: [Creation Date]
    FileName: Sync-AD.ps1
    Source: Adapted from dsoldow's script at https://github.com/dsolodow/IndyPoSH/blob/master/Profile.ps1
    .DESCRIPTION
    The `Sync-AD` function allows you to trigger a replication between specified Domain Controllers (DCs). This function can be customized further for reusability. It uses the `repadmin` tool to perform the replication.
    .PARAMETER DestinationDC
    The destination Domain Controller for the replication. Defaults to 'centralDC'.
    .PARAMETER SourceDC
    The source Domain Controller for the replication. Defaults to 'localDC'.
    .PARAMETER DirectoryPartition
    The directory partition to replicate. Defaults to 'YourDomainName'.
    .EXAMPLE
    PS C:\> Sync-AD -DestinationDC 'centralDC' -SourceDC 'localDC' -DirectoryPartition 'YourDomainName'
    This command triggers a replication from 'localDC' to 'centralDC' for the specified directory partition.
    .LINK
    https://github.com/dsolodow/IndyPoSH/blob/master/Profile.ps1
    #>
    [CmdletBinding()]
    Param (
    [parameter(Mandatory = $false,Position=0)] [String]$DestinationDC = 'centralDC',
    [parameter(Mandatory = $false,Position=1)] [String]$SourceDC = 'localDC',
    [parameter(Mandatory = $false,Position=2)] [String]$DirectoryPartition = 'YourDomainName'
    ) ; 
    Get-AdminCred ; 
    Start-Process -Credential $admin -FilePath repadmin -ArgumentList "/replicate $DestinationDC $SourceDC $DirectoryPartition" -WindowStyle Hidden ; 
}#*------^ END Function Sync-AD ^------ ; 
