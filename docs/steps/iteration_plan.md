# Iteration Plan

**Current Status**: Moving to Iteration 5.
**Date**: January 12, 2026

## Active Iterations

1. **Iteration 5 — Add item quality stars**
2. **Iteration 6A — Implement light zones logic**
3. **Iteration 6B — Implement light controls**
4. **Iteration 7A — Implement vampire light corrosion**
5. **Iteration 7B — Implement zombie proximity corrosion**
6. **Iteration 8 — Finalize patience tuning and queue decay**
7. **Iteration 9 — Implement ghost darkness rule**

---

# Detailed Codex Tasks

## Codex Task — Iteration 5 — Item quality (звёзды) как базовая система

### Goal

Introduce **item quality as a core, extensible system** represented by discrete stars that affect how items react to damage sources (starting with falls). Quality must be persistent, visible, and owned by the domain.

### Context

Items need a simple but future-proof quality axis that later feeds corruption and other systems. For MVP, quality exists, renders clearly, can be modified by damage hooks, and survives all standard item flows.

### Current behavior

* Items have no quality dimension.
* Falls and other interactions do not affect long-term item state.
* UI provides no visual quality feedback.

### Desired behavior

* Each item has a **quality star count** (e.g., `0..3` or `0..5`, configurable).
* Quality is:

  * defined by immutable **item config** (max stars),
  * stored in mutable **runtime item state** (current stars).
* Quality can **decrease** due to damage sources.

  * MVP: only fall-based damage hook required.
  * Future systems (corruption, special effects) must be able to reuse the same API.
* Directional rule (do not fully implement yet):

  > “Чем более предмет хлам, тем меньше урона получает от падений.”
  > MVP math can be simple, but the system must allow swapping the formula later without touching damage sources.

### Domain model

#### Item quality

* `ItemQualityConfig`

  * `max_stars: int`
* `ItemQualityState`

  * `current_stars: int` (0 ≤ current ≤ max)

Quality rules live in the **domain**, not in UI or physics systems.

#### Damage API (domain-owned)

* `ApplyDamage(source, amount)`

  * `source`: enum or tag (e.g., `Fall`, `Corruption`, `Other`)
  * `amount`: abstract damage units
* Damage systems (falls, corruption, etc.) **emit damage**, but do not compute quality math.

Quality logic decides:

* how much quality is lost,
* clamping and boundaries,
* whether damage is ignored or reduced.

### Events & flow

* Damage-causing systems emit `ApplyDamage`.
* Item domain:

  * evaluates damage vs current quality,
  * updates `current_stars` if needed,
  * emits `ItemQualityChanged(old, new)` if state changed.
* UI listens to state changes; it never mutates quality.

### UI requirements

* Show **stars visually** on item card.
* **No text labels** (“Quality: ★★★” is forbidden).
* Damage feedback must be readable:

  * star loss animation or clear visual delta.
* UI is a **pure projection** of item state.

### Acceptance criteria (observable & testable)

* [ ] Items have a quality star value at runtime.
* [ ] Stars render correctly on item cards (visual only, no text).
* [ ] Quality persists through:

  * pick up,
  * put down,
  * drop,
  * move between containers.
* [ ] Fall damage triggers the quality damage hook.
* [ ] Quality never exceeds max or drops below zero.
* [ ] Changing quality does not break existing item flows.
* [ ] Debug/dev tools can spawn items with arbitrary starting quality.

### Tests

#### Unit tests (domain)

* Quality initialization from config.
* Damage application:

  * no negative stars,
  * no overflow above max,
  * repeated damage clamps correctly.
* Source-independence: adding a new damage source does not require changing item internals.

#### Regression tests

* Existing item interactions (pick/place/drop/use) behave exactly as before when quality is unchanged.
* Items without explicit quality config default safely (no crashes, no NaNs, no sadness).

### Minimal debug / dev hooks

* Console or debug action:

  * spawn item with `current_stars = X`.
* Log event:

  * `ITEM_QUALITY_CHANGED item_id=<id> from=<old> to=<new> source=<source>`.

### Constraints

