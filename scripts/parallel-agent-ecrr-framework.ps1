#Requires -Version 7.0

<#
.SYNOPSIS
    ECRR Compliance Framework for Bosscat Parallel Agent System
    Ensures all agent operations follow ECRR methodology with proper documentation

.DESCRIPTION
    This module provides ECRR (Examine → Clean → Report → Role) compliance for parallel
    agent operations, ensuring proper documentation, evidence collection, and audit trails
    for all agent activities.

.PARAMETER SessionId
    Unique session identifier for ECRR tracking

.PARAMETER AgentId
    Agent identifier for ECRR documentation

.PARAMETER OperationType
    Type of operation being performed

.PARAMETER EvidencePath
    Path for storing ECRR evidence and artifacts

.PARAMETER ComplianceLevel
    ECRR compliance level (basic, standard, strict)

.EXAMPLE
    .\parallel-agent-ecrr-framework.ps1 -SessionId "session-001" -AgentId "agent-001" -OperationType "batch-processing"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SessionId,
    
    [Parameter(Mandatory)]
    [string]$AgentId,
    
    [Parameter(Mandatory)]
    [string]$OperationType,
    
    [string]$EvidencePath = 'artifacts/ecrr-evidence',
    
    [ValidateSet('basic', 'standard', 'strict')]
    [string]$ComplianceLevel = 'standard',
    
    [hashtable]$Context = @{},
    
    [switch]$EnableAutoDocumentation,
    
    [switch]$RequireActorDeclaration,
    
    [switch]$EnableComplianceValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ECRR Compliance Classes
class ECRRSession {
    [string]$SessionId
    [string]$AgentId
    [string]$OperationType
    [string]$ComplianceLevel
    [hashtable]$Context
    [datetime]$StartTime
    [datetime]$EndTime
    [string]$Status
    [hashtable]$Phases
    [System.Collections.ArrayList]$Evidence
    [System.Collections.ArrayList]$Violations
    [hashtable]$Metrics
    
    ECRRSession([string]$sessionId, [string]$agentId, [string]$operationType, [string]$complianceLevel, [hashtable]$context) {
        $this.SessionId = $sessionId
        $this.AgentId = $agentId
        $this.OperationType = $operationType
        $this.ComplianceLevel = $complianceLevel
        $this.Context = $context
        $this.StartTime = Get-Date
        $this.Status = 'active'
        $this.Phases = @{}
        $this.Evidence = [System.Collections.ArrayList]::new()
        $this.Violations = [System.Collections.ArrayList]::new()
        $this.Metrics = @{}
        
        $this.InitializePhases()
    }
    
    [void] InitializePhases() {
        $this.Phases = @{
            'examine' = @{
                Status = 'pending'
                StartTime = $null
                EndTime = $null
                Duration = $null
                Evidence = @()
                Findings = @()
                ComplianceScore = 0
            }
            'clean' = @{
                Status = 'pending'
                StartTime = $null
                EndTime = $null
                Duration = $null
                Evidence = @()
                Actions = @()
                ComplianceScore = 0
            }
            'report' = @{
                Status = 'pending'
                StartTime = $null
                EndTime = $null
                Duration = $null
                Evidence = @()
                Reports = @()
                ComplianceScore = 0
            }
            'role' = @{
                Status = 'pending'
                StartTime = $null
                EndTime = $null
                Duration = $null
                Evidence = @()
                ActorDeclaration = $null
                ComplianceScore = 0
            }
        }
    }
    
    [void] StartPhase([string]$phaseName) {
        if (-not $this.Phases.ContainsKey($phaseName)) {
            throw "Invalid ECRR phase: $phaseName"
        }
        
        $phase = $this.Phases[$phaseName]
        $phase.Status = 'active'
        $phase.StartTime = Get-Date
        
        $this.AddEvidence($phaseName, "Phase started", @{
            'phase.name' = $phaseName
            'phase.start_time' = $phase.StartTime.ToString('o')
            'agent.id' = $this.AgentId
        })
    }
    
