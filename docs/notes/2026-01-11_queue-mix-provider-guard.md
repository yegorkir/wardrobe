# Guarding optional queue mix provider

- Added a null check before calling `_queue_mix_provider.is_valid()` to avoid `Invalid call. Nonexistent function 'is_valid' in base 'Nil'` when no mix provider is configured.
- This keeps the default desk assignment flow functional in tests and scenes that don't wire the optional callback.

References:
- https://docs.godotengine.org/en/4.5/classes/class_callable.html
