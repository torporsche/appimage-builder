# Commit Pins

This repository uses pin files to lock the build to specific upstream commits:
- mcpelauncher.commit
- mcpelauncher-ui.commit
- msa.commit (optional; MSA disabled by default)

Workflow:
- To update to latest upstream commits:
  ./update-pins.sh
  git add *.commit && git commit -m "chore(pins): bump to latest upstream"
- To validate pin file format:
  ./tests/test-commit-pins.sh

Notes:
- Qt6/Qt5 builds share the same pin files. The builder will prefer suffixed files (e.g., mcpelauncher-qt6.commit) if present, otherwise it falls back to the unsuffixed files above.
- For reproducible builds, avoid floating pins; commit the .commit file changes to the repo.