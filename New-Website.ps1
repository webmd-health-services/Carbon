<#
.SYNOPSIS
Creates the get-carbon.org website.

.DESCRIPTION
The `New-Website.ps1` script generates the get-carbon.org website. It uses the Silk module for Markdown to HTML conversion.
#>

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
    [Parameter(Mandatory=$true)]
    [string]
    $WebRoot,

    [Switch]
    # Skips generating the command help.
    $SkipCommandHelp
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

function Out-HtmlPage
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('Html')]
        # The contents of the page.
        $Content,

        [Parameter(Mandatory=$true)]
        # The title of the page.
        $Title,

        [Parameter(Mandatory=$true)]
        # The path under the web root of the page.
        $VirtualPath
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        $path = Join-Path -Path $WebRoot -ChildPath $VirtualPath
        $templateArgs = @(
                            $Title,
                            $Content,
                            (Get-Date).Year
                        )
        @'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>{0}</title>
    <link href="silk.css" type="text/css" rel="stylesheet" />
	<link href="styles.css" type="text/css" rel="stylesheet" />
</head>
<body>

    <ul id="SiteNav">
		<li><a href="index.html">Get-Carbon</a></li>
        <li><a href="about_Carbon_Installation.html">-Install</a></li>
		<li><a href="documentation.html">-Documentation</a></li>
        <li><a href="about_Carbon_Support.html">-Support</a></li>
        <li><a href="releasenotes.html">-ReleaseNotes</a></li>
		<li><a href="http://pshdo.com">-Blog</a></li>
        <li><a href="https://github.com/pshdo/Carbon/">-Project</a></li>
    </ul>

    {1}

	<div class="Footer">
		Copyright <a href="http://pshdo.com">Aaron Jensen</a> and WebMD Health Services.
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

$headingMap = @{
                    'NEW DSC RESOURCES' = 'New DSC Resources';
                    'ADDED PASSTHRU PARAMETERS' = 'Added PassThru Parameters';
                    'SWITCH TO SYSTEM.DIRECTORYSERVICES.ACCOUNTMANAGEMENT API FOR USER/GROUP MANAGEMENT' = 'Switch To System.DirectoryServices.AccountManagement API For User/Group Management';
                    'INSTALL FROM ZIP ARCHIVE' = 'Install From ZIP Archive';
                    'INSTALL FROM POWERSHELL GALLERY' = 'Install From PowerShell Gallery';
                    'INSTALL WITH NUGET' = 'Install With NuGet';
               }

$moduleInstallPath = Get-PowerShellModuleInstallPath
$linkPath = Join-Path -Path $moduleInstallPath -ChildPath 'Carbon'
Install-Junction -Link $linkPath -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon') -Verbose:$VerbosePreference

try
{
    Convert-ModuleHelpToHtml -ModuleName 'Carbon' -HeadingMap $headingMap -SkipCommandHelp:$SkipCommandHelp -Script 'Import-Carbon.ps1' |
        ForEach-Object { Out-HtmlPage -Title ('PowerShell - {0} - Carbon' -f $_.Name) -VirtualPath ('{0}.html' -f $_.Name) -Content $_.Html }
}
finally
{
    Uninstall-Junction -Path $linkPath
}

New-ModuleHelpIndex -TagsJsonPath (Join-Path -Path $PSScriptRoot -ChildPath 'tags.json') -ModuleName 'Carbon' -Script 'Import-Carbon.ps1' |
     Out-HtmlPage -Title 'PowerShell - Carbon Module Documentation' -VirtualPath '/documentation.html'

$carbonTitle = 'Carbon: PowerShell DevOps module for configuring and setting up Windows computers, applications, and websites'
Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\en-US\about_Carbon.help.txt') |
    Convert-AboutTopicToHtml -ModuleName 'Carbon' -Script 'Import-Carbon.ps1' |
    ForEach-Object {
        $_ -replace '<h1>about_Carbon</h1>','<h1>Carbon</h1>'
    } |
    Out-HtmlPage -Title $carbonTitle -VirtualPath '/index.html'

Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'CHANGELOG.md') -Raw | 
    Edit-HelpText -ModuleName 'Carbon' |
    Convert-MarkdownToHtml | 
    Out-HtmlPage -Title ('CHANGELOG - {0}' -f $carbonTitle) -VirtualPath '/changelog.html'

Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\Resources\silk.css' -Resolve) `
          -Destination $WebRoot -Verbose