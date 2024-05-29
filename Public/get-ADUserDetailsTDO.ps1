#*------v Function get-ADUserDetailsTDO v------
#if(-not (get-command get-ADUserDetailsTDO -ea 0)){
    Function get-ADUserDetailsTDO {
        <#
        .SYNOPSIS
        get-ADUserDetailsTDO - Uses ADSI LDAP to retrieve AD User information  (wo need for full ActiveDirectory powershell module)
        .NOTES
        Version     : 2.0.5
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 2015-09-03
        FileName    : get-ADUserDetailsTDO.ps1
        License     : (none-asserted)
        Copyright   : (none-asserted)
        Github      : https://github.com/tostka/verb-adms
        Tags        : Powershell, ActiveDirectory, User, Accounts, Security.Principal. SecurityIdentifier
        AddedCredit : Ed Wilson
        AddedWebsite: https://devblogs.microsoft.com/scripting/use-powershell-to-translate-a-users-sid-to-an-active-directory-account-name/
        AddedTwitter: URL
        REVISIONS
        * 2:42 PM 5/29/2024 pulled -samaccountname default to $env:username, and shifted it to an example (keep from resolving, when -SID is specified); added explicit w-o's (rplc'd shell closing Exits); extended CBH); removed extraneous output formatting new-underling()
            ren'd UserToSid-SidToUser.ps1 -> get-ADUserDetailsTDO; ren'd Get-UserToSid() -> _resolve-ADSamAccountNameToSID, Get-SidToUser() -> _resolve-ADSidToSamAccountName()
        #10/12/2010 - posted version
        .DESCRIPTION
        get-ADUserDetailsTDO - Uses ADSI LDAP to retrieve AD User information  (wo need for full ActiveDirectory powershell module)

        Extension of samples from on old ScriptingGuy post from 2010.
        I've extended the basic SamAccountName <-> SID queries demo'd to include ADUser equiv lookup & return, and UPN & SamAccName return. 

        .PARAMETER Domain
        AD Domain hosting the target user [-Domain MyDom]
        .PARAMETER SamAccountName
        AD SamAccountName for the target user [-SamAccountName LnameFI]
        .PARAMETER SID
        AD Account SID value for target user [-SID S-n-n-nn-nnnnnnnnnn-nnnnnnnnn-nnnnnnnnnn-nnnnn]
        .PARAMETER returnADUser
        Switch to return the resolved user's ADUser properties [-returnADUser]
        .PARAMETER returnUPN
        Switch to return the resolved user's UserPrincipalName [-returnUPN]
        .PARAMETER returnSamAccountName
        Switch to return the resolved user's SamAccountName [-returnSamAccountName]
        .INPUTS
        [string]
        .OUTPUTS
        [string] UPN or SamAccountname
        [pscustomobject] AD User properties         
        .EXAMPLE
        PS> $ADUser = get-ADUserDetailsTDO  -samaccountname “mytestuser”
        Resolves the user samaccountname to the matching AD User details
        .EXAMPLE
        PS> $ADUser = get-ADUserDetailsTDO  -samaccountname $env:USERNAME
        Resolves the username environment variable as samaccountname to the matching AD User details
        .EXAMPLE
        PS> $ADUser = get-ADUserDetailsTDO  -sid “S-1-5-21-1877799863-120120469-1066862428-500”
        Resolves the user SID to the matching AD User details
        .EXAMPLE
        PS> $UPN = get-ADUserDetailsTDO  -samaccountname “mytestuser” -returnUPN
        Resolves the user samaccountname to the matching AD User UserPrincipalName, assigns return to a variable
        .EXAMPLE
        PS> $SamaccountName = get-ADUserDetailsTDO  -samaccountname “mytestuser” -returnSamAccountName
        Resolves the user samaccountname to the matching AD User returnSamAccountName, assigns return to a variable
        .LINK
        https://devblogs.microsoft.com/scripting/use-powershell-to-translate-a-users-sid-to-an-active-directory-account-name/
        .LINK
        https://github.com/tostka/verb-ADMS
        #>
        [CmdletBinding()]
        #[Alias('Get-ExchangeServerInSite')]
        PARAM(
            [Parameter(HelpMessage="AD Domain hosting the target user [-Domain MyDom]")]
                [string]$domain = $env:USERDOMAIN, 
            [Parameter(Position=0,ValueFromPipeline=$true,HelpMessage="AD SamAccountName for the target user [-samaccountname LnameFI]")]
                [Alias('user')]
                [string]$SamAccountName, 
            [Parameter(HelpMessage="AD Account SID value for target user [-SID S-n-n-nn-nnnnnnnnnn-nnnnnnnnn-nnnnnnnnnn-nnnnn]")]
                [string]$sid,
            [Parameter(HelpMessage="Switch to return the resolved user's ADUser properties [-returnADUser]")]
                [switch]$returnADUser,
            [Parameter(HelpMessage="Switch to return the resolved user's UserPrincipalName [-returnUPN]")]
                [switch]$returnUPN,
            [Parameter(HelpMessage="Switch to return the resolved user's SamAccountName [-returnSamAccountName]")]
                [switch]$returnSamAccountName
        ) ; 
        BEGIN{
            ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
            $Verbose = ($VerbosePreference -eq 'Continue') ;
            $rPSBoundParameters = $PSBoundParameters ; 
            $PSParameters = New-Object -TypeName PSObject -Property $rPSBoundParameters ;
            write-verbose "`$rPSBoundParameters:`n$(($rPSBoundParameters|out-string).trim())" ;
            #region BANNER ; #*------v BANNER v------
            $sBnr="#*======v $(${CmdletName}): $($SamAccountName,$sid) v======" ;
            $smsg = $sBnr ;
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
            #endregion BANNER ; #*------^ END BANNER ^------
        } ;  # BEG-E
        PROCESS{
            TRY{
                if(-not $SID -and $SamAccountName){
                    $smsg = "Translate SamAccountname $($SamAccountname) to SID" ; 
                    write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"
                    $ntAccount = new-object System.Security.Principal.NTAccount($domain, $SamAccountName) ; 
                    $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier]) ; 
                } ; 
                write-host "Resolve SID to ADUser information (slow [adsi]LDAP:// query...)";
                $account = [adsi]"LDAP://<SID=$($sid)>" ;
                if( $returnUPN){
                    $account.Properties["UserPrincipalName"] | Write-Output
                }elseif($returnSamAccountName){
                    $account.Properties["SamAccountName"] | Write-Output
                }elseif($returnADUser -OR -not ($returnUPN -OR $returnSamAccountName)){
                    $adout = $($account | select-object *) ; 
                    <# empty object/no-matches return: Test .guid populated 
                    AuthenticationType :
                    Children           :
                    Guid               :
                    ObjectSecurity     :
                    Name               :
                    NativeGuid         :
                    NativeObject       :
                    Parent             :
                    Password           :
                    Path               :
                    Properties         :
                    SchemaClassName    :
                    SchemaEntry        :
                    UsePropertyCache   :
                    Username           :
                    Options            :
                    Site               :
                    Container          : 
                    #>
                    if($null -eq $adout.Guid ){
                        
                        $smsg = "No matching AD Object returned for:`n$(($PSParameters|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } else {
                        $smsg = "return resolved ADUser properties to pipeline" ; 
                        write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                        $adout | write-output ;                     
                    } ; 
                };
            } CATCH [System.Management.Automation.MethodInvocationException]{
                $ErrTrapd=$Error[0] ;
                switch -Regex ($ErrTrapd.exception){
                    'Some\sor\sall\sidentity\sreferences\scould\snot\sbe\stranslated\.'{
                        $smsg = "Unable to resolve -SamAccountName '$($SamAccountName)' to an SID" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        break ; 
                    } 
                    default {
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    }
                } ; 
            } CATCH {
                #$ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #
                <# full trap
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $smsg = $ErrTrapd.Exception.Message ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                #-=-=-=-=-=-=-=-=
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                #>
            } ; 
            
        } ;  # PROC-E
        END{
            $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; 
    } ; 
#} ;
#*------^ END Function get-ADUserDetailsTDO ^------