    [void] CompletePhase([string]$phaseName, [hashtable]$results = @{}) {
        if (-not $this.Phases.ContainsKey($phaseName)) {
            throw "Invalid ECRR phase: $phaseName"
        }
        
        $phase = $this.Phases[$phaseName]
        $phase.Status = 'completed'
        $phase.EndTime = Get-Date
        $phase.Duration = ($phase.EndTime - $phase.StartTime).TotalMilliseconds
        
        # Calculate compliance score for phase
        $phase.ComplianceScore = $this.CalculatePhaseCompliance($phaseName, $results)
        
        $this.AddEvidence($phaseName, "Phase completed", @{
            'phase.name' = $phaseName
            'phase.end_time' = $phase.EndTime.ToString('o')
            'phase.duration_ms' = $phase.Duration
            'phase.compliance_score' = $phase.ComplianceScore
            'results' = $results
        })
    }
    
    [double] CalculatePhaseCompliance([string]$phaseName, [hashtable]$results) {
        $score = 100.0
        
        switch ($phaseName) {
            'examine' {
                # Check for required findings and evidence
                if (-not $results.ContainsKey('findings') -or $results.findings.Count -eq 0) {
                    $score -= 25
                }
                if (-not $results.ContainsKey('evidence') -or $results.evidence.Count -eq 0) {
                    $score -= 25
                }
                if (-not $results.ContainsKey('scope') -or [string]::IsNullOrEmpty($results.scope)) {
                    $score -= 20
                }
                if (-not $results.ContainsKey('baseline') -or [string]::IsNullOrEmpty($results.baseline)) {
                    $score -= 15
                }
                if (-not $results.ContainsKey('timestamp')) {
                    $score -= 15
                }
            }
            'clean' {
                # Check for required actions and remediation
                if (-not $results.ContainsKey('actions') -or $results.actions.Count -eq 0) {
                    $score -= 30
                }
                if (-not $results.ContainsKey('remediation') -or [string]::IsNullOrEmpty($results.remediation)) {
                    $score -= 25
                }
                if (-not $results.ContainsKey('validation') -or [string]::IsNullOrEmpty($results.validation)) {
                    $score -= 20
                }
                if (-not $results.ContainsKey('logs') -or $results.logs.Count -eq 0) {
                    $score -= 15
                }
                if (-not $results.ContainsKey('artifacts') -or $results.artifacts.Count -eq 0) {
                    $score -= 10
                }
            }
            'report' {
                # Check for required reports and metrics
                if (-not $results.ContainsKey('reports') -or $results.reports.Count -eq 0) {
                    $score -= 30
                }
                if (-not $results.ContainsKey('metrics') -or $results.metrics.Count -eq 0) {
                    $score -= 25
                }
                if (-not $results.ContainsKey('status') -or [string]::IsNullOrEmpty($results.status)) {
                    $score -= 20
                }
                if (-not $results.ContainsKey('artifacts') -or $results.artifacts.Count -eq 0) {
                    $score -= 15
                }
                if (-not $results.ContainsKey('compliance') -or [string]::IsNullOrEmpty($results.compliance)) {
                    $score -= 10
                }
            }
            'role' {
                # Check for required actor declaration and responsibilities
                if (-not $results.ContainsKey('actor_declaration') -or [string]::IsNullOrEmpty($results.actor_declaration)) {
                    $score -= 40
                }
                if (-not $results.ContainsKey('responsibilities') -or $results.responsibilities.Count -eq 0) {
                    $score -= 25
                }
                if (-not $results.ContainsKey('scope') -or [string]::IsNullOrEmpty($results.scope)) {
                    $score -= 20
                }
                if (-not $results.ContainsKey('accountability') -or [string]::IsNullOrEmpty($results.accountability)) {
                    $score -= 15
                }
            }
        }
        
        return [Math]::Max(0, $score)
    }
    
    [void] AddEvidence([string]$phase, [string]$description, [hashtable]$data) {
        $evidenceEntry = @{
            timestamp = (Get-Date).ToString('o')
            phase = $phase
            description = $description
            data = $data
            session_id = $this.SessionId
            agent_id = $this.AgentId
        }
        
        $null = $this.Evidence.Add($evidenceEntry)
    }
    
