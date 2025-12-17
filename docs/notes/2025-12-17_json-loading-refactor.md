# Wardrobe JSON loading cleanup

## Cleanliness assessment
- `WardrobeScene` mixed multiple responsibilities and repeated the same JSON reading boilerplate for seeds, challenge definitions, and challenge best results.
- The duplication made it easy for edge cases (missing file, empty file, invalid JSON) to drift apart between callers and complicated future maintenance.

## Refactor
- Introduced `_read_json_dictionary()` to encapsulate file existence checks, empty-file handling, and validation errors.
- Updated `_setup_challenge_definition()`, `_load_seed_entries()`, and `_load_best_results()` to rely on the helper, keeping warning behavior configurable per call site.

## Notes
- Future JSON consumers in this scene should reuse the helper to stay consistent; extend it with additional flags if more nuanced handling is required.
