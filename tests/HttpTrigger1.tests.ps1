Describe "Testing HttpTrigger1" {

    BeforeAll {
        # load the functions implementation module (a.k.a. the test subject)
        Get-Module -Name azure-functions | Remove-Module
        Import-Module -Name (Join-Path -Path (Get-Item -Path $PSScriptRoot).Parent -ChildPath "FunctionApp\lib\azure-functions.psm1")

        # load azure functions stub classes and functions
        . "$PSScriptRoot\functions-stubs.ps1"

        # create some mocks
        Mock -CommandName 'Push-OutputBinding' -MockWith { }
        Mock -CommandName 'Write-Host' -MockWith { }
    }

    Context "Function config" {

        BeforeAll {
            # load the function.json
            $functionPath = Join-Path -Path (Get-Item -Path $PSScriptRoot).Parent -ChildPath "FunctionApp\HttpTrigger1"
            $functionConfig = Get-Content -Path "$functionPath\function.json" | ConvertFrom-Json
        }

        It "has the correct HttpTrigger input binding" {
            $binding = $functionConfig.bindings.Where({$_.direction -eq 'in' -and $_.type -eq 'httpTrigger'})
            $binding.Count | Should -Be 1
            $binding.name | Should -Be 'Request'
            $binding.methods | Should -Be @('get', 'post')
            $binding.authLevel | Should -Be 'anonymous'
        }

        It "has the correct http output binding" {
            $binding = $functionConfig.bindings.Where({$_.direction -eq 'out' -and $_.type -eq 'http'})
            $binding.Count | Should -Be 1
            $binding.name | Should -Be 'Response'
        }

        It "references the correct implementation function" {
            $functionConfig.scriptFile | Should -Be "../lib/azure-functions.psm1"
            $functionConfig.entryPoint | Should -Be "Invoke-HttpTrigger1"
        }

    }
    
    Context "Function output" {

        # set up some test cases
        . "$PSScriptRoot\functions-stubs.ps1"
        $defaultBody = 'This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.'
        $customBody = 'Hello, {0}. This HTTP triggered function executed successfully.'

        $testCases = @(
            @{
                request = @{ Query = @{ Name = 'query' } }
                expectedResponse = [HttpResponseContext]@{ StatusCode = 'OK'; Body = ($customBody -f 'query') }
            }
            @{
                request = @{ Body = @{ Name = 'body' } }
                expectedResponse = [HttpResponseContext]@{ StatusCode = 'OK'; Body = ($customBody -f 'body') }
            }
            @{
                request = @{ Query = @{ Name = 'query' }; Body = @{ Name = 'body' } }
                expectedResponse = [HttpResponseContext]@{ StatusCode = 'OK'; Body = ($customBody -f 'query') }
            }
            @{
                request = $null
                expectedResponse = [HttpResponseContext]@{ StatusCode = 'OK'; Body = $defaultBody }
            }
        )

        # test
        It 'passes the correct HTTP response into the HTTP output binding' -TestCases $testCases {
            Invoke-HttpTrigger1 -Request $request -TriggerMetadata @{}
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Name -eq 'Response' -and $Value -as [HttpResponseContext] }
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Name -eq 'Response' -and $Value.StatusCode -eq $expectedResponse.StatusCode }
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Name -eq 'Response' -and $Value.Body -eq $expectedResponse.Body }
        }
    }
}