    [void] AddViolation([string]$phase, [string]$violation, [string]$severity = 'medium') {
        $violationRecord = @{
            timestamp = (Get-Date).ToString('o')
            phase = $phase
            violation = $violation
            severity = $severity
            session_id = $this.SessionId
            agent_id = $this.AgentId
        }
        
        $this.Violations.Add($violationRecord)
    }
    
    [void] AddMetric([string]$name, [double]$value, [hashtable]$tags = @{}) {
        $metric = @{
            timestamp = (Get-Date).ToString('o')
            name = $name
            value = $value
            tags = $tags
            session_id = $this.SessionId
            agent_id = $this.AgentId
        }
        
        $this.Metrics[$name] = $metric
    }
    
    [hashtable] GetComplianceReport() {
        $totalScore = 0
        $phaseCount = 0
        
        foreach ($phase in $this.Phases.Values) {
            if ($phase.Status -eq 'completed') {
                $totalScore += $phase.ComplianceScore
                $phaseCount++
            }
        }
        
        $overallScore = if ($phaseCount -gt 0) { $totalScore / $phaseCount } else { 0 }
        
        return @{
            SessionId = $this.SessionId
            AgentId = $this.AgentId
            OperationType = $this.OperationType
            ComplianceLevel = $this.ComplianceLevel
            OverallScore = [Math]::Round($overallScore, 2)
            PhaseScores = $this.Phases | ForEach-Object { @{ $_.Keys = $_.Values.ComplianceScore } }
            ViolationCount = $this.Violations.Count
            EvidenceCount = $this.Evidence.Count
            MetricsCount = $this.Metrics.Count
            StartTime = $this.StartTime.ToString('o')
            EndTime = $this.EndTime.ToString('o')
            Duration = if ($this.EndTime) { ($this.EndTime - $this.StartTime).TotalMilliseconds } else { $null }
            Status = $this.Status
        }
    }
    
    [void] CompleteSession([hashtable]$finalResults = @{}) {
        $this.EndTime = Get-Date
        $this.Status = 'completed'
        
        # Calculate final metrics
        $this.AddMetric('session_duration_ms', ($this.EndTime - $this.StartTime).TotalMilliseconds)
        $this.AddMetric('evidence_count', $this.Evidence.Count)
        $this.AddMetric('violation_count', $this.Violations.Count)
        
        # Final compliance validation
        $complianceReport = $this.GetComplianceReport()
        $this.AddMetric('compliance_score', $complianceReport.OverallScore)
        
        $this.AddEvidence('session', 'Session completed', @{
            'final_results' = $finalResults
            'compliance_report' = $complianceReport
        })
    }
}

class ECRRValidator {
    [string]$ComplianceLevel
    [hashtable]$ValidationRules
    
    ECRRValidator([string]$complianceLevel) {
        $this.ComplianceLevel = $complianceLevel
        $this.InitializeValidationRules()
    }
    
    [void] InitializeValidationRules() {
        $this.ValidationRules = @{
            'basic' = @{
                'examine' = @('findings', 'scope')
                'clean' = @('actions', 'remediation')
                'report' = @('reports', 'status')
                'role' = @('actor_declaration')
            }
            'standard' = @{
                'examine' = @('findings', 'scope', 'baseline', 'evidence')
                'clean' = @('actions', 'remediation', 'validation', 'logs')
                'report' = @('reports', 'status', 'metrics', 'artifacts')
                'role' = @('actor_declaration', 'responsibilities', 'scope')
            }
            'strict' = @{
                'examine' = @('findings', 'scope', 'baseline', 'evidence', 'timestamp')
                'clean' = @('actions', 'remediation', 'validation', 'logs', 'artifacts')
                'report' = @('reports', 'status', 'metrics', 'artifacts', 'compliance')
                'role' = @('actor_declaration', 'responsibilities', 'scope', 'accountability')
            }
        }
    }
    
