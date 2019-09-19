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

Set-StrictMode -Version 'Latest'

$chocolateyUninstall = Join-Path -Path $PSScriptRoot -ChildPath '..\tools\chocolateyUninstall.ps1' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-CarbonRemoved
{
    param(
        $CarbonRoot
    )

    foreach( $root in $CarbonRoot )
    {
        It ('should remove Carbon module directory ''{0}''' -f $root) {
            $root | Should Not Exist
        }
    }
}

function Assert-CarbonNotInstalled 
{
    It 'should uninstall Carbon from all module paths' {
        Get-Item -Path 'env:PSModulePath' |
            Select-Object -ExpandProperty 'Value' -ErrorAction Ignore |
            ForEach-Object { $_ -split ';' } |
            Where-Object { $_ } |
            Join-Path -ChildPath 'Carbon*' |
            Should Not Exist
        }
}

function MockCarbonInstalled
{
    $testDriveRoot =  Microsoft.PowerShell.Management\Get-Item -Path 'TestDrive:'
    $modulesRoot = Join-Path -Path $testDriveRoot.FullName -ChildPath 'Modules'
    $modulesRoot2 = Join-Path -Path $testDriveRoot.FullName -ChildPath 'Modules2'
    $modulesRoot,$modulesRoot2 | ForEach-Object { Install-Directory -Path $_ }
    $carbonRoot = Join-Path -Path $modulesRoot -ChildPath 'Carbon'
    $carbonRoot2 = Join-Path -Path $modulesRoot2 -ChildPath 'Carbon'

    robocopy (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve) $carbonRoot /MIR | Write-Debug
    robocopy (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve) $carbonRoot2 /MIR | Write-Debug

    Mock 'Get-Item' -Verifiable -MockWith {
        $testDriveRoot =  Microsoft.PowerShell.Management\Get-Item -Path 'TestDrive:'
        $modulesRoot = Join-Path -Path $testDriveRoot.FullName -ChildPath 'Modules'
        $modulesRoot2 = Join-Path -Path $testDriveRoot.FullName -ChildPath 'Modules2'
        return [pscustomobject]@{ Name = 'PSModulePath'; Value = ('{0};{1};;;'-f $modulesRoot,$modulesRoot2) }
    } -ParameterFilter {
        $Path -eq 'env:PSModulePath'
    }
    
    return $carbonRoot,$carbonRoot2
}

Describe 'chocolateyUninstall.ps1 when module is installed' {

    $carbonRoot = MockCarbonInstalled
    $paths = Get-Item 'env:PSModulePath'
    & $chocolateyUninstall
    Assert-CarbonRemoved $carbonRoot
    Assert-CarbonNotInstalled
}

Describe 'chocolateyUninstall.ps1 when module is installed and in use' {
    $Global:Error.Clear()

    $carbonRoot = MockCarbonInstalled

    $preCount = $carbonRoot | Get-ChildItem  -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    
    $file = & {
                    Join-Path -Path $carbonRoot -ChildPath 'bin\fullclr\Carbon.dll' -Resolve 
                    Join-Path -Path $carbonRoot -ChildPath 'bin\coreclr\Carbon.dll' -Resolve 
                } |
                ForEach-Object { [IO.File]::Open($_, 'Open', 'Read', 'Read') }
    try
    {
        & $chocolateyUninstall
    }
    catch
    {
    }
    finally
    {
        $file | ForEach-Object { $_.Close() }
    }

    It 'should write an error' {
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error | Should Match 'access\ to\ the\ path\ .*\ is\ denied'
    }

    $carbonRoot | Should Exist
    
    # Make sure no files were deleted during a failed uninstall
    $postCount = $carbonRoot | Get-ChildItem -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    It 'should not delete any files' {
        $postCount | Should Be $preCount
    }
}

Describe 'chocolateyUninstall.ps1 when the module isn''t installed' {

    $Global:Error.Clear()

    $carbonRoot = MockCarbonInstalled
    & $chocolateyUninstall
    Assert-CarbonRemoved $carbonRoot
    Assert-CarbonNotInstalled
    & $chocolateyUninstall
        
    & $chocolateyUninstall
    It 'should not write an error' {
        $Global:Error | Should BeNullOrEmpty
    }
    Assert-CarbonNotInstalled
}
