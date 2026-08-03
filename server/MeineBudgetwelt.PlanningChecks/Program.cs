using System.Net;
using System.Text;
using System.Text.Json;
using MeineBudgetwelt.Server.Planning;
using Microsoft.Extensions.Options;

var validator = new WeeklyPlanningValidator();
var request = new WeeklyPlanningRequest
{
    WeeklyBudgetCents = 7_000,
    SafetyBufferCents = 1_000,
    People = 2,
    ServingsPerMeal = 2,
    MaxActiveMinutes = 30,
    DietaryStyle = "Alles",
    PlanningStyle = "Meal-Prep und Resteverwertung",
};
var recipe = new WeeklyPlanningRecipe
{
    Id = "lentil_stew",
    Title = "Linseneintopf",
    Mode = "Vorkochen",
    Servings = 2,
    ActiveMinutes = 20,
    EstimatedCostCents = 100,
    Ingredients =
    [
        new WeeklyPlanningIngredient
        {
            Name = "Rote Linsen",
            Quantity = "500 g",
            EstimatedPriceCents = 250,
            IncludeInShopping = true,
            UsesPantry = false,
        },
    ],
    Preparation = "Alle Zutaten vorbereiten und den Eintopf vollständig gar kochen.",
};
var draft = new WeeklyPlanningDraft
{
    Currency = "EUR",
    PriceBasis = "Vorsichtige Schätzpreise; tatsächliche Kassenpreise können abweichen.",
    WeeklyBudgetCents = 7_000,
    SafetyBufferCents = 1_000,
    PlanningTargetCents = 6_000,
    EstimatedCostCents = 700,
    RemainingCents = 5_300,
    Days = Enumerable.Range(0, 7)
        .Select(day => new WeeklyPlanningDay
        {
            DayIndex = day,
            Meal = "Linseneintopf",
            Mode = day == 0 ? "Vorkochen" : "Reste",
            RecipeId = "lentil_stew",
            Servings = 2,
            EstimatedCostCents = 100,
            MealPrepNote = day == 0 ? "Mehrere Portionen vorbereiten." : string.Empty,
            LeftoverNote = day == 1 ? "Die vorbereitete Portion verwenden." : string.Empty,
        })
        .ToList(),
    Recipes = [recipe],
    ShoppingItems =
    [
        new WeeklyPlanningShoppingItem
        {
            Name = "Rote Linsen",
            Quantity = "500 g",
            EstimatedPriceCents = 700,
            RecipeIds = ["lentil_stew"],
        },
    ],
};

validator.ValidateRequest(request);
validator.ValidateDraft(request, draft);

ExpectRejected(
    () => validator.ValidateDraft(
        request,
        draft with
        {
            EstimatedCostCents = 6_100,
            RemainingCents = -100,
            ShoppingItems =
            [
                draft.ShoppingItems[0] with { EstimatedPriceCents = 6_100 },
            ],
        }),
    "Budgetüberschreitung");

ExpectRejected(
    () => validator.ValidateDraft(
        request with { Allergies = ["Erdnuss"] },
        draft with
        {
            Recipes =
            [
                recipe with
                {
                    Ingredients =
                    [
                        recipe.Ingredients[0] with { Allergens = ["Erdnuss"] },
                    ],
                },
            ],
        }),
    "Allergen");

ExpectRejected(
    () => validator.ValidateDraft(
        request with { ExcludedIngredients = ["Linsen"] },
        draft),
    "ausgeschlossene Zutat");

validator.ValidateDraft(
    request with { Allergies = ["Ei"] },
    draft with
    {
        Recipes =
        [
            recipe with
            {
                Ingredients =
                [
                    recipe.Ingredients[0] with { Name = "Reis" },
                ],
            },
        ],
        ShoppingItems =
        [
            draft.ShoppingItems[0] with { Name = "Reis" },
        ],
    });

ExpectRejected(
    () => validator.ValidateDraft(
        request with { Allergies = ["Ei"] },
        draft with
        {
            Recipes =
            [
                recipe with
                {
                    Ingredients =
                    [
                        recipe.Ingredients[0] with { Name = "Eier" },
                    ],
                },
            ],
        }),
    "kurzes Allergenwort");

ExpectRejected(
    () => validator.ValidateDraft(
        request,
        draft with
        {
            ShoppingItems =
            [
                draft.ShoppingItems[0] with { EstimatedPriceCents = 350 },
                draft.ShoppingItems[0] with { EstimatedPriceCents = 350 },
            ],
        }),
    "doppelter Einkaufsartikel");

ExpectRejected(
    () => validator.ValidateDraft(
        request,
        draft with
        {
            Days = draft.Days
                .Select(day => day with { EstimatedCostCents = 101 })
                .ToList(),
            Recipes = [recipe with { EstimatedCostCents = 101 }],
        }),
    "abweichende Summe der Tageskosten");

var handler = new FakeOllamaHandler(draft);
var localAi = new LocalAiWeeklyPlanningService(
    new HttpClient(handler),
    Options.Create(new LocalAiPlanningOptions
    {
        Enabled = true,
        Endpoint = "http://127.0.0.1:11434/api/chat",
        Model = "qwen3.5:4b",
        ContextTokens = 8_192,
        TimeoutSeconds = 30,
        KeepAlive = "5m",
    }));
