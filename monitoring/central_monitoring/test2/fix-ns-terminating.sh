#!/usr/bin/env bash
set -euo pipefail

NS="${1:-monitoring}"

log() { printf "\n[%s] %s\n" "$(date +'%F %T')" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

if ! have kubectl; then
  echo "ERROR: kubectl not found"
  exit 1
fi

log "Target namespace: ${NS}"

# 0) Existence / status
if ! kubectl get ns "${NS}" >/dev/null 2>&1; then
  log "Namespace '${NS}' does not exist. Nothing to do."
  exit 0
fi

STATUS="$(kubectl get ns "${NS}" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
log "Current phase: ${STATUS}"

if [[ "${STATUS}" != "Terminating" ]]; then
  log "Namespace is not Terminating. No forced action needed."
  exit 0
fi

# 1) Show namespace conditions
log "Namespace conditions (if any):"
kubectl get ns "${NS}" -o jsonpath='{range .status.conditions[*]}- {.type}: {.status} ({.reason}){"\n"}{end}' 2>/dev/null || true

# 2) List remaining namespaced resources (best-effort)
log "Scanning remaining resources in namespace '${NS}' (best-effort)..."
TMP_LIST="$(mktemp)"
kubectl api-resources --verbs=list --namespaced -o name > "${TMP_LIST}"

REMAIN_COUNT=0
while IFS= read -r kind; do
  out="$(kubectl get "${kind}" -n "${NS}" --ignore-not-found 2>/dev/null || true)"
  if [[ -n "${out}" ]]; then
    lines="$(printf "%s\n" "${out}" | wc -l | tr -d ' ')"
    if [[ "${lines}" -gt 1 ]]; then
      REMAIN_COUNT=$((REMAIN_COUNT + lines - 1))
      log "Remaining: ${kind}"
      printf "%s\n" "${out}"
    fi
  fi
done < "${TMP_LIST}"
rm -f "${TMP_LIST}"

log "Approx remaining object count (best-effort): ${REMAIN_COUNT}"

# 3) Try delete common monitoring CRD objects first (safe, idempotent)
log "Attempting cleanup of common monitoring CRD objects (ignore failures)..."
set +e
kubectl delete prometheus --all -n "${NS}" --force --grace-period=0 >/dev/null 2>&1
kubectl delete alertmanager --all -n "${NS}" --force --grace-period=0 >/dev/null 2>&1
kubectl delete servicemonitor --all -n "${NS}" --force --grace-period=0 >/dev/null 2>&1
kubectl delete podmonitor --all -n "${NS}" --force --grace-period=0 >/dev/null 2>&1
kubectl delete prometheusrule --all -n "${NS}" --force --grace-period=0 >/dev/null 2>&1
kubectl delete thanosruler --all -n "${NS}" --force --grace-period=0 >/dev/null 2>&1
set -e

# 4) Re-issue namespace delete (idempotent)
log "Re-issuing namespace delete (idempotent)..."
kubectl delete ns "${NS}" --wait=false >/dev/null 2>&1 || true

# 5) Force finalize: remove finalizers via /finalize
log "Forcing finalizer removal for namespace '${NS}'..."

if have jq; then
  kubectl get ns "${NS}" -o json \
  | jq 'del(.spec.finalizers)' \
  | kubectl replace --raw "/api/v1/namespaces/${NS}/finalize" -f - >/dev/null
else
  if ! have python3; then
    echo "ERROR: Need jq or python3 to remove finalizers."
    exit 1
  fi
  kubectl get ns "${NS}" -o json \
  | python3 -c 'import json,sys; obj=json.load(sys.stdin); obj.get("spec",{}).pop("finalizers",None); print(json.dumps(obj))' \
  | kubectl replace --raw "/api/v1/namespaces/${NS}/finalize" -f - >/dev/null
fi

# 6) Verify
log "Verifying namespace deletion..."
if kubectl get ns "${NS}" >/dev/null 2>&1; then
  log "Namespace still exists (may take a short moment). Current:"
  kubectl get ns "${NS}" -o wide || true
  log "If it remains stuck, it can indicate controllers re-adding finalizers or control-plane issues."
  exit 2
else
  log "Namespace '${NS}' successfully removed."
fi
