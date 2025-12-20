# Wardrobe step3/interaction/item visual adapters

## Summary
- Split step3 initialization, desk interaction events, and item visual helpers into dedicated UI adapters.
- `wardrobe_scene.gd` now orchestrates adapter setup and delegates step3 init + desk event handling.

## References
- Callable (GDScript): https://docs.godotengine.org/en/4.5/classes/class_callable.html
- Color.from_string (Color): https://docs.godotengine.org/en/4.5/classes/class_color.html#class-color-method-from-string
