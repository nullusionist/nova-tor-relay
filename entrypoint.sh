#!/bin/bash
set -e

DATA_DIR=/var/lib/tor
NICKNAME_FILE="$DATA_DIR/relay_nickname"

valid_ipv4() { [[ ${1:-} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
have_global_v6_iface() { ip -6 addr show scope global up 2>/dev/null | grep -q 'inet6'; }

retry_get() {
  local tries=$1; shift
  local i v
  for ((i=1;i<=tries;i++)); do
    v=$("$@") && { echo -n "$v"; return 0; }
    sleep 1
  done
  return 1
}

get_v4() { curl -4 -fsS --max-time 3 https://api64.ipify.org || true; }
get_v6() { curl -6 -fsS --max-time 3 https://api64.ipify.org || true; }

PUBLIC_V4="$(retry_get 5 get_v4)"
PUBLIC_V6=""
if have_global_v6_iface; then
  PUBLIC_V6="$(retry_get 8 get_v6)"
fi

if [ -z "$PUBLIC_V4" ] && [ -z "$PUBLIC_V6" ]; then
  echo "❌ Failed to determine public IP address!"
  exit 1
fi

if [ -n "$PUBLIC_V4" ]; then echo "🌍 Detected public IPv4: $PUBLIC_V4"; fi
if [ -n "$PUBLIC_V6" ]; then echo "🌏 Detected public IPv6: $PUBLIC_V6"; fi

PUBLIC_IP="${PUBLIC_V4:-$PUBLIC_V6}"   # for Address

# ---- Nickname handling (unchanged) ----
if [ -n "${NICKNAME:-}" ]; then
  if [ -f "$NICKNAME_FILE" ]; then
    EXISTING_NICKNAME=$(cat "$NICKNAME_FILE")
    EXISTING_PREFIX="${EXISTING_NICKNAME:0:${#NICKNAME}}"
  else
    EXISTING_NICKNAME=""
    EXISTING_PREFIX=""
  fi

  if [ "$EXISTING_PREFIX" != "$NICKNAME" ]; then
    PREFIX="$NICKNAME"
    MAX_TOTAL_LENGTH=19
    MAX_SUFFIX_LENGTH=$((MAX_TOTAL_LENGTH - ${#PREFIX}))
    RANDOM_ID=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$MAX_SUFFIX_LENGTH")
    RELAY_NICKNAME="${PREFIX}${RANDOM_ID}"
    echo "$RELAY_NICKNAME" > "$NICKNAME_FILE"
    echo "📛 Generated new nickname from changed NICKNAME prefix: $RELAY_NICKNAME"
  else
    RELAY_NICKNAME="$EXISTING_NICKNAME"
    echo "🔁 NICKNAME prefix unchanged; reusing: $RELAY_NICKNAME"
  fi
elif [ -f "$NICKNAME_FILE" ]; then
  RELAY_NICKNAME=$(cat "$NICKNAME_FILE")
  echo "🔁 Reusing saved relay nickname: $RELAY_NICKNAME"
else
  PREFIX="NovaRelay"
  MAX_TOTAL_LENGTH=19
  MAX_SUFFIX_LENGTH=$((MAX_TOTAL_LENGTH - ${#PREFIX}))
  RANDOM_ID=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$MAX_SUFFIX_LENGTH")
  RELAY_NICKNAME="${PREFIX}${RANDOM_ID}"
  echo "$RELAY_NICKNAME" > "$NICKNAME_FILE"
  echo "🆕 Generated default relay nickname: $RELAY_NICKNAME"
fi

CONTACT_RAW="${CONTACT:-}"
DEFAULT_PLACEHOLDER="your@email.com"
if [ -z "$CONTACT_RAW" ] || [ "$CONTACT_RAW" = "$DEFAULT_PLACEHOLDER" ]; then
  echo "❌ CONTACT is required and cannot be '$DEFAULT_PLACEHOLDER'."
  exit 1
fi
CONTACT_EMAIL="$CONTACT_RAW"

if [ -n "${ACCOUNTING_START:-}" ] && [ -n "${ACCOUNTING_MAX:-}" ]; then
  ACCOUNTING_BLOCK="\
AccountingStart $ACCOUNTING_START
AccountingMax $ACCOUNTING_MAX"
else
  ACCOUNTING_BLOCK=""
fi

if [ -n "${CONTROL_PORT:-}" ]; then
  CONTROL_PORT_BLOCK="ControlPort ${CONTROL_PORT}
CookieAuthentication ${COOKIE_AUTH:-1}"
else
  CONTROL_PORT_BLOCK=""
fi

OR_PORT="${OR_PORT:-9001}"
DIR_PORT="${DIR_PORT:-9030}"
PORT_BLOCK=""
if [ -n "$PUBLIC_V4" ]; then
  PORT_BLOCK+="ORPort 0.0.0.0:${OR_PORT} IPv4Only
DirPort 0.0.0.0:${DIR_PORT} IPv4Only
"
else
  PORT_BLOCK+="ORPort ${OR_PORT}
DirPort ${DIR_PORT}
"
fi

if have_global_v6_iface; then
  if [ -n "$PUBLIC_V6" ]; then
    PORT_BLOCK+="ORPort [::]:${OR_PORT}
"
  else
    PORT_BLOCK+="ORPort [::]:${OR_PORT} NoAdvertise
"
  fi
fi

# ---- Export for envsubst / torrc template ----
export ADDRESS="$PUBLIC_IP"
export NICKNAME="$RELAY_NICKNAME"
export CONTACT="$CONTACT_EMAIL"
export BANDWIDTH_LIMIT="${BANDWIDTH_LIMIT:-100 KB}"
export BANDWIDTH_BURST="${BANDWIDTH_BURST:-200 KB}"
export ACCOUNTING_BLOCK
export EXIT_RELAY="${EXIT_RELAY:-0}"
export SOCKS_PORT="${SOCKS_PORT:-0}"
export CONTROL_PORT_BLOCK
export TOR_EXTRA_LINES="${TOR_EXTRA_LINES:-}"
export PORT_BLOCK

# (Kept for compatibility with existing users who rely on these envs)
export OR_PORT DIR_PORT

envsubst < /etc/tor/torrc.template > /etc/tor/torrc || {
  echo "❌ Failed to generate torrc configuration!"
  exit 1
}

echo "🚀 Tor relay is starting with the following configuration:"
echo "  - Public IP: $PUBLIC_IP"
echo "  - Relay Nickname: $RELAY_NICKNAME"
echo "  - Contact Email: $CONTACT_EMAIL"
echo "  - Bandwidth Limit: $BANDWIDTH_LIMIT"
echo "  - Bandwidth Burst: $BANDWIDTH_BURST"
echo "  - OR Port: $OR_PORT"
echo "  - Directory Port: $DIR_PORT"
echo "  - Exit Relay: $EXIT_RELAY"
echo "  - SOCKS Port: $SOCKS_PORT"
if [ -n "${CONTROL_PORT:-}" ]; then
  echo "  - Control Port: $CONTROL_PORT"
  echo "  - Cookie Auth: ${COOKIE_AUTH:-1}"
else
  echo "  - Control Port: disabled"
  echo "  - Cookie Auth: n/a"
fi
echo "  - IPv6 advertise: $([ -n "$PUBLIC_V6" ] && echo yes || { have_global_v6_iface && echo 'present (NoAdvertise)'; } )"
echo "  - Extra Tor Lines: $TOR_EXTRA_LINES"

echo "✅ Tor relay configuration complete. Starting relay..."
echo "Please wait while the Tor relay starts up..."

exec su -s /bin/sh tor -c "tor -f /etc/tor/torrc"

sleep 5
echo "🎉 Tor relay is now running!"