* Damage systems **do not own quality math**.
* No UI-driven logic.
* Minimal refactors; extend, don’t rewrite.
* Future formula swaps must not require touching fall/corruption systems.

### Expected files to touch

* Item config definitions (quality max).
* Item runtime state (quality current).
* Domain damage/quality logic module.
* UI item card rendering (stars).
* Debug/dev utilities.
* Unit + regression tests.

### Rollback plan (if a test fails)

* Disable quality mutation behind a feature flag while keeping rendering stubbed.
* Revert damage hook integration first, leaving quality state intact.
* Re-enable incrementally:

  1. data model,
  2. rendering,
  3. damage hook.

---

## Codex Task — Iteration 6A — Свет: зоны света и их логика (без управления)

### Goal

Introduce a **domain-level light zone system** that deterministically answers whether an item is “in light” and which light sources affect it, without any UI controls or gameplay decisions embedded in scene objects.

### Context

Light is a core rule driver for later mechanics (corrosion, vampires, ghosts). Before adding controls or effects, we need a **clean, testable light model** that represents coverage and on/off state independently of visuals.

### Current behavior

* Light is implicit and/or visual-only.
* No unified logic exists to query whether an item is in light.
* Any checks (if present) are scene-driven and hard to test.

### Desired behavior

* Model **light zones** as abstract areas with:

  * on/off state,
  * spatial coverage,
  * association with one or more light sources.
* Provide a **query-only API** to determine light interaction for items.
* No explicit HUD indicators; lighting must be readable through scene visuals only.

### Light layout rules (MVP, deterministic)

#### Columns & rows model

Assume the playfield is logically divided into **columns** and **rows** (existing grid or implicit layout).

#### Curtains

* Affect **left column** (full height).
* Affect **central column** (full height).
* Coverage is column-wide, not row-segmented.

#### Bulbs

* Affect **right column** by **row**.
* Also affect **their half of the central column**, by **row**.
* Central column is segmented vertically per bulb influence.

#### Item-in-light rule

* An item is considered “in light” if its **pivot / center point** lies within at least one active light zone.
* This rule must be explicitly marked as **[PLAYTEST]** and easy to swap later.

### Architecture rules

* Light logic lives in a **reusable service/component**, not inside item scripts.
* Scene objects (curtains, bulbs) only:

  * report their state (on/off),
  * report their logical coverage parameters.
* Items never query scene nodes directly.

### Interfaces / DTOs

#### LightSourceState

* `source_id`
* `type` (Curtain | Bulb | …)
* `is_on: bool`
* `coverage_descriptor` (column/row/segment data)

#### LightZone

* `zone_id`
* `source_id`
* `area` (abstract, grid-based or logical bounds)
* `is_active`

#### Query API

* `IsItemInLight(item) -> bool`
* `WhichLightSourcesAffect(item) -> List<source_id>`

Query results must depend **only** on:

* item position (logical),
* light source states,
* zone definitions.

### Acceptance criteria (observable & testable)

* [ ] Light zones are created from light source states deterministically.
* [ ] Curtains affect left + central columns fully, regardless of row.
* [ ] Bulbs affect right column by row and their half of the central column by row.
* [ ] `IsItemInLight` returns consistent results for fixed item positions.
* [ ] `WhichLightSourcesAffect` returns correct, ordered, non-duplicated source IDs.
* [ ] Item scripts do not contain light logic.
* [ ] Results are easy to unit test without loading a scene.

### Tests

#### Unit tests (required)

* Zone construction from:

  * curtain ON/OFF,
  * bulb ON/OFF with row segmentation.
* Item position → light result matrix:

  * same position, same input → same result (determinism).
* Boundary cases:

  * item exactly on zone edge,
  * overlapping zones,
  * all lights off.

#### Regression safety

* No change in gameplay behavior yet (no effects triggered).

### Debug / developer mode

* Add a **developer-only debug visualization** for light zones:

  * overlays logical zones (colors / outlines),
  * togglable at runtime,
  * must not affect gameplay logic or query results.
* Debug visuals read from the same light service output.

### Constraints

