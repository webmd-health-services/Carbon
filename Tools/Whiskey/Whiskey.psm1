$numRobocopyThreads = Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -ExpandProperty 'NumberOfLogicalProcessors' | Measure-Object -Sum | Select-Object -ExpandProperty 'Sum'
$numRobocopyThreads *= 2

$events = @{ }

$7z = Join-Path -Path $PSScriptRoot -ChildPath 'bin\7-Zip\7z.exe' -Resolve

$buildStartedAt = [DateTime]::MinValue

$supportsWriteInformation = Get-Command -Name 'Write-Information' -ErrorAction Ignore

# Make sure our custom objects get serialized/deserialized correctly, otherwise they don't get passed to PowerShell tasks correctly.
Update-TypeData -TypeName 'Whiskey.BuildContext' -SerializationDepth 50 -ErrorAction Ignore
Update-TypeData -TypeName 'Whiskey.BuildInfo' -SerializationDepth 50 -ErrorAction Ignore
Update-TypeData -TypeName 'Whiskey.BuildVersion' -SerializationDepth 50 -ErrorAction Ignore

$attr = New-Object -TypeName 'Whiskey.TaskAttribute' -ArgumentList 'Whiskey' -ErrorAction Ignore
if( -not ($attr | Get-Member 'SupportsClean') )
{
    Write-Error -Message ('You''ve got an old version of Whiskey loaded. Please open a new PowerShell session.') -ErrorAction Stop
}

Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions'),(Join-Path -Path $PSScriptRoot -ChildPath 'Tasks') -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
