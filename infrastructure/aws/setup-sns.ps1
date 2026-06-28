param(
    [string]$Region = "ap-south-1",
    [string]$ClusterName = "",
    [string]$StackName = "chessverse-sns",
    [string]$TestPhone = ""
)

$ErrorActionPreference = "Stop"
$template = Join-Path $PSScriptRoot "sns-pod-identity.yaml"

aws sts get-caller-identity | Out-Null

$deployArguments = @(
    "cloudformation",
    "deploy",
    "--region", $Region,
    "--stack-name", $StackName,
    "--template-file", $template,
    "--capabilities", "CAPABILITY_NAMED_IAM"
)

if ($ClusterName) {
    $deployArguments += @(
        "--parameter-overrides",
        "ParameterKey=ClusterName,ParameterValue=$ClusterName"
    )
}

& aws @deployArguments

if ($TestPhone) {
    aws sns create-sms-sandbox-phone-number `
        --region $Region `
        --phone-number $TestPhone `
        --language-code en-US

    Write-Host ""
    Write-Host "AWS sent a sandbox verification OTP to $TestPhone."
    Write-Host "Verify it with:"
    Write-Host "aws sns verify-sms-sandbox-phone-number --region $Region --phone-number $TestPhone --one-time-password <OTP>"
}
