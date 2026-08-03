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
        Model = "qwen3.5:9b",
        ContextTokens = 16_384,
        TimeoutSeconds = 30,
        KeepAlive = "30m",
    }));
var generated = await localAi.CreateDraftAsync(request, "test-user");
validator.ValidateDraft(request, generated);
if (!handler.ContractVerified)
{
    throw new InvalidOperationException(
        "Der lokale Ollama-Vertrag wurde nicht vollständig geprüft.");
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

sealed class FakeOllamaHandler(WeeklyPlanningDraft draft) : HttpMessageHandler
{
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
                models = new[] { new { name = "qwen3.5:9b" } },
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
        if (
            root.GetProperty("model").GetString() != "qwen3.5:9b"
            || root.GetProperty("stream").GetBoolean()
            || root.GetProperty("think").GetBoolean()
            || root.GetProperty("format").GetProperty("type").GetString() != "object"
            || root.GetProperty("messages").GetArrayLength() != 2
        )
        {
            throw new InvalidOperationException(
                "Die Ollama-Anfrage erzwingt nicht den erwarteten Planungsvertrag.");
        }
        ContractVerified = true;
        var planJson = JsonSerializer.Serialize(
            draft,
            new JsonSerializerOptions(JsonSerializerDefaults.Web));
        var responseJson = JsonSerializer.Serialize(new
        {
            model = "qwen3.5:9b",
            message = new { role = "assistant", content = planJson },
            done = true,
        });
        return new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(responseJson, Encoding.UTF8, "application/json"),
        };
    }
}
