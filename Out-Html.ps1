################################################################################
# Out-HTML - converts module functions or cmdlet help to HTML format
# Minor modification of Vegard Hamar's OUT-HTML to support modules instead of pssnapin's
# Based on Out-wiki by Dimitry Sotnikov (http://dmitrysotnikov.wordpress.com/2008/08/18/out-wiki-convert-powershell-help-to-wiki-format/)
#
# Modify the invocation line at the bottom of the script if you want to document 
# fewer command, subsets or snapins
# Open default.html to view in frameset or index.html for index page with links.
################################################################################
# Created By: Vegard Hamar
################################################################################

[CmdletBinding()]
param(
    [string]
    # The path where the help should be put.
    $OutputDir = "./help"
)

#Set-StrictMode -Version Latest
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Definition

if( (Get-Module Carbon) )
{
    Remove-Module Carbon
}
Import-Module (Join-Path $PSScriptRoot Carbon)

Add-Type -AssemblyName System.Web

filter Format-ForHtml 
{
    if( $_ )
    {
        [Web.HttpUtility]::HtmlEncode($_)
    }
}

filter Out-HtmlString
{
    $_ | 
        Out-String -Width ([Int32]::MaxValue) | 
        ForEach-Object { $_.Trim() } | 
        Format-ForHtml
}


filter Convert-HelpToHtml 
{
	param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The command to document.
        $CommandHelp,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The menu to show on every page.
        $Menu
    )

    $name = $CommandHelp.Name #| Format-ForHtml
    $synopsis = $CommandHelp.Synopsis #| Format-ForHtml
    $syntax = $CommandHelp.Syntax | Out-HtmlString
    $description = $CommandHelp.Description #| Format-ForHtml
    $relatedCommands = $CommandHelp.RelatedLinks | Out-HtmlString
    if( $relatedCommands )
    {
        $relatedCommands = @"
        <h2>Related Commands</h2>
        {0}
"@ -f ($relatedCommands -join '<br>')
    }
    
    $parameters = $CommandHelp.Parameters.Parameter |
        ForEach-Object {
            @"
			<tr valign='top'>
				<td>{0}</td>
				<td>{1}</td>
				<td>{2}</td>
				<td>{3}</td>
				<td>{4}</td>
                <td>{5}</td>
			</tr>
"@ -f $_.Name,$_.type.name,($_.Description | Out-HtmlString),$_.Required,$_.PipelineInput,$_.DefaultValue
        }
        
    if( $parameters )
    {
        $parameters = @"
		<h2> Parameters </h2>
		<table border='1'>
			<tr>
				<th>Name</th>
                <th>Type</th>
				<th>Description</th>
				<th>Required?</th>
				<th>Pipeline Input</th>
				<th>Default Value</th>
			</tr>
            {0}
        </table>
"@ -f ($parameters -join "`n")
    }

    $inputTypes = $CommandHelp.inputTypes | Out-HtmlString
    if( $inputTypes )
    {
        $inputTypes = @"
        <h2>Input Type</h2>
        <div>{0}</div>
"@ -f $inputTuypes
    }
    
    $returnValues = $commandHelp.returnValues | Out-HtmlString
    if( $returnValues )
    {
        $returnValues = @"
        <h2>Return Values</h2>
        <div>{0}</div>
"@ -f $returnValues
    }
    
    $notes = $CommandHelp.AlertSet | Out-HtmlString
    if( $notes )
    {
        $notes = @"
        <h2>Notes</h2>
        <div>{0}</div>
"@ -f $notes
    }
    
    $examples = $CommandHelp.Examples.example |
        Where-Object { $_ } |
        ForEach-Object {
            @"
            <h2>{0}</h2>
            <pre><code>{1}</code></pre>
            <p>{2}</p>
"@ -f $_.title.Trim(('-',' ')),($_.code | Out-HtmlString),(($_.remarks | Out-HtmlString) -join '</p><p>')
        }
    
@"
<html>
	<head>
		<title>$name</title>
	</head>
	<body>
        $Menu
        
		<h1>$name</h1>
		<div>$synopsis</div>

		<h2>Syntax</h2>
        <pre><code>
$syntax
        </code></pre>

		<h2>Description</h2>
		<div>$description</div>

        $relatedCommands

        $parameters
        
        $inputTypes
        
        $returnValues
        
        $notes
        
        $examples
"@ | Out-File -FilePath (Join-Path $OutputDir ("{0}.html" -f $CommandHelp.Name)) -Encoding OEM

<#
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
#>
}

filter Get-Functions
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The file to parse for functions
        $Path
    )
    
    Write-Verbose "Loading script '$Path'."
    $scriptContent = Get-Content "$Path"
    if( -not $scriptContent )
    {
        return @()
    }

    $errors = [Management.Automation.PSParseError[]] @()
    $tokens = [System.Management.Automation.PsParser]::Tokenize( $scriptContent, [ref] $errors )
    if( $errors -ne $null -and $errors.Count -gt 0 )
    {
        Write-Error "Found $($errors.count) error(s) parsing '$Path'."
        return
    }
    
    Write-Verbose "Found $($tokens.Count) tokens in '$Path'."
    
    for( $idx = 0; $idx -lt $tokens.Count; ++$idx )
    {
        $token = $tokens[$idx]
        if( $token.Type -eq 'Keyword'-and ($token.Content -eq 'Function' -or $token.Content -eq 'Filter') )
        {
            $atFunction = $true
        }
        
        if( $atFunction -and $token.Type -eq 'CommandArgument' -and $token.Content -ne '' )
        {
            Write-Verbose "Found function '$($token.Content).'"
            $token.Content
            $atFunction = $false
        }
    }
}


if( (Test-Path $OutputDir -PathType Container) )
{
    Remove-Item -Path $OutputDir -Recurse -Force
}

$commands = Get-Command | Where-Object { $_.ModuleName -eq 'Carbon'} | Sort-Object Name 

$categories = New-Object 'Collections.Generic.SortedList[string,object]'
Get-ChildItem (Join-Path $PSScriptRoot Carbon\*.ps1) | 
    Sort-Object BaseName |
    ForEach-Object { 
        $currentFile = $_.BaseName
        $categories[$currentFile] = New-Object 'Collections.ArrayList'
        $_ | Get-Functions | Sort-Object | ForEach-Object { 
            [void] $categories[$currentFile].Add($_) 
        }
    }
$categories    

$menuBuilder = New-Object Text.StringBuilder
[void] $menuBuilder.AppendLine( '<div id="CommandMenuContainer" style="float:left;">' )
[void] $menuBuilder.AppendLine( "`t<ul id=""CategoryMenu"">" )
$categories.Keys | ForEach-Object {
    [void] $menuBuilder.AppendFormat( '{0}{0}<li class="Category">{1}</li>{2}', "`t",$_,"`n" )
    [void] $menuBuilder.AppendFormat( "`t`t<ul class=""CommandMenu"">`n" )
    $categories[$_] | ForEach-Object {
        [void] $menuBuilder.AppendFormat( '{0}{0}{0}<li><a href="{1}.html">{1}</a></li>{2}', "`t",$_,"`n" )
    }
    [void] $menuBuilder.AppendFormat( "`t`t</ul>`n" )
}
[void] $menuBuilder.AppendLine( "`t</ul>" )
[void] $menuBuilder.AppendLine( '</div>' )

New-Item $outputDir -ItemType Directory -Force 

$commands | Get-Help -Full | Convert-HelpToHtml -Menu $menuBuilder.ToString()

