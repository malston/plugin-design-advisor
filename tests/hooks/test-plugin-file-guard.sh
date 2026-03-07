#!/usr/bin/env bash
set -euo pipefail

# Test harness for hooks/plugin-file-guard.sh
# Exercises 4 scenarios with temporary directory structures.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../../hooks/plugin-file-guard.sh"
PASS=0
FAIL=0
TMPDIR_BASE=""

cleanup() {
  if [[ -n "$TMPDIR_BASE" && -d "$TMPDIR_BASE" ]]; then
    rm -rf "$TMPDIR_BASE"
  fi
}
trap cleanup EXIT

setup() {
  TMPDIR_BASE="$(mktemp -d)"

  # Create a plugin directory with .claude-plugin/plugin.json
  PLUGIN_DIR="$TMPDIR_BASE/my-plugin"
  mkdir -p "$PLUGIN_DIR/.claude-plugin"
  echo '{"name":"test-plugin"}' > "$PLUGIN_DIR/.claude-plugin/plugin.json"
  mkdir -p "$PLUGIN_DIR/agents"
  mkdir -p "$PLUGIN_DIR/skills/my-skill"

  # Create a non-plugin directory (no .claude-plugin/plugin.json)
  NON_PLUGIN_DIR="$TMPDIR_BASE/plain-project"
  mkdir -p "$NON_PLUGIN_DIR/agents"
}

make_input() {
  local file_path="$1"
  local session_id="${2:-test-session-$$}"
  cat <<EOF
{
  "session_id": "$session_id",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "$file_path",
    "content": "test content"
  }
}
EOF
}

assert_fires() {
  local label="$1"
  local output="$2"
  if echo "$output" | grep -q "systemMessage"; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label -- expected systemMessage in output, got: $output"
  fi
}

assert_silent() {
  local label="$1"
  local output="$2"
  if [[ -z "$output" ]] || ! echo "$output" | grep -q "systemMessage"; then
    PASS=$((PASS + 1))
    echo "PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label -- expected no output, got: $output"
  fi
}

run_tests() {
  setup

  # Use unique session IDs per test to avoid dedup interference
  local sid_prefix="test-$$"

  # Scenario 1: Write to agents/ in a plugin dir -> should fire
  local out
  out=$(make_input "$PLUGIN_DIR/agents/new-agent.md" "${sid_prefix}-1" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
  assert_fires "Scenario 1: Write to agents/ in plugin dir fires" "$out"

  # Scenario 2: Write to skills/ in a plugin dir -> should fire
  out=$(make_input "$PLUGIN_DIR/skills/my-skill/SKILL.md" "${sid_prefix}-2" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
  assert_fires "Scenario 2: Write to skills/ in plugin dir fires" "$out"

  # Scenario 3: Write to README.md in a plugin dir -> should NOT fire
  out=$(make_input "$PLUGIN_DIR/README.md" "${sid_prefix}-3" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
  assert_silent "Scenario 3: Write to README.md in plugin dir is silent" "$out"

  # Scenario 4: Write to agents/ in a non-plugin dir -> should NOT fire
  out=$(make_input "$NON_PLUGIN_DIR/agents/something.md" "${sid_prefix}-4" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
  assert_silent "Scenario 4: Write to agents/ in non-plugin dir is silent" "$out"

  # Scenario 5 (suppression): Second write to same file in same session -> should NOT fire
  out=$(make_input "$PLUGIN_DIR/agents/new-agent.md" "${sid_prefix}-5" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
  assert_fires "Scenario 5a: First write fires" "$out"
  out=$(make_input "$PLUGIN_DIR/agents/new-agent.md" "${sid_prefix}-5" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
  assert_silent "Scenario 5b: Second write to same file is suppressed" "$out"

  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  if [[ $FAIL -gt 0 ]]; then
    exit 1
  fi
}

run_tests
