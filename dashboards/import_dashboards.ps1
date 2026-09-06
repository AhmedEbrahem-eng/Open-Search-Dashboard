param (
    [string]$HostUrl = "http://localhost:5601",
    [string]$Username = "admin",
    [string]$Password = "MyStr0ngP@ssw0rd!"
)

$ndjsonPath = Join-Path $PSScriptRoot "saved_objects.ndjson"

if (-not (Test-Path $ndjsonPath)) {
    Write-Error "Could not find saved_objects.ndjson at $ndjsonPath"
    exit 1
}

$tenants = @("global", "admin", "")

foreach ($tenant in $tenants) {
    $tenantLabel = if ($tenant) { $tenant } else { "default" }
    Write-Host "`nImporting saved objects to tenant: $tenantLabel..."
    
    $headers = @{
        "osd-xsrf" = "true"
    }
    if ($tenant) {
        $headers["securitytenant"] = $tenant
    }
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers["Authorization"] = "Basic $auth"
    
    $headerArgs = @()
    foreach ($k in $headers.Keys) {
        $headerArgs += "-H"
        $headerArgs += "$k`: $($headers[$k])"
    }
    
    $url = "$HostUrl/api/saved_objects/_import?overwrite=true"
    
    & curl.exe -s -X POST $url @headerArgs --form "file=@$ndjsonPath"
    Write-Host "`nImport to $tenantLabel completed."
}
