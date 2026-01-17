extends RefCounted
class_name CabinetSymbolAtlas

const TILE_SIZE := Vector2i(15, 12)
const ACTIVE_TILE_COUNT := 8

static func resolve_index(index: int, texture: Texture2D) -> int:
	if texture == null:
		return 0
	var size: Vector2i = texture.get_size()
	var cols: int = max(1, int(float(size.x) / float(TILE_SIZE.x)))
	var rows: int = max(1, int(float(size.y) / float(TILE_SIZE.y)))
	var total: int = cols * rows
	if total <= 0:
		return 0
	var active: int = min(ACTIVE_TILE_COUNT, total)
	if active <= 0:
		return 0
	return int(posmod(index, active))

static func wrap_index(index: int) -> int:
	if ACTIVE_TILE_COUNT <= 0:
		return 0
	return int(posmod(index, ACTIVE_TILE_COUNT))

static func get_region(texture: Texture2D, index: int) -> Rect2:
	if texture == null:
		return Rect2()
	var size: Vector2i = texture.get_size()
	var cols: int = max(1, int(float(size.x) / float(TILE_SIZE.x)))
	var rows: int = max(1, int(float(size.y) / float(TILE_SIZE.y)))
	var total: int = cols * rows
	if total <= 0:
		return Rect2()
	var safe_index: int = resolve_index(index, texture)
	var col: int = safe_index % cols
	var row: int = int(float(safe_index) / float(cols))
	return Rect2(Vector2(col * TILE_SIZE.x, row * TILE_SIZE.y), TILE_SIZE)

static func make_atlas_texture(texture: Texture2D, index: int) -> AtlasTexture:
	if texture == null:
		return null
	var region: Rect2 = get_region(texture, index)
	if region.size == Vector2.ZERO:
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
