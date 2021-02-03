
function Remove-CDotNetAppSetting
{
    <#
    .SYNOPSIS
    Remove an app setting from the .NET machine.config file.
    
    .DESCRIPTION
    The `Remove-CDotNetAppSetting` removes an app setting from one or more of the .NET machine.config file. The app setting can be removed from up to four different machine.config files:
    
     * .NET 2.0 32-bit (switches -Clr2 -Framework)
     * .NET 2.0 64-bit (switches -Clr2 -Framework64)
     * .NET 4.0 32-bit (switches -Clr4 -Framework)
     * .NET 4.0 64-bit (switches -Clr4 -Framework64)
      
    Any combination of Framework and Clr switch can be used, but you MUST supply one of each.

    If the app setting doesn't exist in the machine.config, nothing happens.

    `Remove-CDotNetAppSetting` was added in Carbon 2.2.0.
    
    .LINK
    Set-CDotNetAppSetting

    .LINK
    Set-CDotNetConnectionString

    .EXAMPLE
    > Remove-CDotNetAppSetting -Name ExampleUrl -Framework -Framework64 -Clr2 -Clr4
    
    Remvoes the `ExampleUrl` app setting from the following machine.config files:
    
     * `%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config`

    .EXAMPLE
    > Remove-CDotNetAppSetting -Name ExampleUrl -Framework64 -Clr4
    
    Sets the ExampleUrl app setting in the following machine.config file:
    
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config`
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app setting to remove.
        $Name,

        [Switch]
        # Remove the app setting from a 32-bit machine.config. Must be used with one or both of the `Clr2` and `Clr4` switches to control which machine.config files to operate on.
        $Framework,
        
        [Switch]
        # Remove the app setting from a 64-bit machine.config. Ignored if running on a 32-bit operating system. Must be used with one or both of the `Clr2` and `Clr4` switches to control which machine.config files to operate on.
        $Framework64,
        
        [Switch]
        # Remove the app setting from a .NET 2.0 machine.config. Must be used with one or both of the `Framework` and `Framework64` switches to control which machine.config files to operate on.
        $Clr2,
        
        [Switch]
        # Remove the app setting from a .NET 4.0 machine.config. Must be used with one or both of the `Framework` and `Framework64` switches to control which machine.config files to operate on.
        $Clr4
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not ($Framework -or $Framework64) )
    {
        Write-Error "You must supply either or both of the Framework and Framework64 switches."
        return
    }
    
    if( -not ($Clr2 -or $Clr4) )
    {
        Write-Error "You must supply either or both of the Clr2 and Clr4 switches."
        return
    }
    
    $runtimes = @()
    if( $Clr2 )
    {
        $runtimes += 'v2.0'
    }
    if( $Clr4 )
    {
        $runtimes += 'v4.0'
    }

    $runtimes | ForEach-Object {
        $params = @{
            FilePath = (Join-Path $CarbonBinDir 'Remove-DotNetAppSetting.ps1' -Resolve);
            ArgumentList = @( 
                                (ConvertTo-CBase64 -Value $Name -NoWarn)
                            );
            Runtime = $_;
            ExecutionPolicy = [Microsoft.PowerShell.ExecutionPolicy]::RemoteSigned;
        }
        
        if( $Framework )
        {    
            Invoke-CPowerShell @params -x86 -NoWarn
        }
        
        if( $Framework64 )
        {
            Invoke-CPowerShell @params -NoWarn
        }
    }
}

