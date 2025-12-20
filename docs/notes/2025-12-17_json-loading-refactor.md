# Wardrobe JSON loading cleanup

## Cleanliness assessment
- `WardrobeScene` mixed multiple responsibilities and repeated the same JSON reading boilerplate for seeds and related UI data.
- The duplication made it easy for edge cases (missing file, empty file, invalid JSON) to drift apart between callers and complicated future maintenance.

## Refactor
- Introduced `_read_json_dictionary()` to encapsulate file existence checks, empty-file handling, and validation errors.
- Updated seed loading helpers to rely on the shared reader, keeping warning behavior configurable per call site.

## Notes
- Future JSON consumers in this scene should reuse the helper to stay consistent; extend it with additional flags if more nuanced handling is required.