    [hashtable] ValidatePhase([string]$phaseName, [hashtable]$results) {
        $violations = @()
        $score = 100.0
        
        $rules = $this.ValidationRules[$this.ComplianceLevel][$phaseName]
        if (-not $rules) {
            $violations += "No validation rules defined for phase: $phaseName"
            return @{ Violations = $violations; Score = 0 }
        }
        
        foreach ($rule in $rules) {
            if (-not $results.ContainsKey($rule) -or [string]::IsNullOrEmpty($results[$rule])) {
                $violations += "Missing required field: $rule"
                $score -= 20
            }
        }
        
        return @{
            Violations = $violations
            Score = [Math]::Max(0, $score)
        }
    }
    
    [hashtable] ValidateSession([ECRRSession]$session) {
        $allViolations = @()
        $totalScore = 0
        $phaseCount = 0
        
        foreach ($phaseName in $session.Phases.Keys) {
            $phase = $session.Phases[$phaseName]
            if ($phase.Status -eq 'completed') {
                $validation = $this.ValidatePhase($phaseName, $phase)
                $allViolations += $validation.Violations
                $totalScore += $validation.Score
                $phaseCount++
            }
        }
        
        $overallScore = if ($phaseCount -gt 0) { $totalScore / $phaseCount } else { 0 }
        
        return @{
            OverallScore = [Math]::Round($overallScore, 2)
            Violations = $allViolations
            IsCompliant = $overallScore -ge 80
            ComplianceLevel = $this.ComplianceLevel
        }
    }
}

class ECRRDocumentGenerator {
    [string]$EvidencePath
    [string]$TemplatePath
    
    ECRRDocumentGenerator([string]$evidencePath) {
        $this.EvidencePath = $evidencePath
        $this.TemplatePath = Join-Path $evidencePath 'templates'
        $this.InitializeTemplates()
    }
    
    [void] InitializeTemplates() {
        if (-not (Test-Path $this.TemplatePath)) {
            $null = New-Item -ItemType Directory -Path $this.TemplatePath -Force
        }
        
        # Create ECRR report template
        $template = @"
# ECRR Report - {0}

## 🔍 1. Examine
- **Finding**: {1}
- **Evidence**: {2}
- **Scope**: {3}
- **Baseline**: {4}
- **Timestamp**: {5}

## 🧹 2. Clean
- **Action**: {6}
- **Remediation**: {7}
- **Validation**: {8}
- **Logs**: {9}
- **Artifacts**: {10}

## 📊 3. Report
- **Status**: {11}
- **Metrics**: {12}
- **Reports**: {13}
- **Artifacts**: {14}
- **Compliance**: {15}

## 👤 4. Role
- **Agent**: {16}
- **Actor Declaration**: {17}
- **Responsibilities**: {18}
- **Scope**: {19}
- **Accountability**: {20}

### ECRR Gate
- **ProductionReady**: {21}
- **EvidenceReference**: {22}
- **ComplianceScore**: {23}
- **ValidationDate**: {24}
"@
        
        $reportTemplatePath = Join-Path $this.TemplatePath 'ecrr-report-template.md'
        Set-Content -Path $reportTemplatePath -Value $template -Encoding UTF8
    }
    
    [string] GenerateECRRReport([ECRRSession]$session, [hashtable]$data) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $reportPath = Join-Path $this.EvidencePath "ECRR-$($session.AgentId)-$timestamp.md"
        
        $examine = $session.Phases['examine']
        $clean = $session.Phases['clean']
        $report = $session.Phases['report']
        $role = $session.Phases['role']
        
        $complianceReport = $session.GetComplianceReport()
        
