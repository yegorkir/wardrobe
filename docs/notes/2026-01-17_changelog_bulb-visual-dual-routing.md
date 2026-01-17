# Changelog: Bulb Visual Dual Routing

- Made LightSwitch the primary input by connecting it to LightService and reacting to bulb state changes.
- Updated BulbLightRig to listen for LightService bulb changes and forward updates to BulbVisual.
- Wired BulbRow rigs to drive BulbVisual while LightSwitch uses its own LightService setup.
- Avoided internal bulb hit testing when external visuals are present to keep click behavior stable.
