extends Node

signal recipes_changed(recipes: Array)

var _recipes: Array = []


func _ready() -> void:
	_recipes = StorageManager.load_custom_recipes()


func get_recipes() -> Array:
	return _recipes.duplicate(true)


func get_recipe(recipe_id: String) -> Dictionary:
	for recipe: Dictionary in _recipes:
		if str(recipe.get("id", "")) == recipe_id:
			return recipe.duplicate(true)
	return {}


func save_recipe(
	recipe_id: String,
	title: String,
	mode: String,
	ingredients: Array,
	preparation: String
) -> String:
	var clean_title := title.strip_edges()
	if clean_title.is_empty() or ingredients.is_empty() or preparation.strip_edges().is_empty():
		return ""
	var clean_id := recipe_id
	if clean_id.is_empty():
		clean_id = "custom_%d" % Time.get_ticks_usec()
	var data := {
		"id": clean_id,
		"title": clean_title,
		"mode": mode,
		"ingredients": ingredients.duplicate(true),
		"preparation": preparation.strip_edges(),
		"custom": true,
	}
	var replaced := false
	for index in _recipes.size():
		if str(_recipes[index].get("id", "")) == clean_id:
			_recipes[index] = data
			replaced = true
			break
	if not replaced:
		_recipes.append(data)
	_save_and_emit()
	return clean_id


func remove_recipe(recipe_id: String) -> bool:
	for index in _recipes.size():
		if str(_recipes[index].get("id", "")) == recipe_id:
			_recipes.remove_at(index)
			return _save_and_emit()
	return false


static func parse_ingredients(text: String) -> Array:
	var result: Array = []
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("|")
		if parts.size() < 3:
			continue
		var name := parts[0].strip_edges()
		var quantity := parts[1].strip_edges()
		var price_text := parts[2].strip_edges().replace(",", ".").replace("€", "")
		if name.is_empty() or quantity.is_empty() or not price_text.is_valid_float():
			continue
		result.append({
			"name": name,
			"quantity": quantity,
			"estimated_price": maxf(price_text.to_float(), 0.0),
		})
	return result


static func ingredients_to_text(ingredients: Array) -> String:
	var lines: Array[String] = []
	for ingredient: Dictionary in ingredients:
		lines.append("%s | %s | %.2f" % [
			str(ingredient.get("name", "")),
			str(ingredient.get("quantity", "")),
			float(ingredient.get("estimated_price", 0.0)),
		])
	return "\n".join(lines)


func _save_and_emit() -> bool:
	var saved := StorageManager.save_custom_recipes(_recipes)
	recipes_changed.emit(get_recipes())
	return saved
