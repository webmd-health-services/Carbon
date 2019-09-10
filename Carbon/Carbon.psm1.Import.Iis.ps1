
if( $exportIisFunctions )
{
    Write-Timing ('Dot-sourcing IIS functions.')
    Get-ChildItem -Path $functionRoot -Filter '*Iis*.ps1' |
        ForEach-Object { . $_.FullName }
        
    if( -not (Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Site' -MemberName 'PhysicalPath') )
    {
        Write-Timing ('Updating Microsoft.Web.Administration.Site type data.')
        Update-TypeData -TypeName 'Microsoft.Web.Administration.Site' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value { 
                $this.Applications |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty VirtualDirectories |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty PhysicalPath
            }
    }

    if( -not (Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Application' -MemberName 'PhysicalPath') )
    {
        Write-Timing ('Updating Microsoft.Web.Administration.Application type data.')
        Update-TypeData -TypeName 'Microsoft.Web.Administration.Application' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value { 
                $this.VirtualDirectories |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty PhysicalPath
            }
    }
}
