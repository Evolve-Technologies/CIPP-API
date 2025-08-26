using namespace System.Net

Function Invoke-ListCSPsku {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.Directory.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Query.tenantFilter
    $CurrentSkuOnly = $Request.Query.currentSkuOnly

    try {
        # Check which CSP integration is enabled
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $ExtensionConfig = (Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json
        
        if ($ExtensionConfig.Sherweb.Enabled) {
            if ($CurrentSkuOnly) {
                $GraphRequest = Get-SherwebCurrentSubscription -TenantFilter $TenantFilter
            } else {
                $GraphRequest = Get-SherwebCatalog -TenantFilter $TenantFilter
            }
        } elseif ($ExtensionConfig.IngramMicro.Enabled) {
            if ($CurrentSkuOnly) {
                $GraphRequest = Get-IngramMicroCurrentSubscription -TenantFilter $TenantFilter
            } else {
                $GraphRequest = Get-IngramMicroCatalog -TenantFilter $TenantFilter
            }
        } else {
            throw 'No CSP integration is enabled'
        }
        
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $GraphRequest = [PSCustomObject]@{
            name = @(@{value = 'Error getting catalog' })
            sku  = $_.Exception.Message
        }
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @($GraphRequest)
        }) -Clobber

}
