function Test-CCimAvailable
{
    # Windows PowerShell comes with CimCmdlets version 1.0.0 and PowerShell Core comes with CimCmdlets version > 7.0.0
    return (Get-Command -Name 'Get-CimInstance' -ErrorAction Ignore).Version.Major -ge 7
}