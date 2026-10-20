#!/bin/bash
# Starts the Tact server + a public link for your iPhone. Stop with Ctrl+C.
cd "$(dirname "$0")/server" || exit 1

if [ ! -d .venv ]; then python3 -m venv .venv; fi
source .venv/bin/activate
pip install -q -r requirements.txt || { echo "pip install failed"; exit 1; }

if ! command -v cloudflared >/dev/null; then
  echo "Installing cloudflared..."
  brew install cloudflared || { echo "Couldn't install cloudflared"; exit 1; }
fi

# Stop old versions: any server on port 5580 and any old tunnel
lsof -ti tcp:5580 | xargs kill 2>/dev/null
pkill -f "cloudflared tunnel --url http://localhost:5580" 2>/dev/null
sleep 1

python wsgi.py > server.log 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT

for i in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  curl -s http://localhost:5580/health >/dev/null && break
done
if ! curl -s http://localhost:5580/health >/dev/null; then
  echo "❌ Server didn't start. Here's why:"
  cat server.log
  exit 1
fi
echo "✅ Server running: $(curl -s http://localhost:5580/health)"
echo "Making your link (takes ~10 seconds)..."

cloudflared tunnel --url http://localhost:5580 2>&1 | while IFS= read -r line; do
  echo "$line" >> tunnel.log
  if [[ $line =~ (https://[a-z0-9-]+\.trycloudflare\.com) ]]; then
    URL="${BASH_REMATCH[1]}"
    printf "%s" "$URL" | pbcopy
    echo
    echo "=================================================="
    echo "  YOUR LINK (already copied — paste it on iPhone):"
    echo "  $URL"
    echo "=================================================="
    echo "Keep this window open. Ctrl+C to stop."
  fi
done
