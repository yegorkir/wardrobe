# Step 3 setup context (P1.3)

## Summary
- Introduced `scripts/ui/wardrobe_step3_setup_context.gd` to group Step 3 setup dependencies.
- Updated `scripts/ui/wardrobe_step3_setup.gd` to accept a context object instead of many parameters.
- Updated `scripts/ui/wardrobe_scene.gd` to build and pass the context.

## Rationale
- Reduces configure-parameter sprawl while keeping setup logic centralized.
- Makes future additions to Step 3 setup dependencies less error-prone.

## Notes
- Context is a `RefCounted` data container to keep UI adapter dependencies together.

## References
- Godot 4.5 GDScript basics (classes, references): https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_basics.html