* No HUD indicators.
* No light controls in this iteration.
* No scene-tree traversal in item logic.
* Minimal refactors; introduce a clean service boundary.

### Expected files to touch

* Light domain/service module (zones, queries).
* Light source state adapters (curtains, bulbs → DTOs).
* Debug visualization module (dev-only).
* Unit tests for zone logic and queries.

### Rollback plan (if a test fails)

* Disable light service behind a feature flag and fall back to “always lit” behavior.
* Keep DTOs and tests intact; re-enable incrementally:

  1. zone construction,
  2. query API,
  3. debug visualization.

---

## Codex Task — Iteration 6B — Свет: управление (шторы/лампы), без изменения правил порчи

### Goal

Add **player-controlled light toggles** (curtains and bulbs) that modify light source state and immediately affect light zone queries, **without changing any light rules** introduced in Iteration 6A.

### Context

Light logic already exists as a queryable system (zones + sources). This iteration adds **control only**: player interactions that flip on/off states and drive visuals. No new gameplay effects, no corrosion changes, no hidden rules.

### Current behavior

* Light zones exist and can be queried.
* Light source state is static or simulated.
* No player interaction to control curtains or bulbs.

### Desired behavior

* Player can:

  * Toggle **curtains** with a single action.
  * Toggle **each bulb per row** in the Storage Hall.
* Curtains and bulbs:

  * Share the **same logical model** (light source with on/off state + coverage).
  * Differ **only in visuals and interaction affordances**.
* Toggling a source updates the **LightZone state** from Iteration 6A.
* No text UI; readability comes from the scene:

  * Curtains: open / closed.
  * Bulbs: glow on / off.

### Architecture rules

* Input handling calls a **small controller** (use-case level).
* Controller updates **domain light source state**.
* Scene objects:

  * forward input,
  * react visually to state changes.
* No direct manipulation of item nodes, item placement, or item scripts.

### Control model

#### LightSource (domain)

* `source_id`
* `type` (Curtain | Bulb)
* `is_on: bool`
* `coverage_descriptor` (already defined in 6A)

#### Controller API (example)

* `ToggleLightSource(source_id)`

  * Flips `is_on`
  * Triggers zone recomputation/update
  * Emits `LightSourceStateChanged`

Scene never decides coverage or rules. It just asks the controller to toggle.

### UI / interaction requirements

* Interactions are **contextual**:

  * click / use on curtain → toggle curtain source
  * click / use on bulb → toggle that bulb’s row source
* No text labels, tooltips, or HUD.
* Visual state must always reflect domain state (not cached locally).

### Acceptance criteria (observable & testable)

* [ ] Player can toggle each curtain and bulb independently.
* [ ] Toggling immediately affects `IsItemInLight` and `WhichLightSourcesAffect`.
* [ ] Light state persists for the entire shift.
* [ ] Curtains and bulbs share the same logical toggle flow.
* [ ] No coupling between light toggles and item placement / drag-drop code.
* [ ] No regressions in existing drag-drop interactions.
* [ ] Visuals always match domain state after reload / rebind.

### Tests

#### Unit tests (domain / controller)

* Toggle source ON → zones become active.
* Toggle source OFF → zones deactivate.
* Multiple toggles are idempotent and deterministic.
* Toggling one source does not affect others.

#### Integration tests (lightweight)

* Simulate:

  * toggle curtain → query item in left/central column
  * toggle bulb → query item in right/central segment
* Verify drag-drop still works when toggling lights mid-interaction.

### Debug / dev notes

* Reuse Iteration 6A debug visualization to confirm zone changes.
* Optional dev log:

  * `LIGHT_TOGGLED source_id=<id> is_on=<bool>`

### Constraints

* No changes to corruption / damage / item quality rules.
* No HUD or textual UI.
* Minimal refactors; extend the existing light service.
* Scene objects must not encode light logic.

### Expected files to touch

* Light controller / use-case layer.
* Light source domain state.
* Scene interaction adapters for curtains and bulbs.
* Visual response scripts (open/close, glow on/off).
* Tests for toggle + query behavior.

### Rollback plan (if a test fails)

