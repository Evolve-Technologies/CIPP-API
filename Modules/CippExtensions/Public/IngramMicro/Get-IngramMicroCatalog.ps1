function Get-IngramMicroCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [Parameter(Mandatory = $false)]
        [string]$TenantFilter,
        [Parameter(Mandatory = $false)]
        [string]$ProductName,
        [Parameter(Mandatory = $false)]
        [string]$ServiceName,
        [Parameter(Mandatory = $false)]
        [string]$MPN,
        [Parameter(Mandatory = $false)]
        [string]$Vendor = 'microsoft',
        [Parameter(Mandatory = $false)]
        [int]$Limit = 500,
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
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $AuthHeader = Get-IngramMicroAuthentication
    
    try {
        # Build query parameters
        $QueryParams = @()
        if ($ProductName) { $QueryParams += "name=$([System.Web.HttpUtility]::UrlEncode($ProductName))" }
        if ($ServiceName) { $QueryParams += "serviceName=$([System.Web.HttpUtility]::UrlEncode($ServiceName))" }
        if ($MPN) { $QueryParams += "mpn=$([System.Web.HttpUtility]::UrlEncode($MPN))" }
        if ($Vendor) { $QueryParams += "vendor=$([System.Web.HttpUtility]::UrlEncode($Vendor))" }
        $QueryParams += "limit=$Limit"
        $QueryParams += "offset=$Offset"
        
        $QueryString = $QueryParams -join '&'
        $Uri = "$($Config.BaseUrl)/products?$QueryString"
        
        $Response = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
        
        # Transform to match CIPP's expected format
        $Products = $Response.data | ForEach-Object {
            [PSCustomObject]@{
                sku = $_.mpn
                name = @(@{ value = $_.name })
                description = @(@{ value = $_.description })
                billingCycle = $_.billingPeriod.unit
                commitmentTerm = $_.subscriptionPeriod.unit
                vendor = $_.vendor
                productId = $_.id
                unitPrice = $_.unitPrice
                minQuantity = $_.minQuantity
                maxQuantity = $_.maxQuantity
            }
        }
        
        return $Products
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to get catalog: $_" -Sev 'Error'
        throw "Failed to get Ingram Micro catalog: $_"
    }
}