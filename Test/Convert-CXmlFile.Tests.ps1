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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    $script:testDir = $null
    $script:testNum = 0
    $script:xmlFilePath = $null
    $script:xdtFilePath = $null
    $script:resultFilePath = $null

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function Assert-XmlTransformed
    {
        $script:resultFilePath | Should -Exist

        # assert
        $newContext = Get-Content -Path $script:resultFilePath -Raw
        $newContext | Should -Match '<add name="MyDB" connectionString="some value"/>'
    }

    function Set-XmlFile
    {
        @'
<?xml version="1.0"?>
<configuration>
    <connectionStrings>
    </connectionStrings>
</configuration>
'@ | Set-Content -Path $script:xmlFilePath
    }

    function Set-XdtFile
    {
        @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <connectionStrings>
        <add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>
</configuration>
'@ | Set-Content -Path $script:xdtFilePath
    }
}

Describe 'Convert-XmlFile' {
    # Can't build the assembly with a custom transform on Appveyor's Windows 2012 R2 images.
    $os = Get-CimInstance Win32_OperatingSystem
    $skip = $os.Caption -like '*2012 R2*'

    BeforeEach {
        $script:testDir = Join-Path -Path $TestDrive -ChildPath $testNum
        New-Item -Path $testDir -ItemType Directory
        $script:xmlFilePath = Join-Path -Path $testDir -ChildPath 'in.xml'
        $script:xdtFilePath = Join-Path -Path $testDir -ChildPath 'xdt.xml'
        $script:resultFilePath = Join-Path -Path $testDir -ChildPath 'out.xml'

        Set-XmlFile
        Set-XdtFile

        $Global:Error.Clear()
    }

    AfterEach {
        $script:testNum += 1

        $Global:Error | Format-List * -Force
    }


    It 'should convert xml file using files as inputs' {
        Convert-XmlFile -Path $script:xmlFilePath -XdtPath $script:xdtFilePath -Destination $script:resultFilePath
        Assert-XmlTransformed
    }

    It 'should allow users to load custom transforms' -Skip:$skip {
        $testBinPath = Join-Path -Path $PSScriptRoot -ChildPath 'bin'
        Install-CDirectory $testBinPath

        $carbonTestAssemblyPath = Join-Path -Path $testBinPath `
                                            -ChildPath "Carbon.Test.Xdt.$($PSVersionTable['PSEdition']).dll"
        if (-not (Test-Path -Path $carbonTestAssemblyPath))
        {
            # We do this in a background job because `Add-Type` also loads the assembly into memory, which we don't
            # want.
            Start-Job -ScriptBlock {
                $scriptRoot = $using:PSScriptRoot
                $outputAssembly = $using:carbonTestAssemblyPath
                $mergeCsPath = Join-Path -Path $scriptRoot -ChildPath '..\Source\Test\Xdt\Merge.cs' -Resolve
                $carbonBinPath = Join-Path -Path $scriptRoot -ChildPath '..\Carbon\bin' -Resolve
                $msWebXmlTransformAssemblyPath =
                    Join-Path -Path $carbonBinPath -ChildPath 'fullclr\Microsoft.Web.XmlTransform.dll' -Resolve
                $IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
                if ($IsPSCore)
                {
                    $msWebXmlTransformAssemblyPath =
                        Join-Path -Path $carbonBinPath -ChildPath 'coreclr\Microsoft.Web.XmlTransform.dll' -Resolve
                }

                $referencedAssemblies = @(
                    $msWebXmlTransformAssemblyPath,
                    'netstandard',
                    'System',
                    'System.Collections',
                    'System.Linq',
                    'System.Xml',
                    'System.Xml.Linq',
                    'System.Xml.ReaderWriter'
                )
                Add-Type -TypeDefinition (Get-Content -Raw -Path $mergeCsPath) `
                         -OutputAssembly $outputAssembly `
                         -OutputType Library `
                         -ReferencedAssemblies $referencedAssemblies
            } | Receive-Job -Wait -AutoRemoveJob
        }

        @'
<?xml version="1.0"?>
<configuration>
    <connectionStrings>
        <add name="PreexistingDB" />
    </connectionStrings>

    <one>
        <two>
            <two.two />
        </two>
        <three />
    </one>
