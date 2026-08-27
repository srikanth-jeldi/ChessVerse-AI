#!/usr/bin/env sh
set -eu

archive="${1:-/work/lichess-broadcast-2020-07.pgn.zst}"
pgn="${2:-/work/lichess-broadcast-2020-07.pgn}"
report="${3:-/work/ai-corpus-validation-report.json}"

apt-get update -qq
apt-get install -y -qq --no-install-recommends stockfish >/dev/null
pip install -q --no-cache-dir python-chess zstandard
python -c "import zstandard, pathlib; source=open('${archive}','rb'); target=open('${pgn}','wb'); zstandard.ZstdDecompressor().copy_stream(source,target); source.close(); target.close()"
python /work/validate_game_analysis_corpus.py "${pgn}" \
  --stockfish /usr/games/stockfish \
  --games "${VALIDATION_GAMES:-100}" \
  --positions-per-game "${VALIDATION_POSITIONS_PER_GAME:-1}" \
  --app-depth "${VALIDATION_APP_DEPTH:-16}" \
  --reference-depth "${VALIDATION_REFERENCE_DEPTH:-20}" \
  --report "${report}"
