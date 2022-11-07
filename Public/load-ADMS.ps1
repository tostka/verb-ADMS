#*------v load-ADMS.ps1 v------
function load-ADMS {
    <#
    .SYNOPSIS
    load-ADMS - Checks local machine for registred AD MS, and loads if not loaded
    .NOTES
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    * 9:18 AM 7/26/2021 added add-PSTitleBar ADMS tag, w verbose supp; moved connect-ad alias into function alias spec
    * 2:10 PM 6/9/2021 add verbose support 
    * 9:57 AM 11/26/2019 added $Cmdlet param, and ADPS_LoadDefaultDrive suppression evari, to speed up or permit selective loads of targeted cmdlests, stipped down the 'load every module' code to just target the single mod
    # 1:23 PM 1/8/2019 load-ADMS:add an alias to put in verb-noun name match with other variants
    vers: 10:23 AM 4/15/2015 fmt doc cleanup
    vers: 10:43 AM 1/14/2015 fixed return & syntax expl to true/false
    vers: 10:20 AM 12/10/2014 moved commentblock into function
    vers: 11:40 AM 11/25/2014 adapted to Lync
    ers: 2:05 PM 7/19/2013 typo fix in 2013 code
    vers: 1:46 PM 7/19/2013
    .DESCRIPTION
    load-ADMS - Checks local machine for registred AD MS, and loads if not loaded
    .INPUTS
    None.
    .OUTPUTS
    Outputs $True/False load-status
    .EXAMPLE
    $ADMTLoaded = load-ADMS ; Write-Debug "`$ADMTLoaded: $ADMTLoaded" ;
    .EXAMPLE
    $ADMTLoaded = load-ADMS -Cmdlet get-aduser,get-adcomputer ; Write-Debug "`$ADMTLoaded: $ADMTLoaded" ;
    Load solely the specified cmdlets from ADMS
    .EXAMPLE
    # load ADMS
    $reqMods+="load-ADMS".split(";") ;
    if( !(check-ReqMods $reqMods) ) {write-error "$((get-date).ToString("yyyyMMdd HH:mm:ss")):Missing function. EXITING." ; exit ;}  ;
    write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):(loading ADMS...)" ;
    load-ADMS | out-null ;
    #load-ADMS -cmdlet get-aduser,Set-ADUser,Get-ADGroupMember,Get-ADDomainController,Get-ADObject,get-adforest | out-null ;
    Demo a load from the verb-ADMS.ps1 module, with opt specific -Cmdlet set
    .EXAMPLE
    if(connect-ad){write-host 'connected'}else {write-warning 'unable to connect'}  ;
    Variant capturing & testing returned (returns true|false), using the alias name (if don't cap|eat return, you'll get a 'True' in console
    #>
    [CmdletBinding()]
    [Alias('connect-AD')]
    PARAM(
        [Parameter(HelpMessage="Specifies an array of cmdlets that this cmdlet imports from the module into the current session. Wildcard characters are permitted[-Cmdlet get-aduser]")]
        [ValidateNotNullOrEmpty()]$Cmdlet
    ) ;
    $Verbose = ($VerbosePreference -eq 'Continue') ;
    # focus specific cmdlet loads to SPEED them UP!
    $tMod = "ActiveDirectory" ;
    $ModsReg=Get-Module -Name $tMod -ListAvailable ;
    $ModsLoad=Get-Module -name $tMod ;
    $pltAD=@{Name=$tMod ; ErrorAction="Stop"; Verbose = ($VerbosePreference -eq 'Continue') } ;
    if($Cmdlet){$pltAD.add('Cmdlet',$Cmdlet) } ;
    if ($ModsReg) {
        if (!($ModsLoad)) {
            $env:ADPS_LoadDefaultDrive = 0 ;
            import-module @pltAD;
            Add-PSTitleBar 'ADMS' -verbose:$($VerbosePreference -eq "Continue") ;
            return $TRUE;
        } else {
            return $TRUE;
        } # if-E ;
    } else {
        Write-Error {"$((get-date).ToString('HH:mm:ss')):($env:computername) does not have AD Mgmt Tools installed!";};
        return $FALSE
    } # if-E ;
} #*----------^END Function load-ADMS ^----------
