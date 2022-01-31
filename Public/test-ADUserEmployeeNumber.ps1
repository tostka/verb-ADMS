# test-ADUserEmployeeNumber.ps1

#*------v Function test-ADUserEmployeeNumber v------
function test-ADUserEmployeeNumber {
    <#
    .SYNOPSIS
    test-ADUserEmployeeNumber - Check ADUser.employeenumber against TOR standards
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
    * 1:09 PM 1/27/2022 shifted input from aduser to string empnum; added examples
    * 3:00 PM 1/26/2022 init
    .DESCRIPTION
    test-ADUserEmployeeNumber - Check an Emmployeenumber string against policy standards

    Fed an EmployeeNumber string, it will evaluate the value against current business rules

    .PARAMETER EmployeeNumber
    EmployeeNumber string [-EmployeeNumber '123456']
    .INPUT
    System.String    
    .OUTPUT
    System.Boolean
    .EXAMPLE
    PS> test-ADUserEmployeeNumber -ADUser UPN@DOMAIN.COM ; 
    Lookup AzureAD Licensing on UPN
    .EXAMPLE
    PS> $EN = $ADUserObject.employeenumber
        $results = test-ADUserEmployeeNumber -employeenumber $EN -verbose ; 
        if($results){ 
            write-host -foregroundcolor green "$($EN) is a legitimate employenumber" ;
        } else {
            write-warning "$($EN) is *NOT* a legitimate ADUser employenumber" ;
        } ; 
    Example returning an object and testing post-status on object
    .EXAMPLE
    PS> if(test-ADUserEmployeeNumber -employeenumber ($ADUsers.employeenumber | get-random -Count 30) -verbose){ 
            write-host -foregroundcolor green "legitimate employenumber" 
        } else {
            write-warning "*NOT* a legitimate ADUser employenumber" 
        } ; 
    Example that pulls 30 random employeenumbers from a variable containing a set of users
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    #Requires -Version 3
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [OutputType('bool')] # optional specified output type
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="EmployeeNumber string [-EmployeeNumber '123456']")]
        $EmployeeNumber,
        [Parameter(HelpMessage="Object output switch [-outputObject]")]
        [switch] $outputObject
    ) # PARAM BLOCK END

    BEGIN { 
        $rgxEmailAddr = "^([0-9a-zA-Z]+[-._+&'])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,63}$" ;
        # added support for . fname lname delimiter (supports pasted in dirname of email addresses, as user)
        $rgxDName = "^([a-zA-Z]{2,}(\s|\.)[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)" ;
        #"^([a-zA-Z]{2,}\s[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)" ;
        $rgxObjNameNewHires = "^([a-zA-Z]{2,}(\s|\.)[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)_[a-z0-9]{10}"  # Name:Fname LName_f4feebafdb (appending uniqueness guid chunk)
        $rgxSamAcctNameTOR = "^\w{2,20}$" ; # up to 20k, the limit prior to win2k
        $rgxEmployeeID = 
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
        
        #$1stConn = $true ; 
        $isLegit = $false ; 
        foreach($EN in $EmployeeNumber){
            $smsg = "$($EN):" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            switch -regex ($EN.length){
                '(9|10)' {
                    write-warning "$($EN): 10-digit is an illegimate employeenumber length!" ;
                    $isLegit = $false ; 
                } 
                '(8|5)' {
                    if($EN -match '^[0-9]+$'){
                        write-verbose "$($EN): 5|8-digit integer mainstream employeenumber" ;
                        $isLegit = $true ; 
                    } else {
                        write-warning "$($EN): 8|5-digit:non-integer 5|8-char is an illegimate employeenumber length!" 
                        $isLegit = $false ; 
                    } ; 
                }
                '(7|6)' {
                    if($EN -match '^[0-9]+$') {
                        write-verbose "$($EN): 7|6-digit integer mainstream employeenumber" ;        
                        $isLegit = $true ; 
                    } elseif($EN -match '^[A-Za-z0-9]+$') {
                        write-warning "$($EN): 7|6-digit non-integer: likely has SamaccountName stuffed in employeenumber!" ;  
                        $isLegit = $false ; 
                    } elseif($EN -match '^[A-Za-z0-9\s]+$') {
                        write-warning "$($EN): 7|6-digit non-integer w \s: likely has leading/trailing \s char!" ;  
                        $isLegit = $false ; 
                    } else {
                        write-warning "7|6-digit:outlier undefined condition!"  ;
                        $isLegit = $false ; 
                    } ;      
                } ; 
                '(3|4)' {
                    if($EN -match '^[0-9]+$') {
                        write-verbose "$($EN): 3|4-digit integer mainstream employeenumber" ;     
                        $isLegit = $true ; 
                    } else {
                        write-warning "$($EN): 3|4-digit:outlier undefined condition!"  ;
                        $isLegit = $false ; 
                    } ;  
                } ; 
                default {
                    write-warning "$($EN.length):-digit:outlier undefined condition!"
                    $isLegit = $false ; 
                } ; 
            } ; 
            if($outputObject){
                <#           
                $oobj = [ordered]@{
                    EmployeeNumber=$EN ; 
                    isEmployeeNumber = $($isLegit) ; 
                } ; 
                #>
                $smsg = "(Returning summary object to pipeline)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
                #[psobject]$oobj | write-output ;
                #$cObj = [pscustomobject] @{EmployeeNumber=$EN ;isEmployeeNumber = $($isLegit) ; } ;
                #$oObj | write-output ; 
                [pscustomobject] @{EmployeeNumber=$EN ;isEmployeeNumber = $($isLegit) ; } | write-output ;
            } else { 
                $smsg = "(Returning boolean to pipeline)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
                $isLegit | write-output ; 
            } ; 
        } ; 

    } ;  # PROC-E
    END {
        

    } ;  # END-E
} ; 
#*------^ END Function test-ADUserEmployeeNumber ^------
