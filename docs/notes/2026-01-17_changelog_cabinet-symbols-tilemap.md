# Changelog: Cabinet Symbols Tilemap

- Added `CabinetSymbolAtlas` helper to normalize 15x12 atlas slicing and wrap symbol indices to the active 8-tile set for both cabinet plates and ticket overlays.
- Tightened atlas math typing and texture filter enum usage to keep headless checks warning-free.
- Attached `CabinetsGrid` behavior to assign stable symbol indices per cabinet slot (sorted by slot id) and refresh cabinet plate icons after indexing.
- Switched cabinet plates to use explicit `PlateIcon` placeholders in `StorageCabinetLayout_Simple`, applying the `ankors.png` atlas without overriding placement.
- Added a dedicated ticket symbol overlay scene and wired `ItemNode` + `WardrobeItemVisualsAdapter` to render `symbols.png` tiles on tickets using the slot's atlas index.
- Fixed ticket symbol application for newly spawned ItemNodes by resolving overlay nodes lazily (before `_ready`).
- Notes: AtlasTexture (https://docs.godotengine.org/en/4.5/classes/class_atlastexture.html), Sprite2D (https://docs.godotengine.org/en/4.5/classes/class_sprite2d.html).
