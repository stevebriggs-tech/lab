<#
.SYNOPSIS
  Bootstraps the Platform Engineering repository structure after GitHub repositories have been cloned.

.DESCRIPTION
  This script assumes the following repositories already exist under the root folder:
    platform-orchestrator
    platform-patterns-cloud
    platform-patterns-linux
    platform-patterns-kubernetes
    platform-patterns-api
    platform-golden-paths
    platform-docs

  It creates standard subdirectories, pattern.json metadata files, README files,
  a golden_path.json definition, and a VS Code workspace file.

.NOTES
  Run from PowerShell:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\bootstrap-platform-engineering.ps1
#>

param(
    [string]$Root = "C:\Development\PlatformEngineering"
)

$ErrorActionPreference = "Stop"

Write-Host "Bootstrapping Platform Engineering structure under $Root" -ForegroundColor Cyan

# -------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
        Write-Host "Created directory: $Path"
    }
}

function Ensure-GitKeep {
    param([string]$Path)

    $gitKeep = Join-Path $Path ".gitkeep"
    if (-not (Test-Path $gitKeep)) {
        New-Item -ItemType File -Force -Path $gitKeep | Out-Null
    }
}

function Write-JsonFile {
    param(
        [object]$Object,
        [string]$Path
    )

    $Object | ConvertTo-Json -Depth 30 | Set-Content -Path $Path -Encoding UTF8
}

function Write-Readme {
    param(
        [string]$Path,
        [string]$Title,
        [string]$Description
    )

    if (-not (Test-Path $Path)) {
@"
# $Title

$Description

## Purpose

This repository or pattern is part of the Platform Engineering framework.

## Versioning

Pattern versions are controlled by Git tags. The `pattern.json` file defines the metadata contract used by the orchestrator validator and variable generator.
"@ | Set-Content -Path $Path -Encoding UTF8
    }
}

# -------------------------------------------------------------------
# Expected repositories
# -------------------------------------------------------------------

$repositories = @(
    "platform-orchestrator",
    "platform-patterns-cloud",
    "platform-patterns-linux",
    "platform-patterns-kubernetes",
    "platform-patterns-api",
    "platform-golden-paths",
    "platform-docs"
)

foreach ($repo in $repositories) {
    $repoPath = Join-Path $Root $repo
    Ensure-Directory $repoPath
}

# -------------------------------------------------------------------
# Base repository structure
# -------------------------------------------------------------------

$baseFolders = @(
    "platform-orchestrator\config",
    "platform-orchestrator\scripts",
    "platform-orchestrator\validators",
    "platform-orchestrator\generators",
    "platform-orchestrator\schemas",
    "platform-orchestrator\docs",
    "platform-orchestrator\build\generated",

    "platform-golden-paths\azure-rke2-enterprise",

    "platform-docs\architecture",
    "platform-docs\standards",
    "platform-docs\design-decisions"
)

foreach ($folder in $baseFolders) {
    $path = Join-Path $Root $folder
    Ensure-Directory $path
    Ensure-GitKeep $path
}

# -------------------------------------------------------------------
# Pattern definitions
# -------------------------------------------------------------------

