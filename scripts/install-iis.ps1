$ErrorActionPreference = "Stop"

$logDirectory = "C:\DeploymentLogs"
$logFile = Join-Path $logDirectory "install-iis.log"
$websiteDirectory = "C:\inetpub\wwwroot"
$indexFile = Join-Path $websiteDirectory "index.html"

if (-not (Test-Path $logDirectory)) {
    New-Item `
        -Path $logDirectory `
        -ItemType Directory `
        -Force | Out-Null
}

Start-Transcript -Path $logFile -Append

try {
    Write-Output "Starting IIS installation."

    $iisFeature = Get-WindowsFeature -Name Web-Server

    if (-not $iisFeature.Installed) {
        Install-WindowsFeature `
            -Name Web-Server `
            -IncludeManagementTools

        Write-Output "IIS installed successfully."
    }
    else {
        Write-Output "IIS is already installed."
    }

    if (-not (Test-Path $websiteDirectory)) {
        New-Item `
            -Path $websiteDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>CloudNorth Technologies</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 30px;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(135deg, #071b34, #075985);
            color: #ffffff;
        }

        .card {
            width: 90%;
            max-width: 850px;
            padding: 55px;
            border-radius: 16px;
            background: #ffffff;
            color: #111827;
            text-align: center;
            box-shadow: 0 18px 45px rgba(0, 0, 0, 0.28);
        }

        h1 {
            color: #0369a1;
            margin-bottom: 20px;
        }

        p {
            line-height: 1.7;
        }

        .status {
            margin-top: 25px;
            color: #15803d;
            font-weight: bold;
        }
    </style>
</head>

<body>
    <main class="card">
        <h1>CloudNorth Technologies</h1>

        <p>
            This company website is hosted on Microsoft IIS running
            on a Windows Server virtual machine in Azure Canada Central.
        </p>

        <p>
            The infrastructure was provisioned using Terraform, while
            IIS and the website were configured automatically using
            PowerShell.
        </p>

        <p class="status">
            IIS web server is online and operational.
        </p>
    </main>
</body>
</html>
"@

    Set-Content `
        -Path $indexFile `
        -Value $htmlContent `
        -Encoding UTF8 `
        -Force

    Set-Service `
        -Name W3SVC `
        -StartupType Automatic

    Start-Service -Name W3SVC

    $firewallRule = Get-NetFirewallRule `
        -DisplayName "Allow IIS HTTP" `
        -ErrorAction SilentlyContinue

    if (-not $firewallRule) {
        New-NetFirewallRule `
            -DisplayName "Allow IIS HTTP" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 80 `
            -Action Allow
    }

    iisreset

    Start-Sleep -Seconds 5

    $response = Invoke-WebRequest `
        -Uri "http://localhost" `
        -UseBasicParsing

    if ($response.StatusCode -ne 200) {
        throw "IIS validation failed. HTTP status: $($response.StatusCode)"
    }

    Write-Output "IIS returned HTTP status 200."
    Write-Output "Website deployment completed successfully."
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    throw
}
finally {
    Stop-Transcript
}