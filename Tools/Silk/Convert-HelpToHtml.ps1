
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
        $Name
    )

    foreach( $commandName in $Name )
    {
        $help = Get-Help -Name $commandName -Full

        $name = $help.Name #| Format-ForHtml
        $synopsis = $help.Synopsis | Convert-MarkdownToHtml
        $syntax = $help.Syntax | Out-HtmlString | Format-ForHtml | ForEach-Object { $_ -split "`n" }
        if( $syntax )
        {
            $syntax = @"
<h2>Syntax</h2>
<pre class="Syntax"><code>{0}</code></pre>
"@ -f ($syntax -join "</code></pre>`n<pre class=""Syntax""><code>")
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
    
        $hasCommonParameters = $false
        $parameters = $help.Parameters.Parameter |
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
                    Write-Warning ("Command {0}: Type {1} not found." -f $_.Name,$_.type.name)
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
                $type = [Type]$matches[1]
                if( -not $type )
                {
                    Write-Warning ("Command {0}: Type {1} not found." -f $_.Name,$matches[1])
                }
                $returnValues = '[{0}](http://msdn.microsoft.com/en-us/library/{1}.aspx). {2}' -f $type.FullName,$type.FullName.ToLower(),$matches[2]
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
                @"
<h2>{0}</h2>
<pre><code>{1}</code></pre>
{2}
"@ -f $_.title.Trim(('-',' ')),($_.code | Out-HtmlString),($_.remarks | Out-HtmlString | Convert-MarkdownToHtml)
            }
    
        $filename = $help.Name
        $fileName = Split-Path -Leaf -Path $filename # handle help for scripts
        $filename = '{0}.html' -f $filename
        if( $help | Get-Member FileName )
        {
            $filename = $help.FileName
        }

    @"
<h1>$name</h1>
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

