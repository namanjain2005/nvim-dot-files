#!/usr/bin/env bash
set -euo pipefail

# Install the newest gopls release compatible with the installed Go toolchain.
# Usage: ./scripts/install-latest-compatible-gopls.sh [GOBIN]

GO_BIN=${GO:-go}
if ! command -v "$GO_BIN" >/dev/null 2>&1; then
  echo "go not found" >&2
  exit 1
fi

if [ $# -ge 1 ]; then
  GOBIN_TARGET=$1
else
  GOBIN_TARGET=$($GO_BIN env GOBIN)
  if [ -z "$GOBIN_TARGET" ]; then
    GOBIN_TARGET="$($GO_BIN env GOPATH)/bin"
  fi
fi
mkdir -p "$GOBIN_TARGET"

go_ver_full=$($GO_BIN env GOVERSION | sed 's/^go//')
go_mm=$(printf '%s\n' "$go_ver_full" | awk -F. '{print $1"."$2}')

# Compare Go minor versions like 1.20 <= 1.21.
ver_le() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]
}

versions=$($GO_BIN list -m -versions golang.org/x/tools/gopls | tr ' ' '\n' | grep '^v' | grep -Ev -- '-pre|-rc|-beta' | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}')

echo "Installed Go: $go_ver_full"
echo "Target GOBIN: $GOBIN_TARGET"

for v in $versions; do
  req=$($GO_BIN list -m -json "golang.org/x/tools/gopls@$v" 2>/dev/null | sed -n 's/.*"GoVersion": "\([^"]*\)".*/\1/p' | head -1)
  [ -z "$req" ] && continue
  req_mm=$(printf '%s\n' "$req" | awk -F. '{print $1"."$2}')
  if ! ver_le "$req_mm" "$go_mm"; then
    continue
  fi

  echo "Trying gopls $v (requires Go $req_mm)..."
  tmp=$(mktemp -d)
  if GOBIN="$tmp" "$GO_BIN" install "golang.org/x/tools/gopls@$v" >/tmp/gopls-install.log 2>&1; then
    install -m 0755 "$tmp/gopls" "$GOBIN_TARGET/gopls"
    rm -rf "$tmp"
    echo "Installed: $("$GOBIN_TARGET/gopls" version 2>&1 | head -1)"
    exit 0
  fi
  rm -rf "$tmp"
  echo "  failed, trying older release..." >&2
done

echo "No compatible gopls version could be installed." >&2
exit 1
