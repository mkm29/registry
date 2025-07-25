#!/usr/bin/env bash

# MinIO Container Setup Script
# This script is run by the mc container to initialize MinIO buckets, users, and policies

set -e

# Configuration
MINIO_ALIAS="myminio"
MINIO_ENDPOINT="http://minio:9000"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin123}"

# Service user passwords
LOKI_USER_PASSWORD="${LOKI_USER_PASSWORD:-SuperSecret1}"
MIMIR_USER_PASSWORD="${MIMIR_USER_PASSWORD:-SuperSecret1}"
TEMPO_USER_PASSWORD="${TEMPO_USER_PASSWORD:-SuperSecret1}"

echo "Setting up MinIO configuration..."

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
until /usr/bin/mc alias set ${MINIO_ALIAS} ${MINIO_ENDPOINT} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}; do
    echo 'Waiting for MinIO to be ready...'
    sleep 3
done
echo 'MinIO is ready'

# Create buckets
echo "Creating buckets..."
mc mb ${MINIO_ALIAS}/loki || echo "Bucket loki already exists"
mc mb ${MINIO_ALIAS}/mimir || echo "Bucket mimir already exists"
mc mb ${MINIO_ALIAS}/tempo || echo "Bucket tempo already exists"
mc mb ${MINIO_ALIAS}/registry || echo "Bucket registry already exists"
mc mb ${MINIO_ALIAS}/backups || echo "Bucket backups already exists"
mc mb ${MINIO_ALIAS}/data || echo "Bucket data already exists"

# Create users
echo "Creating service users..."
mc admin user add ${MINIO_ALIAS} lokiuser ${LOKI_USER_PASSWORD} || echo "User lokiuser already exists"
mc admin user add ${MINIO_ALIAS} mimiruser ${MIMIR_USER_PASSWORD} || echo "User mimiruser already exists"
mc admin user add ${MINIO_ALIAS} tempouser ${TEMPO_USER_PASSWORD} || echo "User tempouser already exists"

# Create policy files
echo "Creating policy files..."

cat > /tmp/loki-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::loki",
        "arn:aws:s3:::loki/*"
      ]
    }
  ]
}
EOF

cat > /tmp/mimir-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::mimir",
        "arn:aws:s3:::mimir/*"
      ]
    }
  ]
}
EOF

cat > /tmp/tempo-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::tempo",
        "arn:aws:s3:::tempo/*"
      ]
    }
  ]
}
EOF

# Create policies
echo "Creating policies..."
mc admin policy create ${MINIO_ALIAS} loki-policy /tmp/loki-policy.json || echo "Policy loki-policy already exists"
mc admin policy create ${MINIO_ALIAS} mimir-policy /tmp/mimir-policy.json || echo "Policy mimir-policy already exists"
mc admin policy create ${MINIO_ALIAS} tempo-policy /tmp/tempo-policy.json || echo "Policy tempo-policy already exists"

# Attach policies to users
echo "Attaching policies to users..."
mc admin policy attach ${MINIO_ALIAS} loki-policy --user lokiuser || echo "Policy already attached"
mc admin policy attach ${MINIO_ALIAS} mimir-policy --user mimiruser || echo "Policy already attached"
mc admin policy attach ${MINIO_ALIAS} tempo-policy --user tempouser || echo "Policy already attached"

# Set bucket policies (optional - makes data bucket publicly readable)
echo "Setting bucket policies..."
mc anonymous set download ${MINIO_ALIAS}/data || echo "Anonymous policy already set"

# Cleanup
rm -f /tmp/loki-policy.json /tmp/mimir-policy.json /tmp/tempo-policy.json

# Display status
echo -e "\nMinIO Setup Complete!"
echo "========================"
echo "Buckets created:"
mc ls ${MINIO_ALIAS}/ | grep -E "(loki|mimir|tempo|registry|backups|data)"

echo -e "\nUsers configured:"
mc admin user list ${MINIO_ALIAS} | grep -E "(lokiuser|mimiruser|tempouser)"

echo -e "\nPolicies created:"
mc admin policy list ${MINIO_ALIAS} | grep -E "(loki-policy|mimir-policy|tempo-policy)"

echo -e "\nVerifying Loki access..."
mc --debug ls ${MINIO_ALIAS}/loki --user lokiuser --password ${LOKI_USER_PASSWORD} 2>&1 | grep -E "(200 OK|ListBucketResult)" && echo "✓ Loki user can access bucket" || echo "✗ Loki user cannot access bucket"

# Keep container running
echo -e "\nMinIO setup complete. Container will keep running..."
tail -f /dev/null