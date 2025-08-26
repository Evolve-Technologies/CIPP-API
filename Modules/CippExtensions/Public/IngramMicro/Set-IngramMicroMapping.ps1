function Set-IngramMicroMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        [Parameter(Mandatory = $true)]
        [string]$IngramMicroCustomerId,
        [Parameter(Mandatory = $false)]
        [string]$IngramMicroCustomerName
    )
    
    $Table = Get-CIPPTable -TableName ExtensionsMappingTable
    
    $Mapping = @{
        PartitionKey = 'IngramMicroMapping'
        RowKey       = $TenantId
        IntegrationId = $IngramMicroCustomerId
        IntegrationName = $IngramMicroCustomerName
    }
    
    try {
        Add-CIPPAzDataTableEntity @Table -Entity $Mapping -Force
        Write-LogMessage -API 'IngramMicro' -message "Mapped tenant $TenantId to Ingram Micro customer $IngramMicroCustomerId" -Sev 'Info'
        return "Successfully mapped tenant to Ingram Micro customer"
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to map tenant: $_" -Sev 'Error'
        throw "Failed to create Ingram Micro mapping: $_"
    }
}

function Get-IngramMicroMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId
    )
    
    $Table = Get-CIPPTable -TableName ExtensionsMappingTable
    
    if ($TenantId) {
        $Filter = "PartitionKey eq 'IngramMicroMapping' and RowKey eq '$TenantId'"
    } else {
        $Filter = "PartitionKey eq 'IngramMicroMapping'"
    }
    
    $Mappings = Get-CIPPAzDataTableEntity @Table -Filter $Filter
    
    return $Mappings
}

function Remove-IngramMicroMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId
    )
    
    $Table = Get-CIPPTable -TableName ExtensionsMappingTable
    
    try {
        $Entity = @{
            PartitionKey = 'IngramMicroMapping'
            RowKey       = $TenantId
        }
        Remove-AzDataTableEntity @Table -Entity $Entity
        Write-LogMessage -API 'IngramMicro' -message "Removed Ingram Micro mapping for tenant $TenantId" -Sev 'Info'
        return "Successfully removed Ingram Micro mapping"
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to remove mapping: $_" -Sev 'Error'
        throw "Failed to remove Ingram Micro mapping: $_"
    }
}