* Disable interactions behind a feature flag while keeping light zones intact.
* Revert controller wiring first, visuals second.
* Re-enable in steps:

  1. controller toggle logic,
  2. domain state persistence,
  3. scene visuals.

---

## Codex Task — Iteration 7A — Vampire‑порча от света

### Goal

Introduce **vampire archetype light corrosion**: vampire items **lose quality over time while in light**, using the existing Light Query Service, with staged exposure and clean separation of concerns.

### Context

Light logic (6A/6B) already answers *where light is* and *what affects an item*. Item quality exists (Iteration 5). Now we connect them **without polluting either system**. This is a ticking hazard, not instant damage.

No new corruption rules, no UI polish fantasies. Just correct, extensible logic.

### Desired behavior (rules, no poetry)

* Vampire items:

  * Accumulate **light exposure** while *in light*.
  * When exposure reaches a **stage threshold**:

    * Apply a **quality decrement** (discrete step).
    * Reset exposure for the next stage.
* Exposure:

  * **Resets to zero** immediately when the item leaves light.
  * **Does NOT regenerate lost stars**. Ever.
* Drag rule:

  * While item is **in hand / cursor**, exposure **does not accumulate**.
  * Hand is a safe zone. Vampires approve.
* MVP numbers can be simple.

  * System must allow changing formulas later without rewriting logic.

### Architecture rules (non‑negotiable)

Split the system into **three explicit responsibilities**:

1. **Exposure detection**

   * Uses `IsItemInLight(item)` from Light Service.
   * No timers, no math, no quality logic.

2. **Exposure accumulation**

   * Per‑item timer/state.
   * Handles:

     * accumulate while in light,
     * reset when leaving light,
     * pause while dragged.

3. **Quality application**

   * Applies discrete quality loss via item quality API.
   * No direct star math in exposure logic.

No global vampire manager.
No hidden ticking singletons.
Each item owns its own damn curse.

### Domain model

#### VampireExposureState (per item)

* `current_stage_exposure: float`
* `stage_index: int` (or derived)
* `is_active: bool` (derived from light + not dragged)

#### Config

* `exposure_threshold_per_stage`
* `quality_loss_per_stage`
  (MVP: 1 stage = -1 star or equivalent discrete unit)

### Flow (tick/update)

On update:

1. If item **is dragged** → do nothing.
2. Else query `IsItemInLight(item)`:

   * false → reset `current_stage_exposure = 0`
   * true → accumulate exposure
3. If exposure ≥ threshold:

   * apply quality decrement
   * reset exposure
   * advance stage
4. If quality already at 0 → stop applying further loss.

### UI feedback (MVP only)

* Show **simple progress bar(s)** on item while exposed.
* No text.
* No final visuals baked in — corrosion animations come later.
* UI reads exposure state only.

### Acceptance criteria (hard checks)

* [ ] Vampire items lose quality only while in light.
* [ ] Exposure resets immediately when item leaves light.
* [ ] Dragging item pauses exposure completely.
* [ ] Quality loss happens only after threshold, not continuously.
* [ ] Lost stars never regenerate.
* [ ] Non‑vampire items are unaffected.
* [ ] Behavior is deterministic across runs.

### Tests

#### Unit tests

* Exposure accumulation over simulated time.
* Exposure reset on light exit.
* Stage progression correctness.
* Quality decrement clamps at zero.
* Drag safety: exposure does not advance while dragged.

#### Simulation tests

* Fast‑forward time in light → expected star loss.
* In/out/in light → exposure resets per stage.
* Light on/off toggling mid‑exposure.

#### Regression

* Existing item flows (pick/place/drop/quality rendering) unchanged.

### Debug / dev hooks

* Log:

  * `VAMPIRE_EXPOSURE_START item_id=…`
  * `VAMPIRE_STAGE_COMPLETE item_id=… stage=…`
  * `VAMPIRE_QUALITY_LOSS item_id=… new_stars=…`
* Optional dev overlay:

  * exposure bar visible regardless of UI mode.

### Constraints

* No changes to light rules.
* No quality math inside light or drag systems.
* No UI‑driven logic.
* Minimal refactors; extend via composition.

