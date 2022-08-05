function Test-CCimAvailable
{
    return ($null -ne (Get-Command -Name 'Get-CimInstance' -ErrorAction Ignore))
}