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
mc mb ${MINIO_ALIAS}/loki 2>/dev/null && echo "  ✓ Created bucket: loki" || echo "  • Bucket already exists: loki"
mc mb ${MINIO_ALIAS}/mimir 2>/dev/null && echo "  ✓ Created bucket: mimir" || echo "  • Bucket already exists: mimir"
mc mb ${MINIO_ALIAS}/tempo 2>/dev/null && echo "  ✓ Created bucket: tempo" || echo "  • Bucket already exists: tempo"
mc mb ${MINIO_ALIAS}/registry 2>/dev/null && echo "  ✓ Created bucket: registry" || echo "  • Bucket already exists: registry"
mc mb ${MINIO_ALIAS}/backups 2>/dev/null && echo "  ✓ Created bucket: backups" || echo "  • Bucket already exists: backups"
mc mb ${MINIO_ALIAS}/data 2>/dev/null && echo "  ✓ Created bucket: data" || echo "  • Bucket already exists: data"

# Create users
echo "Creating service users..."
mc admin user add ${MINIO_ALIAS} lokiuser ${LOKI_USER_PASSWORD} 2>/dev/null && echo "  ✓ Created user: lokiuser" || echo "  • User already exists: lokiuser"
mc admin user add ${MINIO_ALIAS} mimiruser ${MIMIR_USER_PASSWORD} 2>/dev/null && echo "  ✓ Created user: mimiruser" || echo "  • User already exists: mimiruser"
mc admin user add ${MINIO_ALIAS} tempouser ${TEMPO_USER_PASSWORD} 2>/dev/null && echo "  ✓ Created user: tempouser" || echo "  • User already exists: tempouser"

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
mc admin policy create ${MINIO_ALIAS} loki-policy /tmp/loki-policy.json 2>/dev/null && echo "  ✓ Created policy: loki-policy" || echo "  • Policy already exists: loki-policy"
mc admin policy create ${MINIO_ALIAS} mimir-policy /tmp/mimir-policy.json 2>/dev/null && echo "  ✓ Created policy: mimir-policy" || echo "  • Policy already exists: mimir-policy"
mc admin policy create ${MINIO_ALIAS} tempo-policy /tmp/tempo-policy.json 2>/dev/null && echo "  ✓ Created policy: tempo-policy" || echo "  • Policy already exists: tempo-policy"

# Attach policies to users
echo "Attaching policies to users..."
mc admin policy attach ${MINIO_ALIAS} loki-policy --user lokiuser 2>/dev/null && echo "  ✓ Attached loki-policy to lokiuser" || echo "  • Policy loki-policy already attached to lokiuser"
mc admin policy attach ${MINIO_ALIAS} mimir-policy --user mimiruser 2>/dev/null && echo "  ✓ Attached mimir-policy to mimiruser" || echo "  • Policy mimir-policy already attached to mimiruser"
mc admin policy attach ${MINIO_ALIAS} tempo-policy --user tempouser 2>/dev/null && echo "  ✓ Attached tempo-policy to tempouser" || echo "  • Policy tempo-policy already attached to tempouser"

# Set bucket policies (optional - makes data bucket publicly readable)
echo "Setting bucket policies..."
mc anonymous set download ${MINIO_ALIAS}/data 2>/dev/null && echo "  ✓ Set anonymous download policy on data bucket" || echo "  • Anonymous download policy already set on data bucket"

# Cleanup
rm -f /tmp/loki-policy.json /tmp/mimir-policy.json /tmp/tempo-policy.json

# Display status
echo -e "\nMinIO Setup Complete!"
echo "========================"
echo "Buckets created:"
mc ls ${MINIO_ALIAS}/

echo -e "\nUsers configured:"
mc admin user list ${MINIO_ALIAS}

echo -e "\nPolicies created:"
mc admin policy list ${MINIO_ALIAS}

# echo -e "\nVerifying Loki access..."
# mc --debug ls ${MINIO_ALIAS}/loki --user lokiuser --password ${LOKI_USER_PASSWORD} || echo "Failed to access loki bucket with lokiuser"
# echo -e "\nVerifying Mimir access..."
# mc --debug ls ${MINIO_ALIAS}/mimir --user mimiruser --password ${MIMIR_USER_PASSWORD} || echo "Failed to access mimir bucket with mimiruser"
# echo -e "\nVerifying Tempo access..."
# mc --debug ls ${MINIO_ALIAS}/tempo --user tempouser --password ${TEMPO_USER_PASSWORD} || echo "Failed to access tempo bucket with tempouser"

# Keep container running
echo -e "\nMinIO setup complete. Container will keep running..."
tail -f /dev/null