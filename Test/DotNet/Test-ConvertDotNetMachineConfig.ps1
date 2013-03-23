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

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
	
	$transform = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" xdt:Locator="Match(name)" xdt:Transform="Remove" />
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
</configuration>
'@
	
	$removeTransform = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" xdt:Locator="Match(name)" xdt:Transform="Remove" />
	</connectionStrings>
</configuration>
'@
	 Convert-DotNetMachineConfig -Transform $removeTransform -Framework -Framework64 -Clr2 -Clr4
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldConvertMachineConfigDotNet2Net4x32x64
{
    Convert-DotNetMachineConfig -Transform $transform -Framework -Framework64 -Clr2 -Clr4
	Assert-ConnectionString -Name "MyDB" -Value "some value" -Framework -Framework64 -Clr2 -Clr4
}

function Assert-ConnectionString($Name, $value, [Switch]$Framework, [Switch]$Framework64, [Switch]$Clr2, [Switch]$Clr4)
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        $connectionStrings = $config.ConnectionStrings.ConnectionStrings
        
        if( $connectionStrings[$Name] )
        {
            $connectionStrings[$Name].ConnectionString
        }
        else
        {
            $null
        }
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
    
    if( $runtimes.Length -eq 0 )
    {
        throw "Must supply either or both the Clr2 and Clr2 switches."
    }
    
    $runtimes | ForEach-Object {
        $params = @{
            Command = $command
            Args = $Name
            Runtime = $_
        }

        if( $Framework64 )
        {
			$actualValue = Invoke-PowerShell @params
            Assert-Equal $Value $actualValue
        }
        
        if( $Framework )
        {
			$actualValue = Invoke-PowerShell @params -x86
            Assert-Equal $Value $actualValue
        }
    }
}

