function Get-IngramMicroCurrentSubscription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [Parameter(Mandatory = $false)]
        [string]$TenantFilter,
        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $false)]
        [string]$SKU,
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100,
        [Parameter(Mandatory = $false)]
        [int]$Offset = 0
    )
    
    if ($TenantFilter) {
        $TenantFilter = (Get-Tenants -TenantFilter $TenantFilter).customerId
        $Mapping = Get-IngramMicroMapping -TenantId $TenantFilter
        if ($Mapping) {
            $CustomerId = $Mapping.IntegrationId
        } else {
            throw 'No Ingram Micro mapping found for this tenant'
        }
    }
    
    if (-not $CustomerId -and -not $SubscriptionId) {
        throw 'Either CustomerId or SubscriptionId must be provided'
    }
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $AuthHeader = Get-IngramMicroAuthentication
    
    try {
        if ($SubscriptionId) {
            # Get specific subscription
            $Uri = "$($Config.BaseUrl)/subscriptions/$SubscriptionId"
            $Subscription = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
            return $Subscription
        } else {
            # List subscriptions with filters
            $QueryParams = @()
            $QueryParams += "customerId=$([System.Web.HttpUtility]::UrlEncode($CustomerId))"
            $QueryParams += "limit=$Limit"
            $QueryParams += "offset=$Offset"
            
            $QueryString = $QueryParams -join '&'
            $Uri = "$($Config.BaseUrl)/subscriptions?$QueryString"
            
            $Response = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
            
            # Filter by SKU if specified
            if ($SKU) {
                $Subscriptions = $Response.data | Where-Object { 
                    $_.products | Where-Object { $_.mpn -eq $SKU }
                }
            } else {
                $Subscriptions = $Response.data
            }
            
            # Transform to match CIPP's expected format
            $FormattedSubscriptions = $Subscriptions | ForEach-Object {
                $subscription = $_
                $subscription.products | ForEach-Object {
                    [PSCustomObject]@{
                        id = $subscription.id
                        subscriptionId = $subscription.id
                        name = $subscription.name
                        sku = $_.mpn
                        productName = $_.name
                        quantity = $_.quantity
                        status = $subscription.status
                        creationDate = $subscription.creationDate
                        renewalDate = $subscription.renewalDate
                        expirationDate = $subscription.expirationDate
                        billingPeriod = $subscription.billingPeriod
                        subscriptionPeriod = $subscription.subscriptionPeriod
                        totalPrice = $subscription.totalPrice
                        vendor = $_.vendor
                        vendorSubscriptionId = $_.vendorSubscriptionId
                    }
                }
            }
            
            return $FormattedSubscriptions
        }
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to get subscriptions: $_" -Sev 'Error'
        throw "Failed to get Ingram Micro subscriptions: $_"
    }
}