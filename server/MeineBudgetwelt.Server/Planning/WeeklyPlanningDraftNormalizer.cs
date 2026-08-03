namespace MeineBudgetwelt.Server.Planning;

internal static class WeeklyPlanningDraftNormalizer
{
    public static WeeklyPlanningDraft Normalize(
        WeeklyPlanningRequest request,
        WeeklyPlanningDraft draft)
    {
        if (draft.Days is null || draft.Recipes is null)
        {
            throw new PlanningOutputException(
                "Die lokale KI hat keinen vollständigen Plan geliefert.");
        }

        var usageCounts = draft.Days
            .GroupBy(day => day.RecipeId, StringComparer.Ordinal)
            .ToDictionary(group => group.Key, group => group.Count(), StringComparer.Ordinal);
        var recipes = draft.Recipes.Select(recipe => NormalizeRecipe(request, recipe)).ToList();
        var recipeLookup = new Dictionary<string, WeeklyPlanningRecipe>(StringComparer.Ordinal);
        foreach (var recipe in recipes)
        {
            recipeLookup.TryAdd(recipe.Id, recipe);
        }
        var days = draft.Days.Select(day =>
        {
            recipeLookup.TryGetValue(day.RecipeId, out var referencedRecipe);
            return day with
            {
                Meal = NormalizeDisplayText(
                    day.Meal,
                    referencedRecipe?.Title ?? "Tagesgericht",
                    120),
                Mode = NormalizeDisplayText(
                    day.Mode,
                    referencedRecipe?.Mode ?? "Einfach zubereiten",
                    120),
                Servings = request.ServingsPerMeal,
                EstimatedCostCents = referencedRecipe?.EstimatedCostCents ?? 0,
                MealPrepNote = NormalizeOptionalText(day.MealPrepNote, 300),
                LeftoverNote = NormalizeOptionalText(day.LeftoverNote, 300),
            };
        }).ToList();
        EnsurePlanningNotes(days);
        var shopping = BuildShoppingItems(recipes, usageCounts);
        var estimatedCost = CheckedSum(shopping.Select(item => item.EstimatedPriceCents));
        var planningTarget = request.WeeklyBudgetCents - request.SafetyBufferCents;

        return draft with
        {
            Currency = "EUR",
            PriceBasis = NormalizeDisplayText(
                draft.PriceBasis,
                "Vorsichtige lokale Schaetzpreise.",
                220),
            WeeklyBudgetCents = request.WeeklyBudgetCents,
            SafetyBufferCents = request.SafetyBufferCents,
            PlanningTargetCents = planningTarget,
            EstimatedCostCents = estimatedCost,
            RemainingCents = planningTarget - estimatedCost,
            Days = days,
            Recipes = recipes,
            ShoppingItems = shopping,
            Warnings = (draft.Warnings ?? [])
                .Take(20)
                .Select(value => NormalizeOptionalText(value, 300))
                .ToList(),
        };
    }

    private static WeeklyPlanningRecipe NormalizeRecipe(
        WeeklyPlanningRequest request,
        WeeklyPlanningRecipe recipe)
    {
        if (recipe.Ingredients is null)
        {
            throw new PlanningOutputException(
                "Die lokale KI hat ein Rezept ohne Zutaten geliefert.");
        }
        var ingredients = recipe.Ingredients.Select(ingredient => ingredient with
        {
            EstimatedPriceCents = ingredient.UsesPantry ? 0 : ingredient.EstimatedPriceCents,
            IncludeInShopping = !ingredient.UsesPantry && ingredient.IncludeInShopping,
            Allergens = ingredient.Allergens ?? [],
        }).ToList();
        var recipeCost = CheckedSum(ingredients
            .Where(ingredient => ingredient.IncludeInShopping)
            .Select(ingredient => ingredient.EstimatedPriceCents));
        return recipe with
        {
            Title = NormalizeDisplayText(recipe.Title, "Wochenrezept", 120),
            Mode = NormalizeDisplayText(recipe.Mode, "Einfach zubereiten", 120),
            Servings = request.ServingsPerMeal,
            EstimatedCostCents = recipeCost,
            Ingredients = ingredients,
        };
    }

