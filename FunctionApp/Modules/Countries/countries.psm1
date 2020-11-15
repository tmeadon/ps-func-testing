function Search-CountryName {
    [CmdletBinding()]
    param
    (
        # term to perform country name search on
        [Parameter(Mandatory)]
        [string]
        $SearchTerm
    )

    begin {}

    process
    {
        Invoke-RestMethod -Uri "https://restcountries.eu/rest/v2/name/$SearchTerm"
    }

    end {}
}

function Get-RandomCountry {
    [CmdletBinding()]
    param ()

    begin {}

    process
    {
        $allCountries = Invoke-RestMethod -Uri "https://restcountries.eu/rest/v2/all"
        Get-Random -InputObject $allCountries 
    }

    end {}
}

function New-FunctionOutput {
    [CmdletBinding()]
    param
    (
        # object containing output from restcountries api
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject[]]
        $CountryResponse
    )

    begin {}

    process
    {
        foreach ($item in $CountryResponse)
        {
            [PSCustomObject]@{
                Name = $item.name
                CapitalCity = $item.capital
                Region = $item.region
                SubRegion = $item.subregion
            }
        }
    }

    end {}
}