# OpenTelemetry Issue Response — Ready to Post

**Context:** Response to 404 feedback on Windows Day-2 Ops Kit links

---

## Comment to Post

Thanks, @axw - totally fair on the 404s. We completed the repo rename and have now published stable permalinks on our new site:

* **Overview & goals (Windows Day-2 Ops Kit)** -> [https://hub.resonai.uk/docs/day2/windows/overview/](https://hub.resonai.uk/docs/day2/windows/overview/)
* **"Thin" example (Collector-only)** -> [https://hub.resonai.uk/docs/examples/windows-day2-ops/thin/](https://hub.resonai.uk/docs/examples/windows-day2-ops/thin/)
* **Windows service mode (NSSM)** -> [https://hub.resonai.uk/docs/examples/windows-service-mode/](https://hub.resonai.uk/docs/examples/windows-service-mode/)
* **Linux sidecar/Helm** -> [https://hub.resonai.uk/docs/examples/linux-sidecar-helm/](https://hub.resonai.uk/docs/examples/linux-sidecar-helm/)
* **Policy bundle & cosign attestations** -> [https://hub.resonai.uk/docs/security/policy-bundle/](https://hub.resonai.uk/docs/security/policy-bundle/)
* **SBOM + release attestations** -> [https://hub.resonai.uk/docs/security/supply-chain/sbom/](https://hub.resonai.uk/docs/security/supply-chain/sbom/)

If helpful, I can open a Draft PR that contributes just the *thin, self-contained* Windows guardrails example to `opentelemetry-collector-contrib/examples`, keeping the broader framework out-of-tree.

Thanks again for the steer!

---

## Verification Checklist (Before Posting)

- [ ] Wait for GitHub Pages rebuild (2-3 minutes)
- [ ] Test all 6 URLs in browser
- [ ] Confirm all pages load without 404
- [ ] Verify canonical tags present
- [ ] Check styling matches Hub

## URLs to Test

```bash
# All should return 200
curl -I https://hub.resonai.uk/docs/day2/windows/overview/
curl -I https://hub.resonai.uk/docs/examples/windows-day2-ops/thin/
curl -I https://hub.resonai.uk/docs/examples/windows-service-mode/
curl -I https://hub.resonai.uk/docs/examples/linux-sidecar-helm/
curl -I https://hub.resonai.uk/docs/security/policy-bundle/
curl -I https://hub.resonai.uk/docs/security/supply-chain/sbom/
```

## PowerShell Version

```powershell
$urls = @(
    "https://hub.resonai.uk/docs/day2/windows/overview/",
    "https://hub.resonai.uk/docs/examples/windows-day2-ops/thin/",
    "https://hub.resonai.uk/docs/examples/windows-service-mode/",
    "https://hub.resonai.uk/docs/examples/linux-sidecar-helm/",
    "https://hub.resonai.uk/docs/security/policy-bundle/",
    "https://hub.resonai.uk/docs/security/supply-chain/sbom/"
)

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ $url -> $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ $url -> ERROR" -ForegroundColor Red
    }
}
```

---

## Next Steps After Posting

1. Monitor for maintainer response
2. If requested, prepare thin example PR for contrib repo
3. Update permalinks in any existing documentation
4. Add these URLs to Hub navigation (optional)

---

**Status:** Ready to post once Pages rebuild completes (~2-3 minutes)

