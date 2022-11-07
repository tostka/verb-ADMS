
#*------v Function resolve-ADRightsGuid v------
function resolve-ADRightsGuid {
    <#
    .SYNOPSIS
    resolve-ADRightsGuid() - Resolve a given get-ACL guid value to it's Name
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    AddedCredit : Faris Malaeb
    AddedWebsite:	https://devblogs.microsoft.com/powershell-community/understanding-get-acl-and-ad-drive-output/
    AddedTwitter:	URL
    CreatedDate : 2021-11-29
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory,Permissions
    REVISIONS
    * 1:51 PM 11/29/2021 validated functional; init vers, adapted from demo code by Faris Malaeb [Understanding Get-ACL and AD Drive Output - PowerShell Community - devblogs.microsoft.com/](https://devblogs.microsoft.com/powershell-community/understanding-get-acl-and-ad-drive-output/)
    .DESCRIPTION
    resolve-ADRightsGuid() - Resolve a given get-ACL guid value to it's Name
    Queries the AD: AD psdrive provider under the SchemaNamingContext & Extended-Rights, then loops past the set finding the matching guid, and returning the resolved guid name value
    .PARAMETER  guid
    AD Rights guid value to be looked up against AD SchemaNamingContext & Extended-Rights 
    .EXAMPLE
    $guidName =resolve-ADRightsGuid -guid 'bf9679c0-0de6-11d0-a285-00aa003049e2' 
    Resolve the guid above to it's matching Name ('Self-Membership")
    .EXAMPLE
    # a random function that updates an ACL and  returns the acl as an object
    $aclret = grant-ADGroupManagerUpdateMembership -User SAMACCTNAME -group 'ADGROUPNAME' -verbose -returnobject ; 
    # resolve the returned acl guid ('ObjectType' prop) to it's matching name. 
    $guidname = resolve-adrightsguid -guid ($aclret.ObjectType) -verbose ;
    Example demoing a returned ACL guid, resolved to it's matching name
    .LINK
    https://devblogs.microsoft.com/powershell-community/understanding-get-acl-and-ad-drive-output/
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
## [OutputType('bool')] # optional specified output type

    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory=$True,HelpMessage="AD Rights guid value to be looked up against AD SchemaNamingContext & Extended-Rights ")]
        [guid]$guid
    ) ;  
    $verbose = ($VerbosePreference -eq "Continue") ; 

    $error.clear() ;
    TRY {
        $GetADObjectParameter=@{   
            SearchBase=(Get-ADRootDSE).SchemaNamingContext ;
            LDAPFilter='(SchemaIDGUID=*)' ;
            Properties=@("Name", "SchemaIDGUID") ;
        } ;
        write-verbose "Get-ADObject w`n$(($GetADObjectParameter |out-string).trim())" ;
        $SchGUID=Get-ADObject @GetADObjectParameter ;

        $ADObjExtPar=@{
            SearchBase="CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" ;
            LDAPFilter='(ObjectClass=ControlAccessRight)' ;
            Properties=@("Name", "RightsGUID") ;
        } ;
        write-verbose "Get-ADObject w`n$(($ADObjExtPar|out-string).trim())" ;
        $SchExtGUID=Get-ADObject @ADObjExtPar ;
        # loop the returns to find the first match
        foreach($rightsguid in @($SchGUID,$SchExtGUID)){
            if($guidobj = $rightsguid| ?{$_.rightsguid -eq $guid.tostring()}){
                $guidobj.name | write-output    ;
                break ; 
            } ;
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
        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
    } ; 
}  ; 
#*------^ END Function resolve-ADRightsGuid ^------
