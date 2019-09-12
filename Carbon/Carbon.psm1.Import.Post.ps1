
# Extended Type
if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'GetCarbonFileInfo') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (GetCarbonFileInfo).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptMethod -MemberName 'GetCarbonFileInfo' -Value {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the Carbon file info property to get.
            $Name
        )

        Set-StrictMode -Version 'Latest'

        if( -not $this.Exists )
        {
            return
        }

        if( -not ($this | Get-Member -Name 'CarbonFileInfo') )
        {
            $this | Add-Member -MemberType NoteProperty -Name 'CarbonFileInfo' -Value (New-Object 'Carbon.IO.FileInfo' $this.FullName)
        }

        if( $this.CarbonFileInfo | Get-Member -Name $Name )
        {
            return $this.CarbonFileInfo.$Name
        }
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'FileIndex') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (FileIndex).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'FileIndex' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'FileIndex' )
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'LinkCount') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (LinkCount).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'LinkCount' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'LinkCount' )
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'VolumeSerialNumber') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (ColumeSerialNumber).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'VolumeSerialNumber' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'VolumeSerialNumber' )
    }
}

Write-Timing ('Testing the module manifest.')
try
{
    $module = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve)
    if( -not $module )
    {
        return
    }

    Write-Timing ('Creating aliases.')
    [string[]]$functionNames = $module.ExportedFunctions.Keys
    foreach( $functionName in $functionNames )
    {
        $oldFunctionName = $functionName -replace '-C','-'
        Set-Alias -Name $oldFunctionName -Value $functionName
    }

    Write-Timing ('Exporting module members.')
    Export-ModuleMember -Alias '*' -Function $functionNames
}
finally
{
    Write-Timing ('DONE')
}