    private static void EnsurePlanningNotes(List<WeeklyPlanningDay> days)
    {
        var repeatedDays = days
            .GroupBy(day => day.RecipeId, StringComparer.Ordinal)
            .Where(group => group.Count() > 1)
            .Select(group => group.OrderBy(day => day.DayIndex).ToArray())
            .FirstOrDefault();
        if (repeatedDays is null)
        {
            return;
        }
        if (!days.Any(day => !string.IsNullOrWhiteSpace(day.MealPrepNote)))
        {
            var firstIndex = days.FindIndex(day => ReferenceEquals(day, repeatedDays[0]));
            if (firstIndex >= 0)
            {
                days[firstIndex] = days[firstIndex] with
                {
                    MealPrepNote = "Portionen fuer einen weiteren Tag vorbereiten.",
                };
            }
        }
        if (!days.Any(day => !string.IsNullOrWhiteSpace(day.LeftoverNote)))
        {
            var secondIndex = days.FindIndex(day => ReferenceEquals(day, repeatedDays[1]));
            if (secondIndex >= 0)
            {
                days[secondIndex] = days[secondIndex] with
                {
                    LeftoverNote = "Die vorbereitete Portion verwenden.",
                };
            }
        }
    }

    private static string NormalizeDisplayText(
        string? value,
        string fallback,
        int maximumLength)
    {
        var normalized = string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();
        return normalized.Length <= maximumLength
            ? normalized
            : normalized[..maximumLength].TrimEnd();
    }

    private static string NormalizeOptionalText(string? value, int maximumLength)
    {
        var normalized = value?.Trim() ?? string.Empty;
        return normalized.Length <= maximumLength
            ? normalized
            : normalized[..maximumLength].TrimEnd();
    }    private static List<WeeklyPlanningShoppingItem> BuildShoppingItems(
        IReadOnlyList<WeeklyPlanningRecipe> recipes,
        IReadOnlyDictionary<string, int> usageCounts)
    {
        var accumulators = new Dictionary<string, ShoppingAccumulator>(StringComparer.Ordinal);
        foreach (var recipe in recipes)
        {
            var usageCount = Math.Max(1, usageCounts.GetValueOrDefault(recipe.Id));
            foreach (var ingredient in recipe.Ingredients.Where(item => item.IncludeInShopping))
            {
                var key = WeeklyPlanningValidator.NormalizeForComparison(ingredient.Name);
                if (!accumulators.TryGetValue(key, out var accumulator))
                {
                    accumulator = new ShoppingAccumulator(ingredient.Name.Trim());
                    accumulators.Add(key, accumulator);
                }
                accumulator.Add(ingredient, recipe.Id, usageCount);
            }
        }
        return accumulators.Values
            .OrderBy(item => item.Name, StringComparer.OrdinalIgnoreCase)
            .Select(item => item.ToItem())
            .ToList();
    }

    private static int CheckedSum(IEnumerable<int> values)
    {
        long total = 0;
        foreach (var value in values)
        {
            total += value;
            if (total is < int.MinValue or > int.MaxValue)
            {
                throw new PlanningOutputException(
                    "Die lokale KI hat eine ungültige Kostensumme geliefert.");
            }
        }
        return (int)total;
    }

    private sealed class ShoppingAccumulator(string name)
    {
        private long _priceCents;
        private readonly List<string> _quantities = [];
        private readonly HashSet<string> _recipeIds = new(StringComparer.Ordinal);
        private readonly HashSet<string> _allergens = new(StringComparer.OrdinalIgnoreCase);

        public string Name { get; } = name;

        public void Add(WeeklyPlanningIngredient ingredient, string recipeId, int usageCount)
        {
            _priceCents += (long)ingredient.EstimatedPriceCents * usageCount;
            if (_priceCents is < int.MinValue or > int.MaxValue)
            {
                throw new PlanningOutputException(
                    "Die lokale KI hat eine ungültige Einkaufssumme geliefert.");
            }
            var quantity = ingredient.Quantity.Trim();
            _quantities.Add(usageCount > 1 ? $"{usageCount} x {quantity}" : quantity);
            _recipeIds.Add(recipeId);
            foreach (var allergen in ingredient.Allergens)
            {
                _allergens.Add(allergen);
            }
        }

        public WeeklyPlanningShoppingItem ToItem()
        {
            var quantities = _quantities.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
            var quantity = string.Join(" + ", quantities);
            if (quantity.Length > 120)
            {
                quantity = $"{quantities.Length} Rezeptmengen";
            }
            return new WeeklyPlanningShoppingItem
            {
                Name = Name,
                Quantity = quantity,
                EstimatedPriceCents = (int)_priceCents,
                RecipeIds = _recipeIds.OrderBy(value => value, StringComparer.Ordinal).ToList(),
                Allergens = _allergens.OrderBy(value => value, StringComparer.OrdinalIgnoreCase).ToList(),
            };
        }
    }
}
