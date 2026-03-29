#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_HTTP_VERSION_MODE="auto"
readonly DEFAULT_TLS_MIN_VERSION="TLSv1.3"

normalize_http_version_mode() {
    local raw="$1"
    local mode

    mode="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
    mode="${mode#"${mode%%[![:space:]]*}"}"
    mode="${mode%"${mode##*[![:space:]]}"}"

    case "$mode" in
        auto|all|h1|h2|h3|h1+h2)
            printf '%s' "$mode"
            ;;
        http/1.1|http1|http1.1)
            printf 'h1'
            ;;
        http/2|http2)
            printf 'h2'
            ;;
        http/3|http3)
            printf 'h3'
            ;;
        *)
            printf '%s' "$DEFAULT_HTTP_VERSION_MODE"
            ;;
    esac
}

validate_tls_min_version() {
    local value="$1"

    case "$value" in
        TLSv1.2|TLSv1.3)
            printf '%s' "$value"
            ;;
        *)
            printf '%s' "$DEFAULT_TLS_MIN_VERSION"
            ;;
    esac
}

assert_eq() {
    local name="$1"
    local got="$2"
    local want="$3"

    if [[ "$got" == "$want" ]]; then
        echo "PASS: ${name}"
    else
        echo "FAIL: ${name} expected='${want}' got='${got}'" >&2
        exit 1
    fi
}

assert_file_contains() {
    local name="$1"
    local file="$2"
    local needle="$3"

    if grep -qF "$needle" "$file"; then
        echo "PASS: ${name}"
    else
        echo "FAIL: ${name} missing '${needle}' in ${file}" >&2
        exit 1
    fi
}

assert_eq "mode auto" "$(normalize_http_version_mode auto)" "auto"
assert_eq "mode h1" "$(normalize_http_version_mode h1)" "h1"
assert_eq "mode h2 alias" "$(normalize_http_version_mode HTTP/2)" "h2"
assert_eq "mode h3 alias" "$(normalize_http_version_mode http3)" "h3"
assert_eq "mode invalid fallback" "$(normalize_http_version_mode bogus)" "auto"

assert_eq "tls valid 1.2" "$(validate_tls_min_version TLSv1.2)" "TLSv1.2"
assert_eq "tls valid 1.3" "$(validate_tls_min_version TLSv1.3)" "TLSv1.3"
assert_eq "tls invalid fallback" "$(validate_tls_min_version SSLv3)" "TLSv1.3"

tpl="resources/haproxy.cfg.template"
assert_file_contains "template server port placeholder" "$tpl" "__SERVER_PORT__"
assert_file_contains "template bind params placeholder" "$tpl" "__BIND_PARAMS__"
assert_file_contains "template quic placeholder" "$tpl" "__QUIC_BIND_LINE__"
assert_file_contains "template cors check placeholder" "$tpl" "__CORS_CHECK__"
assert_file_contains "template api key check placeholder" "$tpl" "__API_KEY_CHECK__"

echo "runtime_behavior_checks_ok"
