#!/bin/bash
set -e

DATA_DIR=/var/lib/tor
NICKNAME_FILE="$DATA_DIR/relay_nickname"

PUBLIC_IP=$(curl -s https://api64.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
  echo "❌ Failed to determine public IP address!"
  exit 1
fi

echo "🌍 Detected public IP: $PUBLIC_IP"

# ---- Nickname handling (prefix-stable if NICKNAME provided) ----
if [ -n "${NICKNAME:-}" ]; then
  if [ -f "$NICKNAME_FILE" ]; then
    EXISTING_NICKNAME=$(cat "$NICKNAME_FILE")
    # NOTE: ${var:offset:length} is non-POSIX; used only if NICKNAME is set.
    # If your /bin/sh doesn't support it, consider switching shebang to /bin/bash.
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

# ---- CONTACT validation (required; must not be the placeholder) ----
CONTACT_RAW="${CONTACT:-}"
DEFAULT_PLACEHOLDER="your@email.com"

if [ -z "$CONTACT_RAW" ] || [ "$CONTACT_RAW" = "$DEFAULT_PLACEHOLDER" ]; then
  echo "❌ CONTACT is required and cannot be '$DEFAULT_PLACEHOLDER'."
  echo "   Please set CONTACT in your environment or .env (e.g., CONTACT=you@example.com)."
  exit 1
fi

CONTACT_EMAIL="$CONTACT_RAW"

# ---- Optional blocks ----
if [ -n "${ACCOUNTING_START:-}" ] && [ -n "${ACCOUNTING_MAX:-}" ]; then
  ACCOUNTING_BLOCK="\
AccountingStart $ACCOUNTING_START
AccountingMax $ACCOUNTING_MAX"
else
  ACCOUNTING_BLOCK=""
fi

if [ -n "${CONTROL_PORT:-}" ]; then
  CONTROL_PORT_BLOCK="ControlPort $CONTROL_PORT\\nCookieAuthentication ${COOKIE_AUTH:-1}"
else
  CONTROL_PORT_BLOCK=""
fi

# ---- Export for envsubst / torrc template ----
export ADDRESS="$PUBLIC_IP"
export NICKNAME="$RELAY_NICKNAME"
export CONTACT="$CONTACT_EMAIL"
export BANDWIDTH_LIMIT="${BANDWIDTH_LIMIT:-100 KB}"
export BANDWIDTH_BURST="${BANDWIDTH_BURST:-200 KB}"
export ACCOUNTING_BLOCK
export OR_PORT="${OR_PORT:-9001}"
export DIR_PORT="${DIR_PORT:-9030}"
export EXIT_RELAY="${EXIT_RELAY:-0}"
export SOCKS_PORT="${SOCKS_PORT:-0}"
export CONTROL_PORT_BLOCK
export TOR_EXTRA_LINES="${TOR_EXTRA_LINES:-}"

envsubst < /etc/tor/torrc.template > /etc/tor/torrc
if [ $? -ne 0 ]; then
  echo "❌ Failed to generate torrc configuration!"
  exit 1
fi

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
echo "  - Extra Tor Lines: $TOR_EXTRA_LINES"

echo "✅ Tor relay configuration complete. Starting relay..."
echo "Please wait while the Tor relay starts up..."

exec su -s /bin/sh tor -c "tor -f /etc/tor/torrc"

# If exec fails (it shouldn't), this would run; keep for completeness.
sleep 5
echo "🎉 Tor relay is now running!"
