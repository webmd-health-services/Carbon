
function Convert-HelpToHtml 
{
    <#
    .SYNOPSIS
    Converts a command's help topic to HTML.

    .DESCRIPTION
    The `Convert-HelpToHtml` function convert's a command's help topic to HTML. This HTML can then be used in a complete HTML page. It will output the following parts of a help topic, in the following order:

     * Name (in an `h1` element). You can override this name with the `DisplayName` parameter.
     * Synopsis
     * Syntax (which you can override with the `Syntax` parameter)
     * Description
     * Related Commands (i.e. `.LINK`)
     * Parameters
     * Parameters
     * Input Types (i.e. `.INPUTS`)
     * Return Types (i.e. `.OUTPUTS`)
     * Notes
     * Examples

    `Convert-HelpToHtml` converts all help text to HTML using [MarkdownSharp](https://code.google.com/p/markdownsharp/), a C# [Markdown](https://daringfireball.net/projects/markdown/) implementation. Markdown "allows you to write using an easy-to-read, easy-to-write plain text format, [that is converted] to structurally valid XHTML (or HTML)". This makes your help web-friendly.

    If you want to convert an entire module's help to HTML, including any scripts and DSC resources, use the `Convert-ModuleHelpToHtml` function. When converting help for a module, pass the module's name with the `ModuleName` parameter, and any of the module's commands or about topics found enclosed in backticks (Markdown's span of code indicators) will be converted to an anchor element whose `href` attribute is the command's name with a .html extension. For example, this help text:

    > Silk's `Convert-HelpToHtml` function converts help text written with Markdown into HTML.

    would get converted to

    > Silk's <a href="Convert-HelpToHtml.html">Convert-HelpToHtml</a> function converts help text written with Markdown into HTML.

    `Convert-HelpToHtml` assumes you'll take its output, wrap it in a full HTML page, and save all of these generated pages into the same directory. For example,

        $html = Convert-HelpToHtml -Name 'Convert-HelpToHtml' -ModuleName 'Silk'
        @"
        <!DOCTYPE html>
        <html>
        <head>
            <title>Convert-HelpToHTml</title>
            <link href="silk.css" type="text/css" rel="stylesheet" />
        </head>
        <body>
        $html
        </body>
        </html>
        "@ | Set-Content -Path (Join-Path -Path $webRoot -ChildPath 'Convert-HelpToHtml.html')

    `Convert-HelpToHtml` outputs HTML 5 (or tries to). For the best cross-browser compatability, make sure you define a doctype on each page. This is especially important for Internet Explorer. If you don't use a doctype, IE will display your pages in quirks mode, which won't display things correctly.

    Silk ships with a default cascading stylesheet (CSS) in the `Resources` directory. Copy this file into your webroot and link to it in each of your pages (via the `link` tag). To customize the appearance of your pages, we recommend you create your own stylesheet and link to it in each of your pages. Make all your style changes in yoru stylesheet. Future versions of Silk will contain fixes/enhancements to the default stylesheet. Using your own will make upgrading easier.

    .LINK
    https://daringfireball.net/projects/markdown/

    .LINK
    Convert-ModuleHelpToHtml

    .EXAMPLE
    Convert-HelpToHtml -Name 'Get-Module'

    Demonstrates how to use `Convert-HelpToHtml` to generate help for a command. You can pass multiple command names to the `Name` parameter.

    .EXAMPLE
    Get-Command -Module 'Silk' | Convert-HelpToHtml -ModuleName 'Silk'

    Demonstrates how you can pipe commands to `Convert-HelpToHtml` to generate help for them.

    .EXAMPLE
    Convert-HelpToHtml -Name 'Set-TargetResource' -DisplayName 'My_Dsc_Resource' -Syntax (Get-DscResource -Name 'My_Dsc_Resource' -Syntax)

    Demonstrates how you can document DSC resources. In this case, the resource's `Set-TargetResource` function contains the help to convert. Because the syntax for using a DSC resource is different than a PowerShell function/cmdlet, we pass the resource's syntax with the `Syntax` parameter.
    #>
	param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]
        # The name of the command(s) to document.
        $Name,

        [string]
        # The display name. When supplied, it is used as the command's name instead of `Name`. Useful if the command name being documented is different than its public name, e.g. DSC resources.
        $DisplayName,

        [string[]]
        # The syntax of the command. Useful when showing syntax for DSC resources.
        #
        # You can get the syntax for a DSC resource with the `Get-DscResource` cmdlet:
        # 
        #     Get-DscResource -Name 'My_Dsc_Resource' -Syntax
        $Syntax,

        [string]
        # The name of the module whose help is getting converted. Supplying this value will cause any of the module's cmdlets/functions surrounded by backticks (e.g. `Convert-HelpToHtml`) in help text to get replaced with an HTML link to that command's help topic.
        $ModuleName,

        [string[]]
        # The names of any scripts in the module. Supplying these values will cause any script names surround in backticks (e.g. `script.ps1`) in help text to get replaced with an HTML link to that script's help topic.
        $Script
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        foreach( $commandName in $Name )
        {
            $html = New-Object 'Text.StringBuilder'

            $fullCommandName = $commandName
            if( (Get-Help -Name $commandName | Measure-Object).Count -gt 1 )
            {
                $fullCommandName = '{0}\{1}' -f $ModuleName,$commandName
            }
            Write-Verbose -Message $fullCommandName
            $help = Get-Help -Name $fullCommandName -Full

            if( -not $DisplayName )
            {
                $DisplayName = $commandName
                if( [IO.Path]::IsPathRooted($DisplayName) )
                {
                    $DisplayName = Split-Path -Leaf -Path $DisplayName
                }
            }
        
            [void]$html.AppendFormat( '<h1>{0}</h1>{1}', $DisplayName, [Environment]::NewLine )

            $synopsis = $help.Synopsis | Convert-MarkdownToHtml
            if( $synopsis )
            {
                [void]$html.AppendFormat( '<div class="Synopsis">{0}{1}{0}</div>{0}', [Environment]::NewLine, $synopsis )
            }

            if( -not $Syntax )
            {
                $help.Syntax |
                    ForEach-Object { $_.syntaxItem } |
                    Where-Object { [IO.Path]::IsPathRooted($_.name) } |
                    ForEach-Object { $_.Name = Split-Path -Leaf -Path $_.name }

                $Syntax = $help.Syntax | Out-HtmlString | Format-ForHtml | ForEach-Object { $_ -split "`n" }
            }

            if( $Syntax )
            {
                [void]$html.AppendLine( @"

<h2>Syntax</h2>
<pre class="Syntax"><code>{0}</code></pre>
"@ -f ($Syntax -join "</code></pre>$([Environment]::NewLine)<pre class=""Syntax""><code>") )
            }

            $description = $null
            if( $help | Get-Member -Name 'Description' )
            {    
                $description = $help.Description | Out-HtmlString | Convert-MarkdownToHtml
            }
            if( $description )
            {
                [void]$html.AppendLine( @"

<h2>Description</h2>
<div class="Description">
$description
</div>
"@ )
            }
    
            [string[]]$relatedCommands = $help | Convert-RelatedLinkToHtml -ModuleName $ModuleName -Script $Script
    
            if( $relatedCommands )
            {
                $relatedCommands = $relatedCommands | ForEach-Object { "<li>{0}</li>" -f $_ }
                [void]$html.AppendLine( @"

<h2>Related Commands</h2>

<ul class="RelatedCommands">
{0}
</ul>
"@ -f ($relatedCommands -join ([Environment]::NewLine)) )
            }
    
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
            $hasCommonParameters = $false
            $parameters = $help | 
                            Select-Object -ExpandProperty 'Parameters' |
                            Where-Object { $_ | Get-Member -Name 'parameter' } |
                            Select-Object -ExpandProperty 'parameter' |
                            Where-Object { $_ } | 
                            ForEach-Object {
                                if( $commonParameterNames.ContainsKey( $_.name ) )
                                {
                                    $hasCommonParameters = $true
                                }
            
                                $defaultValue = '&nbsp;'
                                if( $_ | Get-Member -Name 'DefaultValue' )
                                {
                                    $defaultValue = $_.DefaultValue
                                }
                                $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $_.type.name
                                $paramDescription = $_ | 
                                                        Where-Object { $_ | Get-Member -name 'Description' } |
                                                        Select-Object -ExpandProperty 'Description' |
                                                        Out-HtmlString | 
                                                        Convert-MarkdownToHtml
                            @"
<tr valign='top'>
	<td>{0}</td>
	<td>{1}</td>
	<td class="ParamDescription">{2}</td>
	<td>{3}</td>
	<td>{4}</td>
    <td>{5}</td>
</tr>
"@ -f $_.Name,$typeLink,$paramDescription,$_.Required,$_.PipelineInput,$defaultValue
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
                [void]$html.AppendLine( (@"

<h2> Parameters </h2>
<table id="Parameters">
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
"@ -f ($parameters -join [Environment]::NewLine),$commonParameters))
            }

            $inputTypes = @()
            if( ($help | Get-Member -Name 'inputTypes') -and ($help.inputTypes | Get-Member 'inputType') )
            {
                $inputTypes = $help.inputTypes.inputType |
                                    Where-Object {  ($_ | Get-Member -Name 'type') -and $_.type -and $_.type.name -match '^([^\s]+)\s*(.*)?$' } |
                                    ForEach-Object { 
                                        $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $Matches[1].Trim('.')
                                        '{0}. {1}' -f $typeLink,$matches[2]
                                    } |
                                    Convert-MarkdownToHtml
            }

            if( $inputTypes )
            {
                [void]$html.AppendLine( @"

<h2>Input Types</h2>
<div class="InputTypes">
{0}
</div>
"@ -f ($inputTypes -join [Environment]::NewLine))
            }
    
            $returnValues =@()
            if( ($help | Get-Member -Name 'returnValues') -and ($help.returnValues | Get-Member -Name 'returnValue') )
            {
                $returnValues = $help.returnValues.returnValue |
                                    Where-Object {  ($_ | Get-Member -Name 'type') -and $_.type -and $_.type.name -match '^([^\s]+)\s*(.*)?$' } |
                                    ForEach-Object { 
                                        $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $Matches[1].Trim('.')
                                        '{0}. {1}' -f $typeLink,$matches[2]
                                    } |
                                    Convert-MarkdownToHtml
            }

            if( $returnValues )
            {
                [void]$html.AppendLine( @"

<h2>Return Values</h2>
<div class="ReturnValues">
{0}
</div>
"@ -f ($returnValues -join [Environment]::NewLine))
            }
    
            $notes = ''
            if( $help | Get-Member -Name 'AlertSet' )
            {
                $notes = $help.AlertSet | Out-HtmlString | ForEach-Object { $_ -replace "\r?\n    ",[Environment]::NewLine } | Convert-MarkdownToHtml
            }

            if( $notes )
            {
                [void]$html.AppendLine( @"

<h2>Notes</h2>
<div class="Notes">
{0}
</div>
"@ -f $notes)
            }
    
            $examples = @()
            if( $help | Get-Member -Name 'Examples' )
            {
                $examples = $help.Examples |
                    Where-Object { $_ } |
                    Where-Object { $_ | Get-Member -Name 'example' } |
                    Select-Object -ExpandProperty 'example' |
                    ForEach-Object {
                        $title = $_.title.Trim(('-',' '))
                        $code = ''
                        if( $_.code )
                        {
                            $code = $_.code | Out-HtmlString
                            $code = '<pre><code>{0}</code></pre>' -f $code
                        }
                        $remarks = $_.remarks | Out-HtmlString | Convert-MarkdownToHtml
                        @"

<h2>{0}</h2>
{1}
{2}
"@ -f $title,$code,($remarks -join [Environment]::NewLine)
                }
            }

            if( $examples )
            {
                [void]$html.AppendLine( ($examples -join ([Environment]::NewLine * 2)) )
            }

            $html.ToString()
        }
    }

    end
    {
    }
}

