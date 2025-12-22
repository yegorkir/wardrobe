extends RefCounted

const RESULT_KEY_SUCCESS := "success"
const RESULT_KEY_REASON := "reason"
const RESULT_KEY_ACTION := "action"
const RESULT_KEY_EVENTS := "events"
const RESULT_KEY_HAND_ITEM := "hand_item"

const EVENT_KEY_TYPE := StringName("type")
const EVENT_KEY_PAYLOAD := StringName("payload")
const EVENT_ITEM_PLACED := StringName("item_placed")
const EVENT_ITEM_PICKED := StringName("item_picked")
const EVENT_ITEM_SWAPPED := StringName("item_swapped")
const EVENT_ACTION_REJECTED := StringName("action_rejected")

const PAYLOAD_SLOT_ID := StringName("slot_id")
const PAYLOAD_ITEM := StringName("item")
const PAYLOAD_OUTGOING_ITEM := StringName("outgoing_item")
const PAYLOAD_INCOMING_ITEM := StringName("incoming_item")
const PAYLOAD_REASON := StringName("reason")
const PAYLOAD_TICK := StringName("tick")
