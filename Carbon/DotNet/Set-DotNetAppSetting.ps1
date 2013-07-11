# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Set-DotNetAppSetting
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
    > Set-DotNetAppSetting -Name ExampleUrl -Value example.com -Framework -Framework64 -Clr2 -Clr4
    
    Sets the ExampleUrl app setting in the following machine.config files:
    
     * `%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\CONFIG\machine.config`
     * `%SYSTEMROOT%\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config`

    .EXAMPLE
    > Set-DotNetAppSetting -Name ExampleUrl -Value example.com -Framework64 -Clr4
    
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
                                (ConvertTo-Base64 -Value $Name),
                                (ConvertTo-Base64 -Value $Value)
                            );
            Runtime = $_;
            ExecutionPolicy = [Microsoft.PowerShell.ExecutionPolicy]::RemoteSigned;
        }
        
        if( $Framework )
        {    
            Invoke-PowerShell @params -x86
        }
        
        if( $Framework64 )
        {
            Invoke-PowerShell @params
        }
    }
}
