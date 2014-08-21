<#
.SYNOPSIS
Creates a new website for a module, using the module's help topics.

.DESCRIPTION

.EXAMPLE
New-ModuleWebsite -ConfigFilePath silk.json -DestinationPath C:\Inetpub\wwwroot\MyModule

Uses the `silk.json` configuration file to publish a module to `C:\Inetpub\wwwroot\MyModule`
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    # The path to the Silk configuration file to use.
    $ConfigFilePath,

    [Parameter(Mandatory=$true)]
    [string]
    # The path where the module's help should be published.
    $DestinationPath
)

$Error.Clear()
Set-StrictMode -Version Latest
$PSScriptRoot = Split-Path -Parent -Path $PSCommandPath

& (Join-Path $PSScriptRoot Import-Silk.ps1 -Resolve)

if( -not (Test-Path -Path $ConfigFilePath -PathType Leaf) )
{
    Write-Error ('Silk configuration file <{0}> not found.' -f $ConfigFilePath)
    exit 1
}

$ConfigFilePath = Resolve-Path -Path $ConfigFilePath | Select-Object -ExpandProperty ProviderPath
$ConfigFileRoot = Split-Path -Parent -Path $ConfigFilePath

$config = [IO.File]::ReadAllText( $ConfigFilePath ) | ConvertFrom-Json
if( -not $config )
{
    Write-Error ('Invalid Silk configuration file <{0}>.' -f $ConfigFilePath)
    exit 1
}

$modulePath = $config.ModulePath
if( -not ([IO.Path]::IsPathRooted($modulePath) ) )
{
    $modulePath = Join-Path $ConfigFileRoot $modulePath
}

if( -not (Test-Path -Path $modulePath) )
{
    Write-Error ('ModulePath <{0}> in Silk configuration file <{1}> not found. Relative paths should be relative to the configuration file itself.' -f $modulePath,$ConfigFilePath)
    exit 1
}

$moduleName = $config.ModuleName
if( (Get-Module $moduleName) )
{
    Remove-Module $moduleName
}
Import-Module $modulePath

if( -not (Get-Module $moduleName) )
{
    Write-Error ('Failed to load module <{0}> from <{1}>.' -f $moduleName,$modulePath)
    exit 1
}

# Normalize topics
$config.Topics |
    ForEach-Object {
        if( -not ([IO.Path]::IsPathRooted($_.Path)) )
        {
            $_.Path = Join-Path $ConfigFileRoot $_.Path
        }

        $baseName = [IO.Path]::GetFileNameWithoutExtension( $_.Path )

        if( -not ($_ | Get-Member FileName) )
        {
            $_ | Add-Member NoteProperty -Name FileName -Value ('{0}.html' -f $baseName)
        }

        if( -not ($_ | Get-Member Title) )
        {
            $_ | Add-Member NoteProperty -Name Title -Value $baseName
        }
    }

$commands = Get-Command -Module $moduleName | 
                Where-Object { $_.ModuleName -eq $moduleName } |
                Where-Object { $_.CommandType -ne 'Alias' } |
                Where-Object { $_.Name } | 
                Sort-Object Name 

$menuBuilder = New-Object Text.StringBuilder
[void] $menuBuilder.AppendLine( '<div id="CommandMenuContainer" style="float:left;">' )
[void] $menuBuilder.AppendLine( '<h1>Topics</h1>' )
[void] $menuBuilder.AppendFormat( "`t<ul class=""CommandMenu"">`n" )
$config.Topics |
    ForEach-Object {
        [void] $menuBuilder.AppendFormat( "`t`t<li><a href=""{0}"">{1}</a></li>`n", $_.FileName, $_.Title )
    }
[void] $menuBuilder.AppendLine( "`t</ul>" )

[void] $menuBuilder.AppendLine( '<h1>Commands</h1>' )
[void] $menuBuilder.AppendFormat( "`t<ul class=""CommandMenu"">`n" )
$commands | 
    Where-Object { $config.CommandsToSkip -notcontains $_ } |
    ForEach-Object {
        [void] $menuBuilder.AppendFormat( "`t`t<li><a href=""{0}.html"">{0}</a></li>`n", $_.Name )
    }
[void] $menuBuilder.AppendLine( "`t</ul>" )

[void] $menuBuilder.AppendLine( '<h1>Scripts</h1>' )
[void] $menuBuilder.AppendFormat( "`t<ul class=""CommandMenu"">`n" )
$config.Scripts |
    ForEach-Object {
        $name = Split-Path -Leaf $_
        [void] $menuBuilder.AppendFormat( "`t`t<li><a href=""{0}.html"">{0}</a></li>`n", $name )
    }
[void] $menuBuilder.AppendLine( "`t</ul>" )

[void] $menuBuilder.AppendLine( '</div>' )

if( -not (Test-Path $DestinationPath -PathType Container) )
{
    $null = New-Item $DestinationPath -ItemType Directory -Force 
}

Join-Path $PSScriptRoot 'Resources\styles.css' | Get-Item | Copy-Item -Destination $DestinationPath

$config.Topics | 
    Split-MarkdownTopic -ConfigFileRoot $ConfigFileRoot |
    Convert-HelpToHtml -Menu $menuBuilder.ToString() -Config $config -DestinationPath $DestinationPath

$commands | 
    #Where-Object { $_.Name -eq 'Invoke-SqlScript' } | 
    Where-Object { $config.CommandsToSkip -notcontains $_.Name } |
    Get-Help -Full | 
    Convert-HelpToHtml -Menu $menuBuilder.ToString() -Config $config -DestinationPath $DestinationPath

$config.Scripts |
    ForEach-Object { Join-Path -Path $ConfigFileRoot -ChildPath $_ -Resolve } |
    ForEach-Object { 
        $topic = Get-Help -Full -Name $_ 
        $topic.Name = Split-Path -Leaf -Path $topic.Name
        if( -not ($topic | Get-Member -Name 'details') ) 
        {
            Write-Error ('Details for ''{0}'' not found.' -f $_)
        }
        else
        {
            $topic.details.name = Split-Path -Leaf -Path $topic.details.name
        }

        if( -not ($topic | Get-Member -Name 'syntax') )
        {
            Write-Error ('Syntax for ''{0}'' not found.' -f $_)
        }
        else
        {
            $topic.syntax | 
                Select-Object -ExpandProperty 'syntaxItem' | 
                ForEach-Object { $_.name = Split-Path -Leaf -Path $_.name }
        }
        $topic
    } |
    Convert-HelpToHtml -Menu $menuBuilder.ToString() -Config $config -DestinationPath $DestinationPath