</configuration>
'@ | Set-Content -Path $script:xmlFilePath

        @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <xdt:Import path="{0}" namespace="Carbon.Test.Xdt"/>

    <connectionStrings xdt:Transform="Merge" >
        <add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>

    <one xdt:Transform="Merge">
        <two xdt:Transform="Merge">
        </two>
    </one>

</configuration>
'@ -f $carbonTestAssemblyPath | Set-Content -Path $script:xdtFilePath

        # act
        Convert-XmlFile -Path $script:xmlFilePath `
                        -XdtPath $script:xdtFilePath `
                        -Destination $script:resultFilePath `
                        -TransformAssemblyPath @( $carbonTestAssemblyPath )

        # assert
        $newContext = (Get-Content $script:resultFilePath) -join "`n"

        $newContext | Should -Match '<add name="MyDB" connectionString="some value"/>'
        $newContext | Should -Match '<add name="PreexistingDB" />'
        $newContext | Should -Match '<two\.two ?/>'
        $newContext | Should -Match '<three ?/>'
    }

    It 'should allow raw xdt xml' {
        $xdt = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <connectionStrings>
        <add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>
</configuration>
'@

        # act
        Convert-XmlFile -Path $script:xmlFilePath -XdtXml $xdt -Destination $script:resultFilePath

        (Get-ChildItem -Path $env:TEMP -Filter 'Carbon_Convert-XmlFile-*') | Should -BeNullOrEmpty

        # assert
        Assert-XmlTransformed
    }

    It 'should give an error if transforming in place' {
        $script:resultFilePath | Should -Not -Exist
        Convert-XmlFile -Path $script:xmlFilePath `
                        -XdtPath $script:xdtFilePath `
                        -Destination $script:xmlFilePath `
                        -ErrorAction SilentlyContinue
        $Global:Error | Should -HaveCount 1
        $Global:Error | Should -BeLike '*Path is the same as Destination*'
        $script:resultFilePath | Should -Not -Exist
    }

    It 'should not lock files' {
        Convert-XmlFile -Path $script:xmlFilePath -XdtPath $script:xdtFilePath -Destination $script:resultFilePath

        Assert-XmlTransformed

        Clear-Content -Path $script:xmlFilePath, $script:xdtFilePath, $script:resultFilePath

        $Global:Error | Should -BeNullOrEmpty
        (Get-Content -Path $script:xmlFilePath) | Should -BeNullOrEmpty
        (Get-Content -Path $script:xdtFilePath) | Should -BeNullOrEmpty
        (Get-Content -Path $script:resultFilePath) | Should -BeNullOrEmpty

    }

    It 'should support should process' {
        Convert-XmlFile -Path $script:xmlFilePath `
                        -XdtPath $script:xdtFilePath `
                        -Destination $script:resultFilePath `
                        -WhatIf

        $script:resultFilePath | Should -Not -Exist
    }

    It 'should fail if destination exists' {
        New-Item -Path $script:resultFilePath | Out-Null
        Convert-XmlFile -Path $script:xmlFilePath `
                        -XdtPath $script:xdtFilePath `
                        -Destination $script:resultFilePath `
                        -ErrorAction SilentlyContinue

        $Global:Error | Should -HaveCount 1
        $Global:Error | Should -BeLike '*Destination ''*'' exists*'
        (Get-Content -Path $script:resultFilePath) | Should -BeNullOrEmpty
    }

    It 'should overwrite destination' {
        Convert-XmlFile -Path $script:xmlFilePath `
                        -XdtPath $script:xdtFilePath `
                        -Destination $script:resultFilePath `
                        -Force

        $Global:Error | Should -BeNullOrEmpty
        Assert-XmlTransformed
    }

    It 'should fail if transform assembly path not found' {
        Convert-XmlFile -Path $script:xmlFilePath `
                        -XdtPath $script:xdtFilePath `
                        -Destination $script:resultFilePath `
                        -TransformAssemblyPath 'C:\I\Do\Not\Exist' `
                        -ErrorAction SilentlyContinue
        $script:resultFilePath | Should -Not -Exist
        $Global:Error | Should -HaveCount 1
        $Global:Error | Should -BeLike '*not found*'
    }
}
