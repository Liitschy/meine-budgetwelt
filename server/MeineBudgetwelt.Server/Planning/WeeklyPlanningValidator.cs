using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace MeineBudgetwelt.Server.Planning;

public sealed partial class WeeklyPlanningValidator
{
    private const int MaximumBudgetCents = 1_000_000;
    private const int MaximumListEntries = 40;
    private const int MaximumTextLength = 120;

    public void ValidateRequest(WeeklyPlanningRequest request)
    {
        if (
            request.Allergies is null
            || request.ExcludedIngredients is null
            || request.PreferredIngredients is null
            || request.Pantry is null
            || request.PersonalPrices is null
        )
        {
            throw new PlanningInputException(
                "Die Planungslisten dürfen nicht leer übertragen werden.");
        }
        if (request.WeeklyBudgetCents is < 100 or > MaximumBudgetCents)
        {
            throw new PlanningInputException(
                "Das Wochenbudget muss zwischen 1,00 und 10.000,00 Euro liegen.");
        }
        if (
            request.SafetyBufferCents < 0
            || request.SafetyBufferCents >= request.WeeklyBudgetCents
        )
        {
            throw new PlanningInputException(
                "Der Sicherheitspuffer muss kleiner als das Wochenbudget sein.");
        }
        if (request.People is < 1 or > 12)
        {
            throw new PlanningInputException(
                "Die Personenanzahl muss zwischen 1 und 12 liegen.");
        }
        if (request.ServingsPerMeal is < 1 or > 24)
        {
            throw new PlanningInputException(
                "Die Portionen pro Gericht müssen zwischen 1 und 24 liegen.");
        }
        if (request.MaxActiveMinutes is < 5 or > 240)
        {
            throw new PlanningInputException(
                "Die aktive Kochzeit muss zwischen 5 und 240 Minuten liegen.");
        }

        ValidateShortText(request.DietaryStyle, "Ernährungsweise", required: true);
        ValidateShortText(request.PlanningStyle, "Planungsart", required: true);
        ValidateTextList(request.Allergies, "Allergien");
        ValidateTextList(request.ExcludedIngredients, "ausgeschlossene Zutaten");
        ValidateTextList(request.PreferredIngredients, "bevorzugte Zutaten");

        if (request.Pantry.Count > MaximumListEntries)
        {
            throw new PlanningInputException(
                "Es können höchstens 40 Vorräte berücksichtigt werden.");
        }
        foreach (var item in request.Pantry)
        {
            ValidateShortText(item.Name, "Vorratsname", required: true);
            ValidateShortText(item.Quantity, "Vorratsmenge", required: true);
        }

        if (request.PersonalPrices.Count > MaximumListEntries)
        {
            throw new PlanningInputException(
                "Es können höchstens 40 persönliche Preise berücksichtigt werden.");
        }
        foreach (var price in request.PersonalPrices)
        {
            ValidateShortText(price.Name, "Preisartikel", required: true);
            ValidateShortText(price.Quantity, "Preispackung", required: true);
            if (price.PriceCents is < 0 or > MaximumBudgetCents)
            {
                throw new PlanningInputException(
                    "Ein persönlicher Preis liegt außerhalb des gültigen Bereichs.");
            }
        }
    }

