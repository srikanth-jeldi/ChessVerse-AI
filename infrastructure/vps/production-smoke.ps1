$ErrorActionPreference = 'Stop'

$endpoints = @(
    'https://chessverseai.com',
    'https://chessverseai.com/privacy',
    'https://chessverseai.com/terms',
    'https://chessverseai.com/data-deletion',
    'https://api.chessverseai.com/api/v1/health',
    'https://api.chessverseai.com/actuator/health/readiness'
)

foreach ($endpoint in $endpoints) {
    $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 20
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "$endpoint returned HTTP $($response.StatusCode)"
    }
    Write-Host "OK $($response.StatusCode) $endpoint"
}
