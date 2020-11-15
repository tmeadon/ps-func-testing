using namespace System.Net

# input bindings are passed in via param block.
param($Request, $TriggerMetadata)

if ($Request.Query.NameSearch)
{
    # query by country name
    $response = Search-CountryName -SearchTerm $Request.Query.NameSearch
}
else
{
    # get a random country
    $response = Get-RandomCountry
}

# create out output
$output = $response | New-FunctionOutput

# return the output
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $output
})
