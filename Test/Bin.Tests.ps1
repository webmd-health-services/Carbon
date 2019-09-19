
Set-StrictMode -Version 'Latest'

Describe 'Bin Directory' {
    foreach( $clr in @( 'coreclr', 'fullclr' ) )
    {
        $allowedAssemblies = &{
            'Carbon.dll'
            'Carbon.Iis.dll'
            'Carbon.Xdt.dll'
            if( $clr -eq 'coreclr' )
            {
                'Microsoft.Web.Administration.dll'
            }
            'Microsoft.Web.XmlTransform.dll'
        }
        Context $clr {
            It 'should not include assemblies that ship with PowerShell' {
                $binPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\bin' -Resolve
                $binPath = Join-Path -Path $binPath -ChildPath $clr
                $binPath = Join-Path -Path $BinPath  -ChildPath '*'
                Get-ChildItem -Path $binPath -Exclude ($allowedAssemblies + '*.pdb') | Should -BeNullOrEmpty
            }
        }

    }
}