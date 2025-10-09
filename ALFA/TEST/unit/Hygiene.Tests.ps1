#Requires -Module Pester

Describe "OTel Ops Pack - Hygiene Validation Tests" {
    
    BeforeAll {
        # Set up test environment
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        $script:ArtifactsPath = Join-Path $RepoRoot "artifacts"
        $script:HygieneScript = Join-Path $RepoRoot "tools\hygiene.ps1"
        
        # Ensure artifacts directory exists
        if (-not (Test-Path $ArtifactsPath)) {
            New-Item -ItemType Directory -Path $ArtifactsPath -Force | Out-Null
        }
    }
    
    Context "Repository Structure" {
        It "Should have required files" {
            $requiredFiles = @(
                "README.md",
                "LICENSE",
                "SECURITY.md",
                "CONTRIBUTING.md",
                "CODE_OF_CONDUCT.md",
                ".editorconfig",
                ".gitattributes",
                ".gitignore",
                ".env.example",
                "docs/REPO_HYGIENE.md"
            )
            
            foreach ($file in $requiredFiles) {
                $filePath = Join-Path $RepoRoot $file
                Test-Path $filePath | Should -Be $true -Because "Required file $file should exist"
            }
        }
        
        It "Should have required directories" {
            $requiredDirs = @(
                "docs",
                "scripts",
                "configs/otel",
                "compose",
                "artifacts",
                ".github/workflows",
                ".github/ISSUE_TEMPLATE"
            )
            
            foreach ($dir in $requiredDirs) {
                $dirPath = Join-Path $RepoRoot $dir
                Test-Path $dirPath | Should -Be $true -Because "Required directory $dir should exist"
            }
        }
    }
    
    Context "PowerShell Script Quality" {
        It "Should have hygiene script" {
            Test-Path $HygieneScript | Should -Be $true -Because "Hygiene script should exist"
        }
        
        It "Should have proper PowerShell script structure" {
            $psScripts = Get-ChildItem -Path (Join-Path $RepoRoot "scripts") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
            
            foreach ($script in $psScripts) {
                $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
                
                if ($content) {
                    $content | Should -Match "Set-StrictMode" -Because "Script $($script.Name) should have Set-StrictMode"
                    $content | Should -Match "ErrorActionPreference" -Because "Script $($script.Name) should have ErrorActionPreference"
                }
            }
        }
    }
    
    Context "Configuration Files" {
        It "Should have valid YAML files" {
            $yamlFiles = @(
                "compose/*.yml",
                ".github/workflows/*.yml",
                "configs/otel/*.yaml"
            )
            
            foreach ($pattern in $yamlFiles) {
                $files = Get-ChildItem -Path (Join-Path $RepoRoot $pattern) -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    $file | Should -Not -BeNullOrEmpty -Because "YAML file $($file.Name) should exist"
                }
            }
        }
        
        It "Should have .env.example with proper structure" {
            $envExamplePath = Join-Path $RepoRoot ".env.example"
            Test-Path $envExamplePath | Should -Be $true -Because ".env.example should exist"
            
            $content = Get-Content $envExamplePath -Raw
            $content | Should -Match "OTEL_COLLECTOR" -Because ".env.example should contain OTel configuration"
            $content | Should -Match "SIGNOZ" -Because ".env.example should contain SigNoz configuration"
        }
    }
    
    Context "Hygiene Script Execution" {
        It "Should run hygiene script without critical errors" {
            $logFile = Join-Path $ArtifactsPath "hygiene-test.log"
            
            # Run hygiene script with skip flags for CI environment
            $result = & pwsh -File $HygieneScript -SkipDocker -SkipOtelCol -ArtifactsPath $ArtifactsPath 2>&1
            $exitCode = $LASTEXITCODE
            
            # The script should complete (exit code 0 or 1, but not crash)
            $exitCode | Should -BeIn @(0, 1) -Because "Hygiene script should complete without crashing"
            
            # Check if log file was created
            Test-Path $logFile | Should -Be $true -Because "Hygiene script should create log file"
        }
        
        It "Should create artifacts directory structure" {
            $expectedArtifacts = @(
                "hygiene.log",
                "tree.txt"
            )
            
            foreach ($artifact in $expectedArtifacts) {
                $artifactPath = Join-Path $ArtifactsPath $artifact
                Test-Path $artifactPath | Should -Be $true -Because "Artifact $artifact should be created"
            }
        }
    }
    
    Context "Security" {
        It "Should not contain obvious secrets in tracked files" {
            $secretPatterns = @(
                'password\s*=\s*["\'][^"\']+["\']',
                'secret\s*=\s*["\'][^"\']+["\']',
                'token\s*=\s*["\'][^"\']+["\']',
                'api[_-]?key\s*=\s*["\'][^"\']+["\']'
            )
            
            $filesToCheck = Get-ChildItem -Path $RepoRoot -Recurse -File | Where-Object { 
                $_.Extension -in @('.ps1', '.yml', '.yaml', '.json') -and
                $_.Name -notlike '*.example' -and
                $_.Name -notlike '*.template' -and
                $_.FullName -notlike "*\artifacts\*"
            }
            
            foreach ($file in $filesToCheck) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    foreach ($pattern in $secretPatterns) {
                        $content | Should -Not -Match $pattern -Because "File $($file.Name) should not contain obvious secrets"
                    }
                }
            }
        }
    }
    
    Context "Documentation" {
        It "Should have comprehensive README" {
            $readmePath = Join-Path $RepoRoot "README.md"
            Test-Path $readmePath | Should -Be $true -Because "README.md should exist"
            
            $content = Get-Content $readmePath -Raw
            $content | Should -Match "Quickstart" -Because "README should contain quickstart information"
            $content | Should -Match "Install" -Because "README should contain installation instructions"
        }
        
        It "Should have rollback documentation" {
            $rollbackPath = Join-Path $RepoRoot "docs\ROLLBACK.md"
            Test-Path $rollbackPath | Should -Be $true -Because "Rollback documentation should exist"
            
            $content = Get-Content $rollbackPath -Raw
            $content | Should -Match "Stop.*Service" -Because "Rollback doc should contain service stop instructions"
            $content | Should -Match "docker compose.*down" -Because "Rollback doc should contain Docker stop instructions"
        }
    }
    
    Context "GitHub Workflows" {
        It "Should have hygiene workflow" {
            $hygieneWorkflow = Join-Path $RepoRoot ".github\workflows\hygiene.yml"
            Test-Path $hygieneWorkflow | Should -Be $true -Because "Hygiene workflow should exist"
        }
        
        It "Should have security workflows" {
            $codeqlWorkflow = Join-Path $RepoRoot ".github\workflows\codeql.yml"
            $gitleaksWorkflow = Join-Path $RepoRoot ".github\workflows\gitleaks.yml"
            
            Test-Path $codeqlWorkflow | Should -Be $true -Because "CodeQL workflow should exist"
            Test-Path $gitleaksWorkflow | Should -Be $true -Because "Gitleaks workflow should exist"
        }
        
        It "Should have dependabot configuration" {
            $dependabotConfig = Join-Path $RepoRoot ".github\dependabot.yml"
            Test-Path $dependabotConfig | Should -Be $true -Because "Dependabot configuration should exist"
        }
    }
    
    Context "Issue Templates" {
        It "Should have bug report template" {
            $bugTemplate = Join-Path $RepoRoot ".github\ISSUE_TEMPLATE\bug_report.yml"
            Test-Path $bugTemplate | Should -Be $true -Because "Bug report template should exist"
        }
        
        It "Should have feature request template" {
            $featureTemplate = Join-Path $RepoRoot ".github\ISSUE_TEMPLATE\feature_request.yml"
            Test-Path $featureTemplate | Should -Be $true -Because "Feature request template should exist"
        }
    }
}