### Expected files to touch

* Vampire exposure component/state.
* Tick/update integration point.
* Item quality API usage.
* UI exposure indicator (temporary).
* Unit + simulation tests.

### Rollback plan

* Feature‑flag vampire exposure.
* Disable accumulation first, keep data model.
* Re‑enable in order:

  1. detection,
  2. accumulation,
  3. quality application.

---

## Codex Task — Iteration 7B — Zombie‑порча по соседству (радиусы, стадийность)

### Goal

Add **zombie proximity corrosion**: zombie items emit a corruption aura that causes nearby items to **lose quality over time**, using staged exposure, stacking rules, and optional propagation—cleanly separated from item, drag, and quality systems.

### Context

Item quality (Iteration 5) exists. Staged corrosion from light (7A) exists. Now we introduce **area‑based corruption** driven by proximity to zombie sources. This must be deterministic, testable, and cheap enough to run every tick.

No UI micromanagement. No frame‑by‑frame spaghetti.

### Desired behavior (rules)

* **Zombie aura**:

  * Zombie items emit a corruption aura with a radius and rate.
  * Nearby items accumulate **exposure over time**.

* **Staged model**:

  * Exposure accumulates → reaches threshold → apply **quality decrement** → reset exposure → next stage.
  * If the source is removed **before threshold**, exposure **resets**.
  * Already lost stars **never restore**.

* **Stacking**:

  * Multiple zombie sources can affect the same item.
  * MVP combine rule: **sum exposure rates with a cap** [PLAYTEST].
  * Rule must be isolated and swappable.

* **Propagation (MVP minimal)**:

  * Once an item **loses stars due to zombie corrosion**, it may start emitting a **weaker aura**.
  * MVP: minimal radius, enabled after first completed stage.

* **Drag / hand rule**:

  * While item is **in hand / cursor**:

    * exposure does **not** accumulate,
    * aura does **not** propagate.
  * Optional VFX trail is cosmetic only.

### Architecture rules (read twice)

* **Aura math lives in a service**.
* Items do not scan neighbors.
* Quality math stays in quality system.
* No per‑item hidden timers outside explicit state objects.

### Domain model

#### ZombieAuraSource

* `source_id`
* `radius`
* `base_rate`
* `is_active`
* `strength_modifier` (for propagated/weak auras)

#### ZombieExposureState (per item)

* `current_stage_exposure: float`
* `stage_index: int`
* `is_emitting_weak_aura: bool`

#### Config

* `exposure_threshold_per_stage`
* `quality_loss_per_stage`
* `stack_rate_cap` [PLAYTEST]
* `propagation_radius_min`

### Services

#### CorruptionAuraService

**Inputs**:

* item positions (logical, not nodes),
* active zombie aura sources.

**Outputs**:

* `GetExposureRate(item_id) -> float`
* `GetAffectingSources(item_id) -> List<source_id>`

Responsibilities:

* distance checks,
* stacking rule,
* capping.

No timers. No quality logic.

### Flow (tick/update)

For each item:

1. If **dragged** → skip entirely.
2. Query `GetExposureRate(item)`.
3. If rate == 0:

   * reset stage exposure.
4. Else:

   * accumulate exposure.
5. On threshold:

   * apply quality decrement,
   * reset exposure,
   * advance stage,
   * enable weak aura emission if applicable.

### Acceptance criteria (must all pass)

* [ ] Items near zombie sources lose quality over time.
* [ ] Removing a zombie source stops further loss immediately.
* [ ] Exposure resets if source disappears before threshold.
* [ ] Stacking from multiple sources increases rate, capped and explainable.
* [ ] Propagation starts only after first completed stage.
* [ ] Dragging items pauses both exposure and propagation.
* [ ] Behavior is deterministic and reproducible.

### Tests

#### Unit tests

* Aura rate calculation with:

  * single source,
  * multiple sources,
  * cap reached.
* Exposure reset on source removal.
* Quality loss clamps at zero.

#### Deterministic scenario test (required)

* 3 items:

  * one zombie,
  * one normal nearby,
  * one normal far away.
