#!/bin/sh
# zena.yml 실행기. 사용법: ./zena.sh up -d | ./zena.sh down | ./zena.sh logs -f backend
# 노드가 최근 상태만 보관하므로 trace 시작 블록을 매번 현재 블록으로 잡는다.
set -e
cd "$(dirname "$0")"

RPC_URL="${ZENA_RPC_URL:-https://evm.zena-ai.io}"
hex=$(curl -sf -m 15 -X POST -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$RPC_URL" |
  sed -E 's/.*"result":"(0x[0-9a-fA-F]+)".*/\1/')

case "$hex" in
  0x*) TRACE_FIRST_BLOCK=$(printf '%d' "$hex") ;;
  *) echo "eth_blockNumber 조회 실패: $RPC_URL" >&2; exit 1 ;;
esac
export TRACE_FIRST_BLOCK

echo "TRACE_FIRST_BLOCK=$TRACE_FIRST_BLOCK"
docker compose -f zena.yml "$@"

# 값이 매번 바뀌어 backend가 새로 만들어지는데, nginx는 옛 backend 주소를 붙잡고 502를 낸다.
if [ "$1" = "up" ]; then
  docker compose -f zena.yml restart proxy
fi
