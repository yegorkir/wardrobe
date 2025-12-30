# 2025-12-24 — Step 5 Hotfix: EndShift drag safety (anti-race)

## Problem
Если завершить смену (end_shift) в момент, когда игрок держит предмет (DnD active / доменная “рука” занята),
сцена может закрыться/сменить экран, а состояние взаимодействия останется “грязным”.
Это приводит к:
- null instance errors при уходе сцены,
- “зависшему” предмету в руке (в домене),
- неконсистентным desk/slot состояниям при следующем заходе.

Сейчас кнопка EndShift привязана напрямую к `RunManager.end_shift()` через `WardrobeHudAdapter`,
то есть WorkdeskScene не может гарантировать безопасное завершение.

## Goal
Сделать завершение смены безопасным:
- EndShift запрещён/обрабатывается корректно, если активен drag.
- Перед `run_manager.end_shift()` выполняется принудительный cancel drag (и/или возврат предмета).
- При этом НЕ менять domain/app логику и НЕ рефакторить DnD.

## Scope
### Edit (allowed)
- `scripts/ui/workdesk_scene.gd`
- `scripts/ui/wardrobe_hud_adapter.gd` (только если нужно минимально убрать binding кнопки)
- (опционально) `scripts/ui/wardrobe_dragdrop_adapter.gd` (только add-only helper: `has_active_drag()`)

### Forbidden
- `scripts/domain/**`
- `scripts/app/**`
- Любые массовые рефакторы HUD/DnD
- Любые изменения логики EndShift в RunManager

## Implementation Plan

### Task A — Make EndShift orchestrated by WorkdeskScene
1) В `WorkdeskScene`:
    - подключить `_end_shift_button.pressed` к локальному обработчику `_on_end_shift_pressed()`.
2) Обеспечить, что `WardrobeHudAdapter` НЕ вызывает `run_manager.end_shift()` напрямую по кнопке в Workdesk режиме.
   Разрешены два варианта (выбрать самый простой по текущему коду):
    - Вариант 1 (лучший): HUD adapter больше не биндит pressed → end_shift вообще; только отображение.
    - Вариант 2 (минимально-инвазивный): HUD adapter получает `Callable`/флаг, и в Workdesk режиме кнопку не биндит.

Anti-footgun:
- Не ломать Wardrobe screen. Если Wardrobe использует тот же HUD adapter, убедиться, что для Wardrobe end_shift работает как раньше (или перевести Wardrobe тоже на оркестрацию сценой — только если это 1-2 строки и без риска).

### Task B — Guard + cancel drag before end_shift
В `WorkdeskScene._on_end_shift_pressed()`:
1) Если wave уже завершён: return.
2) Попытаться безопасно отменить drag:
    - Вызвать `_dragdrop_adapter.force_cancel_drag()` (если есть), иначе `_dragdrop_adapter.cancel_drag()`.
3) После cancel:
    - если drag был активен (см. Task C), то НЕ завершать смену в этот клик.
      (Это предотвращает “случайный EndShift” пока предмет в руке.)
    - можно добавить минимальный “reject” feedback (без текста): звук/вспышка (если уже есть общий reject эффект — использовать).
4) Если drag не активен:
    - выставить `_wave_finished = true` (общий guard)
    - вызвать `_run_manager.end_shift()`

### Task C — Minimal active-drag detection (no domain changes)
Нужен способ узнать “drag был активен”.
Приоритет (выбрать самый простой исходя из текущего кода):
1) Если у DragDropAdapter уже есть флаг `_is_dragging` или аналог — использовать (add-only getter).
2) Если нет:
    - добавить метод `has_active_drag() -> bool` в DragDropAdapter (add-only), который возвращает внутреннее состояние.
3) Не пытаться читать доменную “руку” напрямую через service — не трогать app/domain.

### Task D — Ensure wave timer/auto end uses the same safe finish
В местах, где WorkdeskScene завершает смену автоматически (WIN/FAIL таймер/терпение):
- заменить прямой `run_manager.end_shift()` на общий helper `_finish_shift_safe()`, который:
    - ставит guard `_wave_finished=true`
    - вызывает `_dragdrop_adapter.force_cancel_drag()` / `cancel_drag()`
    - затем вызывает `_run_manager.end_shift()`

Важно:
- Для auto-end (WIN/FAIL) можно завершать сразу после cancel_drag (без “второго клика”), т.к. это системное завершение.

## DoD
- При нажатии EndShift во время активного drag:
    - drag отменяется,
    - смена НЕ завершается в этот же клик,
    - ошибок/исключений нет.
- При нажатии EndShift без активного drag:
    - смена завершается штатно.
- При автоматическом WIN/FAIL:
    - drag (если был) отменяется,
    - смена завершается без ошибок.
- Wardrobe screen не сломан (EndShift работает как раньше).

## Quick manual test
1) Взять предмет в руку и нажать EndShift:
    - предмет возвращается/drag отменяется, сцена не закрывается.
2) Нажать EndShift ещё раз:
    - смена завершается.
3) Довести до auto FAIL (patience=0) держа предмет:
    - drag отменяется, смена завершается без ошибок.