        $reportContent = @"
# ECRR Report - $($session.OperationType)

**Session ID**: $($session.SessionId)  
**Agent ID**: $($session.AgentId)  
**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Compliance Level**: $($session.ComplianceLevel)  
**Overall Score**: $($complianceReport.OverallScore)%

## 🔍 1. Examine
- **Finding**: $($data.examine.findings -join ', ')
- **Evidence**: $($data.examine.evidence -join ', ')
- **Scope**: $($data.examine.scope)
- **Baseline**: $($data.examine.baseline)
- **Timestamp**: $($examine.StartTime.ToString('o'))
- **Compliance Score**: $($examine.ComplianceScore)%

## 🧹 2. Clean
- **Action**: $($data.clean.actions -join ', ')
- **Remediation**: $($data.clean.remediation)
- **Validation**: $($data.clean.validation)
- **Logs**: $($data.clean.logs -join ', ')
- **Artifacts**: $($data.clean.artifacts -join ', ')
- **Compliance Score**: $($clean.ComplianceScore)%

## 📊 3. Report
- **Status**: $($data.report.status)
- **Metrics**: $($data.report.metrics -join ', ')
- **Reports**: $($data.report.reports -join ', ')
- **Artifacts**: $($data.report.artifacts -join ', ')
- **Compliance**: $($data.report.compliance)
- **Compliance Score**: $($report.ComplianceScore)%

## 👤 4. Role
- **Agent**: $($session.AgentId)
- **Actor Declaration**: $($data.role.actor_declaration)
- **Responsibilities**: $($data.role.responsibilities -join ', ')
- **Scope**: $($data.role.scope)
- **Accountability**: $($data.role.accountability)
- **Compliance Score**: $($role.ComplianceScore)%

### ECRR Gate
- **ProductionReady**: $($complianceReport.OverallScore -ge 80)
- **EvidenceReference**: $reportPath
- **ComplianceScore**: $($complianceReport.OverallScore)%
- **ValidationDate**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **ViolationCount**: $($complianceReport.ViolationCount)
- **EvidenceCount**: $($complianceReport.EvidenceCount)

## 📋 Session Summary
- **Start Time**: $($session.StartTime.ToString('o'))
- **End Time**: $($session.EndTime.ToString('o'))
- **Duration**: $([Math]::Round($complianceReport.Duration, 2)) ms
- **Operation Type**: $($session.OperationType)
- **Context**: $($session.Context | ConvertTo-Json -Compress)

## 🚨 Violations
$(if ($session.Violations.Count -gt 0) {
    $session.Violations | ForEach-Object {
        "- **$($_.severity.ToUpper())**: $($_.violation) ($($_.phase))"
    }
} else {
    "- No violations detected"
})

## 📊 Evidence Trail
$(if ($session.Evidence.Count -gt 0) {
    $session.Evidence | ForEach-Object {
        "- **$($_.phase.ToUpper())**: $($_.description) ($($_.timestamp))"
    }
} else {
    "- No evidence recorded"
})
"@
        
        Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
        return $reportPath
    }
}

# Main execution
try {
    # Initialize evidence directory
    if (-not (Test-Path $EvidencePath)) {
        $null = New-Item -ItemType Directory -Path $EvidencePath -Force
    }
    
    # Initialize ECRR session
    $session = [ECRRSession]::new($SessionId, $AgentId, $OperationType, $ComplianceLevel, $Context)
    
    # Initialize validator if enabled
    $validator = if ($EnableComplianceValidation) {
        [ECRRValidator]::new($ComplianceLevel)
    } else {
        $null
    }
    
    # Initialize document generator
    $docGenerator = [ECRRDocumentGenerator]::new($EvidencePath)
    
    Write-Host "`n🎯 ECRR Compliance Framework Initialized" -ForegroundColor Green
    Write-Host "Session ID: $SessionId" -ForegroundColor Cyan
    Write-Host "Agent ID: $AgentId" -ForegroundColor Cyan
    Write-Host "Operation: $OperationType" -ForegroundColor Cyan
    Write-Host "Compliance Level: $ComplianceLevel" -ForegroundColor Cyan
    Write-Host "Evidence Path: $EvidencePath" -ForegroundColor Gray
    
    # Return ECRR components for use by calling scripts
    return @{
        Session = $session
        Validator = $validator
        DocumentGenerator = $docGenerator
        EvidencePath = $EvidencePath
        ComplianceLevel = $ComplianceLevel
    }
    
} catch {
    Write-Error "ECRR compliance framework initialization failed: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
