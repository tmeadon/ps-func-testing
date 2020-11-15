using namespace System.Net

# input bindings are passed in via param block.
param($Request, $TriggerMetadata)

if ($Request.Query.NameSearch)
{
    # query by country name
    $result = Invoke-RestMethod -Uri "https://restcountries.eu/rest/v2/name/$($Request.Query.NameSearch)"
}
else
{
    # get a random country
    $allCountries = Invoke-RestMethod -Uri "https://restcountries.eu/rest/v2/all"
    $result = $allCountries | Get-Random 
}

# create function output
$output = foreach ($country in $result)
{
    [PSCustomObject]@{
        Name = $country.name
        CapitalCity = $country.capital
        Region = $country.region
        SubRegion = $country.subregion
    }
}

# return the output
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $output
})
