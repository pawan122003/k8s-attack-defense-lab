#!/bin/bash
# Kubernetes Audit Log Analysis Tool
# Parse and analyze audit logs for attack indicators
# Usage: ./analyze-audit.sh [audit-log-file]

set -e

AUDIT_LOG="${1:--}"  # Read from stdin or file
OUTPUT_JSON="${2:-audit-analysis.json}"

echo "[*] Kubernetes Audit Log Analysis Tool"
echo "[*] Input: $AUDIT_LOG"
echo "[*] Output: $OUTPUT_JSON"

# Initialize JSON output
cat > "$OUTPUT_JSON" <<'EOF'
{
  "analysis": {
    "timestamp": "TIMESTAMP_PLACEHOLDER",
    "findings": {
      "secret_access": [],
      "rbac_changes": [],
      "suspicious_pods": [],
      "privilege_escalation": [],
      "lateral_movement": [],
      "persistence": [],
      "log_tampering": [],
      "suspicious_users": []
    },
    "statistics": {
      "total_events": 0,
      "critical_events": 0,
      "suspicious_events": 0,
      "timeline_gaps": []
    }
  }
}
EOF

echo ""
echo "[*] Parsing audit logs..."

# Count different event types
TOTAL=$(grep -c "level" "$AUDIT_LOG" 2>/dev/null || echo "0")
echo "[+] Total events: $TOTAL"

# Find secret access
SECRET_ACCESS=$(grep -c '"verb":"get".*"resource":"secrets"' "$AUDIT_LOG" 2>/dev/null || echo "0")
if [ "$SECRET_ACCESS" -gt 10 ]; then
  echo "[!] HIGH: $SECRET_ACCESS secret access requests (possible exfiltration)"
fi

# Find RBAC changes
RBAC_CHANGES=$(grep -c '"verb":"create".*"kind":"ClusterRole' "$AUDIT_LOG" 2>/dev/null || echo "0")
if [ "$RBAC_CHANGES" -gt 0 ]; then
  echo "[!] CRITICAL: $RBAC_CHANGES RBAC changes detected"
fi

# Find DaemonSet creation
DAEMONSET=$(grep -c '"resource":"daemonsets"' "$AUDIT_LOG" 2>/dev/null || echo "0")
if [ "$DAEMONSET" -gt 0 ]; then
  echo "[!] HIGH: $DAEMONSET DaemonSet operations (potential privilege escalation)"
fi

# Find CronJob creation
CRONJOB=$(grep -c '"resource":"cronjobs"' "$AUDIT_LOG" 2>/dev/null || echo "0")
if [ "$CRONJOB" -gt 0 ]; then
  echo "[!] MEDIUM: $CRONJOB CronJob creations (potential persistence)"
fi

# Find event deletions (log tampering)
EVENT_DELETE=$(grep -c '"resource":"events".*"verb":"delete' "$AUDIT_LOG" 2>/dev/null || echo "0")
if [ "$EVENT_DELETE" -gt 0 ]; then
  echo "[!] CRITICAL: $EVENT_DELETE event deletions (LOG TAMPERING INDICATOR)"
fi

# Find pod executions
POD_EXEC=$(grep -c '"resource":"pods/exec"' "$AUDIT_LOG" 2>/dev/null || echo "0")
if [ "$POD_EXEC" -gt 0 ]; then
  echo "[!] HIGH: $POD_EXEC pod/exec operations (possible container access)"
fi

echo ""
echo "[*] Extracting specific incidents..."

# Secret exfiltration pattern
echo ""
echo "[*] Possible secret exfiltration timeline:"
grep '"verb":"get".*"resource":"secrets"' "$AUDIT_LOG" 2>/dev/null | \
  jq -r '.user.username, .requestTimestamp, .objectRef.name' 2>/dev/null | \
  head -20 | paste - - - || echo "(No secret access detected)"

# Privilege escalation attempts
echo ""
echo "[*] Privilege escalation attempts:"
grep '"verb":"create".*"kind":"ClusterRole' "$AUDIT_LOG" 2>/dev/null | \
  jq -r '.user.username, .requestTimestamp, .requestObject.metadata.name' 2>/dev/null | \
  head -20 | paste - - - || echo "(No RBAC escalation detected)"

# Lateral movement patterns
echo ""
echo "[*] Lateral movement indicators:"
grep '"resource":"pods".*"verb":"get"' "$AUDIT_LOG" 2>/dev/null | \
  jq -r '.sourceIPAddress, .user.username, .requestTimestamp' 2>/dev/null | \
  head -15 | paste - - - || echo "(No suspicious pod access detected)"

# Timeline analysis
echo ""
echo "[*] Timeline gaps (missing events):"
TIMESTAMPS=$(grep '"requestTimestamp"' "$AUDIT_LOG" 2>/dev/null | \
  jq -r '.requestTimestamp' | sort | uniq)

PREV_TIME=""
GAP_THRESHOLD=3600  # 1 hour gap

for TSTAMP in $TIMESTAMPS; do
  if [ -n "$PREV_TIME" ]; then
    DIFF=$(date -d "$TSTAMP" +%s 2>/dev/null || echo 0)
    PREV=$(date -d "$PREV_TIME" +%s 2>/dev/null || echo 0)
    GAP=$((DIFF - PREV))
    
    if [ "$GAP" -gt "$GAP_THRESHOLD" ]; then
      echo "[!] Gap detected: $GAP seconds between $PREV_TIME and $TSTAMP"
    fi
  fi
  PREV_TIME="$TSTAMP"
done

echo ""
echo "[+] Analysis complete. Results saved to: $OUTPUT_JSON"

# Generate summary statistics
echo ""
echo "=== SUMMARY ==="
echo "Total Events: $TOTAL"
echo "Secret Access: $SECRET_ACCESS"
echo "RBAC Changes: $RBAC_CHANGES"
echo "DaemonSet Ops: $DAEMONSET"
echo "CronJob Ops: $CRONJOB"
echo "Pod Exec: $POD_EXEC"
echo "Event Deletions (Log Tampering): $EVENT_DELETE"

# Risk assessment
RISK_SCORE=0
[ "$RBAC_CHANGES" -gt 0 ] && RISK_SCORE=$((RISK_SCORE + 50))
[ "$EVENT_DELETE" -gt 0 ] && RISK_SCORE=$((RISK_SCORE + 50))
[ "$SECRET_ACCESS" -gt 50 ] && RISK_SCORE=$((RISK_SCORE + 30))
[ "$POD_EXEC" -gt 5 ] && RISK_SCORE=$((RISK_SCORE + 20))

echo ""
echo "Risk Score: $RISK_SCORE/100"
if [ "$RISK_SCORE" -gt 70 ]; then
  echo "[!] CRITICAL RISK - Probable compromise detected"
elif [ "$RISK_SCORE" -gt 40 ]; then
  echo "[!] HIGH RISK - Suspicious activity detected"
elif [ "$RISK_SCORE" -gt 10 ]; then
  echo "[!] MEDIUM RISK - Anomalies detected"
else
  echo "[+] LOW RISK - Normal cluster activity"
fi
