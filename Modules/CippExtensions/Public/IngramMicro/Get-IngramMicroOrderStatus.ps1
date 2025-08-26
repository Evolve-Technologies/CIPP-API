function Get-IngramMicroOrderStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrderId
    )
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $AuthHeader = Get-IngramMicroAuthentication
    
    try {
        $Uri = "$($Config.BaseUrl)/orders/$OrderId"
        $Order = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
        
        # Transform to user-friendly format
        $OrderStatus = [PSCustomObject]@{
            orderId = $Order.id
            status = $Order.status
            creationDate = $Order.creationDate
            customerId = $Order.customerId
            customerName = $Order.customerName
            totalPrice = $Order.totalPrice
            products = $Order.products | ForEach-Object {
                [PSCustomObject]@{
                    name = $_.name
                    mpn = $_.mpn
                    quantity = $_.quantity
                    unitPrice = $_.unitPrice
                    extendedPrice = $_.extendedPrice
                    status = $_.status
                }
            }
            subscriptions = $Order.subscriptions
        }
        
        return $OrderStatus
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to get order status: $_" -Sev 'Error'
        throw "Failed to get Ingram Micro order status: $_"
    }
}