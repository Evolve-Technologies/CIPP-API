function Test-IngramMicroConnection {
    [CmdletBinding()]
    param()
    
    try {
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
        
        if (-not $Config -or -not $Config.Enabled) {
            return @{
                Success = $false
                Message = 'Ingram Micro extension is not enabled'
            }
        }
        
        # Test authentication
        $AuthHeader = Get-IngramMicroAuthentication -RenewToken
        
        # Test API access by getting reseller info
        $Uri = "$($Config.BaseUrl)/resellers"
        $TestResponse = Invoke-RestMethod -Uri $Uri -Method GET -Headers $AuthHeader
        
        if ($TestResponse) {
            return @{
                Success = $true
                Message = 'Successfully connected to Ingram Micro API'
                ResellerInfo = $TestResponse.data | Select-Object -First 1
            }
        } else {
            return @{
                Success = $false
                Message = 'Connected but no data returned'
            }
        }
    } catch {
        return @{
            Success = $false
            Message = "Connection test failed: $_"
        }
    }
}