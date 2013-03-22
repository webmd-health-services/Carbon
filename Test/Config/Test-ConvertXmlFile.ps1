
function Setup()
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
	
	# create a valid base file
	# create test files
	
	$testFileAPath = (Join-Path $TestDir .\Ain.xml)
	$xdtFileAPath =  (Join-Path $TestDir .\Axdt.xml)
	$testFileBPath = (Join-Path $TestDir .\Bin.xml)
	$testFileDPath = (Join-Path $TestDir .\Din.xml)
}

#TODO: add test for various combinations xdt:Locator="XPath(/configuration/connectionStrings/add[@name="MyDB"]"

function TearDown()
{	
	#Remove-Item $testFileAPath -EA SilentlyContinue
	#Remove-Item $xdtFileAPath -EA SilentlyContinue
    #Remove-Item $testFileBPath -EA SilentlyContinue
	#Remove-Item (Join-Path $TestDir .\Cout.xml) -EA SilentlyContinue
    #Remove-Item $testFileDPath -EA SilentlyContinue
        
	Remove-Module Carbon
}

function Test-ShouldConvertXmlFileUsingFilesAsInputs
{
	# arrange
    $moduleInfo = Get-Module -Name Carbon
    Assert-NotNull $moduleInfo
	
	$testFileAContent = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
	</connectionStrings>
</configuration>
'@
    $testFileAContent > $testFileAPath
	
	
	$xdtFileAContent = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
</configuration>
'@
    $xdtFileAContent > $xdtFileAPath
	
	# act
	Convert-XmlFile -Path $testFileAPath -XdtPath $xdtFileAPath -Destination (Join-Path $TestDir .\Aout.xml) -SkipIdempotencyCheck
	
	# assert
	$newContext = get-content (Join-Path $TestDir .\Aout.xml)
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
}

function Test-ShouldConvertXmlFileUsingTransformationAsString
{
	# arrange
    $moduleInfo = Get-Module -Name Carbon
    Assert-NotNull $moduleInfo
	
	$testFileBContent = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
	</connectionStrings>
</configuration>
'@
    $testFileBContent > $testFileBPath
	
	$transform = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
</configuration>
'@
	
	# act
	Convert-XmlFile -Path $testFileBPath -Transform $transform -Destination (Join-Path $TestDir .\Bout.xml) -SkipIdempotencyCheck
	
	# assert
	$newContext = get-content (Join-Path $TestDir .\Bout.xml)
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
}

function Test-ShouldConvertXmlAndOverwriteFile
{
	# arrange
    $moduleInfo = Get-Module -Name Carbon
    Assert-NotNull $moduleInfo
	
	$testFileDContent = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
	</connectionStrings>
</configuration>
'@
    $testFileDContent > $testFileDPath
	
	$transform = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
</configuration>
'@
	
	# act
	Convert-XmlFile -Path $testFileDPath -Transform $transform  -SkipIdempotencyCheck
	
	# assert
	$newContext = get-content (Join-Path $TestDir .\Din.xml)
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
}

function Test-ShouldConvertXmlFileUsingIdempotencyCheck
{
	# arrange
    $moduleInfo = Get-Module -Name Carbon
    Assert-NotNull $moduleInfo
	
	$testFileBContent = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
	</connectionStrings>
</configuration>
'@
    $testFileBContent > $testFileBPath
	
	$transform = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" xdt:Locator="Match(name)" xdt:Transform="Remove" />
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
</configuration>
'@
	
	# act
	Convert-XmlFile -Path $testFileBPath -Transform $transform -Destination (Join-Path $TestDir .\Cout.xml)
	
	# assert
	$newContext = get-content (Join-Path $TestDir .\Cout.xml)
	
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
}

function Test-ShouldConvertXmlFileUsingMerge
{
	# arrange
    $moduleInfo = Get-Module -Name Carbon
    Assert-NotNull $moduleInfo
	
	$testFileBContent = @'
<?xml version="1.0"?>
<configuration>
</configuration>
'@
    $testFileBContent > $testFileBPath
	
	$transform = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings xdt:Transform="Merge">
		
	</connectionStrings>
</configuration>
'@
	
	# act
	Convert-XmlFile -Path $testFileBPath -Transform $transform -Destination (Join-Path $TestDir .\Cout.xml)# -SkipIdempotencyCheck
	
	# assert
	$newContext = get-content (Join-Path $TestDir .\Cout.xml)
	
	Write-Output $newContent
	
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
}

function Test-ShouldCompareXmlAndDetectAreSame
{
	[xml]$expected = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
		<add name="MyDB" connectionString="some value"/>
	</connectionStrings>
</configuration>
'@
		
	[xml]$expected2 = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
		<add name="MyDB" connectionString="some other value"/>
	</connectionStrings>
</configuration>
'@

	$diff = Compare-Object ($expected.SelectNodes("//*") | Select-Object -Expand Name) ($expected2.SelectNodes("//*") | Select-Object -Expand Name)
	
	Assert-IsNull $diff
}

function Test-ShouldCompareXmlAndDetectDifferences
{
	[xml]$expected = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
		<add name="MyDB" connectionString="some value"/>
	</connectionStrings>
</configuration>
'@
		
	[xml]$expected2 = @'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
		<add name="MySSSDB" connectionString="some other value"/>
	</connectionStrings>
</configuration>
'@

	$diff = Compare-Object ($expected.SelectNodes("//*") | Select-Object -Expand Name) ($expected2.SelectNodes("//*") | Select-Object -Expand Name)
	
	Assert-NotNull $diff
}
#function Test-ConvertXmlFileShouldFailIfPathDoesNotExist
#{
#    $moduleInfo = Get-Module -Name Carbon
#    Assert-NotNull $moduleInfo
#	
#	Convert-XmlFile -Path "C:\$([Guid]::NewGuid())" -ErrorAction SilentlyContinue
#	Assert-Equal 1 $error.Count
#}