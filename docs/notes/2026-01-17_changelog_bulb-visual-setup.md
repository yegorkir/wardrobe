# Changelog: Bulb Visual Setup

- Added an exported external visual node hook to `BulbVisual` so parent scenes can pass a `LightSwitch` instance directly.
- Implemented `set_is_on` to update bulb on/off sprites and keep the external visual in sync.
- Ensured the bulb visual initializes its sprites and external visual state on ready.
