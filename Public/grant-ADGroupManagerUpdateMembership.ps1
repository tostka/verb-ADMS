#*------v Function grant-ADGroupManagerUpdateMembership v------
function grant-ADGroupManagerUpdateMembership {
    <#
    .SYNOPSIS
    grant-ADGroupManagerUpdateMembership - For a specified ADGroup, add '[x]Manager can update membership list' (visible in ADUC on the gorup's Managed-By tab)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-29
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ActiveDirectory,Permissions,Groups
    REVISIONS
    * 2:08 PM 11/30/2021 validated functional ; pulled verb-adms req, added alt to use get-addomaincontroller if verb-adms:get-gcfast() isn't avail
    * 3:18 PM 11/29/2021 initial vers
    .DESCRIPTION
    grant-ADGroupManagerUpdateMembership - For a specified ADGroup, add '[x]Manager can update membership list' (visible in ADUC on the gorup's Managed-By tab)
    This function is an alternative *ADMS*-native powershell approach, to the standard Exchange Mgmt Shell option:    
    #-=-=-=-=-=-=-=-=
    $grp=Get-DistributionGroup -id $group -domainc $dc;
    $pltAADP=[ordered]@{ User=$Manager ; AccessRights='WriteProperty' ; Properties='Member' ; domaincontroller=$dc ; ErrorAction = 'STOP' ; whatif=$($whatif) ; } ;
    $grp | Add-ADPermission @pltAADP ;
    $ADPerms = $grp | Get-ADPermission -domainc $dc | ? {($_.Properties -match 'Member') -AND ($_.AccessRights -eq 'WriteProperty') -AND ($_.User -notlike 'AD\Exchange*')} ; 
    #-=-=-=-=-=-=-=-=
    (which throsw cryptic Access Denied errors, in my enviro, and I don't have time to chase undocumented low level AD perm errors). 
    For me, the ADMS approach works either way. I'm moving ahead on the subject. 
    .PARAMETER  User
    Samaccountname/GUID/DN for user to be granted ManagedBy and 'Manager can update membership list'
    .PARAMETER  group
    AD identifyer (name,DN,guid) for ADGroup/DistribGroup to be configured with the updated permission
    .PARAMETER .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif]
    .EXAMPLE
    grant-ADGroupManagerUpdateMembership -user 'someuser' -group 'group X' -verbose ;
    Configure the permissions for 'someuser' on the 'group X' group, with verbose output
    .LINK
    #>
    #Requires -Modules ActiveDirectory
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("(lyn|bcc|spb|adl)ms6(4|5)(0|1).(china|global)\.ad\.toro\.com")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    ## [OutputType('bool')] # optional specified output type

    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$True,HelpMessage="Samaccountname/GUID/DN for user to be granted ManagedBy and 'Manager can update membership list'")]
        ##[Alias('XXX')]
        [string]$User,
        [parameter(Mandatory=$True,HelpMessage="AD identifyer (name,DN,guid) for ADGroup/DistribGroup to be configured with the updated permission")]
        [string]$group,
        [Parameter(HelpMessage="Switch to return the ACL object to the pipeline (rather than `$true/`$false)[-ReturnObject]")]
        [switch] $ReturnObject,
        [Parameter(HelpMessage="Whatif switch [-whatIf]")]
        [switch] $whatIf
    ) ;  
    
    $verbose = ($VerbosePreference -eq "Continue") ;
    # constants
    $propsACL = 'ActiveDirectoryRights','InheritanceType','ObjectType','AccessControlType','IdentityReference','IsInherited' ; 
    $SelfMembershipGuid = [guid]'bf9679c0-0de6-11d0-a285-00aa003049e2' ;
    $rights = [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty -bOR [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight ;
    $ACLType = [System.Security.AccessControl.AccessControlType]::Allow  ;
    
    $error.clear() ;
    TRY {
        if(get-command get-gcfast){
            # use my verb-adms mod function if avail (validates speed)
            $dc = get-gcfast -Verbose:$($VerbosePreference -eq "Continue") ;         
        } else { 
            # use default adms option
            #$dc = (GET-ADDomaincontroller -discover).hostname
            $dc = (Get-ADDomainController -Filter  {isGlobalCatalog -eq $true -AND Site -eq "$((get-adreplicationsite).name)"}).hostname| Get-Random ; 
        } ; 
        $pltGADU=[ordered]@{
            identity = $user ;
            server=$dc; ErrorAction='STOP'; 
            #whatif=$($whatif);
        } ; 
        $smsg = "Get-ADUser w`n$(($pltGADU|out-string).trim())" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        $grantee = Get-ADUser @pltGADU ;
        
        $granteeSID = [System.Security.Principal.SecurityIdentifier]$grantee.sid ; 
        
        $domNBName = (Get-ADDomain (($grantee.distinguishedName.Split(',') |?{$_ -like 'DC=*'}) -join ',')).NetBIOSName ; 
        
        $pltGADG=[ordered]@{
            identity = $group ;
            properties = '*' ; 
            server=$dc; ErrorAction='STOP'; 
            #whatif=$($whatif);
        } ; 
        $smsg = "Get-ADGroup w`n$(($pltGADG|out-string).trim())" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        $tgroup = Get-ADGroup @pltGADG ;
        
        if ($tgroup.Managedby -AND ( ($tgroup.Managedby| get-recipient -ea 'STOP').distinguishedname -eq $grantee.distinguishedname )){
            $smsg = "$($grantee) is currrent ManagedBy of target DG`n$($tgroup.managedby)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } else { 
            $smsg = "NOTE!: $($grantee) is *not* currrent ManagedBy of target DG!`n$($tgroup.managedby)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            
            $pltSADG=[ordered]@{
                identity = $tgroup.DistinguishedName ;
                Replace=@{managedBy=$grantee.DistinguishedName} ;
                server=$dc; ErrorAction='STOP';
                whatif=$($whatif);
            } ;
 
            $smsg = "$((get-date).ToString('HH:mm:ss')):Make User ManagedBy of Group:" ; 
            $smsg += "`nSet-ADGroup w`n$(($pltSADG|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            Set-ADGroup @pltSADG ; 
            $smsg = "Get-ADGroup w`n$(($pltGADG|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $tgroup = Get-ADGroup @pltGADG ;
            $smsg = "POST Group: `n$(($tgroup|ft -a name,managedby | out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;
        
        $ACLrule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($granteeSID, $rights, $ACLType, $SelfMembershipGuid) ;
        
        if(test-path -path 'AD:'){
            $aclPath = "AD:\$($tgroup.distinguishedName)" ; 
            $acl = Get-Acl $aclPath ;

            if($grantACL = ($acl).Access |?{$_.objecttype -eq $SelfMembershipGuid -AND $_.InheritanceType -eq 'None' -AND $_.IdentityReference -eq "$($domNBName)\$($grantee.SamAccountName)"}){ 
                $smsg = "Found EXISTING matching ACL for user and perms:`n$(($grantACL | fl $propsACL|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            } else { 
                $acl.AddAccessRule($ACLrule)  ;
                $pltSACL=[ordered]@{
                    acl=$acl ;
                    path=$aclPath ;  
                    ErrorAction='STOP'; whatif=$($whatif);
                } ;
                $smsg = "Set-Acl w`n$(($pltSACL|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            
                Set-Acl @pltSACL ; 
                if(-not $whatif){
                $acl = Get-Acl $aclPath ;
                if($grantACL = ($acl).Access |?{$_.objecttype -eq $SelfMembershipGuid -AND $_.InheritanceType -eq 'None' -AND $_.IdentityReference -eq "$($domNBName)\$($grantee.SamAccountName)"}){ 
                    $smsg = "Updated matching ACL w`n$(($grantACL | fl $propsACL|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } else { 
                    $smsg = "Unable to locate Updated matching ACL w`n" ; 
                    $smsg += "`n| ?{$_.objecttype -eq $SelfMembershipGuid -AND $_.InheritanceType -eq 'None' -AND $_.IdentityReference -eq '$($domNBName)\$($grantee.SamAccountName)'} ; "
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ; 
                } else { 
                    $smsg = "(-whatif: skipping verifications)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } ; 
        } else { 
            $smsg = "Missing 'AD:' PsDrive!" 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            throw $smsg ;
        } ; 

        if($ReturnObject){
            $smsg = "(-ReturnObject specified: returning applied ACL object to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $grantACL | write-output ; 
        } else { 
            $smsg = "(returning `$true to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $true | write-output ; 
        } ; 

    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #-=-record a STATUSWARN=-=-=-=-=-=-=
        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
        #-=-=-=-=-=-=-=-=
        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $false | write-output ; 
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ; 
}  ; 
#*------^ END Function grant-ADGroupManagerUpdateMembership ^------
