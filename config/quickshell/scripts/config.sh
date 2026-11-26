#!/usr/bin/env bash

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/caching.sh"

CONFIG_SETTINGS_JSON="${QS_SETTINGS:-$HOME/.config/quickshell/settings.json}"
LOCATION_STATE_JSON="${QS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell}/location.json"

has_valid_location() {
    jq -e 'type == "object" and .latitude != null and .longitude != null' >/dev/null 2>&1
}

get_saved_location() {
    if [[ -s "$LOCATION_STATE_JSON" ]] && has_valid_location < "$LOCATION_STATE_JSON"; then
        jq -c '.' "$LOCATION_STATE_JSON" 2>/dev/null
        return
    fi
    local legacy
    legacy="$(get_setting "general" '{}' | jq -c '.location // empty' 2>/dev/null)"
    if [[ -n "$legacy" ]] && echo "$legacy" | has_valid_location; then
        printf '%s\n' "$legacy"
    fi
}

save_location_state() {
    local loc_data="$1"
    local dir tmp
    dir="$(dirname "$LOCATION_STATE_JSON")"
    [[ -d "$dir" ]] || mkdir -p "$dir"
    tmp="${LOCATION_STATE_JSON}.tmp.$$"
    if echo "$loc_data" | jq -c '.' > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
        mv "$tmp" "$LOCATION_STATE_JSON"
    else
        rm -f "$tmp"
        return 1
    fi
}

_config_ensure_settings() {
    local dir
    dir="$(dirname "$CONFIG_SETTINGS_JSON")"
    [[ -d "$dir" ]] || mkdir -p "$dir"
    [[ -s "$CONFIG_SETTINGS_JSON" ]] || echo '{}' > "$CONFIG_SETTINGS_JSON"
}

get_setting() {
    local key="$1"
    local fallback="${2:-}"
    _config_ensure_settings
    local val
    val="$(jq -r --arg k "$key" 'if has($k) then .[$k] else "__MISSING__" end' "$CONFIG_SETTINGS_JSON" 2>/dev/null)"
    if [[ "$val" == "__MISSING__" || "$val" == "null" ]]; then
        printf '%s' "$fallback"
    else
        printf '%s' "$val"
    fi
}

set_setting() {
    local key="$1"
    local value="$2"
    _config_ensure_settings

    local json_value
    if echo "$value" | jq -e . > /dev/null 2>&1; then
        json_value="$value"
    else
        json_value="$(jq -Rn --arg v "$value" '$v')"
    fi

    local tmp="${CONFIG_SETTINGS_JSON}.tmp"
    if jq --arg k "$key" --argjson v "$json_value" '. + {($k): $v}' "$CONFIG_SETTINGS_JSON" > "$tmp" 2>/dev/null; then
        if jq -e . "$tmp" > /dev/null 2>&1; then
            mv "$tmp" "$CONFIG_SETTINGS_JSON"
        fi
    fi
}

update_settings_bulk() {
    local json_obj="$1"
    _config_ensure_settings
    local tmp="${CONFIG_SETTINGS_JSON}.tmp"
    if jq --argjson patch "$json_obj" '. + $patch' "$CONFIG_SETTINGS_JSON" > "$tmp" 2>/dev/null; then
        if jq -e . "$tmp" > /dev/null 2>&1; then
            mv "$tmp" "$CONFIG_SETTINGS_JSON"
        fi
    fi
}
