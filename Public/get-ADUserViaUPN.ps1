#*------v get-ADUserViaUPN.ps1 v------
function get-ADUserViaUPN {
    <#
    .SYNOPSIS
    get-ADUserViaUPN - get-ADUser wrapper that implements a -UserPrincipalName parameter, and proper -EA STOP error return (like the -Identity parameter). 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-02-03
    FileName    : get-ADUserViaUPN
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell, ActiveDirectory, UserPrincipalName
    REVISIONS
    * 10:57 AM 2/3/2022 init
    .DESCRIPTION
    get-ADUserViaUPN - get-ADUser wrapper that implements proper -EA STOP error return when using -filter {UPN -eq 'someupn@domain'}. 
    Issue is that the get-AD* ActiveDirectory module cmdlets completely fail to implement a variety of standard features of other powershell modules. 
     -Identity has no support for UserPrincipalName lookup (the modern authentication identifier). 
        instead, the standard supported approach is to use the -filter cmdlet to run a filtered search: 
        -filter "userprincipalname -eq 'UPN@domain.com'"
        or, with variables:
        -filter "userprincipalname -eq '$($UPN)'"
     -But, unlike failures to lookup using the -identity parameter, use of the necessary -Filter parameter fails to generate a Try/Catch-able error even when using -ErrorAction 'STOP'. 
     -This makes it a challenge to detect lookup failures. So this wrapper function aims to shim in the missing bits, to provide a get-aduser cmdlet that at least *somewhat* emulates proper -userprinicpalname parameter suppor. 
     
    The wrapper function passes through the following stock get-aduser parameters:
        [string] Partition,
        [String[]] Properties,
        [Int32] ResultPageSize,
        [string] SearchBase,
        [string] SearchScope    

    Note -Properties does *not* implement wild-card resolution: only a comma-delimited or array list of full property names are supported in this wrapper. (get-aduser must do natively resolution of the wildcards to the underlying full properties list on the target objects, and attempts to pass through wildcards intact results in errors). 
    
    The following parameter help is cribbed from the underlying get-ADUser cmdlet...
    
    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER Partition <String>
    Specifies the distinguished name of an Active Directory partition. The distinguished name must be one of the naming contexts on the current directory server. The cmdlet searches this partition to find the object defined by the Identity parameter.

    The following two examples show how to specify a value for this parameter.

    -Partition "CN=Configuration,DC=EUROPE,DC=TEST,DC=CONTOSO,DC=COM"

    -Partition "CN=Schema,CN=Configuration,DC=EUROPE,DC=TEST,DC=CONTOSO,DC=COM"

    In many cases, a default value will be used for the Partition parameter if no value is specified.  The rules for determining the default value are given below.  Note that rules listed first are evaluated first and once a default value can be
    determined, no further rules will be evaluated.

    In AD DS environments, a default value for Partition will be set in the following cases:  - If the Identity parameter is set to a distinguished name, the default value of Partition is automatically generated from this distinguished name.

    - If running cmdlets from an Active Directory provider drive, the default value of Partition is automatically generated from the current path in the drive.

    - If none of the previous cases apply, the default value of Partition will be set to the default partition or naming context of the target domain.

    In AD LDS environments, a default value for Partition will be set in the following cases:

    - If the Identity parameter is set to a distinguished name, the default value of Partition is automatically generated from this distinguished name.

    - If running cmdlets from an Active Directory provider drive, the default value of Partition is automatically generated from the current path in the drive.

    - If the target AD LDS instance has a default naming context, the default value of Partition will be set to the default naming context.  To specify a default naming context for an AD LDS environment, set the msDS-defaultNamingContext property of the
    Active Directory directory service agent (DSA) object (nTDSDSA) for the AD LDS instance.

    - If none of the previous cases apply, the Partition parameter will not take any default value.
    .PARAMETER Properties
    Specifies the properties of the output object to retrieve from the server. Use this parameter to retrieve properties that are not included in the default set.

    Specify properties for this parameter as a comma-separated list of names. To display all of the attributes that are set on the object, specify * (asterisk).

    To specify an individual extended property, use the name of the property. For properties that are not default or extended properties, you must specify the LDAP display name of the attribute.

    To retrieve properties and display them for an object, you can use the Get-* cmdlet associated with the object and pass the output to the Get-Member cmdlet. The following examples show how to retrieve properties for a group where the Administrator's
    group is used as the sample group object.

    Get-ADGroup -Identity Administrators | Get-Member

    To retrieve and display the list of all the properties for an ADGroup object, use the following command:

    Get-ADGroup -Identity Administrators -Properties *| Get-Member

    The following examples show how to use the Properties parameter to retrieve individual properties as well as the default, extended or complete set of properties.

    To retrieve the extended properties "OfficePhone" and "Organization" and the default properties of an ADUser object named "SaraDavis", use the following command:

    GetADUser -Identity SaraDavis  -Properties OfficePhone,Organization

    To retrieve the properties with LDAP display names of "otherTelephone" and "otherMobile", in addition to the default properties for the same user, use the following command:

    GetADUser -Identity SaraDavis  -Properties otherTelephone, otherMobile |Get-Member
    .PARAMETER ResultPageSize
    Specifies the number of objects to include in one page for an Active Directory Domain Services query.

    The default is 256 objects per page.

    The following example shows how to set this parameter.

    -ResultPageSize 500  
    .PARAMETER SearchBase <String>
    Specifies an Active Directory path to search under.

    When you run a cmdlet from an Active Directory provider drive, the default value of this parameter is the current path of the drive.

    When you run a cmdlet outside of an Active Directory provider drive against an AD DS target, the default value of this parameter is the default naming context of the target domain.

    When you run a cmdlet outside of an Active Directory provider drive against an AD LDS target, the default value is the default naming context of the target LDS instance if one has been specified by setting the msDS-defaultNamingContext property of
    the Active Directory directory service agent (DSA) object (nTDSDSA) for the AD LDS instance.  If no default naming context has been specified for the target AD LDS instance, then this parameter has no default value.

    The following example shows how to set this parameter to search under an OU.

    -SearchBase "ou=mfg,dc=noam,dc=corp,dc=contoso,dc=com"

    When the value of the SearchBase parameter is set to an empty string and you are connected to a GC port, all partitions will be searched. If the value of the SearchBase parameter is set to an empty string and you are not connected to a GC port, an
    error will be thrown.

    The following example shows how to set this parameter to an empty string.   -SearchBase ""
    
    .PARAMETER SearchScope <ADSearchScope>
    Specifies the scope of an Active Directory search. Possible values for this parameter are:

    Base or 0

    OneLevel or 1

    Subtree or 2

    A Base query searches only the current path or object. A OneLevel query searches the immediate children of that path or object. A Subtree query searches the current path or object and all children of that path or object.

    The following example shows how to set this parameter to a subtree search.
    .PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to, by providing one of the following values for a corresponding domain name or directory server. The service may be any of the following:  Active Directory Lightweight Domain
    Services, Active Directory Domain Services or Active Directory Snapshot instance.

    Domain name values:

    Fully qualified domain name

    Examples: corp.contoso.com

    NetBIOS name

    Example: CORP

    Directory server values:

    Fully qualified directory server name

    Example: corp-DC12.corp.contoso.com

    NetBIOS name

    Example: corp-DC12

    Fully qualified directory server name and port

    Example: corp-DC12.corp.contoso.com:3268

    The default value for the Server parameter is determined by one of the following methods in the order that they are listed:

    -By using Server value from objects passed through the pipeline.

    -By using the server information associated with the Active Directory PowerShell provider drive, when running under that drive.

    -By using the domain of the computer running Powershell.

    The following example shows how to specify a full qualified domain name as the parameter value.

    -Server "corp.contoso.com"
    
    .PARAMETER UserPrincipalName
    UserPrincipalName [-UserPrincipalName xxx@toro.com]
    .PARAMETER outputObject
    Object output switch [-outputObject]
    .EXAMPLE
    PS> $gadu = get-ADUserViaUPN -UserPrincipalName UPN@DOMAIN.COM -verbose -prop description,title ; 
    Lookup ADUser object filtering on UPN, specifying two properties, verbose, and assign result to a variable   
    .EXAMPLE
    PS> $gadu = get-ADUserViaUPN -UserPrincipalName UPN@DOMAIN.COM  ; 
    Lookup ADUser object filtering on UPN, default behaivior (without -properties specification) is to return all properties of the located object.  
    .LINK
    https://github.com/tostka/verb-AAD
    #>
    #Requires -Version 3
    #Requires -Modules verb-AAD, ActiveDirectory
    #Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    ## [OutputType('bool')] # optional specified output type
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="UserPrincipalName [-UserPrincipalName xxx@toro.com]")]
        [Alias('UPN')]
        $UserPrincipalName,
        [string] $Partition,
        [String[]] $Properties,
        [Int32] $ResultPageSize,
        [string] $SearchBase,
        [string] $SearchScope
        #[Parameter(HelpMessage="Object output switch [-outputObject]")]
        #[switch] $outputObject
    ) # PARAM BLOCK END

    BEGIN { 
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ; 
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
        } else {
            #$smsg = "Data received from parameter input: '$($InputObject)'" ; 
            $smsg = "(non-pipeline - param - input)" ; 
            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
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

                $sBnr="#*======v UPN: $($UPN): v======" ;
                write-verbose "$((get-date).ToString('HH:mm:ss')):`n$($sBnr)" ;
                #$hReports = [ordered]@{} ; 
                
                    # AD abberant -filter syntax: Get-ADUser -Filter 'sAMAccountName -eq $SamAc'
                    $filter = "userprincipalname -eq '$($UPN)'" ;
                    $pltGADU=[ordered]@{
                        filter= $filter ;
                        #Properties = 'DisplayName' ;
                        ErrorAction= 'STOP' 
                    } ;
                    # [string] $Partition,
                    if($Partition){$pltGADU.add('Partition',$Partition)} ;
                    #[String[]] $Properties,
                    if($Properties){
                        if($properties -match '\*'){
                            $smsg = "Asterisk (*) detected in -properties specification:" ; 
                            $smsg += "`nFull partial-property name wild card property conversion is not implemented in this wrapper."
                            $smsg += "`nPlease specify full property names in a comma-deliminted list" ; 
                            $smsg += "`n(or use default *no* -property behavior:return *all* properties of located object)"
                            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
                            break ; 
                        } ; 
                        $pltGADU.add('Properties',$Properties) ; 
                    } else {
                        # if properties unspecified, pull *everything*, like every other blanking module in existence!
                        $smsg = "(no -properties specified: returning *all* properties, like a sensible module would)" ; 
                        write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
                        $pltGADU.add('Properties','*') ; 
                    }  ;
                    #[Int32] $ResultPageSize,
                    if($ResultPageSize){$pltGADU.add('ResultPageSize',$ResultPageSize)} ;
                    #[string] $SearchBase,
                    if($SearchBase){$pltGADU.add('SearchBase',$SearchBase)} ;
                    #[ADSearchScope] $SearchScope,                    
                    if($SearchScope){$pltGADU.add('SearchScope',$SearchScope)} ;
                    $smsg = "get-aduser w`n$(($pltGADU|out-string).trim())" ; 
                    write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ;
                    $ADUser = $null ; 
                    Try {
                        $ADUser = get-aduser @pltGADU ; 
                        # if it won't trigger test & throw 
                        if($AdUser){
                            $smsg = "(get-aduser matched:$($aduser.userprincipalname))" ; 
                            write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ; 
                        } else { 
                            $smsg = "(get-aduser FAILED to match -filter:$($pltGADU.filter))" ; 
                            write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
                            #throw $smsg  ; 
                            # try to throw a stock ad not-found error (emulate it)
                            throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] "$($smsg)"
                        } ; 
                    # doesn't work natively -filter doesn't generate a catchable error, even with -ea STOP, this block never triggers
                    } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        $smsg = "No GET-ADUSER match found for -filter:$($filter)" ; 
                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;      
                        Write-Error $smsg ;
                        Continue ; 
                    # reworking extended vers of above
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                        
                        Continue ;
                    } ; 
                    #
                write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):`n$($sBnr.replace('=v','=^').replace('v=','^='))`n" ;
            
            # convert the hashtable to object for output to pipeline
            #$Rpt += New-Object PSObject -Property $hReports ;
            if($ADUser){
                $ADUser| write-output ;
            } ; 
        
        } ; # loop-E

    } ;  # PROC-E
    END {
        
    } ;  # END-E
} ;
#*------^ get-ADUserViaUPN.ps1 ^------