    public void ValidateDraft(
        WeeklyPlanningRequest request,
        WeeklyPlanningDraft draft)
    {
        if (
            draft.Days is null
            || draft.Recipes is null
            || draft.ShoppingItems is null
            || draft.Warnings is null
        )
        {
            throw InvalidDraft("Eine erforderliche Ergebnisliste fehlt.");
        }
        var planningTarget = request.WeeklyBudgetCents - request.SafetyBufferCents;
        if (!string.Equals(draft.Currency, "EUR", StringComparison.Ordinal))
        {
            throw InvalidDraft("Die Währung ist nicht EUR.");
        }
        if (
            draft.WeeklyBudgetCents != request.WeeklyBudgetCents
            || draft.SafetyBufferCents != request.SafetyBufferCents
            || draft.PlanningTargetCents != planningTarget
        )
        {
            throw InvalidDraft("Budget oder Sicherheitspuffer wurden verändert.");
        }
        if (string.IsNullOrWhiteSpace(draft.PriceBasis))
        {
            throw InvalidDraft("Die Preisbasis fehlt.");
        }
        if (draft.Days.Count != 7)
        {
            throw InvalidDraft("Der Entwurf enthält nicht genau sieben Tage.");
        }
        if (draft.Recipes.Count is < 1 or > 14)
        {
            throw InvalidDraft("Der Entwurf enthält eine ungültige Rezeptanzahl.");
        }
        if (draft.ShoppingItems.Count is < 1 or > 100)
        {
            throw InvalidDraft("Die Einkaufsliste hat eine ungültige Länge.");
        }

        var recipes = new Dictionary<string, WeeklyPlanningRecipe>(
            StringComparer.Ordinal);
        var requiredShoppingSources = new Dictionary<string, HashSet<string>>(
            StringComparer.Ordinal);
        foreach (var recipe in draft.Recipes)
        {
            ValidateIdentifier(recipe.Id, "Rezept-ID");
            if (!recipes.TryAdd(recipe.Id, recipe))
            {
                throw InvalidDraft("Eine Rezept-ID kommt mehrfach vor.");
            }
            ValidateShortOutput(recipe.Title, "Rezepttitel");
            ValidateShortOutput(recipe.Mode, "Zubereitungsart");
            if (recipe.Servings != request.ServingsPerMeal)
            {
                throw InvalidDraft("Eine Rezeptportion stimmt nicht mit der Planung überein.");
            }
            if (recipe.ActiveMinutes is < 1 or > 240)
            {
                throw InvalidDraft("Eine aktive Kochzeit ist ungültig.");
            }
            if (recipe.ActiveMinutes > request.MaxActiveMinutes)
            {
                throw InvalidDraft("Ein Rezept überschreitet die gewünschte aktive Kochzeit.");
            }
            if (recipe.EstimatedCostCents is < 0 or > MaximumBudgetCents)
            {
                throw InvalidDraft("Ein Rezeptpreis ist ungültig.");
            }
            if (recipe.Ingredients.Count is < 1 or > 40)
            {
                throw InvalidDraft("Eine Zutatenliste hat eine ungültige Länge.");
            }
            if (recipe.Preparation.Trim().Length is < 20 or > 4_000)
            {
                throw InvalidDraft("Eine Zubereitung ist unvollständig oder zu lang.");
            }
            foreach (var ingredient in recipe.Ingredients)
            {
                ValidateShortOutput(ingredient.Name, "Zutat");
                ValidateShortOutput(ingredient.Quantity, "Zutatenmenge");
                if (ingredient.EstimatedPriceCents is < 0 or > MaximumBudgetCents)
                {
                    throw InvalidDraft("Ein Zutatenpreis ist ungültig.");
                }
                ValidateTextListOutput(ingredient.Allergens, "Allergenangabe");
                EnsureAllowedIngredient(request, ingredient.Name, ingredient.Allergens);
                if (
                    ingredient.UsesPantry
                    && (ingredient.IncludeInShopping || ingredient.EstimatedPriceCents != 0)
                )
                {
                    throw InvalidDraft(
                        "Ein verwendeter Vorrat wurde zugleich als Einkauf berechnet.");
                }
                if (ingredient.IncludeInShopping)
                {
                    var ingredientName = Normalize(ingredient.Name);
                    if (!requiredShoppingSources.TryGetValue(
                        ingredientName,
                        out var recipeIds))
                    {
                        recipeIds = new HashSet<string>(StringComparer.Ordinal);
                        requiredShoppingSources[ingredientName] = recipeIds;
                    }
                    recipeIds.Add(recipe.Id);
                }
            }
        }

        var seenDays = new HashSet<int>();
        long dayTotal = 0;
        foreach (var day in draft.Days)
        {
            if (day.DayIndex is < 0 or > 6 || !seenDays.Add(day.DayIndex))
            {
                throw InvalidDraft("Die Wochentage sind unvollständig oder doppelt.");
            }
            ValidateShortOutput(day.Meal, "Gericht");
            ValidateShortOutput(day.Mode, "Tagesmodus");
            if (!recipes.TryGetValue(day.RecipeId, out var recipe))
            {
                throw InvalidDraft("Ein Wochentag verweist auf ein unbekanntes Rezept.");
            }
            if (day.Servings != request.ServingsPerMeal)
            {
                throw InvalidDraft("Eine Tagesportion stimmt nicht mit der Planung überein.");
            }
            if (day.EstimatedCostCents != recipe.EstimatedCostCents)
            {
                throw InvalidDraft("Tages- und Rezeptkosten stimmen nicht überein.");
            }
            ValidateOptionalOutput(day.MealPrepNote, "Meal-Prep-Hinweis", 300);
            ValidateOptionalOutput(day.LeftoverNote, "Resteverwertung", 300);
            dayTotal += day.EstimatedCostCents;
        }
        if (!draft.Days.Any(day => !string.IsNullOrWhiteSpace(day.MealPrepNote)))
        {
            throw InvalidDraft("Ein konkreter Meal-Prep-Hinweis fehlt.");
        }
        if (!draft.Days.Any(day => !string.IsNullOrWhiteSpace(day.LeftoverNote)))
        {
            throw InvalidDraft("Eine konkrete Resteverwertung fehlt.");
        }
        if (dayTotal > int.MaxValue || dayTotal != draft.EstimatedCostCents)
        {
            throw InvalidDraft(
                "Tageskosten und ausgewiesene Wochenkosten stimmen nicht überein.");
        }

        var seenShoppingItems = new HashSet<string>(StringComparer.Ordinal);
        long shoppingTotal = 0;
        foreach (var item in draft.ShoppingItems)
        {
            ValidateShortOutput(item.Name, "Einkaufsartikel");
            ValidateShortOutput(item.Quantity, "Einkaufsmenge");
            if (item.EstimatedPriceCents is < 0 or > MaximumBudgetCents)
            {
                throw InvalidDraft("Ein Einkaufspreis ist ungültig.");
            }
            var normalizedName = Normalize(item.Name);
            if (!seenShoppingItems.Add(normalizedName))
            {
                throw InvalidDraft("Ein Einkaufsartikel kommt mehrfach vor.");
            }
            if (!requiredShoppingSources.TryGetValue(
                normalizedName,
                out var requiredRecipeIds))
            {
                throw InvalidDraft(
                    "Ein Einkaufsartikel gehört zu keiner berechneten Rezeptzutat.");
            }
            ValidateTextListOutput(item.Allergens, "Allergenangabe");
            EnsureAllowedIngredient(request, item.Name, item.Allergens);
            if (item.RecipeIds.Count is < 1 or > 14)
            {
                throw InvalidDraft("Die Herkunft eines Einkaufsartikels fehlt.");
            }
            foreach (var recipeId in item.RecipeIds)
            {
                if (!recipes.ContainsKey(recipeId))
                {
                    throw InvalidDraft("Ein Einkaufsartikel verweist auf ein unbekanntes Rezept.");
                }
            }
            if (!requiredRecipeIds.IsSubsetOf(item.RecipeIds))
            {
                throw InvalidDraft(
                    "Ein Einkaufsartikel nennt nicht alle zugehörigen Rezepte.");
            }
            shoppingTotal += item.EstimatedPriceCents;
        }

        if (requiredShoppingSources.Keys.Any(name => !seenShoppingItems.Contains(name)))
        {
            throw InvalidDraft("Eine benötigte Rezeptzutat fehlt in der Einkaufsliste.");
        }

        if (shoppingTotal > int.MaxValue)
        {
            throw InvalidDraft("Die Einkaufssumme ist zu groß.");
        }
        var calculatedTotal = (int)shoppingTotal;
        if (draft.EstimatedCostCents != calculatedTotal)
        {
            throw InvalidDraft("Die ausgewiesene Einkaufssumme ist rechnerisch falsch.");
        }
        if (calculatedTotal > planningTarget)
        {
            throw InvalidDraft("Der Entwurf überschreitet das verbindliche Planungsziel.");
        }
        if (draft.RemainingCents != planningTarget - calculatedTotal)
        {
            throw InvalidDraft("Das verbleibende Budget ist rechnerisch falsch.");
        }
        ValidateTextListOutput(draft.Warnings, "Planungshinweis", 20, 300);
    }

