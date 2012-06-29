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
Add-Type -AssemblyName System.Messaging
Add-Type -Path (Join-Path $PSSCriptRoot Tools\MarkdownSharp\MarkdownSharp.dll)
$markdown = New-Object MarkdownSharp.Markdown
$markdown.AutoHyperlink = $true

$loadedTypes = @{ }
[AppDomain]::CurrentDomain.GetAssemblies() | 
    ForEach-Object { $_.GetTypes() } | 
    ForEach-Object { 
        if( $loadedTypes.ContainsKey( $_.Name ) )
        {
            Write-Verbose ("Found multiple {0} types." -f $_.Name)
        }
        else
        {
            $loadedTypes[$_.Name] = $_.FullName
        }
    }

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
        ForEach-Object { $_.Trim() } 
}

filter Convert-MarkdownToHtml
{
    $markdown.Transform( $_ )
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
    $synopsis = $CommandHelp.Synopsis | Convert-MarkdownToHtml
    $syntax = $CommandHelp.Syntax | Out-HtmlString | Format-ForHtml | ForEach-Object { $_ -split "`n" }
    if( $syntax )
    {
        $syntax = @"
    <h2>Syntax</h2>
    <pre class="Syntax"><code>{0}</code></pre>
"@ -f ($syntax -join "</code></pre>`n<pre class=""Syntax""><code>")
    }
    
    $description = $CommandHelp.Description | Out-HtmlString | Convert-MarkdownToHtml
    if( $description )
    {
        $description = @"
    <h2>Description</h2>
    <div class="Description">
        $description
    </div>
"@
    }
    
    $relatedCommands = $CommandHelp.RelatedLinks |
        Out-String -Width ([Int32]::MaxValue) |
        ForEach-Object { $_ -split "`n" } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        ForEach-Object {
            if( $_ -match '^https?\:\/\/' )
            {
                "[{0}]({1})" -f $_,$_
            }
            else
            {
                "[{0}]({0}.html)" -f $_
            }
        }
    
    if( $relatedCommands )
    {
        $relatedCommands = @( $relatedCommands )
        if( $relatedCommands.Length -gt 0 )
        {
            $relatedCommands = " * {0}" -f ($relatedCommands -join "`n * ")
        }
        $relatedCommands = @"
        <h2>Related Commands</h2>
        {0}
"@ -f ($relatedCommands | Convert-MarkdownToHtml)
    }
    
    $hasCommonParameters = $false
    $parameters = $CommandHelp.Parameters.Parameter |
        Where-Object { $_ } | 
        ForEach-Object {
        $commonParameterNames = @{
                                'Verbose' = $true;
                                'Debug' = $true;
                                'WarningAction' = $true;
                                'WarningVariable' = $true;
                                'ErrorAction' = $true;
                                'ErrorVariable' = $true;
                                'OutVariable' = $true;
                                'OutBuffer' = $true;
                                'WhatIf' = $true;
                                'Confirm' = $true;
                             }
            if( $commonParameterNames.ContainsKey( $_.name ) )
            {
                $hasCommonParameters = $true
            }
            
            $typeDisplayName = $_.type.name
            $typeName = $typeDisplayName
            if( $typeName.EndsWith('[]') )
            {
                $typeName = $typeName -replace '\[\]',''
            }
            $typeFullName = $loadedTypes[$typeName]
            $typeLink = $typeDisplayName
            if( -not $typeFullName )
            {
                Write-Warning ("Type {0} not found." -f $_.type.name)
            }
            else
            {
                $typeLink = '<a href="http://msdn.microsoft.com/en-us/library/{0}.aspx">{1}</a>' -f $typeFullName.ToLower(),$typeDisplayName
            }
            $paramDescription = $_.Description | 
                            Out-HtmlString | 
                            Convert-MarkdownToHtml | 
                            ForEach-Object { $_.Replace('<p>','').Replace('</p>','') }
            @"
			<tr valign='top'>
				<td>{0}</td>
				<td>{1}</td>
				<td>{2}</td>
				<td>{3}</td>
				<td>{4}</td>
                <td>{5}</td>
			</tr>
"@ -f $_.Name,$typeLink,$paramDescription,$_.Required,$_.PipelineInput,$_.DefaultValue
        }
        
    if( $parameters )
    {
        $commonParameters = ''
        if( $hasCommonParameters )
        {
            $commonParameters = @"
                <tr valign="top">
                <td><a href="http://technet.microsoft.com/en-us/library/dd315352.aspx">CommonParameters</a></td>
                <td></td>
                <td>This cmdlet supports common parameters.  For more information type <br> <code>Get-Help about_CommonParameters</code>.</td>
                <td></td>
                <td></td>
                <td></td>
                </tr>
"@
        }
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
            {1}
        </table>
"@ -f ($parameters -join "`n"),$commonParameters
    }

    $inputTypes = $CommandHelp.inputTypes | Out-HtmlString
    if( $inputTypes )
    {
        $inputTypes = @"
        <h2>Input Type</h2>
        <div>{0}</div>
"@ -f $inputTuypes
    }
    
    $returnValues = ($commandHelp.returnValues | Out-HtmlString) -replace "`n",' '
    if( $returnValues )
    {
        if( $returnValues -match '^(.*?)\.(\s+(.*))?$' )
        {
            $type = [Type]$matches[1]
            if( -not $type )
            {
                Write-Warning ("Type {0} not found." -f $matches[1])
            }
            $returnValues = '[{0}](http://msdn.microsoft.com/en-us/library/{1}.aspx). {2}' -f $type.FullName,$type.FullName.ToLower(),$matches[2]
        }
        else
        {
            Write-Warning "Unable to find type name in $returnValues.  Return value full type name should end with a period."
        }
        $returnValues = $returnValues | Convert-MarkdownToHtml
        $returnValues = @"
        <h2>Return Values</h2>
        {0}
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
"@ -f $_.title.Trim(('-',' ')),($_.code | Out-HtmlString),(($_.remarks | Out-HtmlString | Convert-MarkdownToHtml) -join '</p><p>')
        }
    
@"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>$name</title>
	<link href="styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
    $Menu

    <h1>$name</h1>
    <div>$synopsis</div>

    $syntax
    
    $description
    
    $relatedCommands

    $parameters
        
    $inputTypes
        
    $returnValues
        
    $notes
        
    $examples
</body>
</html>   
"@ | Out-File -FilePath (Join-Path $OutputDir ("{0}.html" -f $CommandHelp.Name)) -Encoding OEM
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

Get-ChildItem $OutputDir *.html | Remove-Item

$commands = Get-Command | 
                Where-Object { $_.ModuleName -eq 'Carbon' -and $_.Name } | 
                Sort-Object Name 

$categories = New-Object 'Collections.Generic.SortedList[string,object]'
Get-ChildItem (Join-Path $PSScriptRoot Carbon\*.ps1) -Exclude Import-Carbon.ps1 | 
    Sort-Object BaseName |
    ForEach-Object { 
        $currentFile = $_.BaseName
        $categories[$currentFile] = New-Object 'Collections.ArrayList'
        $_ | Get-Functions | Where-Object { Test-Path "function:$_" } | Sort-Object | ForEach-Object { 
            [void] $categories[$currentFile].Add($_) 
        }
    }

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

if( -not (Test-Path $OutputDir -PathType Container) )
{
    New-Item $outputDir -ItemType Directory -Force 
}

@"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>Carbon PowerShell Module Documentation</title>
	<link href="styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
    {0}
</body>
</html>
"@ -f $menuBuilder.ToString() | Out-File -FilePath (Join-Path $outputDir index.html) -Encoding OEM


$commands | 
    #Where-Object { $_.Name -eq 'Get-Certificate' } | 
    Get-Help -Full | 
    Convert-HelpToHtml -Menu $menuBuilder.ToString()