$patternDefinitions = @{

    "platform-patterns-cloud\PAT-azure-foundation" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-azure-foundation"
        version = "1.0.0"
        description = "Creates or validates Azure foundation resources required for platform deployment."
        required_sheets = @(
            "01_customer_configuration",
            "03_provider_configuration"
        )
        optional_sheets = @(
            "14_network_security"
        )
        required_parameters = @{
            "01_customer_configuration" = @(
                "provider_type",
                "deployment_mode"
            )
            "03_provider_configuration" = @(
                "resource_group_name",
                "location"
            )
        }
        optional_parameters = @{
            "03_provider_configuration" = @(
                "subscription_id",
                "default_dns_domain",
                "dns_mode",
                "dns_servers",
                "proxy_required",
                "http_proxy",
                "https_proxy",
                "no_proxy"
            )
        }
        generated_variables = @(
            "azure_foundation",
            "resource_group_name",
            "location",
            "dns_mode",
            "proxy_settings"
        )
        dependencies = @()
    }

    "platform-patterns-cloud\PAT-azure-network" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-azure-network"
        version = "1.0.0"
        description = "Creates or validates Azure network resources including subnets, route tables and network security rules."
        required_sheets = @(
            "03_provider_configuration",
            "06_network_configuration"
        )
        optional_sheets = @(
            "14_network_security"
        )
        required_parameters = @{
            "03_provider_configuration" = @(
                "resource_group_name",
                "location"
            )
            "06_network_configuration" = @(
                "cluster_name",
                "node_pool_name",
                "nic_name",
                "enabled",
                "network_type",
                "network_name",
                "subnet_name",
                "ip_allocation",
                "network_management",
                "nic_index"
            )
        }
        optional_parameters = @{
            "06_network_configuration" = @(
                "vlan_id",
                "ip_address",
                "prefix_length",
                "gateway",
                "route_table_name",
                "bond_name",
                "network_bond_mode",
                "member_interfaces"
            )
            "14_network_security" = @(
                "cluster_name",
                "scope",
                "enabled",
                "policy_type",
                "policy_name",
                "priority",
                "source_type",
                "source_value",
                "destination_type",
                "destination_value",
                "protocol",
                "port",
                "action"
            )
        }
        generated_variables = @(
            "network_configuration",
            "subnets",
            "network_interfaces",
            "route_tables",
            "network_security_rules"
        )
        dependencies = @(
            "PAT-azure-foundation"
        )
    }

    "platform-patterns-cloud\PAT-azure-nodepool" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-azure-nodepool"
        version = "1.0.0"
        description = "Creates Azure Linux virtual machines from node pool, image, network and disk definitions."
        required_sheets = @(
            "03_provider_configuration",
            "04_image_sources",
            "05_node_pools",
            "06_network_configuration",
            "07_disks"
        )
        optional_sheets = @(
            "09_supplied_hosts"
        )
        required_parameters = @{
            "03_provider_configuration" = @(
                "resource_group_name",
                "location"
            )
            "04_image_sources" = @(
                "image_name",
                "provider_type",
                "enabled",
                "image_source_type",
                "os_distribution",
                "os_version"
            )
            "05_node_pools" = @(
                "cluster_name",
                "node_pool_name",
                "enabled",
                "node_role",
                "service_role",
                "count",
                "hostname_prefix",
                "cpu_count",
                "memory_mb",
                "os_disk_size_gb",
                "image_name"
            )
            "06_network_configuration" = @(
                "cluster_name",
                "node_pool_name",
                "nic_name",
                "enabled",
                "network_type",
                "network_name",
                "subnet_name",
                "ip_allocation",
                "network_management",
                "nic_index"
            )
            "07_disks" = @(
                "node_pool_name",
                "enabled",
                "disk_purpose",
                "disk_index",
                "size_gb"
            )
        }
        optional_parameters = @{
            "04_image_sources" = @(
                "publisher",
                "offer",
                "sku",
                "version",
                "template_name",
                "iso_path",
                "cloud_init_enabled",
                "dynamic_nics_supported",
                "max_tested_nics",
                "hardened",
                "cis_level",
                "owner"
            )
            "05_node_pools" = @(
                "availability_zone",
                "site",
                "taints"
            )
            "07_disks" = @(
                "lun",
                "volume_group",
                "logical_volume",
                "lv_size_gb",
                "mount_point",
                "filesystem"
            )
            "09_supplied_hosts" = @(
                "hostname",
                "enabled",
                "ip_address",
                "cluster_name",
                "node_pool_name",
                "node_role",
                "service_role",
                "os_distribution",
                "os_version",
                "ssh_user",
                "ssh_auth_method"
            )
        }
        generated_variables = @(
            "node_pools",
            "vm_instances",
            "image_sources",
            "network_interfaces",
            "managed_disks",
            "host_inventory"
        )
        dependencies = @(
            "PAT-azure-foundation",
            "PAT-azure-network"
        )
    }

    "platform-patterns-linux\PAT-sles-base" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-sles-base"
        version = "1.0.0"
        description = "Applies base SLES operating system configuration required before platform deployment."
        required_sheets = @(
            "05_node_pools"
        )
        optional_sheets = @(
            "09_supplied_hosts",
            "07_disks"
        )
        required_parameters = @{
            "05_node_pools" = @(
                "cluster_name",
                "node_pool_name",
                "enabled",
                "node_role",
                "service_role"
            )
        }
        optional_parameters = @{
            "09_supplied_hosts" = @(
                "hostname",
                "enabled",
                "ip_address",
                "cluster_name",
                "node_pool_name",
                "node_role",
                "service_role",
                "os_distribution",
                "os_version",
                "ssh_user",
                "ssh_auth_method"
            )
        }
        generated_variables = @(
            "linux_hosts",
            "os_baseline",
            "ssh_connection",
            "package_baseline"
        )
        dependencies = @()
    }

    "platform-patterns-linux\PAT-rhel-base" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-rhel-base"
        version = "1.0.0"
        description = "Applies base RHEL operating system configuration required before platform deployment."
        required_sheets = @(
            "05_node_pools"
        )
        optional_sheets = @(
            "09_supplied_hosts",
            "07_disks"
        )
        required_parameters = @{
            "05_node_pools" = @(
                "cluster_name",
                "node_pool_name",
                "enabled",
                "node_role",
                "service_role"
            )
        }
        optional_parameters = @{
            "09_supplied_hosts" = @(
                "hostname",
                "enabled",
                "ip_address",
                "cluster_name",
                "node_pool_name",
                "node_role",
                "service_role",
                "os_distribution",
                "os_version",
                "ssh_user",
                "ssh_auth_method"
            )
        }
        generated_variables = @(
            "linux_hosts",
            "os_baseline",
            "ssh_connection",
            "package_baseline"
        )
        dependencies = @()
    }

    "platform-patterns-linux\PAT-linux-hardening" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-linux-hardening"
        version = "1.0.0"
        description = "Applies common Linux hardening, validation and operating system compliance configuration."
        required_sheets = @(
            "05_node_pools"
        )
        optional_sheets = @(
            "09_supplied_hosts"
        )
        required_parameters = @{
            "05_node_pools" = @(
                "cluster_name",
                "node_pool_name",
                "enabled",
                "node_role",
                "service_role"
            )
        }
        optional_parameters = @{
            "09_supplied_hosts" = @(
                "hostname",
                "enabled",
                "ip_address",
                "cluster_name",
                "node_pool_name",
                "node_role",
                "service_role",
                "ssh_user",
                "ssh_auth_method"
            )
        }
        generated_variables = @(
            "linux_hosts",
            "hardening_profile",
            "compliance_state"
        )
        dependencies = @()
    }

    "platform-patterns-linux\PAT-linux-storage-lvm" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-linux-storage-lvm"
        version = "1.0.0"
        description = "Configures Linux local storage using disks, volume groups, logical volumes, filesystems and mount points."
        required_sheets = @(
            "07_disks"
        )
        optional_sheets = @(
            "05_node_pools",
            "09_supplied_hosts"
        )
        required_parameters = @{
            "07_disks" = @(
                "node_pool_name",
                "enabled",
                "disk_purpose",
                "disk_index",
                "size_gb"
            )
        }
        optional_parameters = @{
            "07_disks" = @(
                "lun",
                "volume_group",
                "logical_volume",
                "lv_size_gb",
                "mount_point",
                "filesystem"
            )
        }
        generated_variables = @(
            "disk_layout",
            "volume_groups",
            "logical_volumes",
            "filesystems",
            "mounts"
        )
        dependencies = @()
    }

    "platform-patterns-kubernetes\PAT-rke2-cluster" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-rke2-cluster"
        version = "1.0.0"
        description = "Deploys and configures an RKE2 Kubernetes cluster using node pool and RKE2 configuration sheets."
        required_sheets = @(
            "05_node_pools",
            "06_network_configuration",
            "07_disks",
            "13_rke2"
        )
        optional_sheets = @(
            "08_storage_connectivity",
            "09_supplied_hosts",
            "14_network_security"
        )
        required_parameters = @{
            "05_node_pools" = @(
                "cluster_name",
                "node_pool_name",
                "enabled",
                "node_role",
                "service_role",
                "count",
                "hostname_prefix",
                "image_name"
            )
            "13_rke2" = @(
                "rke2_version",
                "cluster_name",
                "cni"
            )
        }
        optional_parameters = @{
            "13_rke2" = @(
                "cluster_domain",
                "cluster_cidr",
                "service_cidr",
                "disable_builtin_ingress",
                "kubernetes_api_vip",
                "api_endpoint_mode",
                "protect_kernel_defaults",
                "control_plane_count",
                "worker_count",
                "tls_san"
            )
            "14_network_security" = @(
                "cluster_name",
                "scope",
                "enabled",
                "policy_type",
                "policy_name",
                "priority",
                "source_type",
                "source_value",
                "destination_type",
                "destination_value",
                "protocol",
                "port",
                "action"
            )
        }
        generated_variables = @(
            "rke2_cluster",
            "rke2_servers",
            "rke2_agents",
            "cluster_config",
            "kubeconfig"
        )
        dependencies = @(
            "PAT-sles-base",
            "PAT-linux-storage-lvm"
        )
    }

    "platform-patterns-kubernetes\PAT-rancher-management" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-rancher-management"
        version = "1.0.0"
        description = "Installs and configures Rancher management for the Kubernetes platform."
        required_sheets = @(
            "12_rancher",
            "10_load_balancers",
            "11_dns",
            "15_ingress"
        )
        optional_sheets = @(
            "13_rke2"
        )
        required_parameters = @{
            "12_rancher" = @(
                "service_state",
                "rancher_distribution",
                "rancher_hostname",
                "rancher_version"
            )
            "15_ingress" = @(
                "cluster_name",
                "ingress_name",
                "enabled",
                "namespace",
                "ingress_class",
                "service_role",
                "lb_name"
            )
        }
        optional_parameters = @{
            "12_rancher" = @(
                "audit_logging_enabled",
                "cert_manager_enabled",
                "tls_source",
                "bootstrap_password_source"
            )
            "10_load_balancers" = @(
                "cluster_name",
                "lb_name",
                "enabled",
                "provider_type",
                "service_role",
                "frontend_name",
                "frontend_ip",
                "protocol",
                "frontend_port",
                "backend_pool",
                "backend_port",
                "health_probe_path"
            )
            "11_dns" = @(
                "cluster_name",
                "record_name",
                "dns_record_type",
                "enabled",
                "zone_name",
                "target",
                "ttl"
            )
        }
        generated_variables = @(
            "rancher_values",
            "rancher_hostname",
            "rancher_tls",
            "rancher_ingress"
        )
        dependencies = @(
            "PAT-rke2-cluster",
            "PAT-nginx-ingress"
        )
    }

    "platform-patterns-kubernetes\PAT-nginx-ingress" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-nginx-ingress"
        version = "1.0.0"
        description = "Deploys one or more NGINX ingress controllers and associates them with load balancer definitions."
        required_sheets = @(
            "15_ingress",
            "10_load_balancers"
        )
        optional_sheets = @(
            "11_dns",
            "14_network_security"
        )
        required_parameters = @{
            "15_ingress" = @(
                "cluster_name",
                "ingress_name",
                "enabled",
                "namespace",
                "ingress_class",
                "replica_count",
                "service_type",
                "http_node_port",
                "https_node_port",
                "service_role",
                "lb_name"
            )
            "10_load_balancers" = @(
                "cluster_name",
                "lb_name",
                "enabled",
                "provider_type",
                "service_role",
                "frontend_ip",
                "protocol",
                "frontend_port",
                "backend_port"
            )
        }
        optional_parameters = @{
            "15_ingress" = @(
                "controller_value",
                "watch_without_class",
                "default_class"
            )
            "10_load_balancers" = @(
                "frontend_name",
                "backend_pool",
                "health_probe_path"
            )
        }
        generated_variables = @(
            "ingress_controllers",
            "ingress_classes",
            "node_ports",
            "load_balancer_bindings"
        )
        dependencies = @(
            "PAT-rke2-cluster"
        )
    }

    "platform-patterns-kubernetes\PAT-k8s-network-policy" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-k8s-network-policy"
        version = "1.0.0"
        description = "Applies Kubernetes network policies and related platform network security rules."
        required_sheets = @(
            "14_network_security"
        )
        optional_sheets = @()
        required_parameters = @{
            "14_network_security" = @(
                "cluster_name",
                "scope",
                "enabled",
                "policy_type",
                "policy_name",
                "source_type",
                "source_value",
                "destination_type",
                "destination_value",
                "protocol",
                "port",
                "action"
            )
        }
        optional_parameters = @{
            "14_network_security" = @(
                "priority"
            )
        }
        generated_variables = @(
            "network_policies",
            "security_rules"
        )
        dependencies = @(
            "PAT-rke2-cluster"
        )
    }

    "platform-patterns-api\PAT-kong-gateway" = @{
        metadata_schema_version = "1.0"
        pattern_name = "PAT-kong-gateway"
        version = "1.0.0"
        description = "Deploys Kong Gateway instances for selected environments using ingress and load balancer definitions."
        required_sheets = @(
            "16_kong",
            "15_ingress",
            "10_load_balancers"
        )
        optional_sheets = @(
            "11_dns",
            "14_network_security",
            "08_storage_connectivity"
        )
        required_parameters = @{
            "16_kong" = @(
                "kong_name",
                "enabled",
                "environment_type",
                "service_state",
                "kong_namespace",
                "kong_ingress_class",
                "kong_mode",
                "proxy_service_type"
            )
            "15_ingress" = @(
                "cluster_name",
                "ingress_name",
                "enabled",
                "namespace",
                "ingress_class",
                "service_role",
                "lb_name"
            )
        }
        optional_parameters = @{
            "16_kong" = @(
                "kong_version",
                "admin_enabled",
                "manager_enabled",
                "install_crds",
                "enable_oidc_plugin",
                "enable_rate_limiting_plugin",
                "enable_key_auth_plugin",
                "ingress_name"
            )
            "11_dns" = @(
                "cluster_name",
                "record_name",
                "dns_record_type",
                "enabled",
                "zone_name",
                "target",
                "ttl"
            )
        }
        generated_variables = @(
            "kong_instances",
            "kong_namespaces",
            "kong_helm_values",
            "kong_ingress_bindings"
        )
        dependencies = @(
            "PAT-rke2-cluster",
            "PAT-nginx-ingress"
        )
    }
}

