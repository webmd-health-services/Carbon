
filter Convert-HelpToHtml 
{
    <#
    .SYNOPSIS
    Converts a command's help topic to an HTML page.
    #>
	param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]
        # The name of the command(s) to document.
        $Name,

        [string]
        # The display name. Useful if the command name being documented is different than its public name, e.g. DSC resources.
        $DisplayName,

        [string[]]
        # The syntax of the command. Useful when showing syntax for DSC resources.
        $Syntax,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module whose help is getting converted.
        $ModuleName,

        [string[]]
        # The names of any scripts in the module.
        $Script
    )

    Set-StrictMode -Version 'Latest'

    foreach( $commandName in $Name )
    {
        $fullCommandName = $commandName
        if( (Get-Help -Name $commandName | Measure-Object).Count -gt 1 )
        {
            $fullCommandName = '{0}\{1}' -f $ModuleName,$commandName
        }
        Write-Verbose -Message $fullCommandName -Verbose
        $help = Get-Help -Name $fullCommandName -Full

        $synopsis = $help.Synopsis | Convert-MarkdownToHtml
        if( -not $Syntax )
        {
            $help.Syntax |
                Where-Object { [IO.Path]::IsPathRooted($_.syntaxItem.name) } |
                ForEach-Object { $_.syntaxItem.Name = Split-Path -Leaf -Path $_.syntaxItem.name }

            $Syntax = $help.Syntax | Out-HtmlString | Format-ForHtml | ForEach-Object { $_ -split "`n" }
        }
        if( $Syntax )
        {
            $Syntax = @"
<h2>Syntax</h2>
<pre class="Syntax"><code>{0}</code></pre>
"@ -f ($Syntax -join "</code></pre>`n<pre class=""Syntax""><code>")
        }

        $description = $null
        if( $help | Get-Member -Name 'Description' )
        {    
            $description = $help.Description | Out-HtmlString | Convert-MarkdownToHtml
        }
        if( $description )
        {
            $description = @"
<h2>Description</h2>
<div class="Description">
$description
</div>
"@
        }
    
        [string[]]$relatedCommands = $help | Convert-RelatedLinkToHtml -ModuleName $ModuleName -Script $Script
    
        if( $relatedCommands )
        {
            $relatedCommands = $relatedCommands | ForEach-Object { "<li>{0}</li>" -f $_ }
            $relatedCommands = @"
<h2>Related Commands</h2>

<ul>
{0}
</ul>
"@ -f ($relatedCommands -join ([Environment]::NewLine))
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
            $parameters = @"
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
"@ -f ($parameters -join "`n"),$commonParameters
        }

        $inputTypes = @()
        if( $help | Get-Member -Name 'inputTypes' )
        {
            $inputTypes = $help.inputTypes | Out-HtmlString
        }

        if( $inputTypes )
        {
            $inputTypes = @"
<h2>Input Type</h2>
<div>{0}</div>
"@ -f $inputTypes
        }
    
        $returnValues =@()
        if( ($help | Get-Member -Name 'returnValues') -and ($help.returnValues | Get-Member -Name 'returnValue') -and ($help.returnValues.returnValue | Get-Member -Name 'type') -and $help.returnValues.returnValue.type )
        {
            if( $help.returnValues.returnValue.type.name -match '^([^\s]+)\s*(.*)?$' )
            {
                $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $Matches[1].Trim('.')
                $returnValues = '{0}. {1}' -f $typeLink,$matches[2]
                Write-Verbose $returnValues
            }
            $returnValues = $returnValues | Convert-MarkdownToHtml
        }

        if( $returnValues )
        {
            $returnValues = @"
<h2>Return Values</h2>
{0}
"@ -f $returnValues
        }
    
        $notes = ''
        if( $help | Get-Member -Name 'AlertSet' )
        {
            $notes = $help.AlertSet | Out-HtmlString
        }

        if( $notes )
        {
            $notes = @"
<h2>Notes</h2>
<div>{0}</div>
"@ -f $notes
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
"@ -f $title,$code,$remarks
                }
        }
    
        $filename = $help.Name
        $fileName = Split-Path -Leaf -Path $filename # handle help for scripts
        $filename = '{0}.html' -f $filename
        if( $help | Get-Member -Name 'FileName' )
        {
            $filename = $help.FileName
        }

    if( -not $DisplayName )
    {
        $DisplayName = $commandName
        if( [IO.Path]::IsPathRooted($DisplayName) )
        {
            $DisplayName = Split-Path -Leaf -Path $DisplayName
        }
    }

    @"
<h1>$DisplayName</h1>
<div>$synopsis</div>

$syntax
    
$description
    
$relatedCommands

$parameters
        
$inputTypes
        
$returnValues
        
$notes
        
$($examples -join ([Environment]::NewLine * 2))
"@
    }
}

