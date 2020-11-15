Describe "Countries Tests" {

    BeforeAll {
        # reload the module
        Get-Module -Name "countries" | Remove-Module
        Import-Module -Name (Join-Path -Path (Get-Item -Path $PSScriptRoot).Parent -ChildPath "FunctionApp\Modules\Countries")
    }

    Context "Test countries module" {

        BeforeEach {
            # load example api response and function output
            $exampleResponse = Get-Content -Path "$PSScriptRoot\example-api-response.json" | ConvertFrom-Json
            $expectedOutput = Get-Content -Path "$PSScriptRoot\example-function-output.json" | ConvertFrom-Json
    
            # create a mock for Invoke-RestMethod that returns the example response
            Mock -CommandName 'Invoke-RestMethod' -MockWith { $exampleResponse }

            # create a mock for Get-Random that just returns the first item in $InputObject
            Mock -CommandName 'Get-Random' -MockWith { $InputObject[0] }

            # store the countries api base uri
            $baseUri = "https://restcountries.eu/rest/v2"
        }

        It "Search-CountryName returns the raw output from the REST countries API" {
            Search-CountryName -SearchTerm 'xyz' | Should -Be $exampleResponse
        }

        It "Search-CountryName calls the correct uri" {
            Search-CountryName -SearchTerm 'xyz'
            Should -Invoke 'Invoke-RestMethod' -Exactly 1 -ParameterFilter { $Uri -eq "$baseUri/name/xyz" }
        }

        It "Get-RandomCountry returns the raw output from the REST countries API" {
            Get-RandomCountry | Should -Be $exampleResponse[0]
        }

        It "Get-RandomCountry calls the correct uri" {
            Get-RandomCountry
            Should -Invoke 'Invoke-RestMethod' -Exactly 1 -ParameterFilter { $Uri -eq "$baseUri/all" }
        }

        It "New-FunctionOutput returns the correct output" {
            (New-FunctionOutput -CountryResponse $exampleResponse | ConvertTo-Json) | Should -Be ($expectedOutput | ConvertTo-Json)
        } 
    }

    Context "Test Function" {

        BeforeAll {
            # load functions runtime stubs
            . "$PSScriptRoot\functions-stubs.ps1"

            # store some variables
            $scriptPath = (Join-Path -Path (Get-Item -Path $PSScriptRoot).Parent -ChildPath "FunctionApp\Countries\run.ps1")
            $functionConfig = Get-Content -Path (Join-Path -Path (Get-Item -Path $PSScriptRoot).Parent -ChildPath "FunctionApp\Countries\function.json") | ConvertFrom-Json
            $httpOutBindingName = $functionConfig.bindings.Where({$_.direction -eq 'out' -and $_.type -eq 'http'}).name
            $nameSearchOutput = 'search-results'
            $randomOutput = 'random-country'

            # create some shared mocks
            Mock -CommandName 'Search-CountryName' -MockWith { $nameSearchOutput }
            Mock -CommandName 'Get-RandomCountry' -MockWith { $randomOutput }
            Mock -CommandName 'New-FunctionOutput' -MockWith { $CountryResponse }
            Mock -CommandName 'Push-OutputBinding' -MockWith { }
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

        It "produces the correct output if NameSearch is in the query string" {
            & $scriptPath -Request @{ Query = @{ NameSearch = 'xyz' }}
            Should -Invoke 'Search-CountryName' -Exactly 1 -ParameterFilter { $SearchTerm -eq 'xyz' }
            Should -Invoke 'New-FunctionOutput' -Exactly 1 -ParameterFilter { $CountryResponse -eq $nameSearchOutput }
        }

        It "produces the correct output if NameSearch is not in the query string" {
            & $scriptPath -Request @{}
            Should -Invoke 'Get-RandomCountry' -Exactly 1
            Should -Invoke 'New-FunctionOutput' -Exactly 1 -ParameterFilter { $CountryResponse -eq $randomOutput }
        }

        It "sends the correct output to the correct output binding if NameSearch is in the query string" {
            & $scriptPath -Request @{ Query = @{ NameSearch = 'xyz' }}
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Name -eq $httpOutBindingName }
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Value.StatusCode -eq [System.Net.HttpStatusCode]::OK }
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Value.Body -eq $nameSearchOutput }
        }

        It "sends the correct output to the correct output binding if NameSearch is not in the query string" {
            & $scriptPath -Request @{}
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Name -eq $httpOutBindingName }
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Value.StatusCode -eq [System.Net.HttpStatusCode]::OK }
            Should -Invoke 'Push-OutputBinding' -Exactly 1 -ParameterFilter { $Value.Body -eq $randomOutput }
        }
    }
}
