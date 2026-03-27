# test-CredentialsTDO.ps1


#region TEST_CREDENTIALSTDO ; #*------v test-CredentialsTDO v------
function test-CredentialsTDO{
        <#
        .SYNOPSIS
        test-CredentialsTDO - tests provided uid+pw cred combo
        .NOTES
        Version     : 0.0.
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 20250711-0423PM
        FileName    : test-CredentialsTDO.ps1
        License     : (none asserted)
        Copyright   : (none asserted)
        Github      : https://github.com/tostka/verb-io
        Tags        : Powershell,ActiveDirectory,Account,Credential
        AddedCredit : Michel de Rooij / michel@eightwone.com
        AddedWebsite: http://eightwone.com
        AddedTwitter: URL        
        REVISIONS
        * 4:33 PM 10/16/2025 logic fix, self-contained, brought in alt deps; CBH demo1 fix
        * 12:59 PM 9/17/2025 add to vnet; remove write-my*() calls (write-log has native defer support now)
        * 1:44 PM 8/8/2025 ren test-Credentials821 -> test-CredentialsTDO, aliased orig name (I made sufficient changes, may as well keep a copy in verb-io)
        11:59 AM 7/18/2025 lifted copy of sub from install-Ex15, updated to support pw as plaintext or securestring, tweaked pw conv code, orig was failing
        .DESCRIPTION
        test-CredentialsTDO - tests provided uid+pw cred combo
                
        .INPUTS
        None, no piped input.
        .OUTPUTS
        System.Object summary of Exchange server descriptors, and service statuses.
        .EXAMPLE
        PS> $tcred = get-credential ; 
        PS> if(test-CredentialsTDO -UserName $tcred.username -Password $tcred.GetNetworkCredential().Password){
        PS>     write-host -foregroundcolor green "Credential validated" ; 
        PS> } ; 
        .LINK
        https://github.org/tostka/verb-ex2010/
        #>
        [CmdletBinding()]
        [alias('test-Credentials')]
        PARAM(            
            [Parameter(HelpMessage = "Account to be tested")]
                [Alias('Account','logon')]
                [string]$UserName,
            [Parameter(Mandatory=$true,HelpMessage = "Account password to be tested (securestring or plain text)")]
                [Alias('AdminPassword')]
                #[string]
                $Password                       
        ) ;
        switch ($Password.gettype().fullname){
            'System.String' {
                #$PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString $Password) ))
                $PlainTextPassword= $Password ; 
            }
            'System.Security.SecureString'{
                #$PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( $Password ))
                $tmpCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("None",$Password ) ;                
                #$PlainTextPassword = $Password.GetNetworkCredential().Password 
                $PlainTextPassword = $tmpcred.GetNetworkCredential().Password ; 
                remove-variable tmpCred
            }
            default{
                $smsg = "Unrecognized -Password type:$($Password.gettype().fullname)" ; 
                $smsg += "`nSpecify as either plain text or SecureSTring" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                throw $smsg ; 
            }
        }
        #$PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString $Password) ))
        if(get-command FullPlainTextAccount -ea SilentlyContinue){
            $FullPlainTextAccount= get-FullDomainAccountTDO -Account $UserName ;
        }else{
            #write-warning "missing:FullPlainTextAccount(), skipping account format specification" ; 
            switch -regex ($username){
                '(.*)\\(.*)' {
                    $Parts = $UserName.split('\') ; 
                    $FullPlainTextAccount = "$($Parts[0].ToUpper())\$($Parts[1])" ; write-host  "UserName is in Legacy format" ; 
                    break ; 
                } ; 
                '(.*)@(.*)' {
                    write-host  "Username is in UPN format"  ; 
                    $FullPlainTextAccount = $UserName ; 
                    break ; 
                }
                default{
                    if($env:USERDOMAIN){
                        $FullPlainTextAccount = "$($env:USERDOMAIN)\$($UserName)" ; 
                        write-host  "simple string: Assuming Logon, asserting `$env:USERDOMAIN for domain in legacy format" ; 
                    } else{
                        throw "Unrecognized -Username format:$($Username)" ; 
                    };
                    break ;  
                } ; 
            } ; 
        }
        TRY {
            if($env:USERDOMAIN -eq $env:COMPUTERNAME){
                write-host "`$env:USERDOMAIN -eq `$env:COMPUTERNAME: => non-domain-joined, checking Test-LocalCredentialTDO()" ; 
                $Username = $FullPlainTextAccount.split("\")[-1]
                if(get-command Test-LocalCredentialTDO){
                    Return $( Test-LocalCredentialTDO -UserName $Username -Password $PlainTextPassword)
                }else{
                    #throw "Missing:Test-LocalCredentialTDO(), unable to test non-Domain-Joined account" ;  
                    $smsg = "Missing:Test-LocalCredentialTDO(), unable to test non-Domain-Joined account" ;  write-host -foregroundcolor yellow $smsg ; 
                    TRY {Add-Type -AssemblyName System.DirectoryServices.AccountManagement} CATCH {} ; 
                    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',$ComputerName)
                    Return $($DS.ValidateCredentials($UserName, $Password))
                } ; 
            }else{
                $dc= New-Object DirectoryServices.DirectoryEntry( $Null, $FullPlainTextAccount, $PlainTextPassword)
                If($dc.Name) {
                    return $true
                }Else {
                    Return $false
                }
            }
        }CATCH {
            Return $false
        }
        Return $false        
    }
#endregion TEST_CREDENTIALSTDO ; #*------^ END test-CredentialsTDO ^------

