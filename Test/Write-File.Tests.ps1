# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Write-File' {

    $file = ''
    
    BeforeEach {
        $Global:Error.Clear()
        $file = Join-Path -Path 'TestDrive:' -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $file -ItemType 'File'
        $file = Get-Item -Path $file | Select-Object -ExpandProperty 'FullName'
    }
    
    It 'should write multiple lines to a file using a pipeline' {
        @( 'a', 'b' ) | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}b{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write one line to a file using a pipeline' {
        'a' | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write nothing to a file using a pipeline' {
        'a' | Set-Content -Path $file

        @() | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should BeNullOrEmpty
    }
    
    It 'should write an empty string to a file using a parameter' {
        '' | Write-File -Path $file

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write multiple lines to a file using a parameter' {
        Write-File -Path $file -InputObject @( 'a', 'b' )

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}b{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write one line to a file using a parameter' {
        Write-File -Path $file -InputObject 'a' 

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("a{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write an empty string to a file using a parameter' {
        Write-File -Path $file -InputObject '' 

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should Be ("{0}" -f [Environment]::NewLine) 
    }
    
    It 'should write nothing to a file using a parameter' {
        'a' | Set-Content -Path $file

        Write-File -Path $file -InputObject @()

        $contents = [IO.File]::ReadAllText($file)
        $contents | Should BeNullOrEmpty
    }
    
    It 'should support what if' {
        'a' | Set-Content -Path $file
        'b' | Write-File -Path $file -WhatIf
        [IO.File]::ReadAllText($file) | Should Be ("a{0}" -f [Environment]::NewLine)
    }

    function Lock-File
    {
        param(
            $Seconds
        )

        Start-Job -ScriptBlock {
                                            
                                    $file = [IO.File]::Open($using:file, 'Open', 'Write', 'None')
                                    try
                                    {
                                        Start-Sleep -Seconds $using:Seconds
                                    }
                                    finally
                                    {
                                        $file.Close()
                                    }
                                }
        # Wait for file to get locked
        do
        {
            Start-Sleep -Milliseconds 100
            Write-Debug -Message ('Waiting for hosts file to get locked.')
        }
        while( (Get-Content -Path $file -ErrorAction SilentlyContinue ) )

        $Global:Error.Clear()
    }
        
    It 'should wait while file is in use' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1
        try
        {
            'a' | Write-File -Path $file
            $Global:Error.Count | Should Be 0
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

        [IO.File]::ReadAllText($file) | Should Be ("a{0}" -f [Environment]::NewLine)
    }
  
    It 'should wait while file is in use and $Global:Error is full' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1
        try
        {
            1..256 | ForEach-Object { Write-Error -Message $_ -ErrorAction SilentlyContinue }
            'a' | Write-File -Path $file
            $Global:Error.Count | Should Be 256
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

        [IO.File]::ReadAllText($file) | Should Be ("a{0}" -f [Environment]::NewLine)
    }
  
    It 'should control how long to wait for file to be released and report final error' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1
        try
        {
            # Wait for file to get locked
            'a' | Write-File -Path $file -MaximumTries 1 -RetryDelayMilliseconds 100 -ErrorAction SilentlyContinue
            $Global:Error.Count | Should Be 1
            $Global:Error | Should Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

        [IO.File]::ReadAllText($file) | Should Be ("b{0}" -f [Environment]::NewLine)
    }


    It 'should report errors with ErrorVariable parameter' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1
        try
        {
            $result = 'a' | Write-File -Path $file -MaximumTries 1 -ErrorVariable 'cmdErrors' -ErrorAction SilentlyContinue
            ,$result | Should BeNullOrEmpty
            ,$cmdErrors | Should Not BeNullOrEmpty
            $cmdErrors.Count | Should BeGreaterThan 0
            $cmdErrors | Should Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
        Get-Content -Path $file | Should Be 'b'

    }
}