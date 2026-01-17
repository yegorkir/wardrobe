# Shader tween parameter bugfix (2026-01-17)

## Context
Godot spams `ERROR: Error calling method from MethodTweener: 'ShaderMaterial::set_shader_parameter': Cannot convert argument 1 from float to StringName.` during runtime.

## Root cause
`ItemNode.set_ghost_appearance()` used `tween_method(mat.set_shader_parameter.bind("transparency"), ...)`. In Godot 4, `Callable.bind()` appends arguments, so the tween invoked `set_shader_parameter(value, "transparency")`, reversing the expected `(StringName, Variant)` order.

## Fix
- Add a helper method that receives the tweened float first and the shader material/parameter name after, then calls `set_shader_parameter(param, value)`.
- Swap the tween method targets to use the helper, and replace raw string keys with `StringName` constants.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- `"$GODOT_BIN" --path .`

## Docs
- Godot 4.5 `Callable.bind()`: https://docs.godotengine.org/en/4.5/classes/class_callable.html
- Godot 4.5 `Tween.tween_method()`: https://docs.godotengine.org/en/4.5/classes/class_tween.html#class-tween-method-tween-method