var generated = await localAi.CreateDraftAsync(request, "test-user");
if (
    generated.Currency != "EUR"
    || generated.WeeklyBudgetCents != request.WeeklyBudgetCents
    || generated.SafetyBufferCents != request.SafetyBufferCents
    || generated.PlanningTargetCents != 6_000
    || generated.EstimatedCostCents != 1_750
    || generated.RemainingCents != 4_250
    || generated.Recipes.Single().EstimatedCostCents != 250
    || generated.Days.Any(day => day.Servings != 2 || day.EstimatedCostCents != 250)
    || generated.ShoppingItems.Count != 1
    || generated.ShoppingItems[0].EstimatedPriceCents != 1_750
    || generated.ShoppingItems[0].Quantity != "7 x 500 g"
)
{
    throw new InvalidOperationException(
        "Die deterministische Kosten- und Einkaufsnachberechnung ist fehlerhaft.");
}
validator.ValidateDraft(request, generated);

var presentationNormalized = WeeklyPlanningDraftNormalizer.Normalize(
    request,
    draft with
    {
        PriceBasis = string.Empty,
        Days = draft.Days.Select(day => day with
        {
            Meal = string.Empty,
            Mode = string.Empty,
            MealPrepNote = string.Empty,
            LeftoverNote = string.Empty,
        }).ToList(),
        Recipes = [recipe with { Title = string.Empty, Mode = string.Empty }],
        ShoppingItems = [],
    });
if (
    string.IsNullOrWhiteSpace(presentationNormalized.PriceBasis)
    || presentationNormalized.Recipes.Any(item =>
        string.IsNullOrWhiteSpace(item.Title) || string.IsNullOrWhiteSpace(item.Mode))
    || presentationNormalized.Days.Any(day =>
        string.IsNullOrWhiteSpace(day.Meal) || string.IsNullOrWhiteSpace(day.Mode))
    || !presentationNormalized.Days.Any(day =>
        !string.IsNullOrWhiteSpace(day.MealPrepNote))
    || !presentationNormalized.Days.Any(day =>
        !string.IsNullOrWhiteSpace(day.LeftoverNote))
)
{
    throw new InvalidOperationException(
        "Fehlende Darstellungsfelder wurden nicht sicher normalisiert.");
}
validator.ValidateDraft(request, presentationNormalized);

var pantryRecipe = recipe with
{
    Ingredients =
    [
        recipe.Ingredients[0],
        new WeeklyPlanningIngredient
        {
            Name = "Vorratsreis",
            Quantity = "250 g",
            EstimatedPriceCents = 999,
            IncludeInShopping = true,
            UsesPantry = true,
        },
    ],
};
var pantryNormalized = WeeklyPlanningDraftNormalizer.Normalize(
    request,
    draft with { Recipes = [pantryRecipe], ShoppingItems = [] });
if (
    pantryNormalized.Recipes[0].Ingredients[1].EstimatedPriceCents != 0
    || pantryNormalized.Recipes[0].Ingredients[1].IncludeInShopping
    || pantryNormalized.ShoppingItems.Any(item => item.Name == "Vorratsreis")
)
{
    throw new InvalidOperationException(
        "Vorratszutaten wurden nicht kostenfrei aus dem Einkauf entfernt.");
}
validator.ValidateDraft(request, pantryNormalized);

var aggregateRecipe = recipe with
{
    Ingredients =
    [
        recipe.Ingredients[0],
        recipe.Ingredients[0] with
        {
            Name = "ROTE-LINSEN",
            Quantity = "250 g",
            EstimatedPriceCents = 100,
        },
    ],
};
var aggregated = WeeklyPlanningDraftNormalizer.Normalize(
    request,
    draft with { Recipes = [aggregateRecipe], ShoppingItems = [] });
if (
    aggregated.EstimatedCostCents != 2_450
    || aggregated.ShoppingItems.Count != 1
    || aggregated.ShoppingItems[0].EstimatedPriceCents != 2_450
    || aggregated.ShoppingItems[0].Quantity != "7 x 500 g + 7 x 250 g"
)
{
    throw new InvalidOperationException(
        "Gleiche Einkaufsartikel wurden nicht korrekt zusammengefasst.");
}
validator.ValidateDraft(request, aggregated);

var smallBudgetRequest = request with
{
    WeeklyBudgetCents = 2_000,
    SafetyBufferCents = 0,
};
var overBudget = WeeklyPlanningDraftNormalizer.Normalize(
    smallBudgetRequest,
    draft with { Recipes = [aggregateRecipe], ShoppingItems = [] });
ExpectRejected(
    () => validator.ValidateDraft(smallBudgetRequest, overBudget),
    "deterministisch erkannte Budgetueberschreitung");

if (!handler.ContractVerified)
{
    throw new InvalidOperationException(
        "Der lokale Ollama-Vertrag wurde nicht vollständig geprüft.");
}
var missingModelHandler = new FakeOllamaHandler(
    draft,
    ["qwen3.5:9b"]);
