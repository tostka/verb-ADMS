#*------v Function Validate-Password v------
Function Validate-Password{
    <#
    .SYNOPSIS
    Validate-Password - Validate Password complexity, to Base AD Complexity standards
    .NOTES
    Version     : 1.0.2
    Author      : Shay Levy & commondollars
    Website     :	http://scriptolog.blogspot.com/2008/01/validating-password-strength.html
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-03
    FileName    : Function Validate-Password.ps1
    License     : (none specified)
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 2:02 PM 8/2/2023 w revised req's: reset minLen to 14; added param & test for testComplexity (defaults false)
    * 11:43 AM 4/6/2016 hybrid of Shay Levy's 2008 post, and CommonDollars's 2013 code
    .DESCRIPTION
    Validate-Password - Validate Password complexity, to Base AD Complexity standards
    Win2008's 2008's stnd: Passwords must contain characters from 3 of the following 4 cats:
    * English uppercase characters (A through Z).
    * English lowercase characters (a through z).
    * Base 10 digits (0 through 9).
    * Non-alphabetic characters (for example, !, $, #, %).
    (also samaccountname must not appear within the pw, and displayname split on spaces, commas, semi's etc cannot appear as substring of pw - neither tested with this code)
    .PARAMETER  pwd
    Password to be tested
    .PARAMETER  minLength
    Minimum permissible Password Length
    .PARAMETER TestComplexity
    Switch to test Get-ADDefaultDomainPasswordPolicy ComplexityEnabled specs (Defaults false: requires a mix of Uppercase, Lowercase, Digits and Nonalphanumeric characters)[-TestComplexity]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Outputs $true/$false to pipeline
    .EXAMPLE
    [Reflection.Assembly]::LoadWithPartialName("System.Web")|out-null ;
    Do { $password = $([System.Web.Security.Membership]::GeneratePassword(8,2)) } Until (Validate-Password -pwd $password ) ;
    Pull and validate passwords in a Loop until an AD Complexity-compliant password is returned.
    .EXAMPLE
    if (Validate-Password -pwd "password" -minLength 10
    Above validates pw: Contains at least 10 characters, 2 upper case characters (default), 2 lower case characters (default), 3 numbers, and at least 3 special characters
    .LINK
    http://scriptolog.blogspot.com/2008/01/validating-password-strength.html
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,HelpMessage="Password to be tested[-Pwd 'string']")]
        [ValidateNotNullOrEmpty()]
        [string]$pwd,
        [Parameter(HelpMessage="Minimum permissible Password Length (defaults to 14)[-minLen 10]")]
        [int]$minLen=14,
        [Parameter(HelpMessage="Switch to test Get-ADDefaultDomainPasswordPolicy ComplexityEnabled specs (Defaults false: requires a mix of Uppercase, Lowercase, Digits and Nonalphanumeric characters)[-TestComplexity]")]
        [switch]$TestComplexity=$false
    ) ;
    $IsGood=0 ;
    if($pwd.length -lt $minLen) {write-output $false; return} ;
    if($TestComplexity){
        if(([regex]"[A-Z]").Matches($pwd).Count) {$isGood++ ;} ;
        if(([regex]"[a-z]").Matches($pwd).Count) {$isGood++ ;} ;
        if(([regex]"[0-9]").Matches($pwd).Count) {$isGood++ ;} ;
        if(([regex]"[^a-zA-Z0-9]" ).Matches($pwd).Count) {$isGood++ ;} ;
        If ($isGood -ge 3){ write-output $true ;  } else { write-output $false} ;
    } else { 
        write-verbose "complexity test skipped" ; 
        write-output $true ;
    } ; 
}#*------^ END Function Validate-Password ^------
