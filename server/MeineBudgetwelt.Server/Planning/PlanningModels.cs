namespace MeineBudgetwelt.Server.Planning;

public sealed record WeeklyPlanningRequest
{
    public int WeeklyBudgetCents { get; init; }

    public int SafetyBufferCents { get; init; }

    public int People { get; init; }

    public int ServingsPerMeal { get; init; }

    public int MaxActiveMinutes { get; init; }

    public string DietaryStyle { get; init; } = string.Empty;

    public string PlanningStyle { get; init; } = string.Empty;

    public List<string> Allergies { get; init; } = [];

    public List<string> ExcludedIngredients { get; init; } = [];

    public List<string> PreferredIngredients { get; init; } = [];

    public List<PlanningPantryItem> Pantry { get; init; } = [];

    public List<PlanningPersonalPrice> PersonalPrices { get; init; } = [];
}

public sealed record PlanningPantryItem
{
    public string Name { get; init; } = string.Empty;

    public string Quantity { get; init; } = string.Empty;
}

public sealed record PlanningPersonalPrice
{
    public string Name { get; init; } = string.Empty;

    public string Quantity { get; init; } = string.Empty;

    public int PriceCents { get; init; }
}

public sealed record WeeklyPlanningDraft
{
    public string Currency { get; init; } = string.Empty;

    public string PriceBasis { get; init; } = string.Empty;

    public int WeeklyBudgetCents { get; init; }

    public int SafetyBufferCents { get; init; }

    public int PlanningTargetCents { get; init; }

    public int EstimatedCostCents { get; init; }

    public int RemainingCents { get; init; }

    public List<WeeklyPlanningDay> Days { get; init; } = [];

    public List<WeeklyPlanningRecipe> Recipes { get; init; } = [];

    public List<WeeklyPlanningShoppingItem> ShoppingItems { get; init; } = [];

    public List<string> Warnings { get; init; } = [];
}

public sealed record WeeklyPlanningDay
{
    public int DayIndex { get; init; }

    public string Meal { get; init; } = string.Empty;

    public string Mode { get; init; } = string.Empty;

    public string RecipeId { get; init; } = string.Empty;

    public int Servings { get; init; }

    public int EstimatedCostCents { get; init; }

    public string MealPrepNote { get; init; } = string.Empty;

    public string LeftoverNote { get; init; } = string.Empty;
}

public sealed record WeeklyPlanningRecipe
{
    public string Id { get; init; } = string.Empty;

    public string Title { get; init; } = string.Empty;

    public string Mode { get; init; } = string.Empty;

    public int Servings { get; init; }

    public int ActiveMinutes { get; init; }

    public int EstimatedCostCents { get; init; }

    public List<WeeklyPlanningIngredient> Ingredients { get; init; } = [];

    public string Preparation { get; init; } = string.Empty;
}

public sealed record WeeklyPlanningIngredient
{
    public string Name { get; init; } = string.Empty;

    public string Quantity { get; init; } = string.Empty;

    public int EstimatedPriceCents { get; init; }

    public bool IncludeInShopping { get; init; }

    public bool UsesPantry { get; init; }

    public List<string> Allergens { get; init; } = [];
}

public sealed record WeeklyPlanningShoppingItem
{
    public string Name { get; init; } = string.Empty;

    public string Quantity { get; init; } = string.Empty;

    public int EstimatedPriceCents { get; init; }

    public List<string> RecipeIds { get; init; } = [];

    public List<string> Allergens { get; init; } = [];
}

public sealed class PlanningInputException(string message)
    : Exception(message);

public sealed class PlanningOutputException(string message)
    : Exception(message);

public sealed class PlanningProviderException(string message, Exception? inner = null)
    : Exception(message, inner);

public sealed class PlanningUnavailableException(string message)
    : Exception(message);
