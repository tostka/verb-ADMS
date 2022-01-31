# test-AADUserSync.ps1

#*------v Function test-AADUserSync v------
function test-AADUserSync {
    <#
    .SYNOPSIS
    test-AADUserSync - Check AD->AzureAD user sync status 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 3:37 PM 1/28/2022 fixed error, due to un-instantiated $rpt (needed to be an explicit array, forgot to declare at top). 
    * 3:00 PM 1/26/2022 init
    .DESCRIPTION
    test-AADUserSync - Check AD->AzureAD user sync status 

    -outputObject param returns a summary psobject to the pipeline:
    MSOLimmutableid : UC7OxxxxxxxxxxxxxxxR6g==
    MSOLguid        : 8cce2xxxxxxxxxxxxxxxxxxxxxxxxad391ea
    ADimmutableId   : UC7OxxxxxxxxxxxxxxxR6g==
    ADguid          : 8cce2xxxxxxxxxxxxxxxxxxxxxxxxad391ea
    isAADUserSynced    : True

    otherwise a boolean is returned, corresponding to the isAADUserSynced value

    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER showDebug
    Debugging Flag [-showDebug]
    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER outputObject
    Object output switch [-outputObject]
    .EXAMPLE
    PS> test-AADUserSync -UserPrincipalName UPN@DOMAIN.COM ; 
    Lookup AzureAD Licensing on UPN
    .EXAMPLE
    PS> $results = test-AADUserSync -UserPrincipalName UPN@DOMAIN.COM -outputObject ; 
        if($results.AADUserSynced){ 
            write-host -foregroundcolor green "ADUser:$($UPN) is AAD synced" 
        } else {
            write-warning "ADUser:$($UPN) is *NOT* AAD synced" 
        } ; 
    Example returning an object and testing post-status on object
    .EXAMPLE
    PS> if(test-AADUserSync -UserPrincipalName (get-exomailbox USER@DOMAIN.COM).userprincipalname{ 
        write-host -foregroundcolor green "ADUser:$($UPN) is AAD synced" 
        } else {
            write-warning "ADUser:$($UPN) is *NOT* AAD synced" 
        } ; 
    Lookup AzureAD Licensing on UPN, leveraging EXO mbx lookup to resolve, and test returned boolean
    .EXAMPLE
    PS> test-AADUserSync -UserPrincipalName USER@DOMAIN.COM 
    Single user test
    .EXAMPLE
    PS> $mdtable = @"
|Users|User_Name|Failed_assignements|Top_reasons_for_failure|
|---|---|---|---|
|FName LName|UPN@DOMAIN.com|1/1| Non-unique proxy address in Exchange Online|
|FName LName|email@DOMAIN.com|1/1| Non-unique proxy address in Exchange Online|
"@ ; 
    $users = $mdtable | convertfrom-markdowntable  ; 
    $results = test-AADUserSync -UserPrincipalName $users.user_name -outputObject -verbose ;
    $results | %{write-host "`n===" ; $_ } ; 
    Markdown table fed array test, with delimited output 
    .LINK
    https://github.com/tostka/verb-AAD
    #>
    #Requires -Version 3
    #Requires -Modules MSOnline, verb-AAD, ActiveDirectory, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Network, verb-Text
    #Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    ## [OutputType('bool')] # optional specified output type


    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="UserPrincipalName [-UserPrincipalName xxx@toro.com]")][Alias('UPN')]
        $UserPrincipalName,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Object output switch [-outputObject]")]
        [switch] $outputObject
    ) # PARAM BLOCK END

    BEGIN { 
        $rgxEmployeeNumberProper = '^([0-9]{3,8})$' # 3-8 digit integer
        $rgxEmployeeNumberSamAcct = '^([A-Za-z0-9]{6,7})$' # 6-7 digit alphanum, likely is a samacctname in Employeenumber
        $rgxEmployeeNumberSamAcctSpaces = '^[\sA-Za-z0-9]{6,7}$' # 6-7 digit alphanum w spaces -> likely is a samacctname in Employeenumber w leading/trailing \s (trim it)
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } else {
            #$smsg = "Data received from parameter input: '$($InputObject)'" ; 
            $smsg = "(non-pipeline - param - input)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ; 
        # call func with $PSBoundParameters and an extra (includes Verbose)
        #call-somefunc @PSBoundParameters -anotherParam
    
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array - 
        #   param, iterated as $array=[pipe element n] through the entire inbound stack. 
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).
    
        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per 
        #   Process{} iteration (as process only brings in a single element of the pipe per pass) 
        
        [array]$Rpt = @() ; 
        $1stConn = $true ; 
        foreach($UPN in $UserPrincipalName) {
            # dosomething w $item
        
            # put your real processing in here, and assume everything that needs to happen per loop pass is within this section.
            # that way every pipeline or named variable param item passed will be processed through. 

            # if these are driven by ADConnect fails, it's almost guaranteed that the referred UPN exists in o365. But it may not onprem.

            if(gcm -name connect-msol){
                $sBnr="#*======v UPN: $($UPN): v======" ;
                write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):`n$($sBnr)" ;
                $hReports = [ordered]@{} ; 
                $Error.Clear() ; 
                Try {
                    if($showDebug){write-host  "$((get-date).ToString("HH:mm:ss")):connect-msol"; } ;
                    if($1stConn) { connect-msol ; $1stConn = $false }
                    else {connect-msol -silent} ; 
                    $pltgmu=[ordered]@{UserPrincipalName=$UPN  ;ErrorAction= 'STOP' } ;
                    $smsg = "get-msoluser w`n$(($pltgmu|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $msolu = $null ; 
                    $msolu = get-msoluser @pltgmu ; 
                    #$MSOLimmutableid=$null ; 
                    #$MSOLimmutableid=$msolu.ImmutableId ;
                    $MSOLguid=New-Object -TypeName guid (,[System.Convert]::FromBase64String($msolu.ImmutableId)) ;
                    $smsg = "(adding `$hReports.MSOLimmutableid, `$hReports.MSOLguid, and `$hReports.MSOLDname)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('MSOLimmutableid',$msolu.ImmutableId) ; 
                    $hReports.add('MSOLguid',$MSOLguid) ; 
                    $hReports.add('MSOLDname',$msolu.displayname) ; 

                } Catch {
                    Write-warning "Failed to exec cmd because: $($Error[0])" ;
                    Break ; 
                }  ;
        
                #$Error.Clear() ; 
                #Try {
                    $ADguid=$null ; 
                    # AD abberant -filter syntax: Get-ADUser -Filter 'sAMAccountName -eq $SamAc'
                    $filter = "userprincipalname -eq '$($UPN)'" ;
                    $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                    $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $ADUser = $null ; 
                    Try {
                        $ADUser = get-aduser @pltGADU ; 
                        # if it won't trigger test & throw 
                        if($AdUser){
                            $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        } else { 
                            $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            #throw $smsg  ; 
                            # try to throw a stock ad not-found error (emulate it)
                            throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] "$($smsg)"
                        } ; 
                    # doesn't work natively -filter doesn't generate a catchable error, even with -ea STOP, this block never triggers
                    } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        # Do stuff if not found
                        $smsg = "No GET-ADUSER match found for -filter:$($filter)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;      
                        # triage the UPN provided, trim to pre-strip leading/trailing \s's
                        $potEmployeeNumber,$UPNDomain = $UPN.split('@').trim() ;   
                        switch -Regex ($potEmployeeNumber){
                            $rgxEmployeeNumberProper {
                                # '^([0-9]{3,8})$' # 3-8 digit integer# 3-8 digit integer
                                $filter = "employeenumber -eq '$($potEmployeeNumber)'" ;
                                $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                #$pltGADU=[ordered]@{filter= "'employeenumber -eq $($potEmployeeNumber)'" ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ADUser = $null ; 
                                Try {
                                    $ADUser = get-aduser @pltGADU ; 
                                    # if it won't trigger test & throw 
                                    if($AdUser){
                                        $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    } else { 
                                        $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                        throw $smsg  ; 
                                    } ; 
                                } Catch {
                                   $smsg = "$(pltGADU.filter) *not* found";
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    throw $smsg 
                                    continue ; 
                                };
                            }
                            $rgxEmployeeNumberSamAcct {
                                # '^([A-Za-z0-9]{7,6})$' # 6-7 digit alphanum, likely is a samacctname in Employeenumber
                                $filter = "samaccountname -eq '$($potEmployeeNumber)'" ;
                                $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                #$pltGADU=[ordered]@{filter= "'samaccountname -eq $($potEmployeeNumber)'" ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ADUser = $null ; 
                                Try {
                                    $ADUser = get-aduser @pltGADU ; 
                                    # if it won't trigger test & throw 
                                    if($AdUser){
                                        $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    } else { 
                                        $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                        throw $smsg  ; 
                                    } ; 
                                } Catch {
                                   $smsg = "$(pltGADU.filter) *not* found";
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    throw $smsg 
                                    continue ; 
                                };
                            }
                            $rgxEmployeeNumberSamAcctSpaces {
                                # '^[\sA-Za-z0-9]{7,6}$' # 6-7 digit alphanum w spaces -> likely is a samacctname in Employeenumber w leading/trailing \s (trim it)
                                # shouldn't get here (stip ☝🏻 ) but leave it defined.
                                $potEmployeeNumber = $potEmployeeNumber.trim() ; # retrim, see if it will clear
                                $filter = "samaccountname -eq '$($potEmployeeNumber)'" ;
                                $pltGADU=[ordered]@{filter= $filter ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                #$pltGADU=[ordered]@{filter= "'samaccountname -eq $($potEmployeeNumber)'" ;Properties = 'DisplayName' ; ErrorAction= 'STOP' } ; 
                                $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ADUser = $null ; 
                                Try {
                                    $ADUser = get-aduser @pltGADU ; 
                                    # if it won't trigger test & throw 
                                    if($AdUser){
                                        $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    } else { 
                                        $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                        throw $smsg  ; 
                                    } ; 
                                }  Catch {
                                   $smsg = "$(pltGADU.filter) *not* found";
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    throw $smsg 
                                    continue ; 
                                };

                            } 
                            default {
                                $smsg = "Unrecognized EmployeeNumber scheme!" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                throw $smsg 
                                continue; 
                            } 
                        } ; # Switch-E
                        
                    #} ;                       
                    <#} Catch {
                        $smsg = "Failed to exec cmd because: $($Error[0])" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Break ; 
                    }  ;
                    #>
                    # reworking extended vers of above
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
                        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                    } ; 
                    #

                    $ADguid=[guid]$ADUser.objectguid ;
                    $ADimmutableId = [System.Convert]::ToBase64String($ADguid.ToByteArray()) ;
                    $smsg = "(adding `$hReports.ADimmutableId, `$hReports.ADguid, and `$hReports.ADDname)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('ADimmutableId',$ADimmutableId) ; 
                    $hReports.add('ADguid',$ADguid) ; 
                    $hReports.add('ADDname',$ADUser.displayname) ; 
                <#} Catch {
                    $smsg = "Failed to exec cmd because: $($Error[0])" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    Break ; 
                }  ;
                #>
        
                if(($msolu.ImmutableId -eq $ADimmutableId) -AND ($ADguid.guid -eq $MSOLguid.guid)){
                    #write-host -foregroundcolor green "`n$((get-date).ToString('HH:mm:ss')):`n===$($tUPN) AD->AAD sync is INTACT:`n`n`$msolu.ImmutableId:`t$($msolu.ImmutableId) `nMATCHES converted `n`$ADimmutableId:`t`t$($ADimmutableId)`n`nAND `$ADguid.guid:`t$($ADguid.guid) `nMATCHES converted `n`$MSOLguid.guid:`t`t$($MSOLguid.guid)`n" ; 
                    $smsg = "`n$((get-date).ToString('HH:mm:ss')):`n===$($tUPN) AD->AAD sync is INTACT:"
                    $smsg += "`n`n`$msolu.ImmutableId:`t$($msolu.ImmutableId) `nMATCHES converted `n`$ADimmutableId:`t`t$($ADimmutableId)"
                    $smsg += "`n`nAND `$ADguid.guid:`t$($ADguid.guid) `nMATCHES converted `n`$MSOLguid.guid:`t`t$($MSOLguid.guid)`n" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $smsg = "(adding `$hReports.isAADUserSynced:`$true)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('isAADUserSynced',$true) ; 
                } else {
                    #write-host -foregroundcolor red "`n$((get-date).ToString('HH:mm:ss')):`n===$(tUPN) AD->AAD sync is BROKEN:`n`n`$msolu.ImmutableId:`t($($msolu.ImmutableId)) `nDOES NOT MATCH converted `n`$ADimmutableId:`t`t($($ADimmutableId))`n`nAND `$ADguid.guid:`t($($ADguid.guid)) `nDOES NOT MATCH converted `n`$MSOLguid.guid:`t`t($($MSOLguid.guid))`n" ; 
                    $smsg = "`n$((get-date).ToString('HH:mm:ss')):`n===$(tUPN) AD->AAD sync is BROKEN:" ; 
                    $smsg += "`n`n`$msolu.ImmutableId:`t($($msolu.ImmutableId)) `nDOES NOT MATCH converted `n`$ADimmutableId:`t`t($($ADimmutableId))" ; 
                    $smsg += "`n`nAND `$ADguid.guid:`t($($ADguid.guid)) `nDOES NOT MATCH converted `n`$MSOLguid.guid:`t`t($($MSOLguid.guid))`n" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $smsg = "(adding `$hReports.isAADUserSynced:`$false)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $hReports.add('isAADUserSynced',$false) ; 
                } ; 
        
                write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):`n$($sBnr.replace('=v','=^').replace('v=','^='))`n" ;
        
            } else {
                write-warning "Current profile lacks underlying connect-msol()" ; 
            } ; 
            
            # convert the hashtable to object for output to pipeline
            $Rpt += New-Object PSObject -Property $hReports ;
            
        
        } ; # loop-E

    } ;  # PROC-E
    END {
        if($outputObject){
            $smsg = "(Returning summary object to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
            $Rpt | Write-Output ; 
        } else {
            $smsg = "(Returning isAADUserSyncd boolean to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
            $Rpt.isAADUserSynced | write-output ; 
        }  
    } ;  # END-E
} ; 
#*------^ END Function test-AADUserSync ^------
