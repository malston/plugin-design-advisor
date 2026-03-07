#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook for Write/Edit calls targeting agents/ or skills/
# in a Claude Code plugin directory.
#
# Fires at most once per file path per session.
# Injects a brief mechanism-selection reminder into context.

input=$(cat)

command -v jq &>/dev/null || exit 0

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

if [[ -z "$file_path" ]]; then
  exit 0
fi

# Walk up from the file's directory, max 4 levels, looking for .claude-plugin/plugin.json
dir="$(dirname "$file_path")"
plugin_root=""
for _ in 1 2 3 4; do
  if [[ -f "$dir/.claude-plugin/plugin.json" ]]; then
    plugin_root="$dir"
    break
  fi
  parent="$(dirname "$dir")"
  if [[ "$parent" = "$dir" ]]; then
    break
  fi
  dir="$parent"
done

if [[ -z "$plugin_root" ]]; then
  exit 0
fi

# Check if file is under agents/ or skills/ relative to the plugin root
rel_path="${file_path#"$plugin_root"/}"
case "$rel_path" in
  agents/*|skills/*)
    ;;
  *)
    exit 0
    ;;
esac

# Session dedup: fire at most once per file path per session
if [[ -n "$session_id" ]]; then
  dedup_dir="${TMPDIR:-/tmp}/plugin-file-guard"
  if mkdir -p "$dedup_dir" 2>/dev/null; then
    # Prune dedup files older than 24 hours
    find "$dedup_dir" -type f -mtime +1 -delete 2>/dev/null || true

    # Hash the session_id + file_path to create a dedup key
    if command -v shasum &>/dev/null; then
      dedup_key=$(printf '%s:%s' "$session_id" "$file_path" | shasum -a 256 | cut -d' ' -f1)
    elif command -v sha256sum &>/dev/null; then
      dedup_key=$(printf '%s:%s' "$session_id" "$file_path" | sha256sum | cut -d' ' -f1)
    else
      # Fallback: base64-encode the key (no hashing available)
      dedup_key=$(printf '%s:%s' "$session_id" "$file_path" | base64 | tr -d '=/+\n')
    fi

    dedup_file="$dedup_dir/$dedup_key"
    if [[ -f "$dedup_file" ]]; then
      exit 0
    fi
    touch "$dedup_file"
  fi
fi

cat <<'GUIDANCE'
{
  "systemMessage": "Plugin file guard: Is this encoding knowledge (\u2192 skill) or driving isolated behavior (\u2192 agent)?\n\nKey signals: Does it need its own context window? Agent. Is it reusable reference material? Skill. Does it run tools with structured I/O? Agent. Is it auto-invoked from conversation context? Skill.\n\nRun /plugin-design-advisor:validate . to audit the full plugin structure."
}
GUIDANCE
