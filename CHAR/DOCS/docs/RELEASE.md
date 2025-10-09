# Release Provenance & Verification

## 🔐 **Supply Chain Security**

Every codex-local release includes cryptographically signed artifacts for supply chain integrity verification.

### **Release Artifacts**

Each release (`vX.Y.Z`) includes:

- **SBOM**: `codex-local-sbom.cdx.json` - Software Bill of Materials (CycloneDX format)
- **SBOM Signature**: `codex-local-sbom.cdx.sig` - Cryptographic signature
- **Policy Bundle**: `codex-policy-bundle.tar.gz` - OPA/Rego policy bundle
- **Policy Signature**: `codex-policy-bundle.sig` - Cryptographic signature

### **Verification Commands**

#### **Verify SBOM**
```bash
# Download release artifacts
wget https://github.com/resonai/codex-local/releases/download/v1.0.0/codex-local-sbom.cdx.json
wget https://github.com/resonai/codex-local/releases/download/v1.0.0/codex-local-sbom.cdx.sig

# Verify signature
cosign verify-blob \
  --key https://github.com/resonai/codex-local/.github/workflows/cosign.pub \
  --signature codex-local-sbom.cdx.sig \
  codex-local-sbom.cdx.json
```

#### **Verify Policy Bundle**
```bash
# Download policy artifacts
wget https://github.com/resonai/codex-local/releases/download/v1.0.0/codex-policy-bundle.tar.gz
wget https://github.com/resonai/codex-local/releases/download/v1.0.0/codex-policy-bundle.sig

# Verify signature
cosign verify-blob \
  --key https://github.com/resonai/codex-local/.github/workflows/cosign.pub \
  --signature codex-policy-bundle.sig \
  codex-policy-bundle.tar.gz
```

#### **Verify SHA256 Checksums**
```bash
# Download checksums
wget https://github.com/resonai/codex-local/releases/download/v1.0.0/checksums.txt

# Verify checksums
sha256sum -c checksums.txt
```

### **Cosign Public Key**

The public key for verification is available at:
- **GitHub**: https://github.com/resonai/codex-local/.github/workflows/cosign.pub
- **Sigstore**: https://search.sigstore.dev/?rekor.url=https%3A%2F%2Frekor.sigstore.dev

### **Rekor Transparency Log**

All signatures are recorded in the Rekor transparency log:
- **Rekor Search**: https://search.sigstore.dev/
- **Rekor API**: https://rekor.sigstore.dev

### **Verification Script**

For automated verification, use our verification script:

```powershell
# PowerShell verification
pwsh -File scripts/supplychain/verify-release.ps1 -Version v1.0.0

# Bash verification
bash scripts/supplychain/verify-release.sh v1.0.0
```

### **Trust Model**

- **Signing Key**: Generated using cosign keyless signing with GitHub OIDC
- **Transparency**: All signatures recorded in Rekor transparency log
- **Verification**: Public key available in repository for verification
- **Integrity**: SHA256 checksums provided for all artifacts

### **Security Considerations**

- **Keyless Signing**: Uses GitHub OIDC for ephemeral key generation
- **Transparency**: All signatures publicly verifiable via Rekor
- **Non-Repudiation**: Cryptographic signatures prevent tampering
- **Audit Trail**: Complete provenance chain from source to release

### **Compliance**

This release provenance approach supports:
- **SLSA Level 3**: Provenance and non-falsifiable build information
- **NIST Cybersecurity Framework**: Supply chain risk management
- **SOC 2**: Security and availability controls
- **ISO 27001**: Information security management

### **Troubleshooting**

#### **Verification Fails**
1. Check internet connectivity
2. Verify release version exists
3. Confirm public key is accessible
4. Check Rekor transparency log

#### **Signature Invalid**
1. Verify artifact wasn't modified
2. Check signature file integrity
3. Confirm correct public key
4. Validate timestamp in Rekor

#### **Checksum Mismatch**
1. Re-download artifacts
2. Verify download integrity
3. Check for network corruption
4. Compare with Rekor entries

### **Support**

For verification issues:
- **GitHub Issues**: https://github.com/resonai/codex-local/issues
- **Security**: security@resonai.com
- **Documentation**: https://github.com/resonai/codex-local/blob/main/docs/SECURITY.md

---

**Last Updated**: 2025-09-28  
**Version**: 1.0.0  
**Next Review**: 2025-10-28