var missingModelAi = new LocalAiWeeklyPlanningService(
    new HttpClient(missingModelHandler),
    Options.Create(new LocalAiPlanningOptions
    {
        Enabled = true,
        Endpoint = "http://127.0.0.1:11434/api/chat",
        Model = "qwen3.5:4b",
        ContextTokens = 8_192,
        TimeoutSeconds = 30,
        KeepAlive = "5m",
    }));
var missingModelRejected = false;
try
{
    _ = await missingModelAi.CreateDraftAsync(request, "missing-model-user");
}
catch (PlanningUnavailableException exception)
    when (exception.Message.Contains("qwen3.5:4b", StringComparison.Ordinal))
{
    missingModelRejected = true;
}
if (!missingModelRejected || missingModelHandler.ContractVerified)
{
    throw new InvalidOperationException(
        "Ein fehlendes 4B-Modell darf nicht unbemerkt auf das langsame 9B-Modell fallen.");
}
ExpectUnsafeEndpointRejected();

Console.WriteLine("Lokale KI-Planung: Validator und Ollama-Vertrag bestanden.");

static void ExpectRejected(Action action, string caseName)
{
    try
    {
        action();
    }
    catch (PlanningOutputException)
    {
        return;
    }
    throw new InvalidOperationException(
        $"Ungültiger Fall wurde nicht abgelehnt: {caseName}");
}

static void ExpectUnsafeEndpointRejected()
{
    try
    {
        _ = new LocalAiWeeklyPlanningService(
            new HttpClient(new FakeOllamaHandler(new WeeklyPlanningDraft())),
            Options.Create(new LocalAiPlanningOptions
            {
                Enabled = true,
                Endpoint = "https://ki.example.com/api/chat",
            }));
    }
    catch (InvalidOperationException)
    {
        return;
    }
    throw new InvalidOperationException(
        "Eine entfernte KI-Adresse wurde nicht abgelehnt.");
}

sealed class FakeOllamaHandler : HttpMessageHandler
{
    private readonly WeeklyPlanningDraft _draft;
    private readonly IReadOnlyList<string> _installedModels;
    private readonly string _expectedModel;

    public FakeOllamaHandler(
        WeeklyPlanningDraft draft,
        IReadOnlyList<string>? installedModels = null,
        string expectedModel = "qwen3.5:4b")
    {
        _draft = draft;
        _installedModels = installedModels ?? ["qwen3.5:4b", "qwen3.5:9b"];
        _expectedModel = expectedModel;
    }

    public bool ContractVerified { get; private set; }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        if (
            request.Method == HttpMethod.Get
            && request.RequestUri?.AbsoluteUri == "http://127.0.0.1:11434/api/tags"
        )
        {
            var tagsJson = JsonSerializer.Serialize(new
            {
                models = _installedModels.Select(name => new { name }),
            });
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(tagsJson, Encoding.UTF8, "application/json"),
            };
        }
        if (
            request.Method != HttpMethod.Post
            || request.RequestUri?.AbsoluteUri != "http://127.0.0.1:11434/api/chat"
            || request.Headers.Authorization is not null
        )
        {
            throw new InvalidOperationException(
                "Die lokale KI-Anfrage verwendet einen unsicheren Transport.");
        }
        var body = await request.Content!.ReadAsStringAsync(cancellationToken);
        using var requestDocument = JsonDocument.Parse(body);
        var root = requestDocument.RootElement;
        var recipesSchema = root.GetProperty("format")
            .GetProperty("properties")
            .GetProperty("recipes");
        var ingredientsSchema = recipesSchema.GetProperty("items")
            .GetProperty("properties")
            .GetProperty("ingredients");
        if (
            root.GetProperty("model").GetString() != _expectedModel
            || root.GetProperty("stream").GetBoolean()
            || root.GetProperty("think").GetBoolean()
            || root.GetProperty("options").GetProperty("num_predict").GetInt32() != 1_280
            || root.GetProperty("options").GetProperty("num_ctx").GetInt32() != 8_192
            || root.GetProperty("format").GetProperty("type").GetString() != "object"
            || root.GetProperty("format").GetProperty("properties")
                .TryGetProperty("shoppingItems", out _)
            || recipesSchema.GetProperty("minItems").GetInt32() != 3
            || recipesSchema.GetProperty("maxItems").GetInt32() != 3
            || ingredientsSchema.GetProperty("maxItems").GetInt32() != 6
            || root.GetProperty("messages").GetArrayLength() != 2
        )
        {
            throw new InvalidOperationException(
                "Die Ollama-Anfrage erzwingt nicht den erwarteten Planungsvertrag.");
        }
        ContractVerified = true;
        var planJson = JsonSerializer.Serialize(
            _draft,
            new JsonSerializerOptions(JsonSerializerDefaults.Web));
        var responseJson = JsonSerializer.Serialize(new
        {
            model = _expectedModel,
            message = new { role = "assistant", content = planJson },
            done = true,
        });
        return new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(responseJson, Encoding.UTF8, "application/json"),
        };
    }
}
