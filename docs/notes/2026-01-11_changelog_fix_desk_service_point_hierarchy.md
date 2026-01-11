# Changelog: Fix DeskServicePoint Hierarchy

- Restored the DeskServicePoint client UI nodes (ClientVisual, PatienceBarBg/Fill) to be direct children so adapter lookups work.
- Reapplied portrait and patience bar bounds after removing the extra Node2D wrapper.
