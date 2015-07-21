<#
.SYNOPSIS
Creates the get-carbon.org website.

.DESCRIPTION
The `New-Website.ps1` script generates the get-carbon.org website. It uses the Silk module for Markdown to HTML conversion.
#>
[CmdletBinding()]
param(
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
            $jQueryScriptTag = '<script src="/jquery-2.1.4-min.js"></script>'
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
	<link href="styles.css" type="text/css" rel="stylesheet" />
    {1}
</head>
<body>

    <ul id="SiteNav">
		<li><a href="/">Get-Carbon</a></li>
        <li><a href="https://bitbucket.org/splatteredbits/carbon/downloads">-Download</li>
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

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1' -Resolve)

$webRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Website'
$cmdRoot = Join-Path -Path $webRoot -ChildPath 'help'
$tagsRoot = Join-Path -Path $webRoot -ChildPath 'tags'

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

$commands = Get-Command -Module 'Carbon' | Where-Object { $_.CommandType -ne 'Alias' } | Sort-Object -Property 'Name'
[int]$numCommands = $commands | Measure-Object | Select-Object -ExpandProperty 'Count'
$count = 0
foreach( $command in $commands )
{
    if( -not $verbs.ContainsKey( $command.Verb ) )
    {
        $verbs[$command.Verb] = New-Object 'Collections.Generic.List[string]'
    }
    $verbs[$command.Verb].Add( $command.Name )

    Write-Progress -Activity 'Generating Command HTML' -PercentComplete ($count / $numCommands * 100) -CurrentOperation $command.Name
    #Convert-HelpToHtml -Name $command.Name | Out-HtmlPage -Title ('PowerShell - {0} - Carbon' -f $command.Name) -VirtualPath ('/help/{0}.html' -f $command.Name)
    $count++
}

$commandList = $commands | Select-Object -ExpandProperty 'Name' | Sort-Object | ForEach-Object { '<li><a href="/help/{0}.html">{0}</a></li>' -f $_ }

$verbList = $verbs.Keys | Sort-Object | ForEach-Object {
    $verb = $_
    $verbCommands = $verbs[$verb] | ForEach-Object { '<li><a href="/help/{0}.html">{0}</a></li>' -f $_ }
    @'
<h2>{0}</h2>

{1}
'@ -f $verb,($verbCommands -join ([Environment]::NewLine))
}

$topicList = New-Object 'Collections.Generic.List[string]'

$topicsFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon') -Filter 'about_Carbon*.help.txt'
foreach( $topicFile in $topicsFiles )
{
    $topicName = $topicFile.BaseName -replace '\.help$',''
    $virtualPath = '/help/{0}.html' -f $topicName

    $title = $topicFile.BaseName -replace '^about_Carbon_',''
    $title = $title -replace '_',' '

    $topicFile | Convert-AboutTopicToHtml | Out-HtmlPage -Title ('Carbon - {0}' -f $title) -VirtualPath $virtualPath

    $topicList.Add( ('<li><a href="{0}">{1}</a></li>' -f $virtualPath,$topicName) )
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
<ul>
    <li>By Tag</li>
    <li>By Name</li>
    <li>By Verb</li>
</ul>

<div id="ByTag">
    <ul id="Tags">
    {0}
    </ul>
</div>

<div id="ByName">
    <ul>
        {1}
    </ul>
</div>

<div id="ByVerb">
    <ul>
        {2}
    </ul>
</div>
'@ -f $helpIndexArgs | Out-HtmlPage -Title 'Carbon PowerShell Module Documentation' -JQuery -VirtualPath '/help/index.html'

$carbonTitle = 'Carbon: PowerShell DevOps module for configuring and setting up Windows computers, applications, and websites'
Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'about_Carbon.md') -Raw | Convert-MarkdownToHtml | Out-HtmlPage -Title $carbonTitle -VirtualPath '/index.html'
Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE NOTES.txt') -Raw | Convert-MarkdownToHtml | Out-HtmlPage -Title ('Release Notes - {0}' -f $carbonTitle) -VirtualPath '/releasenotes.html'

