# test-isADComputerName_func.ps1

Function test-isADComputerName{
    <#
    .SYNOPSIS
    test-isADComputerName.ps1 - Validate that passed string is an ADComputer object name
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-
    FileName    : test-isADComputerName.ps1
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Luc Fullenwarth
    AddedWebsite: https://gravatar.com/fullenw1
    AddedTwitter: twitter.com/LFullenwarth
    REVISIONS
    * 2:03 PM 6/6/2024 rounded out param validation sample to full function
    * 8/5/20 LF posted arti
    .DESCRIPTION
    test-isADComputerName.ps1 - Validate that passed string is an ADComputer object name
    .PARAMETER  ComputerName
    ComputerName string to be validated[-ComputerName SomeBox]
    .INPUTS
    System.String Accepts piped input
    .OUTPUTS
    System.Boolean
    .EXAMPLE
    PS> test-isADComputerName.ps1 -ComputerName $env:computername
    Demo simple test
    .LINK
    https://github.com/tostka/verb-Network
    .LINK
    https://bitbucket.org/tostka/powershell/
    .LINK
    https://itluke.online/2020/08/05/validating-computer-names-with-powershell/
    #>    
    #Requires -Modules ActiveDirectory
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,HelpMessage="ComputerName string to be validated[-ComputerName SomeBox]")]
            [ValidateScript({Get-ADComputer -Identity $PSItem})]
            [ValidateNotNullOrEmpty()]
            [string]$ComputerName
    )
    write-output $true ; 
} ; 

