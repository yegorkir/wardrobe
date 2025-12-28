class_name WardrobePhysicsLayers
extends RefCounted

const LAYER_SHELF_IDX := 1
const LAYER_ITEM_IDX := 2
const LAYER_PICK_AREA_IDX := 3
const LAYER_FLOOR_IDX := 4
const LAYER_ITEM_REJECT_IDX := 5
const LAYER_TRANSFER_FALL_IDX := 6

const LAYER_SHELF_BIT := 1 << (LAYER_SHELF_IDX - 1)
const LAYER_ITEM_BIT := 1 << (LAYER_ITEM_IDX - 1)
const LAYER_PICK_AREA_BIT := 1 << (LAYER_PICK_AREA_IDX - 1)
const LAYER_FLOOR_BIT := 1 << (LAYER_FLOOR_IDX - 1)
const LAYER_ITEM_REJECT_BIT := 1 << (LAYER_ITEM_REJECT_IDX - 1)
const LAYER_TRANSFER_FALL_BIT := 1 << (LAYER_TRANSFER_FALL_IDX - 1)

# Default mask for items: collides with shelves, floor, and other items
const MASK_ITEM_DEFAULT := LAYER_SHELF_BIT | LAYER_FLOOR_BIT | LAYER_ITEM_BIT
# Shelfed items should not collide with other items.
const MASK_ITEM_SHELFED := LAYER_SHELF_BIT | LAYER_FLOOR_BIT
# Mask for items in "reject fall" state: collides only with the floor
const MASK_ITEM_REJECT_FALL := LAYER_FLOOR_BIT

const MASK_FLOOR_ONLY := LAYER_FLOOR_BIT
const MASK_TRANSFER_FALL_ONLY := LAYER_FLOOR_BIT
const MASK_PICK_QUERY := LAYER_PICK_AREA_BIT
const MASK_ITEMS_QUERY := LAYER_ITEM_BIT

const GROUP_SHELVES := &"wardrobe_shelves"
const GROUP_FLOORS := &"wardrobe_floor_zones"
const GROUP_TICK := &"wardrobe_physics_tick"
