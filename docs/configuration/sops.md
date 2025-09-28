# SOPS Encryption Guide

## Overview

This project uses SOPS with AGE encryption to manage secrets. The `.secrets.env` files are encrypted and stored as `.secrets.env.enc`.

## Initial Setup

1. **Install SOPS and AGE**:

   ```bash
   brew install sops age
   ```

1. **Generate AGE key** (if you don't have one):

   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

1. **Get your public key**:

   ```bash
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

## Encrypting Files

For `.env` files, explicitly specify the format:

```bash
# Encrypt a .secrets.env file
sops --encrypt --input-type dotenv --output-type dotenv auth/.secrets.env > auth/.secrets.env.enc

# Or use the SOPS config (detects format from .sops.yaml)
sops -e auth/.secrets.env > auth/.secrets.env.enc
```

## Decrypting Files

The error "invalid character 'P' looking for beginning of value" occurs when SOPS tries to parse the encrypted file as JSON. For `.env` files, specify the format:

```bash
# Decrypt with explicit format (recommended)
sops --decrypt --input-type dotenv --output-type dotenv auth/.secrets.env.enc > auth/.secrets.env

# Or use the short form
sops -d --input-type dotenv auth/.secrets.env.enc > auth/.secrets.env
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
   Add to `.gitignore`:

   ```
   *.secrets.env
   !*.secrets.env.enc
   ```

1. **Use consistent naming**:

   - Secrets: `.secrets.env`
   - Encrypted: `.secrets.env.enc`

1. **Document required secrets**:
   Create a `.secrets.env.example` with dummy values:

   ```env
   POSTGRES_PASSWORD=changeme
   AUTHENTIK_SECRET_KEY=generate-a-secure-key
   ```

## Project Configuration

The `.sops.yaml` file configures SOPS for this project:

```yaml
creation_rules:
  - path_regex: '.*\.secrets\.env$'
    age: age1chya88tugul5h37x7ptag9jn3gx6k5urnpf0pxp7uwf9jpc7eehqv9m250
```

This automatically uses AGE encryption for any `.secrets.env` file.