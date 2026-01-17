# Plan: Cabinet/Tag Tilemap Symbols

## Goal
Place paired icons from `assets/sprites/ankors.png` (cabinet plates) and `assets/sprites/symbols.png` (number tags) in `StorageCabinetLayout_Simple`, ensuring each cabinet/slot uses the same tile index across both atlases.

## Scope
- Scene: `scenes/.../StorageCabinetLayout_Simple.tscn` (exact path to confirm).
- Adapter logic: likely `scripts/ui/wardrobe_step3_setup.gd` and/or `scripts/wardrobe/**` for placement.
- Assets: `assets/sprites/ankors.png`, `assets/sprites/symbols.png` (tile size 15x12).

## Plan
1. Locate the cabinet layout scene and the code path that instantiates cabinet plates and number tags.
2. Confirm import settings or create TileSet/Atlas resources for `ankors.png` and `symbols.png` with 15x12 tiles, preserving index order.
3. Add a small, typed pairing layer that chooses a tile index per cabinet/slot and applies the same index to both atlases.
4. Update scene nodes/prefabs to render the icons (TileMap or Sprite2D+AtlasTexture), with deterministic ordering (two icons per cabinet, one per slot).
5. Add/update changelog and checklist entries for the implementation, including references to the APIs used.
6. Run required tests and launch Godot once per repo policy.

## Notes / References
- Godot 4.5 TileSet: https://docs.godotengine.org/en/4.5/classes/class_tileset.html
- Godot 4.5 AtlasTexture: https://docs.godotengine.org/en/4.5/classes/class_atlastexture.html
- Godot 4.5 TileMap (if used): https://docs.godotengine.org/en/4.5/classes/class_tilemap.html