    private static void EnsureAllowedIngredient(
        WeeklyPlanningRequest request,
        string name,
        IReadOnlyList<string> declaredAllergens)
    {
        foreach (var blocked in request.ExcludedIngredients)
        {
            if (MatchesBlockedTerm(name, blocked))
            {
                throw InvalidDraft(
                    $"Die ausgeschlossene Zutat '{blocked.Trim()}' ist im Entwurf enthalten.");
            }
        }

        foreach (var allergy in request.Allergies)
        {
            if (
                MatchesBlockedTerm(name, allergy)
                || declaredAllergens.Any(value => MatchesBlockedTerm(value, allergy))
            )
            {
                throw InvalidDraft(
                    $"Das Allergen '{allergy.Trim()}' ist im Entwurf enthalten.");
            }
        }
    }

    private static bool MatchesBlockedTerm(string candidate, string blocked)
    {
        var normalizedCandidate = Normalize(candidate);
        var normalizedBlocked = Normalize(blocked);
        if (normalizedBlocked.Length == 0)
        {
            return false;
        }
        if (normalizedBlocked.Length <= 3)
        {
            var words = WordRegex().Matches(normalizedCandidate)
                .Select(match => match.Value)
                .ToArray();
            if (words.Contains(normalizedBlocked, StringComparer.Ordinal))
            {
                return true;
            }
            return normalizedBlocked == "ei" && words.Any(word =>
                word.StartsWith("eier", StringComparison.Ordinal)
                || word.StartsWith("eip", StringComparison.Ordinal)
                || word.StartsWith("eiw", StringComparison.Ordinal));
        }
        return normalizedCandidate.Contains(normalizedBlocked, StringComparison.Ordinal);
    }

