extends RefCounted


static func calculate(values: Dictionary) -> Dictionary:
	var starting_balance := float(values.get("balance", 0.0))
	var additional_income := maxf(float(values.get("additional_income", 0.0)), 0.0)
	var weekly_credit_total := maxf(float(values.get("weekly_credit_total", 0.0)), 0.0)
	var balance := starting_balance + additional_income + weekly_credit_total
	var fixed_total := float(values.get("fixed_costs_total", 0.0))
	var fixed_paid := minf(float(values.get("fixed_costs_paid", 0.0)), fixed_total)
	var variable_expenses := maxf(float(values.get("variable_expenses", 0.0)), 0.0)
	var savings_payments := maxf(float(values.get("savings_payments", 0.0)), 0.0)
	var weekly_expenses := maxf(float(values.get("weekly_expenses", 0.0)), 0.0)
	var weekly_credit := maxf(float(values.get("weekly_credit", 0.0)), 0.0)
	var fixed_open := maxf(fixed_total - fixed_paid, 0.0)
	var available_now := maxf(
		balance - fixed_paid - variable_expenses - savings_payments,
		0.0
	)
	var freely_available := maxf(
		balance - fixed_total - variable_expenses - savings_payments,
		0.0
	)
	var weekly_free_budget := maxf(
		(balance - weekly_credit_total - fixed_total - savings_payments) / 4.0,
		0.0
	) + weekly_credit
	var weekly_budget_remaining := maxf(weekly_free_budget - weekly_expenses, 0.0)
	var savings_goal := float(values.get("savings_goal", 0.0))
	var remaining_savings_reserve := maxf(savings_goal - savings_payments, 0.0)
	var after_savings := maxf(freely_available - remaining_savings_reserve, 0.0)

	return {
		"balance": starting_balance,
		"effective_balance": balance,
		"current_balance": available_now,
		"additional_income": additional_income,
		"fixed_costs_total": fixed_total,
		"fixed_costs_paid": fixed_paid,
		"fixed_costs_open": fixed_open,
		"available_now": available_now,
		"freely_available": freely_available,
		"weekly_free_budget": weekly_free_budget,
		"weekly_expenses": weekly_expenses,
		"weekly_credit": weekly_credit,
		"weekly_credit_total": weekly_credit_total,
		"weekly_budget_remaining": weekly_budget_remaining,
		"after_savings": after_savings,
		"savings_goal": savings_goal,
		"savings_payments": savings_payments,
		"remaining_savings_reserve": remaining_savings_reserve,
		"variable_expenses": variable_expenses,
		"weekly_grocery_budget": float(values.get("weekly_grocery_budget", 0.0)),
	}