# -------------------------------------------------------------------
# Create pattern folders, metadata and README files
# -------------------------------------------------------------------

foreach ($relativePath in $patternDefinitions.Keys) {
    $patternPath = Join-Path $Root $relativePath
    $pattern = $patternDefinitions[$relativePath]

    Ensure-Directory $patternPath
    Ensure-GitKeep $patternPath

    $subdirs = @("docs", "tests", "ansible", "templates")
    foreach ($subdir in $subdirs) {
        $subdirPath = Join-Path $patternPath $subdir
        Ensure-Directory $subdirPath
        Ensure-GitKeep $subdirPath
    }

    $patternJsonPath = Join-Path $patternPath "pattern.json"
    Write-JsonFile -Object $pattern -Path $patternJsonPath

    $readmePath = Join-Path $patternPath "README.md"
@"
# $($pattern.pattern_name)

$($pattern.description)

## Version

$($pattern.version)

## Metadata Contract

The `pattern.json` file is the source of truth for workbook validation and pattern variable generation.

## Required Sheets

See `pattern.json`.

## Required Parameters

See `pattern.json`.

## Generated Variables

See `pattern.json`.
"@ | Set-Content -Path $readmePath -Encoding UTF8
}

# -------------------------------------------------------------------
# Golden Path definition
# -------------------------------------------------------------------

