#!/usr/bin/env python3
"""
BossCat CI Pipeline Monitor
Monitors GitHub Actions runs for BossCat gate verification pipeline
"""

import requests
import json
import time
from datetime import datetime
from typing import Dict, List, Optional

class BossCatCIMonitor:
    def __init__(self, repo_owner: str, repo_name: str, github_token: Optional[str] = None):
        self.repo_owner = repo_owner
        self.repo_name = repo_name
        self.github_token = github_token
        self.base_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}"
        self.headers = {
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "BossCat-CI-Monitor"
        }
        if github_token:
            self.headers["Authorization"] = f"token {github_token}"
    
    def get_workflow_runs(self, workflow_name: str = "bosscat-gate-verify") -> List[Dict]:
        """Get recent workflow runs for BossCat pipeline"""
        try:
            url = f"{self.base_url}/actions/workflows/{workflow_name}.yml/runs"
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            return response.json().get("workflow_runs", [])
        except Exception as e:
            print(f"[ERROR] Failed to fetch workflow runs: {e}")
            return []
    
    def format_status(self, status: str, conclusion: str) -> str:
        """Format workflow status"""
        if status == "completed":
            if conclusion == "success":
                return "[OK] SUCCESS"
            elif conclusion == "failure":
                return "[ERROR] FAILED"
            elif conclusion == "cancelled":
                return "[STOP] CANCELLED"
            else:
                return f"[WARN] {conclusion.upper()}"
        elif status == "in_progress":
            return "[RUNNING] IN PROGRESS"
        elif status == "queued":
            return "[WAIT] QUEUED"
        else:
            return f"[UNKNOWN] {status.upper()}"
    
    def print_run_summary(self, run: Dict):
        """Print a summary of a workflow run"""
        status_text = self.format_status(run.get("status", ""), run.get("conclusion", ""))
        created_at = datetime.fromisoformat(run.get("created_at", "").replace("Z", "+00:00"))
        updated_at = datetime.fromisoformat(run.get("updated_at", "").replace("Z", "+00:00"))
        
        print(f"\n[INFO] Run #{run.get('run_number', 'N/A')}")
        print(f"   Status: {status_text}")
        print(f"   Triggered: {created_at.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f"   Updated: {updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f"   Branch: {run.get('head_branch', 'N/A')}")
        print(f"   Commit: {run.get('head_sha', 'N/A')[:8]}")
        print(f"   URL: {run.get('html_url', 'N/A')}")
    
    def monitor_recent_runs(self, limit: int = 5):
        """Monitor recent BossCat pipeline runs"""
        print("BossCat CI Pipeline Monitor")
        print("=" * 50)
        
        runs = self.get_workflow_runs()
        if not runs:
            print("[ERROR] No workflow runs found or unable to fetch data")
            print("[INFO] Make sure:")
            print("   - The workflow file exists in .github/workflows/")
            print("   - At least one run has been triggered")
            print("   - GitHub token has appropriate permissions (if using)")
            return
        
        print(f"[STATS] Found {len(runs)} recent runs")
        
        for i, run in enumerate(runs[:limit]):
            self.print_run_summary(run)
        
        print(f"\n[STATS] Monitoring Summary:")
        print(f"   Total runs: {len(runs)}")
        
        # Count statuses
        status_counts = {}
        for run in runs:
            status = run.get("status", "unknown")
            conclusion = run.get("conclusion", "unknown")
            key = f"{status}_{conclusion}" if status == "completed" else status
            status_counts[key] = status_counts.get(key, 0) + 1
        
        for status, count in status_counts.items():
            print(f"   {status}: {count}")

def main():
    """Main monitoring function"""
    print("[LAUNCH] Starting BossCat CI Pipeline Monitor...")
    
    # Configuration - Update these values
    REPO_OWNER = "MoneyCat-inc"  # Update with your GitHub username/org
    REPO_NAME = "otel-ops-pack"   # Update with your repository name
    GITHUB_TOKEN = None           # Optional: Add your GitHub token for higher rate limits
    
    monitor = BossCatCIMonitor(REPO_OWNER, REPO_NAME, GITHUB_TOKEN)
    monitor.monitor_recent_runs(limit=5)
    
    print(f"\n[INFO] Next Steps:")
    print(f"   1. Check GitHub Actions tab: https://github.com/{REPO_OWNER}/{REPO_NAME}/actions")
    print(f"   2. Look for 'BossCat Gate Verification' workflow")
    print(f"   3. Review any failed runs for troubleshooting")
    print(f"   4. Monitor performance metrics and thresholds")

if __name__ == "__main__":
    main()