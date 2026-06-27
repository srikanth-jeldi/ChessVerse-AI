# Stockfish Engine

ChessVerse uses a backend UCI adapter so web, mobile, tablet and desktop clients
all receive moves from the same proven chess engine.

## Levels

| Level | Target Elo | Move time |
| --- | ---: | ---: |
| 1 | 1320 | 100 ms |
| 2 | 1400 | 130 ms |
| 3 | 1500 | 170 ms |
| 4 | 1600 | 230 ms |
| 5 | 1750 | 320 ms |
| 6 | 1900 | 450 ms |
| 7 | 2100 | 650 ms |
| 8 | 2300 | 900 ms |
| 9 | 2600 | 1200 ms |
| 10 | 3000 | 1600 ms |

The backend sets `UCI_LimitStrength` and `UCI_Elo`, then requests a bounded
move-time search. If the engine service is unavailable, the client keeps a
basic offline fallback so the board does not freeze.

## Configuration

Set `STOCKFISH_PATH` to an official UCI executable. Local Windows development
uses the ignored path `.local/stockfish/stockfish.exe`. The backend container
installs the distribution Stockfish package and uses `/usr/games/stockfish`.

## License

Stockfish is licensed under GNU GPL v3. ChessVerse does not commit the local
binary. Any distributed image or application containing Stockfish must include
the license and provide the exact corresponding source.

- Source: https://github.com/official-stockfish/Stockfish
- Stockfish 18 tag: https://github.com/official-stockfish/Stockfish/tree/sf_18
- License: https://github.com/official-stockfish/Stockfish/blob/sf_18/Copying.txt
