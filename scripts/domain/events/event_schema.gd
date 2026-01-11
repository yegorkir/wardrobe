extends RefCounted

const EVENT_KEY_TYPE := StringName("type")
const EVENT_KEY_PAYLOAD := StringName("payload")

const EVENT_ITEM_PLACED := StringName("item_placed")
const EVENT_ITEM_PICKED := StringName("item_picked")
const EVENT_ACTION_REJECTED := StringName("action_rejected")
const EVENT_ITEM_LANDED := StringName("item_landed")

const EVENT_DESK_CONSUMED_ITEM := StringName("desk_consumed_item")
const EVENT_DESK_SPAWNED_ITEM := StringName("desk_spawned_item")
const EVENT_CLIENT_PHASE_CHANGED := StringName("client_phase_changed")
const EVENT_CLIENT_COMPLETED := StringName("client_completed")
const EVENT_DESK_REJECTED_DELIVERY := StringName("desk_rejected_delivery")
const EVENT_CLIENT_PATIENCE_ZERO := StringName("client_patience_zero")

const PAYLOAD_SLOT_ID := StringName("slot_id")
const PAYLOAD_ITEM := StringName("item")
const PAYLOAD_REASON := StringName("reason")
const PAYLOAD_TICK := StringName("tick")
const PAYLOAD_ITEM_ID := StringName("item_id")
const PAYLOAD_SURFACE_KIND := StringName("surface_kind")
const PAYLOAD_CAUSE := StringName("cause")
const PAYLOAD_IMPACT := StringName("impact")

const PAYLOAD_DESK_ID := StringName("desk_id")
const PAYLOAD_ITEM_INSTANCE_ID := StringName("item_instance_id")
const PAYLOAD_ITEM_KIND := StringName("item_kind")
const PAYLOAD_REASON_CODE := StringName("reason_code")
const PAYLOAD_CLIENT_ID := StringName("client_id")
const PAYLOAD_FROM := StringName("from")
const PAYLOAD_TO := StringName("to")
const PAYLOAD_STRIKES_CURRENT := StringName("strikes_current")
const PAYLOAD_STRIKES_LIMIT := StringName("strikes_limit")

const REASON_DROP_OFF_TICKET := StringName("dropoff_ticket_taken")
const REASON_PICKUP_COAT := StringName("pickup_coat_taken")
const REASON_CLIENT_AWAY := StringName("client_away")
const REASON_WRONG_COAT := StringName("wrong_coat")

const CAUSE_DROP := StringName("drop")
const CAUSE_REJECT := StringName("reject")
const CAUSE_ACCIDENT := StringName("accident")
const CAUSE_COLLISION := StringName("collision")

const SURFACE_KIND_FLOOR := StringName("floor")
const SURFACE_KIND_SHELF := StringName("shelf")
const SURFACE_KIND_UNKNOWN := StringName("unknown")