    private static string Normalize(string value)
    {
        var decomposed = value.Trim().ToLowerInvariant()
            .Replace("ß", "ss", StringComparison.Ordinal)
            .Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(decomposed.Length);
        foreach (var character in decomposed)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(character)
                != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(char.IsLetterOrDigit(character) ? character : ' ');
            }
        }
        return SpaceRegex().Replace(builder.ToString(), " ").Trim();
    }

    private static void ValidateTextList(IReadOnlyList<string> values, string field)
    {
        if (values.Count > MaximumListEntries)
        {
            throw new PlanningInputException(
                $"Das Feld '{field}' enthält zu viele Einträge.");
        }
        foreach (var value in values)
        {
            ValidateShortText(value, field, required: true);
        }
    }

    private static void ValidateTextListOutput(
        IReadOnlyList<string> values,
        string field,
        int maximumEntries = MaximumListEntries,
        int maximumLength = MaximumTextLength)
    {
        if (values.Count > maximumEntries)
        {
            throw InvalidDraft($"Das Feld '{field}' enthält zu viele Einträge.");
        }
        foreach (var value in values)
        {
            ValidateOptionalOutput(value, field, maximumLength);
        }
    }

    private static void ValidateShortText(string value, string field, bool required)
    {
        var clean = value?.Trim() ?? string.Empty;
        if ((required && clean.Length == 0) || clean.Length > MaximumTextLength)
        {
            throw new PlanningInputException(
                $"Das Feld '{field}' ist leer oder zu lang.");
        }
    }

    private static void ValidateShortOutput(string value, string field)
    {
        var clean = value?.Trim() ?? string.Empty;
        if (clean.Length == 0 || clean.Length > MaximumTextLength)
        {
            throw InvalidDraft($"Das Feld '{field}' ist leer oder zu lang.");
        }
    }

    private static void ValidateOptionalOutput(
        string value,
        string field,
        int maximumLength)
    {
        if ((value?.Trim().Length ?? 0) > maximumLength)
        {
            throw InvalidDraft($"Das Feld '{field}' ist zu lang.");
        }
    }

    private static void ValidateIdentifier(string value, string field)
    {
        if (!IdentifierRegex().IsMatch(value ?? string.Empty))
        {
            throw InvalidDraft($"Das Feld '{field}' ist ungültig.");
        }
    }

    private static PlanningOutputException InvalidDraft(string detail) =>
        new($"Der erzeugte Wochenplan wurde aus Sicherheitsgründen abgelehnt: {detail}");

    [GeneratedRegex("[a-z0-9]+", RegexOptions.CultureInvariant)]
    private static partial Regex WordRegex();

    [GeneratedRegex("\\s+", RegexOptions.CultureInvariant)]
    private static partial Regex SpaceRegex();

    [GeneratedRegex("^[a-z0-9][a-z0-9_-]{2,63}$", RegexOptions.CultureInvariant)]
    private static partial Regex IdentifierRegex();
}
