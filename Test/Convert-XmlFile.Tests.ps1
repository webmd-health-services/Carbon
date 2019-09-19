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

$tempDir = $null
$xmlFilePath = $null
$xdtFilePath = $null
$resultFilePath = $null

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-XmlTransformed
{
    $resultFilePath | Should -Exist
    	
    # assert
    $newContext = Get-Content $resultFilePath
    ($newContext -match '<add name="MyDB" connectionString="some value"/>') | Should -Be $true
}
    
Describe 'Convert-XmlFile' {
    BeforeEach {
        $xmlFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'in.xml'
        $xdtFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'xdt.xml'
        $resultFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'out.xml'
        Get-ChildItem -Path $TestDrive.FullName | Remove-Item 
    }
    
    function Set-XmlFile
    {
    	@'
<?xml version="1.0"?>
<configuration>
    <connectionStrings>
    </connectionStrings>
</configuration>
'@ > $xmlFilePath
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
'@ > $xdtFilePath
    }
    
    It 'should convert xml file using files as inputs' {
        Set-XmlFile	
        Set-XdtFile	
    	
    	# act
    	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath
    
        Assert-XmlTransformed
    }
    
    It 'should allow users to load custom transforms' {
        $carbonTestXdtBinPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Source\Test\Xdt\bin' -Resolve
        $carbonTestAssemblyPath = Join-Path -Path $carbonTestXdtBinPath -ChildPath 'net452' -Resolve

        $IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
        if( $IsPSCore )
        {
            $carbonTestAssemblyPath = Join-Path -Path $carbonTestXdtBinPath -ChildPath 'netstandard2.0' -Resolve
        }

        $carbonTestAssemblyPath = Join-Path -Path $carbonTestAssemblyPath -ChildPath 'Carbon.Test.Xdt.dll' -Resolve
    
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
'@ > $xmlFilePath
    	
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
'@ -f $carbonTestAssemblyPath > $xdtFilePath
    	
    	# act
    	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -TransformAssemblyPath @( $carbonTestAssemblyPath )
    	
    	# assert
    	$newContext = (Get-Content $resultFilePath) -join "`n"
    	
    	($newContext -match '<add name="MyDB" connectionString="some value"/>') | Should -Be $true
    	($newContext -match '<add name="PreexistingDB" />') | Should -Be $true
    	($newContext -match '<two\.two ?/>') | Should -Be $true
    	($newContext -match '<three ?/>') | Should -Be $true
    }
    
    It 'should allow raw xdt xml' {
        Set-XmlFile
    	
    	$xdt = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <connectionStrings>
    	<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>
</configuration>
'@ 
    	
    	# act
    	Convert-XmlFile -Path $xmlFilePath -XdtXml $xdt -Destination $resultFilePath
    
        (Get-ChildItem -Path $env:TEMP -Filter 'Carbon_Convert-XmlFile-*') | Should -BeNullOrEmpty
    	
    	# assert
        Assert-XmlTransformed
    }
    
    It 'should give an error if transforming in place' {
        $error.Clear()
        $null = New-Item -Path $xmlFilePath,$xdtFilePath -ItemType File
        $resultFilePath | Should -Not -Exist
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $xmlFilePath -ErrorAction SilentlyContinue
        $error.Count | Should -Be 1
        ($error[0].ErrorDetails.Message -like '*Path is the same as Destination*') | Should -BeTrue
        $resultFilePath | Should -Not -Exist
    }
    
    It 'should not lock files' {
        Set-XmlFile
        Set-XdtFile
    
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath
    
        Assert-XmlTransformed
    
        $error.Clear()
    
        '' > $xmlFilePath
        '' > $xdtFilePath
        '' > $resultFilePath
    
        $error.Count | Should -Be 0
        (Get-Content -Path $xmlFilePath) | Should -Be ''
        (Get-Content -Path $xdtFilePath) | Should -Be ''
        (Get-Content -Path $resultFilePath) | Should -Be ''
    
    }
    
    It 'should support should process' {
        Set-XmlFile
        Set-XdtFile
    
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -WhatIf
    
        $resultFilePath | Should -Not -Exist
    }
    
    It 'should fail if destination exists' {
        Set-XmlFile
        Set-XdtFile
        '' > $resultFilePath
    
        $error.Clear()
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -ErrorAction SilentlyContinue
    
        $error.Count | Should -Be 1
        ($error[0].ErrorDetails.Message -like '*Destination ''*'' exists*') | Should -BeTrue
        (Get-Content -Path $resultFilePath) | Should -Be ''
    }
    
    It 'should overwrite destination' {
        Set-XmlFile
        Set-XdtFile
        '' > $resultFilePath
    
        $error.Clear()
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -Force
    
        $error.Count | Should -Be 0
        Assert-XmlTransformed
    }
    
    It 'should fail if transform assembly path not found' {
        Set-XmlFile
        Set-XdtFile
        
        $error.Clear()
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -TransformAssemblyPath 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
        $resultFilePath | Should -Not -Exist
        $error.Count | Should -Be 1
        $error[0].Exception.Message | Should -BeLike '*not found*'
    }
    
}
