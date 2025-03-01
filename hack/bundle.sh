#!/usr/bin/env bash

if [[ ! "$#" -gt 2 ]]; then
    echo "Missing id or package or dir name" >&2
    exit 2
fi

for env_var in ADDON_VERSION ADDON_OVERLAY; do
  if [ -z "${!env_var}" ]; then
    echo "Make sure to set the ${env_var} environment variable." >&2
    exit 2
  fi
done

export BUNDLE_BASE=$(dirname "${BASH_SOURCE[0]}")/..
export BUNDLE_ID="${1}"
export BUNDLE_NAME="${2}"
export BUNDLE_DIR="${3}"
export BUNDLE_CHANNEL="${4}"
export DIR_OVERLAY="${BUNDLE_BASE}/kustomize/overlays/${ADDON_OVERLAY}/data-plane/${BUNDLE_ID}"
export DIR_ADDON="${BUNDLE_BASE}/addons/connectors-operator/${BUNDLE_DIR}"

if [ ! -d "${DIR_OVERLAY}" ]; then
    echo "Missing overlay ${DIR_OVERLAY}" >&2
    exit 2
fi

echo "##############################################"
echo "# id      : ${BUNDLE_ID}"
echo "# version : ${ADDON_VERSION}"
echo "# dir     : ${BUNDLE_DIR}"
echo "# package : ${BUNDLE_NAME}"
echo "# base    : ${BUNDLE_BASE}"
echo "# channel : ${BUNDLE_CHANNEL}"
echo "##############################################"

kustomize build "${DIR_OVERLAY}" | operator-sdk generate bundle \
    --package "${BUNDLE_NAME}" \
    --channels ${BUNDLE_CHANNEL} \
    --default-channel ${BUNDLE_CHANNEL} \
    --output-dir "${DIR_ADDON}" \
    --version "${ADDON_VERSION}" \
    --kustomize-dir "${DIR_OVERLAY}"

rm bundle.Dockerfile

yq -i 'del(.annotations."operators.operatorframework.io.metrics.builder")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.metrics.mediatype.v1")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.metrics.project_layout")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.test.mediatype.v1")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.test.config.v1")' \
  "${DIR_ADDON}/metadata/annotations.yaml"

yq -i 'del(.metadata.annotations."operators.operatorframework.io/builder")' \
  "${DIR_ADDON}/manifests/${BUNDLE_NAME}.clusterserviceversion.yaml"
yq -i 'del(.metadata.annotations."operators.operatorframework.io/project_layout")' \
  "${DIR_ADDON}/manifests/${BUNDLE_NAME}.clusterserviceversion.yaml"
yq -i 'del(.spec.icon[0])' \
  "${DIR_ADDON}/manifests/${BUNDLE_NAME}.clusterserviceversion.yaml"