$goldenPathDir = Join-Path $Root "platform-golden-paths\azure-rke2-enterprise"
Ensure-Directory $goldenPathDir
Ensure-GitKeep $goldenPathDir

$goldenPathJson = @{
    golden_path_name = "azure-rke2-enterprise"
    version = "1.0.0"
    description = "Azure RKE2 enterprise platform golden path using selected reusable patterns."
    patterns = @(
        @{ pattern_name = "PAT-azure-foundation"; version = "1.0.0"; repository = "platform-patterns-cloud" },
        @{ pattern_name = "PAT-azure-network"; version = "1.0.0"; repository = "platform-patterns-cloud" },
        @{ pattern_name = "PAT-azure-nodepool"; version = "1.0.0"; repository = "platform-patterns-cloud" },
        @{ pattern_name = "PAT-sles-base"; version = "1.0.0"; repository = "platform-patterns-linux" },
        @{ pattern_name = "PAT-linux-storage-lvm"; version = "1.0.0"; repository = "platform-patterns-linux" },
        @{ pattern_name = "PAT-rke2-cluster"; version = "1.0.0"; repository = "platform-patterns-kubernetes" },
        @{ pattern_name = "PAT-rancher-management"; version = "1.0.0"; repository = "platform-patterns-kubernetes" },
        @{ pattern_name = "PAT-nginx-ingress"; version = "1.0.0"; repository = "platform-patterns-kubernetes" },
        @{ pattern_name = "PAT-kong-gateway"; version = "1.0.0"; repository = "platform-patterns-api" }
    )
}

