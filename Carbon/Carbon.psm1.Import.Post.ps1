
$ErrorActionPreference = 'Stop'

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
    [Collections.Generic.List[String]]$functionNames = New-Object 'Collections.Generic.List[String]'
    foreach( $functionName in $module.ExportedFunctions.Keys )
    {
        [void]$functionNames.Add($functionName)

        if( $functionName -match '(Get|Install|Uninstall)-CWindowsFeature' )
        {
            continue
        }

        $oldFunctionName = $functionName -replace '-C','-'
        $oldFunctionPath = "function:\$($oldFunctionName)" 
        if( (Test-Path -Path $oldFunctionPath) )
        {
            $functionInfo = Get-Item -Path $oldFunctionPath
            if( $functionInfo.Source -eq 'Carbon' )
            {
                # For some reason, we had to implement a non-dynamic version of this function.
                [void]$functionNames.Add($oldFunctionName)
                continue
            }

            $functionSource = ''
            if( $functionInfo.Source )
            {
                $functionSource = " in module ""$($functionInfo.Source)"""
            }
            $msg = "Skipping export of Carbon function ""$($oldFunctionName)"": that function already " +
                   "exists$($functionSource)."
            Write-Warning -Message $msg

            continue
        }

        $functionPath = "function:$($functionName)"
        if( -not (Test-Path -Path $functionPath) )
        {
            # Some functions don't exist in 32-bit PowerShell.
            if( $functionName -in @('Initialize-CLcm') )
            {
                continue
            }

            if( -not $exportIisFunctions -and $functionName -like '*-CIis*' )
            {
                Write-Debug "Skipping ""$($functionName)"": IIS isn't installed or not loaded."
                continue
            }

            $msg = "Something unexpected happened. The ""$($functionName)"" function doesn't exist even though it " +
                   'should.'
            Write-Error -Message $msg
            continue
        }

        $cFunctionInfo = Get-Item -Path "function:$($functionName)"
        $preambleStart = $cFunctionInfo.definition.IndexOf('    [CmdletBinding(')
        if( $preambleStart -lt 0 )
        {
            $msg = "Unable to extract ""$($functionName)"" function's parameters: can't find ""[CmdletBinding()]"" " +
                   'attribute.'
            Write-Error -Message $msg
            continue
        }
        $preamble = $cFunctionInfo.definition.Substring($preambleStart)
        $preambleEnd = $preamble.IndexOf('    )')
        if( $preambleEnd -lt 0 )
        {
            $msg = "Unable to extract ""$($functionName)"" function's parameters: can't find "")"" that closes the " +
                   'parameter block.'
            Write-Error -Message $msg
            continue
        }
        $preamble = $preamble.Substring(0, $preambleEnd + 5)
        New-Item -Path 'function:' -Name $oldFunctionName -Value @"
$($preamble)

begin
{
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet `$PSCmdlet -SessionState `$ExecutionContext.SessionState

    Write-CRenamedCommandWarning -CommandName `$MyInvocation.MyCommand.Name -NewCommandName '$($functionName)'
}

process
{
    $($functionName) @PSBoundParameters
}
"@ | Out-Null
        [void]$functionNames.Add($oldFunctionName)
    }

    Write-Timing ('Exporting module members.')
    Export-ModuleMember -Alias '*' -Function $functionNames.ToArray()
}
finally
{
    Write-Timing ('DONE')
}