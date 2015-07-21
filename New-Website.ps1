<#
.SYNOPSIS
Creates the get-carbon.org website.

.DESCRIPTION
The `New-Website.ps1` script generates the get-carbon.org website. It uses the Silk module for Markdown to HTML conversion.
#>

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

[CmdletBinding()]
param(
    [Switch]
    # Skips generating the command help.
    $SkipCommandHelp
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

function Out-HtmlPage
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The contents of the page.
        $Content,

        [Parameter(Mandatory=$true)]
        # The title of the page.
        $Title,

        [Parameter(Mandatory=$true)]
        # The path under the web root of the page.
        $VirtualPath,

        [Switch]
        # Include JQuery in the page.
        $JQuery
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        $jQueryScriptTag = ''
        if( $JQuery )
        {
            $jQueryScriptTag = '<script src="/jquery-2.1.4.min.js"></script>{0}<script src="/helpindex.js"></script>' -f ([Environment]::NewLine)
        }

        $path = Join-Path -Path $webRoot -ChildPath $VirtualPath
        $templateArgs = @(
                            $Title,
                            $jQueryScriptTag,
                            $Content,
                            (Get-Date).Year
                        )
        @'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>{0}</title>
	<link href="/styles.css" type="text/css" rel="stylesheet" />
    {1}
</head>
<body>

    <ul id="SiteNav">
		<li><a href="/">Get-Carbon</a></li>
        <li><a href="/help/about_Carbon_Installation.html">-Install</a></li>
		<li><a href="/help/index.html">-Documentation</a></li>
        <li><a href="/releasenotes.html">-ReleaseNotes</a></li>
		<li><a href="http://pshdo.com">-Blog</a></li>
    </ul>

    {2}

	<div class="Footer">
		Copyright &copy; 2012 - {3} <a href="http://pshdo.com">Aaron Jensen</a>.  All rights reserved.
	</div>

</body>
</html>
'@ -f $templateArgs | Set-Content -Path $path
    }

    end
    {
    }
}


