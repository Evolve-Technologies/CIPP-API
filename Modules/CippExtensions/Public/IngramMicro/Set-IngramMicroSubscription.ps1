function Set-IngramMicroSubscription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [Parameter(Mandatory = $true)]
        [string]$SKU,
        [Parameter(Mandatory = $false)]
        [int]$Quantity,
        [Parameter(Mandatory = $false)]
        [int]$Add,
        [Parameter(Mandatory = $false)]
        [int]$Remove,
        [Parameter(Mandatory = $false)]
        [string]$TenantFilter,
        [Parameter(Mandatory = $false)]
        $Headers,
        [Parameter(Mandatory = $false)]
        [string]$ProductId,
        [Parameter(Mandatory = $false)]
        [hashtable]$OrderParameters
    )
    
    if ($Headers) {
        # Get extension config and check for AllowedCustomRoles
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $ExtensionConfig = (Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json
        $Config = $ExtensionConfig.IngramMicro
        
        $AllowedRoles = $Config.AllowedCustomRoles.value
        if ($AllowedRoles -and $Headers.'x-ms-client-principal') {
            $UserRoles = Get-CIPPAccessRole -Headers $Headers
            $Allowed = $false
            foreach ($Role in $UserRoles) {
                if ($AllowedRoles -contains $Role) {
                    Write-Information "User has allowed CIPP role: $Role"
                    $Allowed = $true
                    break
                }
            }
            if (-not $Allowed) {
                throw 'This user is not allowed to modify Ingram Micro subscriptions.'
            }
        }
    }
    
    if ($TenantFilter) {
        $TenantFilter = (Get-Tenants -TenantFilter $TenantFilter).customerId
        $Mapping = Get-IngramMicroMapping -TenantId $TenantFilter
        if ($Mapping) {
            $CustomerId = $Mapping.IntegrationId
        } else {
            throw 'No Ingram Micro mapping found for this tenant'
        }
    }
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $AuthHeader = Get-IngramMicroAuthentication
    
    # Check for existing subscription
    $ExistingSubscription = Get-IngramMicroCurrentSubscription -CustomerId $CustomerId -SKU $SKU
    
    if (-not $ExistingSubscription) {
        # Create new subscription via order
        if ($Add -or $Remove) {
            throw "Unable to Add or Remove. No existing subscription with SKU '$SKU' found."
        }
        
        if (-not $Quantity -or $Quantity -le 0) {
            throw 'A valid Quantity must be specified to create a new subscription when none currently exists.'
        }
        
        # Get product details if not provided
        if (-not $ProductId) {
            $Products = Get-IngramMicroCatalog -CustomerId $CustomerId -MPN $SKU
            if (-not $Products) {
                throw "Product with SKU '$SKU' not found in catalog"
            }
            $ProductId = $Products[0].productId
        }
        
        # Build order request
        $OrderBody = @{
            customerId = $CustomerId
            products = @(
                @{
                    id = $ProductId
                    quantity = $Quantity
                }
            )
        }
        
        # Add order parameters if provided
        if ($OrderParameters) {
            $OrderBody.orderParameters = @()
            foreach ($key in $OrderParameters.Keys) {
                $OrderBody.orderParameters += @{
                    name = $key
                    value = $OrderParameters[$key]
                }
            }
        }
        
        $OrderJson = $OrderBody | ConvertTo-Json -Depth 10
        
        try {
            # First estimate the order
            $EstimateUri = "$($Config.BaseUrl)/orders/estimate"
            $Estimate = Invoke-RestMethod -Uri $EstimateUri -Method POST -Headers $AuthHeader -Body $OrderJson -ContentType 'application/json'
            
            # Then place the actual order
            $OrderUri = "$($Config.BaseUrl)/orders"
            $Order = Invoke-RestMethod -Uri $OrderUri -Method POST -Headers $AuthHeader -Body $OrderJson -ContentType 'application/json'
            
            Write-LogMessage -API 'IngramMicro' -message "Created new order for $Quantity licenses of SKU $SKU for customer $CustomerId" -Sev 'Info'
            return $Order
        } catch {
            Write-LogMessage -API 'IngramMicro' -message "Failed to create order: $_" -Sev 'Error'
            throw "Failed to create Ingram Micro order: $_"
        }
        
    } else {
        # Modify existing subscription
        $SubscriptionId = $ExistingSubscription[0].subscriptionId
        $CurrentQuantity = $ExistingSubscription[0].quantity
        
        if ($Add) {
            $FinalQuantity = $CurrentQuantity + $Add
        } elseif ($Remove) {
            $FinalQuantity = $CurrentQuantity - $Remove
            if ($FinalQuantity -lt 0) {
                throw "Cannot remove more licenses than currently allocated. Current: $CurrentQuantity, Attempting to remove: $Remove."
            }
        } else {
            if (-not $Quantity -or $Quantity -le 0) {
                throw 'A valid Quantity must be specified if Add/Remove are not used.'
            }
            $FinalQuantity = $Quantity
        }
        
        # Get the product from the subscription
        $ProductInSubscription = $ExistingSubscription[0]
        
        # Build update request
        $UpdateBody = @{
            products = @(
                @{
                    mpn = $SKU
                    quantity = $FinalQuantity
                }
            )
        } | ConvertTo-Json -Depth 10
        
        try {
            $UpdateUri = "$($Config.BaseUrl)/subscriptions/$SubscriptionId"
            $Update = Invoke-RestMethod -Uri $UpdateUri -Method PATCH -Headers $AuthHeader -Body $UpdateBody -ContentType 'application/json'
            
            Write-LogMessage -API 'IngramMicro' -message "Updated subscription $SubscriptionId quantity from $CurrentQuantity to $FinalQuantity" -Sev 'Info'
            return $Update
        } catch {
            Write-LogMessage -API 'IngramMicro' -message "Failed to update subscription: $_" -Sev 'Error'
            throw "Failed to update Ingram Micro subscription: $_"
        }
    }
}