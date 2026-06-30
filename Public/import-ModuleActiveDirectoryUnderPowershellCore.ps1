# import-ModuleActiveDirectoryUnderPowershellCore.ps1

#region IMPORT_MODULEACTIVEDIRECTORYUNDERPOWERSHELLCORE ; #*------v import-ModuleActiveDirectoryUnderPowershellCore v------
function import-ModuleActiveDirectoryUnderPowershellCore {
    <#
    .SYNOPSIS
    import-ModuleActiveDirectoryUnderPowershellCore() - Works around Powershell7/PowershellCore limitation - ActiveDirectory module is .net-based and incompatible with PSc. Loads background session in windowspowershell, and imports that session into the ps7 session, to expose AD cmdlets. 
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-04-03
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-ADMS
    Tags        : Powershell,ActiveDirectory
    REVISIONS
    * 10:44 AM 6/29/2026 initial vers
    .DESCRIPTION
    import-ModuleActiveDirectoryUnderPowershellCore() - Works around Powershell7/PowershellCore limitation - ActiveDirectory module is .net-based and incompatible with PSc. Loads background session in windowspowershell, and imports that session into the ps7 session, to expose AD cmdlets. 
    
    Issue: Both Import-Module ActiveDirectory -UseWindowsPowerShell and the below...
    ```powershell
    PS> $s = New-PSSession -UseWindowsPowerShell ; 
    PS> Import-Module ActiveDirectory -PSSession $s ; 
    
        cmdlet Measure-Object at command pipeline position 2
        Supply values for the following parameters:
        Property:
    ```
    generate the above supply values ... prompt, and Fail, if you specify an arbitrary value at the prompt, like '*'

     Testing has revealed solely this variant that works for this critical hybrid user mgmt module:
    ```powershell
    PS> Invoke-Command $s { powershell -NoProfile -Command "Import-Module ActiveDirectory" } ; 
    PS> Import-Module ActiveDirectory -PSSession $s ; 
    PS> get-aduser LOGON ; 
 
    ```
    
    Copilot reports the following root cause, and options that 'should' work (not in my testing)

    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    This is a **known (and very annoying) PowerShell 7 + WinPS compatibility bug**, not something you're doing wrong.

    What you're seeing:

    ```
    cmdlet Measure-Object at command pipeline position 2
    Supply values for the following parameters:
    Property:
    ```

    followed by:

    ```
    Failed to generate proxies for remote module 'ActiveDirectory'.
    Data returned by the remote Get-Command command is not in the expected format.
    ```

    means:

    ? The **WinPS compatibility layer is breaking during proxy generation**  
    ? It's mis-parsing output from the remote session  
    ? `Measure-Object` is being invoked incorrectly with a missing `-Property`

    * * *

    # ? Root Cause (what's actually broken)

    This happens when **something in the Windows PowerShell session is interfering with `Get-Command` output**, typically:

    ### ?? Most common triggers

    1.  **A profile script in Windows PowerShell (5.1)**
        
        -   Especially anything modifying pipeline behavior
        -   e.g. aliases, functions, formatting, or wrappers around core cmdlets
    2.  **A redefined or shadowed `Measure-Object`**
        
        -   Function or alias overriding the built-in cmdlet
    3.  **Custom type/format data**
        
        -   `.ps1xml` changes that break object serialization
    4.  **Third-party modules auto-loading in WinPS**
        
        -   These can silently corrupt the pipeline output

    * * *

    # ? Why it breaks _this specific import_

    Internally, PS7 does something like:

    PowerShell

    Invoke-Command -Session $s { Get-Command -Module ActiveDirectory } | Measure-Object

    ```

    If **anything modifies `Measure-Object` behavior**, it triggers:

    ```
    Supply values for the following parameters: Property
    ```

    ? which completely breaks proxy generation

    * * *

    # ? The Fix (cleanest and most reliable)

    ## ? Option 1 — Start a clean WinPS session (NO profile)

    PowerShell

    $s = New-PSSession -UseWindowsPowerShell -ConfigurationName Microsoft.PowerShell

    Then:

    PowerShell

    Invoke-Command $s { powershell -NoProfile -Command "Import-Module ActiveDirectory" }

    Import-Module ActiveDirectory -PSSession $s

    * * *

    ## ? Option 2 — Disable profile loading globally (BEST FIX)

    Check your WinPS profile:

    PowerShell

    notepad $PROFILE

    Also check **all scopes**:

    PowerShell

    $PROFILE | Format-List \*

    Then temporarily test:

    PowerShell

    powershell.exe -NoProfile

    Inside that session:

    PowerShell

    Import-Module ActiveDirectory

    Get-Command Get-ADUser

    ? If this works ? your profile is the problem

    * * *

    ## ? Option 3 — Detect a broken Measure-Object

    In **Windows PowerShell (5.1)** run:

    PowerShell

    Get-Command Measure-Object

    Expected:

    ```
    Cmdlet Measure-Object
    ```

    If you see:

    -   `Function`
    -   `Alias`

    ? That's your issue

    * * *

    ### Fix it:

    PowerShell

    Remove-Item function:Measure-Object -ErrorAction SilentlyContinue

    Remove-Item alias:Measure-Object -ErrorAction SilentlyContinue

    ```

    * * *

    ## ? Option 4 — Force clean import (recommended workaround)

    This often bypasses the bug:

    PowerShell

    $s = New-PSSession -UseWindowsPowerShell

    Invoke-Command $s {

    Remove-Item function:Measure-Object -ErrorAction SilentlyContinue

    Import-Module ActiveDirectory

    }

    Import-Module ActiveDirectory -PSSession $s -DisableNameChecking

    * * *

    # ? Quick diagnostic (do this first)

    Run this in PS7:

    PowerShell

    Invoke-Command -Session $s { Get-Command Measure-Object }

    If it DOESN'T return:

    ```
    Cmdlet Measure-Object
    ```

    ? you've confirmed the root cause

    * * *

    # ? Nuclear but effective fix

    If this is a server with lots of legacy scripts:

    PowerShell

    rename-item $HOME\\Documents\\WindowsPowerShell\\profile.ps1 profile.ps1.bak

    ```

    Then retry your import.

    * * *

    # ? Alternative (if you just need it working)

    Honestly, for stability:

    ?? Run AD commands in **Windows PowerShell 5.1 directly**

    PowerShell

    powershell.exe

    Import-Module ActiveDirectory

    This avoids:

    -   proxy generation bugs
    -   serialization issues
    -   compatibility headaches

    * * *

    # ? Bottom line

    Your issue is **NOT:**

    -   module path
    -   permissions
    -   remoting config

    ? It **IS:**

    A corrupted WinPS command pipeline (almost always `Measure-Object` or profile interference)

    * * *
    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    
    .OUTPUT
    None
    .EXAMPLE
    $OU=import-ModuleActiveDirectoryUnderPowershellCore -Sitecode SITE -Generic
    Retrieve the DN OU path for the specified SITE OU's Email-related Generic Mbx sub-OU    
    .LINK
    https://github.com/tostka/verb-ADMS
    #>
    [CmdletBinding()]
    #[Alias('xxx')]
    PARAM (        
    ) ;  # PARAM-E    
    TRY{
        Invoke-Command $s { powershell -NoProfile -Command "Import-Module ActiveDirectory -ErrorAction STOP" } ; 
        Import-Module ActiveDirectory -PSSession $s -ErrorAction STOP; 
        $TRUE | write-output ; 
    } CATCH {$ErrTrapd=$Error[0] ;
        write-host -foregroundcolor gray  "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        write-warning  "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
        $false | write-output  ;         
    } ;
} ;  
#endregion IMPORT_MODULEACTIVEDIRECTORYUNDERPOWERSHELLCORE ; #*------^ END import-ModuleActiveDirectoryUnderPowershellCore ^------