& (Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Silk\Import-Silk.ps1' -Resolve)

if( (Get-Module -Name 'Blade') )
{
    Remove-Module 'Blade'
}

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1' -Resolve) -Force

$webRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Website'
$cmdRoot = Join-Path -Path $webRoot -ChildPath 'help'
$tagsRoot = Join-Path -Path $webRoot -ChildPath 'tags'

$headingMap = @{
                    'NEW DSC RESOURCES' = 'New DSC Resources';
                    'ADDED PASSTHRU PARAMETERS' = 'Added PassThru Parameters';
                    'SWITCH TO SYSTEM.DIRECTORYSERVICES.ACCOUNTMANAGEMENT API FOR USER/GROUP MANAGEMENT' = 'Switch To System.DirectoryServices.AccountManagement API For User/Group Management';
                    'INSTALL FROM ZIP ARCHIVE' = 'Install From ZIP Archive';
                    'INSTALL FROM POWERSHELL GALLERY' = 'Install From PowerShell Gallery';
                    'INSTALL WITH NUGET' = 'Install With NuGet';
               }

$help = Convert-ModuleHelpToHtml -ModuleName 'Carbon' -HeadingMap $headingMap -SkipCommandHelp:$SkipCommandHelp |
            ForEach-Object {
                $_.Html | Out-HtmlPage -Title ('PowerShell - {0} - Carbon' -f $_.Name) -VirtualPath ('/help/{0}.html' -f $_.Name)
                $_
            }

$tagsJson = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tags.json') | ConvertFrom-Json
if( -not $tagsJson )
{
    return
}

$tags = @{ }

foreach( $item in $tagsJson )
{
    foreach( $tagName in $item.Tags )
    {
        if( -not $tags.ContainsKey( $tagName ) )
        {
            $tags[$tagName] = New-Object 'Collections.Generic.List[string]'
        }

        $tags[$tagName].Add( $item.Name )
    }
}

$tagCloud = $tags.Keys | Sort-Object | ForEach-Object { 

    $commands = $tags[$_] | ForEach-Object { '<li><a href="/help/{0}.html">{0}</a></li>' -f $_ }
@'
<h3>{0}</h3>

<ul>
    {1}
</ul>
'@ -f $_,($commands -join ([Environment]::NewLine))
}

$verbs = @{ }

$commands = Get-Command -Module 'Carbon' -CommandType Cmdlet,Function,Filter | Sort-Object -Property 'Name'
foreach( $command in $commands )
{
    if( -not $verbs.ContainsKey( $command.Verb ) )
    {
        $verbs[$command.Verb] = New-Object 'Collections.Generic.List[string]'
    }
    $verbs[$command.Verb].Add( $command.Name )
}

$commandList = $commands | Select-Object -ExpandProperty 'Name' | Sort-Object | ForEach-Object { '<li><a href="/help/{0}.html">{0}</a></li>' -f $_ }

$verbList = $verbs.Keys | Sort-Object | ForEach-Object {
    $verb = $_
    $verbCommands = $verbs[$verb] | ForEach-Object { '<li><a href="/help/{0}.html">{0}</a></li>' -f $_ }
    @'
<h3>{0}</h3>

<ul>
    {1}
</ul>
'@ -f $verb,($verbCommands -join ([Environment]::NewLine))
}

$topicList = New-Object 'Collections.Generic.List[string]'

foreach( $helpItem in $help )
{
    if( $helpItem.Type -ne 'AboutTopic' )
    {
        continue
    }

    $virtualPath = '/help/{0}.html' -f $helpItem.Name
    $topicList.Add( ('<li><a href="{0}">{1}</a></li>' -f $virtualPath,$helpItem.Name) )
}

$helpIndexArgs = @(
                    ($tagCloud -join ([Environment]::NewLine)),
                    ($commandList -join ([Environment]::NewLine)),
                    ($verbList -join ([Environment]::NewLine)),
                    ($topicList.ToArray() -join ([Environment]::NewLine))
                  )

@'
<h1>Carbon Documentation</h1>

<h2>About Help Topics</h2>

<ul>
    {3}
</ul>

<h2>Commands</h1>
<ul id="CommandsMenu">
    <li id="ByTagMenuItem" class="selected"><a href="#ByTag">By Tag</a></li>
    <li id="ByNameMenuItem" ><a href="#ByName">By Name</a></li>
    <li id="ByVerbMenuItem" ><a href="#ByVerb">By Verb</a></li>
</ul>

<div id="CommandsContent">

    <div id="ByTag">
        <a id="ByTag"></a>
        {0}
    </div>

    <div id="ByName">
        <a id="ByName"></a>
        <ul>
            {1}
        </ul>
    </div>

    <div id="ByVerb">
        <a id="ByVerb"></a>
        {2}
    </div>

</div>
'@ -f $helpIndexArgs | Out-HtmlPage -Title 'Carbon PowerShell Module Documentation' -JQuery -VirtualPath '/help/index.html'

$carbonTitle = 'Carbon: PowerShell DevOps module for configuring and setting up Windows computers, applications, and websites'
Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\about_Carbon.help.txt') |
    Convert-AboutTopicToHtml -ModuleName 'Carbon' |
    ForEach-Object {
        $text = $_ -replace '<a href="([^/]+)\.html">([^<]+)</a>','<a href="/help/$1.html">$2</a>'
        $text -replace '<h1>about_Carbon</h1>','<h1>Carbon</h1>'
    } |
    Out-HtmlPage -Title $carbonTitle -VirtualPath '/index.html'

Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE NOTES.txt') -Raw | 
    Edit-HelpText -ModuleName 'Carbon' |
    Convert-MarkdownToHtml | 
    Out-HtmlPage -Title ('Release Notes - {0}' -f $carbonTitle) -VirtualPath '/releasenotes.html'

