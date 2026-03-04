#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
CPU_COUNT="$(nproc)"
JOBS="${JOBS:-$CPU_COUNT}"
WORKDIR="${WORKDIR:-$HOME/ci-k8s}"
K8S_REF="${K8S_REF:-v1.32.1}"

# ── Setup ────────────────────────────────────────────────────
SETUP_START=$(date +%s)

GO_VERSION="go1.23.5"
GO_TARBALL="${GO_VERSION}.linux-amd64.tar.gz"
curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"
sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
export PATH="/usr/local/go/bin:$PATH"
go version

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

git clone --depth 1 --branch "${K8S_REF}" https://github.com/kubernetes/kubernetes.git
cd kubernetes

SETUP_DURATION=$(($(date +%s) - SETUP_START))

# ── Test ─────────────────────────────────────────────────────
TEST_START=$(date +%s)

export KUBE_BUILD_PLATFORMS=linux/amd64
export KUBE_TEST_ARGS="-p ${JOBS} -count=1"

make -j"${JOBS}" WHAT="cmd/kubelet cmd/kubeadm cmd/kubectl"
make test WHAT="./staging/src/k8s.io/apimachinery/... ./pkg/util/..."

TEST_DURATION=$(($(date +%s) - TEST_START))

echo "SETUP_DURATION=${SETUP_DURATION}"
echo "TEST_DURATION=${TEST_DURATION}"
