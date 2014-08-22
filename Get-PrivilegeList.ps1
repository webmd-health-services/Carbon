<#
#>
[CmdletBinding()]
param(
)

@( 'http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx', 'http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx' ) |
    ForEach-Object { Invoke-WebRequest -Uri $_ } |
    Select-Object -ExpandProperty 'RawContent' |
    Select-String -AllMatches 'TEXT\("([^"]+)"\)' |
    Select-Object -ExpandProperty 'Matches' |
    Select-Object -ExpandProperty 'Groups' |
    Select-Object -ExpandProperty 'Value' |
    Where-Object { $_ -notlike 'TEXT*' } |
    Select-Object -Unique |
    Sort-Object | 
    ForEach-Object { ' * {0}' -f $_ }