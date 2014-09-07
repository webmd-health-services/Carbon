
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

        [string]
        # The syntax of the command. Useful when showing syntax for DSC resources.
        $Syntax
    )

    foreach( $commandName in $Name )
    {
        $help = Get-Help -Name $commandName -Full

        $synopsis = $help.Synopsis | Convert-MarkdownToHtml
        if( -not $Syntax )
        {
            $Syntax = $help.Syntax | Out-HtmlString | Format-ForHtml | ForEach-Object { $_ -split "`n" }
        }
        if( $Syntax )
        {
            $Syntax = @"
<h2>Syntax</h2>
<pre class="Syntax"><code>{0}</code></pre>
"@ -f ($Syntax -join "</code></pre>`n<pre class=""Syntax""><code>")
        }
    
        $description = $help.Description | Out-HtmlString | Convert-MarkdownToHtml
        if( $description )
        {
            $description = @"
<h2>Description</h2>
<div class="Description">
$description
</div>
"@
        }
    
        $relatedCommands = $help.RelatedLinks |
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
                $relatedCommands = " * {0}" -f (($relatedCommands -replace '_','\_') -join "`n * ")
            }
            $relatedCommands = @"
<h2>Related Commands</h2>
{0}
"@ -f ($relatedCommands | Convert-MarkdownToHtml)
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
        $parameters = $help.Parameters.Parameter |
            Where-Object { $_ } | 
            ForEach-Object {
                if( $commonParameterNames.ContainsKey( $_.name ) )
                {
                    $hasCommonParameters = $true
                }
            
                $typeLink = Get-TypeDocumentationLink -TypeName $_.type.name
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

        $inputTypes = $help.inputTypes | Out-HtmlString
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
                $typeLink = Get-TypeDocumentationLink -TypeName $matches[1]
                $returnValues = '{0}. {1}' -f $typeLink,$matches[2]
            }
            else
            {
                Write-Warning ("Command {0}: Unable to find type name in {1}.  Return value full type name should end with a period." -f $_.Name,$returnValues)
            }
            $returnValues = $returnValues | Convert-MarkdownToHtml
            $returnValues = @"
<h2>Return Values</h2>
{0}
"@ -f $returnValues
        }
    
        $notes = $help.AlertSet | Out-HtmlString
        if( $notes )
        {
            $notes = @"
<h2>Notes</h2>
<div>{0}</div>
"@ -f $notes
        }
    
        $examples = $help.Examples.example |
            Where-Object { $_ } |
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
    
        $filename = $help.Name
        $fileName = Split-Path -Leaf -Path $filename # handle help for scripts
        $filename = '{0}.html' -f $filename
        if( $help | Get-Member FileName )
        {
            $filename = $help.FileName
        }

    if( -not $DisplayName )
    {
        $DisplayName = $commandName
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

