function Remove-IngramMicroSubscription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $false)]
        [string]$Reason = 'Cancelled by CIPP'
    )
    
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).IngramMicro
    
    if (-not $Config -or -not $Config.Enabled) {
        throw 'Ingram Micro extension is not enabled'
    }
    
    $AuthHeader = Get-IngramMicroAuthentication
    
    try {
        # Update subscription status to terminated
        $UpdateBody = @{
            status = 'terminated'
            attributes = @{
                terminationReason = $Reason
            }
        } | ConvertTo-Json -Depth 10
        
        $Uri = "$($Config.BaseUrl)/subscriptions/$SubscriptionId"
        $Result = Invoke-RestMethod -Uri $Uri -Method PATCH -Headers $AuthHeader -Body $UpdateBody -ContentType 'application/json'
        
        Write-LogMessage -API 'IngramMicro' -message "Terminated subscription $SubscriptionId with reason: $Reason" -Sev 'Info'
        return $Result
    } catch {
        Write-LogMessage -API 'IngramMicro' -message "Failed to terminate subscription: $_" -Sev 'Error'
        throw "Failed to terminate Ingram Micro subscription: $_"
    }
}