#!/usr/bin/env bash

# MinIO Container Setup Script
# Run by the minio-setup (mc) container to initialize buckets, users, and policies
# Required env vars: MINIO_ROOT_USER, MINIO_ROOT_PASSWORD
# Optional env vars: LOKI_S3_ACCESS_KEY, LOKI_S3_SECRET_KEY,
#                    MIMIR_S3_ACCESS_KEY, MIMIR_S3_SECRET_KEY,
#                    TEMPO_S3_ACCESS_KEY, TEMPO_S3_SECRET_KEY

set -e

MINIO_ALIAS="myminio"
MINIO_ENDPOINT="http://minio:9000"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin123}"

# Service credentials (sourced from secrets/all.env.dec via env_file)
LOKI_S3_ACCESS_KEY="${LOKI_S3_ACCESS_KEY:-lokiuser}"
LOKI_S3_SECRET_KEY="${LOKI_S3_SECRET_KEY:-LokiP@ss5}"
MIMIR_S3_ACCESS_KEY="${MIMIR_S3_ACCESS_KEY:-mimiruser}"
MIMIR_S3_SECRET_KEY="${MIMIR_S3_SECRET_KEY:-MimirP@ss5}"
TEMPO_S3_ACCESS_KEY="${TEMPO_S3_ACCESS_KEY:-tempouser}"
TEMPO_S3_SECRET_KEY="${TEMPO_S3_SECRET_KEY:-TempoP@ss5}"

# Buckets and their associated service users
SERVICES="loki mimir tempo"

echo "Waiting for MinIO..."
until /usr/bin/mc alias set "${MINIO_ALIAS}" "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null 2>&1; do
    sleep 3
done
echo "MinIO is ready"

# --- Create buckets ---
echo "Creating buckets..."
for svc in ${SERVICES}; do
    mc mb "${MINIO_ALIAS}/${svc}" 2>/dev/null \
        && echo "  + ${svc}" \
        || echo "  . ${svc} (exists)"
done

# --- Create service users ---
echo "Creating service users..."
create_user() {
    local user="$1" pass="$2"
    mc admin user add "${MINIO_ALIAS}" "${user}" "${pass}" 2>/dev/null \
        && echo "  + ${user}" \
        || echo "  . ${user} (exists)"
}
create_user "${LOKI_S3_ACCESS_KEY}"  "${LOKI_S3_SECRET_KEY}"
create_user "${MIMIR_S3_ACCESS_KEY}" "${MIMIR_S3_SECRET_KEY}"
create_user "${TEMPO_S3_ACCESS_KEY}" "${TEMPO_S3_SECRET_KEY}"

# --- Create and attach per-bucket policies ---
echo "Configuring policies..."
attach_policy() {
    local svc="$1" user="$2"
    local policy_name="${svc}-policy"
    local policy_file="/tmp/${policy_name}.json"

    cat > "${policy_file}" <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::${svc}",
        "arn:aws:s3:::${svc}/*"
      ]
    }
  ]
}
POLICY

    mc admin policy create "${MINIO_ALIAS}" "${policy_name}" "${policy_file}" 2>/dev/null \
        && echo "  + ${policy_name}" \
        || echo "  . ${policy_name} (exists)"
    mc admin policy attach "${MINIO_ALIAS}" "${policy_name}" --user "${user}" 2>/dev/null \
        && echo "    -> attached to ${user}" \
        || echo "    -> already attached to ${user}"
    rm -f "${policy_file}"
}
attach_policy "loki"  "${LOKI_S3_ACCESS_KEY}"
attach_policy "mimir" "${MIMIR_S3_ACCESS_KEY}"
attach_policy "tempo" "${TEMPO_S3_ACCESS_KEY}"

# --- Summary ---
echo ""
echo "MinIO setup complete"
echo "  Buckets: $(mc ls "${MINIO_ALIAS}" 2>/dev/null | wc -l)"
echo "  Users:   $(mc admin user list "${MINIO_ALIAS}" 2>/dev/null | wc -l)"

exit 0
