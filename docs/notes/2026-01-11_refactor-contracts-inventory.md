# Контракты до/после (P0.1–P0.2)

## Domain: MagicSystem (`scripts/domain/magic/magic_system.gd`)
- До: `setup(config: Dictionary)`, `get_config() -> Dictionary`, `apply_insurance(...) -> Dictionary`, `request_emergency_locate(...) -> Dictionary`.
- После: `setup(config: MagicConfig)`, `get_config() -> MagicConfig`, `apply_insurance(...) -> MagicEvent`, `request_emergency_locate(...) -> MagicEvent`.

## Domain: InspectionSystem (`scripts/domain/inspection/inspection_system.gd`)
- До: `setup(config: Dictionary)`, `get_config() -> Dictionary`, `build_inspection_report(...) -> Dictionary`.
- После: `setup(config: InspectionConfig)`, `get_config() -> InspectionConfig`, `build_inspection_report(...) -> InspectionReport`.

## Domain: WardrobeStorageState (`scripts/domain/storage/wardrobe_storage_state.gd`)
- До: `put/pick/pop_slot_item(...) -> Dictionary`, `get_snapshot() -> Dictionary`.
- После: `put/pick/pop_slot_item(...) -> StorageActionResult`, `get_snapshot() -> WardrobeStorageSnapshot`.

## Domain: InteractionEngine (`scripts/domain/interaction/interaction_engine.gd`)
- До: `process_command(command: Dictionary, ...) -> InteractionResult` + events как `Array[Dictionary]`.
- После: `process_command(command: InteractionCommand, ...) -> InteractionResult` + events как `Array[InteractionEvent]`.

## App: ShiftService / ShiftWinPolicy / ShiftLog
- До: `ShiftWinPolicy.evaluate(...) -> Dictionary`, `ShiftService` использует `Dictionary` для HUD/summary/shift events, `ShiftLog` хранит `Dictionary` entries.
- После: `ShiftWinPolicy.evaluate(...) -> ShiftWinResult`, `ShiftService` использует `ShiftHudSnapshot`/`ShiftSummary`/`ShiftFailurePayload`/`ShiftWinPayload`, `ShiftLog` хранит `ShiftLogEntry`.
