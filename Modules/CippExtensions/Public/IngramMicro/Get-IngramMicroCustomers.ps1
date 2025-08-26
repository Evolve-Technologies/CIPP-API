function Get-IngramMicroCustomers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [Parameter(Mandatory = $false)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Email,
        [Parameter(Mandatory = $false)]
        [string]$ExternalId,
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100,
        [Parameter(Mandatory = $false)]
        [int]$Offset = 0
    )
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $AuthHeader = Get-IngramMicroAuthentication
    
    try {
        if ($CustomerId) {
            # Get specific customer
            $Uri = "$($Config.BaseUrl)/customers/$CustomerId"
            $Customer = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
            return $Customer
        } else {
            # List customers with filters
            $QueryParams = @()
            if ($Name) { $QueryParams += "name=$([System.Web.HttpUtility]::UrlEncode($Name))" }
            if ($Email) { $QueryParams += "email=$([System.Web.HttpUtility]::UrlEncode($Email))" }
            if ($ExternalId) { $QueryParams += "externalId=$([System.Web.HttpUtility]::UrlEncode($ExternalId))" }
            $QueryParams += "limit=$Limit"
            $QueryParams += "offset=$Offset"
            
            $QueryString = $QueryParams -join '&'
            $Uri = "$($Config.BaseUrl)/customers?$QueryString"
            
            $Response = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
            return $Response.data
        }
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to get customers: $_" -Sev 'Error'
        throw "Failed to get Ingram Micro customers: $_"
    }
}