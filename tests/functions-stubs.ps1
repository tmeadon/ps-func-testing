using namespace System.Net

class HttpResponseContext
{
    [HttpStatusCode] $StatusCode
    [object] $Body
}

function Push-OutputBinding
{
    [CmdletBinding()]
    param ($Name, $Value)
}
