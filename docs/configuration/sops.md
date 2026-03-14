# SOPS Encryption Guide

## Overview

This project uses SOPS with AGE encryption to manage secrets. Secret files live in the centralized `secrets/` directory: encrypted files use the `.env.enc` extension (committed to git) and decrypted files use `.env.dec` (transient, gitignored).

## Initial Setup

1. **Install SOPS and AGE**:

   ```bash
   # macOS
   brew install sops age

   # Linux (Debian/Ubuntu)
   sudo apt install age
   # Download SOPS binary from https://github.com/getsops/sops/releases
   ```

1. **Generate AGE key** (if you don't have one):

   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

1. **Get your public key**:

   ```bash
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

## Encrypting and Decrypting Files

Use the Taskfile commands for encryption and decryption:

```bash
# Decrypt all secrets in the secrets/ directory
task secrets:decrypt

# Collect all decrypted secrets into a single aggregated file (secrets/all.env.dec)
task secrets:collect
```

If you need to run SOPS manually, specify the dotenv format explicitly:

```bash
# Encrypt
sops --encrypt --input-type dotenv --output-type dotenv secrets/auth-secrets.env > secrets/auth-secrets.env.enc

# Decrypt
sops --decrypt --input-type dotenv --output-type dotenv secrets/auth-secrets.env.enc > secrets/auth-secrets.env.dec
```

## Common Issues

### 1. "Invalid character" error

- **Cause**: SOPS is trying to parse the file with wrong format
- **Solution**: Use `--input-type dotenv` for .env files

### 2. "No identity matched any of the recipients"

- **Cause**: Your AGE key doesn't match the recipient
- **Solution**: Ensure your AGE key is in `~/.config/sops/age/keys.txt` or set `SOPS_AGE_KEY_FILE`

### 3. Format detection issues

- **Cause**: SOPS can't determine file format from extension
- **Solution**: Always use explicit `--input-type` and `--output-type` for .env files

## Best Practices

1. **Never commit decrypted files**:
   The `.gitignore` already excludes decrypted secrets:

   ```bash
   *.env.dec
   ```

1. **Use consistent naming**:

   - Encrypted (committed): `secrets/<service>-secrets.env.enc`
   - Decrypted (transient): `secrets/<service>-secrets.env.dec`
   - Aggregated master file: `secrets/all.env.dec`

1. **Document required secrets**:
   Create a `secrets/<service>-secrets.env.example` with dummy values:

   ```bash
   POSTGRES_PASSWORD=changeme
   AUTHENTIK_SECRET_KEY=generate-a-secure-key
   ```

## Project Configuration

The `.sops.yaml` file configures SOPS for this project:

```yaml
creation_rules:
  - path_regex: 'secrets/.*'
    age: age1chya88tugul5h37x7ptag9jn3gx6k5urnpf0pxp7uwf9jpc7eehqv9m250
```

This automatically uses AGE encryption for any file under the `secrets/` directory, matching the `*-secrets.env` naming convention.
