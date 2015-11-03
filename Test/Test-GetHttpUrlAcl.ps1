
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

function Test-ShouldGetAllUrlAcls
{
    [Carbon.Security.HttpUrlSecurity[]]$acls = Get-HttpUrlAcl
    Assert-NotNull $acls
    $urlacl = netsh http show urlacl
    $urlacl = $urlacl -join [Environment]::NewLine

    foreach( $acl in $acls )
    {
        $header = '' -f $acl.Url

        if( $acl.Access.Count -eq 1 )
        {
            $rule = $acl.Access[0]
            $identity = $rule.IdentityReference.ToString()
            if( $identity -eq 'Everyone' )
            {
                $identity = '\Everyone'
            }

            $listen = 'No'
            if( $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::Register -or $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::RegisterAndDelegate )
            {
                $listen = 'Yes'
            }

            $delegate = 'No'
            if( $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::Delegate -or $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::RegisterAndDelegate )
            {
                $delegate = 'Yes'
            }

            Assert-That $urlacl -Contains (@'
    Reserved URL            : {0} 
        User: {1}
            Listen: {2}
            Delegate: {3}
'@ -f $acl.Url,$identity,$listen,$delegate)

        }
    }
}