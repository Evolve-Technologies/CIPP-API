using namespace System.Net

Function Invoke-ListCSPLicenses {
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

    try {
        # Check which CSP integration is enabled
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $ExtensionConfig = (Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json
        
        if ($ExtensionConfig.Sherweb.Enabled) {
            $Result = Get-SherwebCurrentSubscription -TenantFilter $TenantFilter
        } elseif ($ExtensionConfig.IngramMicro.Enabled) {
            $Result = Get-IngramMicroCurrentSubscription -TenantFilter $TenantFilter
        } else {
            throw 'No CSP integration is enabled'
        }
        
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $Result = 'Unable to retrieve CSP licenses, ensure that you have enabled a CSP integration (Sherweb or Ingram Micro) and mapped the tenant in the integration settings.'
        $StatusCode = [HttpStatusCode]::BadRequest
    }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @($Result)
        }) -Clobber

}
