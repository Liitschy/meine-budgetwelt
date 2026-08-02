extends Node

signal recipes_changed(recipes: Array)

var _recipes: Array = []


func _ready() -> void:
	reload_from_storage(false)


func reload_from_storage(emit_change: bool = true) -> void:
	_recipes = StorageManager.load_custom_recipes()
	if emit_change:
		recipes_changed.emit(get_recipes())


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
	preparation: String,
	details: Dictionary = {}
) -> String:
	var clean_title := title.strip_edges()
	var clean_ingredients: Array = []
	for raw_ingredient: Variant in ingredients:
		if not raw_ingredient is Dictionary:
			continue
		var ingredient: Dictionary = raw_ingredient
		var ingredient_name := str(ingredient.get("name", "")).strip_edges()
		var quantity := str(ingredient.get("quantity", "")).strip_edges()
		if ingredient_name.is_empty() or quantity.is_empty():
			continue
		var clean_ingredient := ingredient.duplicate(true)
		clean_ingredient.name = ingredient_name
		clean_ingredient.quantity = quantity
		clean_ingredient.estimated_price = maxf(
			float(ingredient.get("estimated_price", 0.0)),
			0.0
		)
		clean_ingredient.include_in_shopping = bool(
			ingredient.get("include_in_shopping", true)
		)
		clean_ingredients.append(clean_ingredient)
	if clean_title.is_empty() or clean_ingredients.is_empty() or preparation.strip_edges().is_empty():
		return ""
	var clean_id := recipe_id
	if clean_id.is_empty():
		clean_id = "custom_%d" % Time.get_ticks_usec()
	var previous := get_recipe(clean_id)
	var data := previous.duplicate(true)
	data.merge({
		"id": clean_id,
		"title": clean_title,
		"mode": mode.strip_edges() if not mode.strip_edges().is_empty() else "Normal kochen",
		"servings": clampi(int(details.get("servings", previous.get("servings", 2))), 1, 24),
		"active_minutes": clampi(int(details.get("active_minutes", previous.get("active_minutes", 30))), 1, 240),
		"ingredients": clean_ingredients,
		"preparation": preparation.strip_edges(),
		"custom": true,
		"favorite": bool(details.get("favorite", previous.get("favorite", false))),
		"estimated_cost": _ingredient_total(clean_ingredients),
	}, true)
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


func set_favorite(recipe_id: String, favorite: bool) -> bool:
	for index in _recipes.size():
		if str(_recipes[index].get("id", "")) == recipe_id:
			_recipes[index].favorite = favorite
			return _save_and_emit()
	return false


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


static func _ingredient_total(ingredients: Array) -> float:
	var total := 0.0
	for raw_ingredient: Variant in ingredients:
		if raw_ingredient is Dictionary:
			total += maxf(float(raw_ingredient.get("estimated_price", 0.0)), 0.0)
	return total
