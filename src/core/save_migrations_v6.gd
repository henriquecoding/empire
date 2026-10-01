class_name SaveMigrationsV6
extends RefCounted
const OLD := "paul"
const NEW := "bruma"


static func apply(saved: Dictionary) -> void:
	var renamed: Dictionary = rename(saved)
	saved.clear()
	saved.merge(renamed)
	var world: Variant = saved.get(&"world", {})
	if world is Dictionary:
		for key in [&"seasons", &"camp_life", &"settlements", &"underground_sight", &"other_rot"]:
			if not world.has(key):
				world[key] = {}


static func rename(value: Variant) -> Variant:
	if value is String or value is StringName:
		var original := String(value)
		var result := (
			NEW + original.substr(OLD.length())
			if original == OLD or original.begins_with(OLD + "_")
			else original
		)
		return StringName(result) if value is StringName else result
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			result[rename(key)] = rename(value[key])
		return result
	if value is Array:
		var result := []
		for item: Variant in value:
			result.append(rename(item))
		return result
	if value is PackedStringArray:
		var result := PackedStringArray()
		for item in value:
			result.append(rename(item))
		return result
	return value
