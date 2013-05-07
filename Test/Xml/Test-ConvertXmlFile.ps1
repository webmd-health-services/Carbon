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

$tempDir = $null
$xmlFilePath = $null
$xdtFilePath = $null
$resultFilePath = $null

function Setup()
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
	
    $tempDir = New-TempDirectory -Prefix 'Carbon-Test-ConvertXmlFile'
	# create a valid base file
	# create test files
	
    $xmlFilePath = Join-Path $tempDir 'in.xml'
    $xdtFilePath = Join-Path $tempDir 'xdt.xml'
    $resultFilePath = Join-Path $tempDir 'out.xml'
}

function TearDown()
{
    if( (Test-Path -Path $tempDir -PathType Container ) )
    {
        Remove-Item $tempDir -Recurse
    }
        
	Remove-Module Carbon
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

function Test-ShouldConvertXmlFileUsingFilesAsInputs
{
    Set-XmlFile	
    Set-XdtFile	
	
	# act
	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath

    Assert-XmlTransformed
}

function Test-ShouldAllowUsersToLoadCustomTransforms
{
    $carbonTestAssemblyPath = Join-Path $TestDir ..\..\Source\Test\bin\Debug\Carbon.Test.dll -Resolve

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
	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath 
	
	# assert
	$newContext = (Get-Content $resultFilePath) -join "`n"
	
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
	Assert-True ($newContext -match '<add name="PreexistingDB" />')
	Assert-True ($newContext -match '<two\.two/>')
	Assert-True ($newContext -match '<three/>')
}

function Test-ShouldAllowRawXdtXml
{
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

    Assert-Null (Get-ChildItem -Path $env:TEMP -Filter 'Carbon_Convert-XmlFile-*')
	
	# assert
    Assert-XmlTransformed
}

function Test-ShouldGiveAnErrorIfTransformingInPlace
{
    $error.Clear()
    $null = New-Item -Path $xmlFilePath,$xdtFilePath -ItemType File
    Assert-FileDoesNotExist $resultFilePath
    Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $xmlFilePath -ErrorAction SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-True ($error[0].ErrorDetails.Message -like '*Path is the same as Destination*')
    Assert-FileDoesNotExist $resultFilePath
}

function Test-ShouldNotLockFiles
{
    Set-XmlFile
    Set-XdtFile

    Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath

    Assert-XmlTransformed

    $error.Clear()

    '' > $xmlFilePath
    '' > $xdtFilePath
    '' > $resultFilePath

    Assert-Equal 0 $error.Count
    Assert-Equal '' (Get-Content -Path $xmlFilePath)
    Assert-Equal '' (Get-Content -Path $xdtFilePath)
    Assert-Equal '' (Get-Content -Path $resultFilePath)

}

function Test-ShouldSupportShouldProcess
{
    Set-XmlFile
    Set-XdtFile

    Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -WhatIf

    Assert-FileDoesNotExist $resultFilePath
}

function Test-ShouldFailIfDestinationExists
{
    Set-XmlFile
    Set-XdtFile
    '' > $resultFilePath

    $error.Clear()
    Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -ErrorAction SilentlyContinue

    Assert-Equal 1 $error.Count
    Assert-True ($error[0].ErrorDetails.Message -like '*Destination ''*'' exists*')
    Assert-Equal '' (Get-Content -Path $resultFilePath)
}

function Test-ShouldOverwriteDestination
{
    Set-XmlFile
    Set-XdtFile
    '' > $resultFilePath

    $error.Clear()
    Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -Force

    Assert-Equal 0 $error.Count
    Assert-XmlTransformed
}
function Assert-XmlTransformed
{
    Assert-FileExists $resultFilePath
	
	# assert
	$newContext = Get-Content $resultFilePath
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')    
}