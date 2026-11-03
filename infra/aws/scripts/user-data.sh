# First boot only (cloud-init, as root). The stack prepends `/opt/velio/stack.env`.
# Installs Docker and the Compose plugin. The app itself arrives with each deploy (deploy.sh).
set -euxo pipefail

# Amazon Linux 2023 locks its package repository to the AMI's release, so the pinned AMI pins
# the docker and jq versions.
for attempt in $(seq 1 10); do
  # Retried: the Elastic IP replaces the launch address shortly after boot, dropping connections.
  dnf install -y docker jq && break
  [ "$attempt" -lt 10 ] && sleep 15
done

COMPOSE_VERSION=v5.7.0
COMPOSE_SHA256=15861535d14e26555736b49376c95e14bfd94285366c8446bfac7156a972e76f
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL --retry 10 --retry-all-errors -o /usr/local/lib/docker/cli-plugins/docker-compose \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-aarch64"
echo "${COMPOSE_SHA256}  /usr/local/lib/docker/cli-plugins/docker-compose" | sha256sum -c -
chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose

systemctl enable --now docker

mkdir -p /opt/velio/data /opt/velio/releases
chmod 700 /opt/velio
