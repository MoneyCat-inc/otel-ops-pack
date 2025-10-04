# GitHub Secrets Setup Instructions
# Run these commands to configure required secrets:

Write-Host "Setting up GitHub secrets for automation..." -ForegroundColor Cyan

# Set SigNoz credentials
gh secret set SIGNOZ_URL --body 'http://your-signoz-instance.com'
gh secret set SIGNOZ_USER --body 'your-signoz-username'  
gh secret set SIGNOZ_PASS --body 'your-signoz-password'

# Verify secrets are set
gh secret list

Write-Host "✅ Secrets configured successfully!" -ForegroundColor Green
