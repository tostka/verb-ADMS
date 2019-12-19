#*----------v Function load-ADMS v----------
function load-ADMS {
    <#
    .SYNOPSIS
    load-ADMS - Checks local machine for registred AD MS, and loads if not loaded
    .NOTES
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
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
    #>
    PARAM(
        [Parameter(HelpMessage="Specifies an array of cmdlets that this cmdlet imports from the module into the current session. Wildcard characters are permitted[-Cmdlet get-aduser]")]
        [ValidateNotNullOrEmpty()]$Cmdlet
    ) ;
    # -Cmdlet
    # check registred v loaded ;
    #$ModsReg=Get-Module -ListAvailable;
    # focus both of the above to SPEED them UP!
    $tMod = "ActiveDirectory" ; 
    $ModsReg=Get-Module -Name $tMod -ListAvailable ; 
    #$ModsLoad=Get-Module;
    $ModsLoad=Get-Module -name $tMod ; 
    $pltAD=@{Name=$tMod ; ErrorAction="Stop" } ; 
    if($Cmdlet){$pltAD.add('Cmdlet',$Cmdlet) } ;
    #if ($ModsReg | where {$_.Name -eq $tMod}) {
    if ($ModsReg) {
        #if (!($ModsLoad | where {$_.Name -eq $tMod})) {
        if (!($ModsLoad)) {
            $env:ADPS_LoadDefaultDrive = 0 ; 
            #import-module -Name $tMod -Cmdlet:$($Cmdlet) -ErrorAction Stop ;return $TRUE;
            import-module @pltAD; 
            return $TRUE;
        } else {
            return $TRUE;
        } # if-E ; 
    } else {
        Write-Error {"$((get-date).ToString('HH:mm:ss')):($env:computername) does not have AD Mgmt Tools installed!";};
        return $FALSE
    } # if-E ; 
} #*----------^END Function load-ADMS ^----------
# 1:23 PM 1/8/2019 load-ADMS:add an alias to put in verb-noun name match with other variants
if(!(get-alias | ?{$_.name -like "connect-ad"})) {Set-Alias 'connect-ad' -Value 'load-ADMS' ; } ;
# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBlTNwAUA4LCeUmj8AWIstMvz
# a9ygggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTTPrxu
# XyKksl24/OYJ48XocVrpujANBgkqhkiG9w0BAQEFAASBgBdlI3/QYgLGZL+SlMfk
# Jzule9b0vm+Wh1u2WMH1BcqQW0CU98Qp/K7pCahq6HQsx+I9XXqq5voSuhP8QYNg
# PKoZrIiyNL9uivtA0Dmg2hDD4RYixzTVgDC6NPO4sxTwqjwchKfnPUhagrPtvKXM
# 0ggusS6p0/8dW/hoAt5Gbdal
# SIG # End signature block
