# CFSSL Configuration

For TLS certificate generation, customize the CFSSL configuration files in the `cfssl/` directory:

## Root CA Configuration (`cfssl/ca.json`)

Root CA configuration used to generate the root certificate and signing policy; update organization and expiry settings as needed.

## Intermediate CA Configuration (`cfssl/intermediate-ca.json`)

Intermediate CA configuration for signing subordinate certificates and creating an intermediate certificate authority.

## Registry Certificate Configuration (`cfssl/registry.json`)

Registry certificate configuration to create server certificates for the registry hostnames and any SANs required.

## Certificate Profiles (`cfssl/cfssl.json`)

Certificate profiles and expiry settings used by CFSSL to generate certificates according to desired lifetimes and constraints.

Update organization details, hostnames, and certificate expiry times as needed for your environment.

## Certificate Generation with CFSSL

After customizing the configuration files, you can generate the certificates. This setup uses a proper PKI hierarchy with root and intermediate CAs:

```bash
# Generate all certificates at once
make certs

# Or generate them step by step:
make cert-ca              # Generate root CA
make cert-intermediate    # Generate intermediate CA
make cert-registry        # Generate registry certificates

# Verify the certificate chain
make verify-certs
```

The Makefile automates the following steps:

1. Generates root CA certificate
1. Generates intermediate CA certificate
1. Signs intermediate CA with root CA
1. Generates registry certificates (peer, server, client profiles)
1. Creates certificate chain for the registry