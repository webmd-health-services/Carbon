
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:username = 'CarbonInstallUser'
    $script:password = 'IM33tRequ!rem$'

    function Assert-Credential
    {
        param(
            $Password
        )

        try
        {
            $ctx = [DirectoryServices.AccountManagement.ContextType]::Machine
            $px = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctx,$env:COMPUTERNAME
            ($px.ValidateCredentials( $script:username, $script:password )) | Should -BeTrue
        }
        finally
        {
            $px.Dispose()
        }
    }

    function Remove-TestUser
    {
        Uninstall-CUser -Username $script:username
    }
}

Describe 'Install-CUser' {
    BeforeEach {
        Remove-TestUser
    }

    AfterEach {
        Remove-TestUser
    }

    It 'should create new user using obsolete function name and parameters' {
        $fullName = 'Carbon Install User'
        $description = "Test user for testing the Carbon Install-CUser function."
        $user = Install-User -UserName $script:username `
                              -Password $script:password `
                              -Description $description `
                              -FullName $fullName `
                              -PassThru
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user | Should -BeOfType ([DirectoryServices.AccountManagement.UserPrincipal])
            (Test-CUser -Username $script:username) | Should -BeTrue
        }
        finally
        {
            $user.Dispose()
        }

        [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-CUser -Username $script:username
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user.Description | Should -Be $description
            $user.PasswordNeverExpires | Should -BeTrue
            $user.Enabled | Should -BeTrue
            $user.SamAccountName | Should -Be $script:username
            $user.UserCannotChangePassword | Should -BeFalse
            $user.DisplayName | Should -Be $fullName
            Assert-Credential -Password $script:password
        }
        finally
        {
            $user.Dispose()
        }
    }


    It 'should create new user with credential' {
        $fullName = 'Carbon Install User'
        $description = "Test user for testing the Carbon Install-CUser function."
        $c = New-Credential -UserName $script:username -Password $script:password
        $user = Install-CUser -Credential $c -Description $description -FullName $fullName -PassThru
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user | Should -BeOfType ([DirectoryServices.AccountManagement.UserPrincipal])
            (Test-CUser -Username $script:username) | Should -BeTrue
        }
        finally
        {
            $user.Dispose()
        }

        [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-CUser -Username $script:username
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user.Description | Should -Be $description
            $user.PasswordNeverExpires | Should -BeTrue
            $user.Enabled | Should -BeTrue
            $user.SamAccountName | Should -Be $script:username
            $user.UserCannotChangePassword | Should -BeFalse
            $user.DisplayName | Should -Be $fullName
            Assert-Credential -Password $script:password
        }
        finally
        {
            $user.Dispose()
        }
    }

    It 'should update existing users properties' {
        $fullName = 'Carbon Install User'
        $result = Install-CUser -Username $script:username -Password $script:password -Description "Original description" -FullName $fullName
        $result | Should -BeNullOrEmpty

        $originalUser = Get-CUser -Username $script:username
        $originalUser | Should -Not -BeNullOrEmpty
        try
        {

            $newFullName = 'New {0}' -f $fullName
            $newDescription = "New description"
            $newPassword = 'IM33tRequ!re$2'
            $result = Install-CUser -Username $script:username `
                                   -Password $newPassword `
                                   -Description $newDescription `
                                   -FullName $newFullName `
                                   -UserCannotChangePassword `
                                   -PasswordExpires
            try
            {
                $result | Should -BeNullOrEmpty
            }
            finally
            {
                if( $result )
                {
                    $result.Dispose()
                }
            }

            [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-CUser -Username $script:username
            $newUser | Should -Not -BeNullOrEmpty
            try
            {
                $newUser.SID | Should -Be $originalUser.SID
                $newUser.Description | Should -Be $newDescription
                $newUser.DisplayName | Should -Be $newFullName
                $newUser.PasswordNeverExpires | Should -BeFalse
                $newUser.UserCannotChangePassword | Should -BeTrue
                Assert-Credential -Password $newPassword
            }
            finally
            {
                $newUser.Dispose()
            }
        }
        finally
        {
            $originalUser.Dispose()
        }
    }

    It 'should update existing users properties with credential' {
        $fullName = 'Carbon Install User'
        $credential = New-Credential -Username $script:username -Password $script:password
        $result = Install-CUser -Credential $credential -Description "Original description" -FullName $fullName
        try
        {
            $result | Should -BeNullOrEmpty
        }
        finally
        {
            if( $result )
            {
                $result.Dispose()
            }
        }

        $originalUser = Get-CUser -Username $script:username
        $originalUser | Should -Not -BeNullOrEmpty
        try
        {

            $newFullName = 'New {0}' -f $fullName
            $newDescription = "New description"
            $newPassword = [Guid]::NewGuid().ToString().Substring(0,14)
            $credential = New-Credential -UserName $script:username -Password $newPassword

            $result = Install-CUser -Credential $credential `
                                   -Description $newDescription `
                                   -FullName $newFullName `
                                   -UserCannotChangePassword `
                                   -PasswordExpires
            try
            {
                $result | Should -BeNullOrEmpty
            }
            finally
            {
                if( $result )
                {
                    $result.Dispose()
                }
            }

            [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-CUser -Username $script:username
            $newUser | Should -Not -BeNullOrEmpty
            try
            {
                $newUser.SID | Should -Be $originalUser.SID
                $newUser.Description | Should -Be $newDescription
                $newUser.DisplayName | Should -Be $newFullName
                $newUser.PasswordNeverExpires | Should -BeFalse
                $newUser.UserCannotChangePassword | Should -BeTrue
                Assert-Credential -Password $newPassword
            }
            finally
            {
                $newUser.Dispose()
            }
        }
        finally
        {
            $originalUser.Dispose()
        }
    }

    It 'should allow optional full name' {
        $fullName = 'Carbon Install User'
        $description = "Test user for testing the Carbon Install-CUser function."
        $result = Install-CUser -Username $script:username -Password $script:password -FullName $fullName -Description $description
        try
        {
            $result | Should -BeNullOrEmpty
        }
        finally
        {
            if( $result )
            {
                $result.Dispose()
            }
        }

        $user = Get-CUser -Username $script:username
        try
        {
            $user.DisplayName | Should -Be $fullName
        }
        finally
        {
            $user.Dispose()
        }
    }

    It 'should support what if' {
        $user = Install-CUser -Username $script:username -Password $script:password -WhatIf -PassThru
        try
        {
            $user | Should -Not -BeNullOrEmpty
        }
        finally
        {
            $user.Dispose()
        }

        $user = Get-CUser -Username $script:username -ErrorAction SilentlyContinue
        try
        {
            $user | Should -BeNullOrEmpty
        }
        finally
        {
            if( $user )
            {
                $user.Dispose()
            }
        }
    }
}
