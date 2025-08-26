function Get-IngramMicroAuthentication {
    [CmdletBinding()]
    param(
        [switch]$RenewToken
    )
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $APIKey = Get-ExtensionAPIKey -Extension 'IngramMicro'
    
    # Check if we have a cached token
    $TokenTable = Get-CIPPTable -TableName 'cache'
    $TokenKey = 'IngramMicroToken'
    $CachedToken = Get-CIPPAzDataTableEntity @TokenTable -Filter "RowKey eq '$TokenKey'" | Select-Object -First 1
    
    $Now = [DateTime]::UtcNow
    
    if (-not $RenewToken -and $CachedToken -and $CachedToken.ExpiresAt) {
        $ExpiresAt = [DateTime]::Parse($CachedToken.ExpiresAt)
        if ($ExpiresAt -gt $Now.AddMinutes(5)) {
            # Token is still valid for more than 5 minutes
            return @{
                Authorization               = "Bearer $($CachedToken.Token)"
                'X-Subscription-Key'       = $Config.SubscriptionKey
                'Content-Type'             = 'application/json'
            }
        }
    }
    
    # Generate new token
    $BasicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.Username):$APIKey"))
    
    $TokenBody = @{
        marketplace = $Config.Marketplace
    } | ConvertTo-Json
    
    $TokenHeaders = @{
        'Authorization'      = "Basic $BasicAuth"
        'X-Subscription-Key' = $Config.SubscriptionKey
        'Content-Type'       = 'application/json'
    }
    
    try {
        $TokenResponse = Invoke-RestMethod -Uri "$($Config.BaseUrl)/token" -Method POST -Headers $TokenHeaders -Body $TokenBody
        
        # Cache the token
        $CacheEntry = @{
            PartitionKey = 'cache'
            RowKey       = $TokenKey
            Token        = $TokenResponse.token
            ExpiresAt    = $Now.AddSeconds($TokenResponse.expiresInSeconds - 60).ToString('o')
        }
        
        Add-CIPPAzDataTableEntity @TokenTable -Entity $CacheEntry -Force
        
        return @{
            Authorization               = "Bearer $($TokenResponse.token)"
            'X-Subscription-Key'       = $Config.SubscriptionKey
            'Content-Type'             = 'application/json'
        }
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to authenticate with Ingram Micro: $_" -Sev 'Error'
        throw "Ingram Micro authentication failed: $_"
    }
}