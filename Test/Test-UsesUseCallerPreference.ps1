
function Test-FunctionsShouldUseUseCallerPreference
{
    $files = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\*\*.ps1') -File |
                Where-Object { $_.Directory.Name -ne 'bin' -and $_.Directory.Name -ne 'DscResources' -and $_.BaseName -ne 'Use-CallerPreference' } |
                Where-Object { -not ($_ | Select-String -Pattern 'Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState' -SimpleMatch) } | 
                Select-Object -ExpandProperty 'Name' |
                Sort-Object

    if( $files )
    {
        Fail ('The following scripts don''t don''t use `Use-CallerPreference`:{0} * {1}' -f ([Environment]::NewLine),($files -join ('{0} * ' -f ([Environment]::NewLine))))
    }
}
