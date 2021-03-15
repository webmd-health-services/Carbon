
function Set-CDotNetAppSetting
{
    <#
    .SYNOPSIS
    Sets an app setting in the .NET machine.config file.
    
    .DESCRIPTION
    The app setting can be set in up to four different machine.config files:
    
     * .NET 2.0 32-bit (switches -Clr2 -Framework)
     * .NET 2.0 64-bit (switches -Clr2 -Framework64)
     * .NET 4.0 32-bit (switches -Clr4 -Framework)
     * .NET 4.0 64-bit (switches -Clr4 -Framework64)
      
    Any combination of Framework and Clr switch can be used, but you MUST supply one of each.
    
    .EXAMPLE
    > Set-CDotNetAppSetting -Name ExampleUrl -Value example.com -Framework -Framework64 -Clr2 -Clr4
    
    Sets the ExampleUrl app setting in the following machine.config files:
    
     * `%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config`

    .LINK
    Remove-CDotNetAppSetting

    .LINK
    Set-CDotNetConnectionString

    .EXAMPLE
    > Set-CDotNetAppSetting -Name ExampleUrl -Value example.com -Framework64 -Clr4
    
    Sets the ExampleUrl app setting in the following machine.config file:
    
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config`
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app setting to be set
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The valie of the app setting to be set.
        $Value,
        
        [Switch]
        # Set the app setting in the 32-bit machine.config.
        $Framework,
        
        [Switch]
        # Set the app setting in the 64-bit machine.config.  Ignored if running on a 32-bit operating system.
        $Framework64,
        
        [Switch]
        # Set the app setting in the .NET 2.0 machine.config.
        $Clr2,
        
        [Switch]
        # Set the app setting in the .NET 4.0 machine.config.
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
            FilePath = (Join-Path $CarbonBinDir 'Set-DotNetAppSetting.ps1' -Resolve);
            ArgumentList = @( 
                                (ConvertTo-CBase64 -Value $Name -NoWarn),
                                (ConvertTo-CBase64 -Value $Value -NoWarn)
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

