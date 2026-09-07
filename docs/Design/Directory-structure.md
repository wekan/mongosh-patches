# Directory structure

| Path | Purpose |
| --- | --- |
| `.github/workflows/` | Complete and missing release workflows |
| `dist/` | Checksum-verified patches only |
| `releases/` | Source resolution, bundle and target packaging scripts |
| `tests/` | Offline workflow and negative tests |
| `build.sh`, `build.bat` | Interactive or direct local entry points |

Generated upstream source, `mongosh.js`, Node binaries and release archives are
not committed.
