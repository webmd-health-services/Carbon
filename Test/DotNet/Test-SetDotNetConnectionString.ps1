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
$connectionStringName = "TEST_CONNECTION_STRING_NAME"
$connectionStringValue = "TEST_CONNECTION_STRING_VALUE"
$connectionStringNewValue = "TEST_CONNECTION_STRING_NEW_VALUE"
$providerName = 'Carbon.Set-DotNetConnectionString'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-ConnectionStrings    
}

function Stop-Test
{
    Remove-ConnectionStrings
}

function Remove-ConnectionStrings
{
    $command = @"
        
        Add-Type -AssemblyName System.Configuration
        
        `$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        `$connectionStrings = `$config.ConnectionStrings.ConnectionStrings
        if( `$connectionStrings['$connectionStringName'] )
        {
            `$connectionStrings.Remove( '$connectionStringName' )
            `$config.Save()
        }
"@
    
    if( (Test-DotNet -V2) )
    {
        Invoke-PowerShell -Command $command -Encode -x86 -Runtime v2.0 -NoWarn
        Invoke-PowerShell -Command $command -Encode -Runtime v2.0 -NoWarn
    }

    if( (Test-DotNet -V4 -Full) )
    {
        Invoke-PowerShell -Command $command -Encode -x86 -Runtime v4.0 -NoWarn
        Invoke-PowerShell -Command $command -Encode -Runtime v4.0 -NoWarn
    }
}

function Test-ShouldUpdateDotNet2x86MachineConfig
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
}

function Test-ShouldUpdateDotNet2x64MachineConfig
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr2
}

function Test-ShouldUpdateDotNet4x86MachineConfig
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr4
}

function Test-ShouldUpdateDotNet4x64MachineConfig
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
}

function Test-ShouldUpdateConnectionString
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Clr2 
}

function Test-ShouldAddProviderName
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
}

function Test-ShouldClearProviderName
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
}

function Test-ShouldUpdateProviderName
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4

    $newProviderName = '{0}.{0}' -f $providerName
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $newProviderName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $newProviderName -Framework64 -Clr4
}

function Test-ShouldRequireAFrameworkFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Clr2 -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Framework and Framework64 switches.'
}

function Test-ShouldRequireAClrFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Clr2 and Clr4 switches.'    
}

function Test-ShouldAddConnectionStringWithSensitiveCharacters
{
    $name = $value = $providerName = '`1234567890-=qwertyuiop[]\a sdfghjkl;''zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?'
    Set-DotNetConnectionString -Name $name -Value $value -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $name -Value $value -ProviderName $providerName -Framework64 -Clr4
}

function Assert-ConnectionString
{
    param(
        $Name, 
        
        $value, 

        $ProviderName,
        
        [Switch]
        $Framework, 
        
        [Switch]
        $Framework64, 
        
        [Switch]
        $Clr2, 
        
        [Switch]
        $Clr4
    )

    $Name = $Name -replace "'","''"

    $command = @"
        
        Add-Type -AssemblyName System.Configuration
        
        `$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        `$connectionStrings = `$config.ConnectionStrings.ConnectionStrings
        
        if( `$connectionStrings['$Name'] )
        {
            `$connectionStrings['$Name']
        }
        else
        {
            `$null
        }
"@
    
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
    
    $runtimes | 
        ForEach-Object {
            $params = @{
                Command = $command
                Encode = $true
                Runtime = $_
                OutputFormat = 'XML'
            }

            if( $Framework )
            {
                Invoke-PowerShell @params -x86 -NoWarn
            }

            if( $Framework64 )
            {
                Invoke-PowerShell @params -NoWarn
            }
        } | 
        ForEach-Object {
            Assert-Equal $Value $_.ConnectionString
            if( $ProviderName )
            {
                Assert-Equal $ProviderName $_.ProviderName
            }
            else
            {
                Assert-Empty $_.ProviderName
            }        
        }
}

