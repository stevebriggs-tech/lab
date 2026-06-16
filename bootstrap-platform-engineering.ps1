param(
    [string]$Root = "C:\Development\PlatformEngineering"
)

Write-Host "Creating Platform Engineering structure under $Root"

$folders = @(
    "platform-orchestrator\config",
    "platform-orchestrator\scripts",
    "platform-orchestrator\validators",
    "platform-orchestrator\generators",
    "platform-orchestrator\schemas",
    "platform-orchestrator\docs",
    "platform-orchestrator\build\generated",

    "platform-patterns-cloud\PAT-azure-foundation",
    "platform-patterns-cloud\PAT-azure-network",
    "platform-patterns-cloud\PAT-azure-nodepool",

    "platform-patterns-linux\PAT-sles-base",
    "platform-patterns-linux\PAT-rhel-base",
    "platform-patterns-linux\PAT-linux-hardening",

    "platform-patterns-kubernetes\PAT-rke2-cluster",
    "platform-patterns-kubernetes\PAT-rancher-management",
    "platform-patterns-kubernetes\PAT-nginx-ingress",
    "platform-patterns-kubernetes\PAT-k8s-network-policy",

    "platform-patterns-api\PAT-kong-gateway",

    "platform-golden-paths\azure-rke2-enterprise",

    "platform-docs\architecture",
    "platform-docs\standards",
    "platform-docs\design-decisions"
)

foreach ($folder in $folders) {
    $path = Join-Path $Root $folder
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $path ".gitkeep") | Out-Null
}

$patterns = @(
    "platform-patterns-cloud\PAT-azure-foundation",
    "platform-patterns-cloud\PAT-azure-network",
    "platform-patterns-cloud\PAT-azure-nodepool",
    "platform-patterns-linux\PAT-sles-base",
    "platform-patterns-linux\PAT-rhel-base",
    "platform-patterns-linux\PAT-linux-hardening",
    "platform-patterns-kubernetes\PAT-rke2-cluster",
    "platform-patterns-kubernetes\PAT-rancher-management",
    "platform-patterns-kubernetes\PAT-nginx-ingress",
    "platform-patterns-kubernetes\PAT-k8s-network-policy",
    "platform-patterns-api\PAT-kong-gateway"
)

foreach ($pattern in $patterns) {
    $patternName = Split-Path $pattern -Leaf
    $metadataPath = Join-Path $Root "$pattern\metadata.json"

    if (-not (Test-Path $metadataPath)) {
        @"
{
  "pattern_name": "$patternName",
  "version": "1.0.0",
  "required_sheets": [],
  "required_parameters": {},
  "description": ""
}
"@ | Set-Content -Path $metadataPath -Encoding UTF8
    }
}

$workspacePath = Join-Path $Root "platform-engineering.code-workspace"

@"
{
  "folders": [
    { "path": "platform-orchestrator" },
    { "path": "platform-patterns-cloud" },
    { "path": "platform-patterns-linux" },
    { "path": "platform-patterns-kubernetes" },
    { "path": "platform-patterns-api" },
    { "path": "platform-golden-paths" },
    { "path": "platform-docs" }
  ],
  "settings": {}
}
"@ | Set-Content -Path $workspacePath -Encoding UTF8

Write-Host "Done."
Write-Host "Open workspace:"
Write-Host $workspacePath
