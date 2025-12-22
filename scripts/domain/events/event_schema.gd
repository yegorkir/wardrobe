extends RefCounted

const EVENT_KEY_TYPE := StringName("type")
const EVENT_KEY_PAYLOAD := StringName("payload")

const EVENT_ITEM_PLACED := StringName("item_placed")
const EVENT_ITEM_PICKED := StringName("item_picked")
const EVENT_ITEM_SWAPPED := StringName("item_swapped")
const EVENT_ACTION_REJECTED := StringName("action_rejected")

const EVENT_DESK_CONSUMED_ITEM := StringName("desk_consumed_item")
const EVENT_DESK_SPAWNED_ITEM := StringName("desk_spawned_item")
const EVENT_CLIENT_PHASE_CHANGED := StringName("client_phase_changed")
const EVENT_CLIENT_COMPLETED := StringName("client_completed")
const EVENT_DESK_REJECTED_DELIVERY := StringName("desk_rejected_delivery")

const PAYLOAD_SLOT_ID := StringName("slot_id")
const PAYLOAD_ITEM := StringName("item")
const PAYLOAD_OUTGOING_ITEM := StringName("outgoing_item")
const PAYLOAD_INCOMING_ITEM := StringName("incoming_item")
const PAYLOAD_REASON := StringName("reason")
const PAYLOAD_TICK := StringName("tick")

const PAYLOAD_DESK_ID := StringName("desk_id")
const PAYLOAD_ITEM_INSTANCE_ID := StringName("item_instance_id")
const PAYLOAD_ITEM_KIND := StringName("item_kind")
const PAYLOAD_REASON_CODE := StringName("reason_code")
const PAYLOAD_CLIENT_ID := StringName("client_id")
const PAYLOAD_FROM := StringName("from")
const PAYLOAD_TO := StringName("to")

const REASON_DROP_OFF_TICKET := StringName("dropoff_ticket_taken")
const REASON_PICKUP_COAT := StringName("pickup_coat_taken")
const REASON_CLIENT_AWAY := StringName("client_away")
const REASON_WRONG_COAT := StringName("wrong_coat")
