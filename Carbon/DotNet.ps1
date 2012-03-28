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
    Sets an app setting in the .NET machine.config file
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory=$true)]
        # The name of the app setting to be set
        $Name,

        [Parameter(Mandatory=$true)]
        # The valie of the app setting to be set.
        $Value,
        
        [Switch]
        # Set the app setting in the 32-bit machine.config.
        $Framework,
        
        [Switch]
        # Set the app setting in the 64-bit machine.config
        $Framework64
        
    )
    
    if( -not ($Framework -or $Framework64) )
    {
        Write-Error "You must specify either or both of the Framework or Framework64 flags."
        return
    }
    
    $command = {
        param(
            $Name,
            $Value
        )
        
        Add-Type -AssemblyName System.Configuration

        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        $appSettings = $config.AppSettings.Settings
        if( $appSettings[$Name] )
        {
            $appSettings[$Name].Value = $Value
        }
        else
        {
            $appSettings.Add( $Name, $Value )
        }
        $config.Save()
    }

    if( $Framework )
    {    
        Invoke-PowerShell -Command $command -Args $Name,$Value -x86
    }
    
    if( $Framework64 )
    {
        Invoke-PowerShell -Command $command -Args $Name,$Value
    }
}

function Set-DotNetConnectionString
{
    <#
    .SYNOPSIS
    Sets a named connection string in the .NET machine.config file
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The name of the .net connection string to be set
        $Name,

        [Parameter(Mandatory=$true)]
        # The connection string to be set.
        $Value,
        
        [Switch]
        # Set the connection string in the 32-bit machine.config.
        $Framework,
        
        [Switch]
        # Set the connection string in the 64-bit machine.config
        $Framework64
    )
    
    if( -not ($Framework -or $Framework64) )
    {
        Write-Error "You must specify either or both of the Framework or Framework64 flags."
        return
    }
    
    $command = {
        param(
            $Name,
            $Value
        )
        
        Add-Type -AssemblyName System.Configuration

        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        $connectionStrings = $config.ConnectionStrings.ConnectionStrings
        if( $connectionStrings[$Name] )
        {
            $connectionStrings[$Name].ConnectionString = $Value
        }
        else
        {
            $connectionString = New-Object Configuration.ConnectionStringSettings $Name,$Value
            $connectionStrings.Add( $connectionString )
        }
        $config.Save()
    }

    if( $Framework )
    {    
        Invoke-PowerShell -Command $command -Args $Name,$Value -x86
    }
    
    if( $Framework64 )
    {
        Invoke-PowerShell -Command $command -Args $Name,$Value
    }
}
