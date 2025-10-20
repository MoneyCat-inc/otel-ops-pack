# Index Performance Claims (77×, 7×, 196.7)
# Generates CSV with file path, line number, match, context, and classification tags

$results = @()

# Search for inflated claims (77× and 196.7)
$inflatedMatches = rg -n --hidden --glob '!node_modules/*' --glob '!.git/*' `
    -e '77\s*[x×]' -e '196\.7'

foreach ($line in $inflatedMatches) {
    if ($line -match '^([^:]+):(\d+):(.+)$') {
        $file = $matches[1]
        $lineNum = $matches[2]
        $content = $matches[3]
        
        # Classify based on file path and content
        $tag = "unspecified"
        $lowerFile = $file.ToLower()
        $lowerContent = $content.ToLower()
        
        if ($lowerFile -match '(readme|index\.html|portal\.html|patreon|monetization)' -or 
            $lowerContent -match '(hero|landing|badge|headline|marketing)') {
            $tag = "marketing"
        }
        elseif ($lowerContent -match '(k6|threshold|test|baseline|median|p95|otlp|signoz|collector|throughput|logs/sec)') {
            $tag = "measured"
        }
        elseif ($lowerFile -match '(archive|history|legacy|prsv|char/evid)' -or 
                $lowerContent -match '(legacy|history|old claim|audit|archived)') {
            $tag = "historical"
        }
        elseif ($lowerFile -match '(delt/artf|artifacts)') {
            $tag = "artifact"
        }
        elseif ($lowerFile -match '(ecrr_reports|bosscat)') {
            $tag = "ecrr_report"
        }
        
        # Determine claim type
        $claimType = if ($content -match '77') { "77× (INFLATED)" } else { "196.7 (INFLATED)" }
        
        $results += [PSCustomObject]@{
            File = $file
            Line = $lineNum
            Claim = $claimType
            Tag = $tag
            Context = $content.Substring(0, [Math]::Min(120, $content.Length)).Trim()
        }
    }
}

# Export results
$outputPath = "artifacts/claims_index_tagged.csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "✅ Indexed $($results.Count) inflated claims"
Write-Host "📁 Output: $outputPath"

# Summary by tag
Write-Host "`n📊 Classification Summary:"
$results | Group-Object Tag | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) occurrences"
}

# Critical files requiring immediate fix
Write-Host "`n🚨 Critical Files (marketing/measured):"
$critical = $results | Where-Object { $_.Tag -eq 'marketing' -or $_.Tag -eq 'measured' } | 
    Group-Object File | Select-Object -First 10
foreach ($file in $critical) {
    Write-Host "  - $($file.Name) ($($file.Count) claims)"
}

