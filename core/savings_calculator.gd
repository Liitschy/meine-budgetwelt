extends RefCounted


static func summarize(goals: Array) -> Dictionary:
	var target_total := 0.0
	var saved_total := 0.0
	var monthly_total := 0.0

	for goal: Variant in goals:
		if not goal is Dictionary:
			continue
		var target := maxf(float(goal.get("target_amount", 0.0)), 0.0)
		var saved := clampf(float(goal.get("saved_amount", 0.0)), 0.0, target)
		target_total += target
		saved_total += saved
		monthly_total += maxf(float(goal.get("monthly_contribution", 0.0)), 0.0)

	return {
		"target_total": target_total,
		"saved_total": saved_total,
		"remaining_total": maxf(target_total - saved_total, 0.0),
		"monthly_total": monthly_total,
		"progress": saved_total / target_total if target_total > 0.0 else 0.0,
	}


static func progress(goal: Dictionary) -> float:
	var target := maxf(float(goal.get("target_amount", 0.0)), 0.0)
	if target <= 0.0:
		return 0.0
	return clampf(float(goal.get("saved_amount", 0.0)) / target, 0.0, 1.0)