* Verify:

  * stacking,
  * cap,
  * propagation after first stage,
  * no regen.

### Debug / dev hooks

* Logs:

  * `ZOMBIE_AURA_APPLIED item_id=… rate=…`
  * `ZOMBIE_STAGE_COMPLETE item_id=… stage=…`
  * `ZOMBIE_PROPAGATION_ENABLED item_id=…`
* Optional dev overlay:

  * aura radii visualization (developer‑only).

### Constraints

* No per‑frame global scans beyond MVP limits.
* No coupling to drag‑drop or placement code.
* No UI logic inside corruption systems.
* Minimal refactors; extend via services and state.

### Expected files to touch

* Corruption aura service.
* Zombie exposure state/component.
* Tick/update integration.
* Quality API usage.
* Tests (unit + scenario).

### Rollback plan

* Feature‑flag zombie corruption.
* Disable propagation first, then stacking, then base aura.
* Keep data model intact for fast retry.

---

## Codex Task — Iteration 8 — Patience в очереди + анти‑игнор тюнинг

### Goal

Extend the **patience system** to support **queue decay** (separate from service‑slot decay) with tunable rates, preventing “profitable clogging” while keeping all strike/lose rules intact and deterministic.

### Context

Right now patience only meaningfully decays in service slots. This allows players to park clients in queue too cheaply. We want queue patience to decay too—**not slower by accident, not faster by superstition**, but via config and playtest tuning.

No rule rewrites. No UI hacks. Just clean math in one place.

### Current behavior (baseline)

* Patience decays **only** in service slots.
* When patience reaches 0:

  * Only that **slot** becomes blocked.
  * A **strike** is counted **only once**, on transition `>0 → 0`.
* Lose condition: **3 strikes**.
* **Behavior B**: if one slot is blocked, the other remains usable.

This behavior must remain valid.

### Desired behavior

* Add **queue patience decay**, independent from slot decay.
* Queue decay uses a **configurable multiplier** relative to slot decay.

  * Initial [PLAYTEST] target: `0.7–1.0`
  * **Do not hardcode** numbers.
* Queue decay must be strong enough to discourage ignoring the queue forever.
* Slot logic, strike logic, and lose logic remain unchanged.

### Architecture rules

* Patience math lives in **one system**, not sprinkled across queue/slot code.
* Decay **rates and multipliers are config**, not constants.
* Strike and lose rules are **domain logic**, not UI‑driven.
* UI only reflects patience; it never decides outcomes.

### Domain model

#### PatienceState (per client)

* `current_patience: float`
* `is_in_queue: bool`
* `is_in_service_slot: bool`
* `has_triggered_strike: bool`

#### PatienceConfig (shift‑level, single source of truth)

* `slot_decay_rate`
* `queue_decay_multiplier`
* `max_strikes`
* any future patience tuning knobs

No other place is allowed to define patience numbers.

### Decay logic (tick/update)

For each client:

1. Determine **mode**:

   * in service slot → slot decay
   * in queue → slot decay × queue multiplier
2. Apply decay deterministically over time.
3. On patience crossing `>0 → 0`:

   * trigger **one** strike,
   * block the relevant slot if applicable.
4. Do **not** retrigger strikes while at 0.

### Acceptance criteria (must all pass)

* [ ] Queue patience decays over time using a configurable multiplier.
* [ ] Slot patience behavior is unchanged.
* [ ] Strike counted **only once** per client on `>0 → 0`.
* [ ] Blocking one slot does not block the other (Behavior B preserved).
* [ ] Changing decay multipliers does not break existing flows.
* [ ] All patience/strike parameters live in **one shift config**.
* [ ] Results are deterministic under simulated time.

### Tests

#### Unit tests

* Slot vs queue decay rates apply correctly.
* Multiplier changes affect only queue decay.
* Strike triggers exactly once per client.
* No extra strikes at negative patience.

#### Simulation tests

* Fast‑forward time with:

  * clients only in queue,
  * clients moving queue → slot,
  * mixed blocked/unblocked slots.
* Verify:

  * no infinite queue stalling,
  * no premature game over.

### Debug / dev hooks

