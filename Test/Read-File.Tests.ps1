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

Describe 'Read-File' {

    $file = ''

    function Lock-File
    {
        param(
            $Seconds
        )

        Start-Job -ScriptBlock {
                                    $file = [IO.File]::Open($using:file, 'Open', 'Read', 'None')
                                    try
                                    {
                                        Start-Sleep -Seconds $using:Seconds
                                    }
                                    finally
                                    {
                                        $file.Close()
                                    }
                               }

        do
        {
            Start-Sleep -Milliseconds 100
            Write-Debug -Message ('Waiting for hosts file to get locked.')
        }
        while( (Get-Content -Path $file -ErrorAction SilentlyContinue ) )

        $Global:Error.Clear()

    }
    
    BeforeEach {
        $Global:Error.Clear()
        $file = Join-Path -Path 'TestDrive:' -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $file -ItemType 'File'
        $file = Get-Item -Path $file | Select-Object -ExpandProperty 'FullName'
    }
    
    It 'should read multiple lines' {
        @( 'a', 'b' ) | Set-Content -Path $file

        $contents = Read-File -Path $file
        $contents.Count | Should Be 2
        $contents[0] | Should Be 'a'
        $contents[1] | Should Be 'b'
    }
    
    It 'should read one line' {
        'a' | Write-File -Path $file

        $contents = Read-File -Path $file
        $contents | Should Be 'a'
    }
    
    It 'should read empty file' {
        Clear-Content -Path $file
        $contents = Read-File -Path $file
        ,$contents | Should BeNullOrEmpty
    }
    
    It 'should read raw file' {
        @( 'a', 'b' ) | Set-Content -Path $file
        $content = Read-File -Path $file -Raw
        $content | Should Be ("a{0}b{0}" -f [Environment]::NewLine)
    }
    
    It 'should wait while file is in use' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1

        try
        {
            # Simulate a full error buffer
            Read-File -Path $file | Should Be 'b'
            $Global:Error.Count | Should Be 0
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
    }

    It 'should wait while file is in use and $Global:Error is full' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1

        try
        {
            # Simulate a full error buffer
            1..256 | ForEach-Object { Write-Error -Message $_ -ErrorAction SilentlyContinue }
            Read-File -Path $file | Should Be 'b'
            $Global:Error.Count | Should Be 256
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
    }
    return
    It 'should control how long to wait for file to be released and report final error' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1

        try
        {
            Read-File -Path $file -MaximumTries 1 -RetryDelayMilliseconds 100 -ErrorAction SilentlyContinue  | Should BeNullOrEmpty
            Read-File -Path $file -MaximumTries 1 -RetryDelayMilliseconds 100 -Raw -ErrorAction SilentlyContinue| Should BeNullOrEmpty
            $Global:Error.Count | Should Be 2
            $Global:Error | Should Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }
    }

    It 'should report errors with ErrorVariable parameter' {
        'b' | Set-Content -Path $file
        $job = Lock-File -Seconds 1
        try
        {
            $result = Read-File -Path $file -MaximumTries 1 -ErrorVariable 'cmdErrors' -ErrorAction SilentlyContinue
            ,$result | Should BeNullOrEmpty
            ,$cmdErrors | Should Not BeNullOrEmpty
            $cmdErrors.Count | Should BeGreaterThan 0
            $cmdErrors | Should Match 'cannot access the file'

            $Global:Error.Clear()

            $result = Read-File -Path $file -MaximumTries 1 -Raw -ErrorVariable 'cmdErrors2' -ErrorAction SilentlyContinue
            ,$result | Should BeNullOrEmpty
            ,$cmdErrors2 | Should Not BeNullOrEmpty
            $cmdErrors2.Count | Should BeGreaterThan 0
            $cmdErrors2 | Should Match 'cannot access the file'
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Write-Debug
        }

    }
}