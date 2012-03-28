<#
.SYNOPSIS
Adds the license notice to a set of files.
#>

# License

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true,ParameterSetName='FromUser')]
    $Path,
    
    [Parameter(Mandatory=$true,ParameterSetName='FromPipeline',ValueFromPipeline=$true)]
    # The files to add 
    $InputObject,
    
    [Parameter(Mandatory=$true)]
    [string]
    # The copyright string.
    $Copyright
)

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

    $noticeLines = New-Object Collections.Generic.List[string]

    $licenseFilePath = JOin-Path $PSScriptRoot LICENSE -Resolve
    $foundNotice = $false
    Get-Content $licenseFilePath | ForEach-Object {
        if( $_ -eq '   Copyright [yyyy] [name of copyright owner]' )
        {
            $noticeLines.Add( '# Copyright ' + $Copyright )
            $foundNotice = $true
            return
        }
        
        if( -not $foundNotice )
        {
            return
        }
        
        $trimmedLine = $_
        if( $_.Length -gt 3 )
        {
            $trimmedLine = $_.Substring( 3 )
        }
        $noticeLines.Add( '# ' + $trimmedLine )
    }

}

process
{
    $filePath = ''
    if( $pscmdlet.ParameterSetName -eq 'FromUser' )
    {
        $filePath = $Path
    }
    elseif( $pscmdlet.ParameterSetName -eq 'FromPipeline' )
    {
        $filePath = Select-Object -InputObject $_ -Property FullName
        if( $filePath.FullName )
        {
            $filePath = $filePath.FullName
        }
    }
    
    if( -not (Test-Path -Path $filePath -PathType Leaf) )
    {
        Write-Warning "Unable to add license to '$filePath': not a file."
        return
    }
    
    $fileContents = Get-Content -Path $filePath
    $file = ($fileContents[1..$fileContents.Length]) -join "`n"
    $notice = $noticeLines.GetRange(1, $noticeLines.Count - 1) -join "`n"
    if( $file.StartsWith( $notice ) )
    {
        $fileContents = $fileContents[$noticeLines.Count..$fileContents.Length]
    }
    $noticeLines | Out-File -FilePath $filePath -Encoding OEM
    $fileContents | Out-File -FilePath $filePath -Append -Encoding OEM
}

end
{
}