function Set-CIPPIngramMicroLicense {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter,
        [Parameter(Mandatory = $true)]
        [string]$SKU,
        [Parameter(Mandatory = $false)]
        [int]$Quantity,
        [Parameter(Mandatory = $false)]
        [int]$Add,
        [Parameter(Mandatory = $false)]
        [int]$Remove,
        [Parameter(Mandatory = $false)]
        $Headers,
        [Parameter(Mandatory = $false)]
        [hashtable]$OrderParameters
    )
    
    try {
        # Check if IngramMicro is enabled
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $ExtensionConfig = (Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json
        
        if (-not $ExtensionConfig.IngramMicro.Enabled) {
            throw 'Ingram Micro extension is not enabled'
        }
        
        # Call the IngramMicro subscription management function
        $Result = Set-IngramMicroSubscription -TenantFilter $TenantFilter -SKU $SKU -Quantity $Quantity -Add $Add -Remove $Remove -Headers $Headers -OrderParameters $OrderParameters
        
        Write-LogMessage -API 'IngramMicroLicense' -message "Successfully processed license change for tenant $TenantFilter" -Sev 'Info'
        
        return $Result
    } catch {
        Write-LogMessage -API 'IngramMicroLicense' -message "Failed to process license change: $_" -Sev 'Error'
        throw $_
    }
}