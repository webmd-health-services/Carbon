################################################################################
# Out-HTML - converts module functions or cmdlet help to HTML format
# Minor modification of Vegard Hamar's OUT-HTML to support modules instead of pssnapin's
# Based on Out-wiki by Dimitry Sotnikov (http://dmitrysotnikov.wordpress.com/2008/08/18/out-wiki-convert-powershell-help-to-wiki-format/)
#
# Modify the invocation line at the bottom of the script if you want to document 
# fewer command, subsets or snapins
# Open default.htm to view in frameset or index.htm for index page with links.
################################################################################
# Created By: Vegard Hamar
################################################################################

param($outputDir = "./help")

function FixString {
	param($in = "")
	if ($in -eq $null) {
		$in = ""
	}
	return $in.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
}

function Out-HTML {
	param($commands = $null, $outputDir = "./help")

	$commandsHelp = $commands | sort-object modulename, name | get-help -full

	#create an output directory
	if ( -not (Test-Path $outputDir)) {
		md $outputDir | Out-Null
	}

	#Generate frame page
	$indexFileName = $outputDir + "/index.htm"
	
	#Generate frameset
@'
<html>
	<head>
		<title>PowerShell Help</title>
	</head>
	<frameset cols="250,*">
		<frame src="./index.htm" />
		<frame src="" name="display"/>
	</frameset>
</html>
'@ | Out-File "$outputDir/default.htm"

	#Generate index
@'
<html>
	<head>
		<title>PowerShell Help</title>
	</head>
	<body>
'@  | out-file $indexFileName

	$SnapIn = ""
	foreach ($c in $commandsHelp) {
		if ($SnapIn -ne $c.modulename) {
			"<a href='#" + $c.modulename + "'>* " + $c.modulename.Replace(".", " ") + "</a></br>"   | out-file $indexFileName -Append
			$SnapIn = $c.modulename
		}
	}

	$SnapIn = ""
	foreach ($c in $commandsHelp) {
		if ($SnapIn -ne $c.modulename) {
			"<h3><a name='$($c.modulename)'>" +$c.modulename.Replace(".", " ") + "</a></h3>" | Out-File $indexFileName -Append
			$SnapIn = $c.modulename
		}
		"<a href='" + $c.name + ".htm' target='display'>* $($c.Name)</a></br>"   | out-file $indexFileName -Append
	}

	#Generate all single help files
	$outputText = $null
	foreach ($c in $commandsHelp) {
		$fileName = ( $outputDir + "/" + $c.Name + ".htm" )

@"
<html>
	<head>
		<title>$($c.Name)</title>
	</head>
	<body>
		<h1>$($c.Name)</h1>
		<div>$($c.synopsis)</div>

		<h2> Syntax </h2>
		<code>$(FixString($c.syntax | out-string  -width 2000).Trim())</code>  

		<h2> Detailed Description </h2>
		<div>$(FixString($c.Description  | out-string  -width 2000))</div>

		<h2> Related Commands </h2>
		<div>
"@ | out-file $fileName 
		foreach ($relatedLink in $c.relatedLinks.navigationLink) {
			if($relatedLink.linkText -ne $null -and $relatedLink.linkText.StartsWith("about") -eq $false){
				"			* <a href='$($relatedLink.linkText).htm'>$($relatedLink.linkText)</a><br/>" | out-file $fileName -Append         
			}
		}
	  
@"
		</div>
		<h2> Parameters </h2>
		<table border='1'>
			<tr>
				<th>Name</th>
				<th>Description</th>
				<th>Required?</th>
				<th>Pipeline Input</th>
				<th>Default Value</th>
			</tr>
"@   | out-file $fileName -Append

		$paramNum = 0
		foreach ($param in $c.parameters.parameter ) {
@"
			<tr valign='top'>
				<td>$($param.Name)&nbsp;</td>
				<td>$(FixString(($param.Description  | out-string  -width 2000).Trim()))&nbsp;</td>
				<td>$(FixString($param.Required))&nbsp;</td>
				<td>$(FixString($param.PipelineInput))&nbsp;</td>
				<td>$(FixString($param.DefaultValue))&nbsp;</td>
			</tr>
"@  | out-file $fileName -Append
		}
		"		</table>}"  | out-file $fileName -Append
   
		# Input Type
		if (($c.inputTypes | Out-String ).Trim().Length -gt 0) {
@"
		<h2> Input Type </h2>
		<div>$(FixString($c.inputTypes  | out-string  -width 2000).Trim())</div>
"@  | out-file $fileName -Append
		}
   
		# Return Type
		if (($c.returnValues | Out-String ).Trim().Length -gt 0) {
@"
		<h2> Return Values </h2>
		<div>$(FixString($c.returnValues  | out-string  -width 2000).Trim())</div>
"@  | out-file $fileName -Append
		}
          
		# Notes
		if (($c.alertSet | Out-String).Trim().Length -gt 0) {
@"
		<h2> Notes </h2>
			"<div>$(FixString($c.alertSet  | out-string -Width 2000).Trim())</div>
"@  | out-file $fileName -Append
		}
   
		# Examples
		if (($c.examples | Out-String).Trim().Length -gt 0) {
			"		<h2> Examples </h2>"  | out-file $fileName -Append      
			foreach ($example in $c.examples.example) {
@"
		<h3> $(FixString($example.title.Trim(('-',' '))))</h3>
				<pre>$(FixString($example.code | out-string ).Trim())</pre>
				<div>$(FixString($example.remarks | out-string -Width 2000).Trim())</div>
"@  | out-file $fileName -Append
			}
		}
@"
	</body>
</html>
"@ | out-file $fileName -Append
	}
@"
	</body>
</html>
"@ | out-file $indexFileName -Append
}

if( (Get-Module Carbon) )
{
    Remove-Module Carbon
}

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Definition

Import-MOdule (Join-Path $PSScriptRoot Carbon)

Out-HTML ( get-command | where {$_.modulename -eq 'Carbon'}) $outputDir