Write-JsonFile -Object $goldenPathJson -Path (Join-Path $goldenPathDir "golden_path.json")

$goldenPathReadme = Join-Path $goldenPathDir "README.md"
@"
# azure-rke2-enterprise

Azure RKE2 enterprise platform golden path using selected reusable patterns.

## Purpose

This golden path assembles the reusable patterns required to build the initial Azure-based RKE2, Rancher, NGINX ingress and Kong Gateway platform.

## Pattern Selection

See `golden_path.json`.
"@ | Set-Content -Path $goldenPathReadme -Encoding UTF8

# -------------------------------------------------------------------
# Repository README files
# -------------------------------------------------------------------

Write-Readme -Path (Join-Path $Root "platform-orchestrator\README.md") -Title "platform-orchestrator" -Description "Workbook parsing, validation, pattern loading, variable generation and execution orchestration."
Write-Readme -Path (Join-Path $Root "platform-patterns-cloud\README.md") -Title "platform-patterns-cloud" -Description "Reusable cloud infrastructure patterns including Azure and future VMware/cloud provider implementations."
Write-Readme -Path (Join-Path $Root "platform-patterns-linux\README.md") -Title "platform-patterns-linux" -Description "Reusable Linux operating system, storage, hardening and baseline configuration patterns."
Write-Readme -Path (Join-Path $Root "platform-patterns-kubernetes\README.md") -Title "platform-patterns-kubernetes" -Description "Reusable Kubernetes platform patterns including RKE2, Rancher, ingress and network policy."
Write-Readme -Path (Join-Path $Root "platform-patterns-api\README.md") -Title "platform-patterns-api" -Description "Reusable API gateway and platform integration patterns."
Write-Readme -Path (Join-Path $Root "platform-golden-paths\README.md") -Title "platform-golden-paths" -Description "Approved customer deployment golden paths assembled from versioned reusable patterns."
Write-Readme -Path (Join-Path $Root "platform-docs\README.md") -Title "platform-docs" -Description "Platform Engineering architecture, standards, design decisions and delivery documentation."

# -------------------------------------------------------------------
# VS Code workspace file
# -------------------------------------------------------------------

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

Write-Host "Done." -ForegroundColor Green
Write-Host "Open workspace:" -ForegroundColor Cyan
Write-Host $workspacePath -ForegroundColor Yellow