* Log events:

  * `PATIENCE_DECAY mode=queue rate=… client_id=…`
  * `PATIENCE_ZERO client_id=… strike_count=…`
* Optional dev override to tweak multipliers at runtime (playtest only).

### Constraints

* No UI‑side logic.
* No duplication of patience constants.
* Minimal refactors—centralize, don’t explode.
* Queue decay must be swappable/tunable without code changes.

### Expected files to touch

* Patience system / service.
* Shift config definitions.
* Queue + service slot integration points.
* Deterministic time‑based tests.

### Rollback plan

* Feature‑flag queue decay.
* If tuning fails:

  1. disable queue decay only,
  2. keep config + tests,
  3. re‑enable after retuning.

---

## Codex Task — Iteration 9 — Ghost: темнота / интерактивность

### Goal

Add **ghost archetype interaction rules** tied to light: in darkness, ghost items become **non‑interactive** (cannot be picked or moved); in light, they behave like normal items.

This is **MVP playtest mode C**: simple, readable, reversible.

### Context

Light logic already exists (queries, zones). Item archetypes already exist. We now connect them via **interaction permission**, not via UI hacks or input spaghetti.

No new light rules. No physics magic. Just a clean gate.

### Desired behavior (rules)

* Ghost items:

  * **In darkness**:

    * appear pale / bleached,
    * **cannot be picked or dragged**.
  * **In light**:

    * behave exactly like normal items.
* Optional [PLAYTEST]:

  * small **lock icon overlay** on the item when blocked,
  * no text,
  * must be trivial to toggle off.
* Non‑ghost items are completely unaffected.

### Architecture rules (important, don’t cheat)

* Ghost behavior is implemented as an **archetype effect**, not UI logic.
* Use the existing **Light Query Service** (`IsItemInLight`).
* Input / drag system must consult a **rule provider**, not item scripts.

### Interaction gate

#### Rule provider API (example)

* `ItemCanBePicked(item) -> bool`

Responsibilities:

* evaluate archetype effects (ghost),
* consult light state,
* return a single yes/no.

Input code **must not**:

* check light directly,
* check archetype directly,
* guess.

### Visual feedback

* Visuals react to **domain state**:

  * pale/bleached material when blocked,
  * normal look when allowed.
* Optional lock icon:

  * overlay only,
  * no logic inside,
  * disabled by config/flag.

UI does not decide rules. It only reflects them.

### Flow

On pick / drag attempt:

1. Input system calls `ItemCanBePicked(item)`.
2. If `false`:

   * cancel interaction,
   * play blocked feedback (visual only).
3. If `true`:

   * proceed normally.

Light changes:

* must immediately update:

  * pick permission,
  * visuals.

### Acceptance criteria (observable & testable)

* [ ] Ghost items cannot be picked **only** when in darkness.
* [ ] Ghost items are pickable again immediately when entering light.
* [ ] Visual feedback clearly communicates blocked state.
* [ ] Optional lock icon can be toggled off without code changes.
* [ ] Non‑ghost items behave exactly as before.
* [ ] No coupling between input system and light implementation details.

### Tests

#### Unit tests

* `ItemCanBePicked`:

  * ghost + light → `true`
  * ghost + dark → `false`
  * non‑ghost + any → `true`

#### Integration sanity

* Toggle light on/off → ghost pickability updates.
* Drag‑drop flows unchanged for normal items.

### Debug / dev notes

* Optional log:

  * `GHOST_PICK_BLOCKED item_id=… reason=darkness`
* Reuse light debug overlays if needed.

### Constraints

* No special‑casing in UI code.
* No light logic inside input handlers.
* Minimal refactors; extend rule provider pattern.
* Playtest‑friendly, easily revertible.

### Expected files to touch

* Ghost archetype effect logic.
* Item interaction rule provider.
* Input / drag gate integration.
* Item visual state handling.
* Unit tests for pick permission.

### Rollback plan

* Feature‑flag ghost interaction rule.
* Disable pick blocking first, keep visuals.
* Re‑enable in steps:

  1. rule provider,
  2. input gate,
  3. visuals.