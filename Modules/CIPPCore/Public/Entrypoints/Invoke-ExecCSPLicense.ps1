using namespace System.Net

function Invoke-ExecCSPLicense {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.Directory.ReadWrite
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Body.tenantFilter
    $Action = $Request.Body.Action
    $SKU = $Request.Body.SKU.value ?? $Request.Body.SKU

    try {
        # Check which CSP integration is enabled
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $ExtensionConfig = (Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json
        
        if ($ExtensionConfig.Sherweb.Enabled) {
            if ($Action -eq 'Add') {
                $null = Set-SherwebSubscription -Headers $Headers -tenantFilter $TenantFilter -SKU $SKU -add $Request.Body.Add
            }

            if ($Action -eq 'Remove') {
                $null = Set-SherwebSubscription -Headers $Headers -tenantFilter $TenantFilter -SKU $SKU -remove $Request.Body.Remove
            }

            if ($Action -eq 'NewSub') {
                $null = Set-SherwebSubscription -Headers $Headers -tenantFilter $TenantFilter -SKU $SKU -Quantity $Request.Body.Quantity
            }
            if ($Action -eq 'Cancel') {
                $null = Remove-SherwebSubscription -Headers $Headers -tenantFilter $TenantFilter -SubscriptionIds $Request.Body.SubscriptionIds
            }
        } elseif ($ExtensionConfig.IngramMicro.Enabled) {
            if ($Action -eq 'Add') {
                $null = Set-IngramMicroSubscription -Headers $Headers -tenantFilter $TenantFilter -SKU $SKU -add $Request.Body.Add
            }

            if ($Action -eq 'Remove') {
                $null = Set-IngramMicroSubscription -Headers $Headers -tenantFilter $TenantFilter -SKU $SKU -remove $Request.Body.Remove
            }

            if ($Action -eq 'NewSub') {
                $OrderParams = @{}
                if ($Request.Body.OrderParameters) {
                    $OrderParams = $Request.Body.OrderParameters
                }
                $null = Set-IngramMicroSubscription -Headers $Headers -tenantFilter $TenantFilter -SKU $SKU -Quantity $Request.Body.Quantity -OrderParameters $OrderParams
            }
            if ($Action -eq 'Cancel') {
                # IngramMicro uses subscription IDs directly
                foreach ($SubscriptionId in $Request.Body.SubscriptionIds) {
                    $null = Remove-IngramMicroSubscription -SubscriptionId $SubscriptionId
                }
            }
        } else {
            throw 'No CSP integration is enabled'
        }
        
        $Result = 'License change executed successfully.'
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $Result = "Failed to execute license change. Error: $_"
        $StatusCode = [HttpStatusCode]::InternalServerError
    }
    # If $GraphRequest is a GUID, the subscription was edited successfully, and return that it's done.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $Result
        }) -Clobber

}
