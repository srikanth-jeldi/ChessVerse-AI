Build 340 artwork
Built-in imagegen created source.png: twelve isolated premium Staunton pieces,
ivory/gold and obsidian/gold, king/queen/bishop/knight/rook/pawn.
User authorised local cleanup after imagegen left semi-transparent speckles.
tools/build_clear_piece_assets.py removes stray alpha components, normalises
300px canvases, applies six material finishes, and writes existing asset paths.
Desktop and mobile use the same refreshed silhouettes. No animation logic changed.
The generated source is documentation only and is not bundled in the app.
board-preview.png and all-finishes.png show final packaged artwork.
