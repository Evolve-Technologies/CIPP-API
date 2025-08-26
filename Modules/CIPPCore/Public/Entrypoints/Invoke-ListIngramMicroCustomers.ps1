using namespace System.Net

Function Invoke-ListIngramMicroCustomers {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        CIPP.Extension.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    try {
        # Get IngramMicro customers
        $Customers = Get-IngramMicroCustomers -Limit 500
        
        # Format for frontend
        $FormattedCustomers = $Customers | ForEach-Object {
            [PSCustomObject]@{
                value = $_.id
                label = "$($_.name) ($($_.id))"
                name = $_.name
                id = $_.id
                email = $_.contactEmail
                externalId = $_.externalId
            }
        }
        
        $StatusCode = [HttpStatusCode]::OK
        $Result = $FormattedCustomers
    } catch {
        $Result = "Failed to retrieve Ingram Micro customers: $_"
        $StatusCode = [HttpStatusCode]::InternalServerError
        Write-LogMessage -API $APIName -headers $Headers -message $Result -Sev 'Error'
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @($Result)
        }) -Clobber
}