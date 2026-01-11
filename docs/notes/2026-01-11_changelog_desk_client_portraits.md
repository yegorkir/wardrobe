# Changelog: Desk Client Portraits

- Replaced the workdesk client placeholder ColorRect with a TextureRect so the desk client visuals can show portrait textures.
- Updated the workdesk client UI adapter to resolve `portrait_key` into a texture (with caching and fallback) instead of tinting by coat color.
- Kept patience bar visibility behavior unchanged while switching desk client visuals to portraits.
