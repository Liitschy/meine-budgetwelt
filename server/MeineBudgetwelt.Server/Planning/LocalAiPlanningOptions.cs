namespace MeineBudgetwelt.Server.Planning;

public sealed class LocalAiPlanningOptions
{
    public bool Enabled { get; init; }

    public string Endpoint { get; init; } =
        "http://127.0.0.1:11434/api/chat";

    public string Model { get; init; } = "qwen3.5:9b";

    public int ContextTokens { get; init; } = 16_384;

    public int TimeoutSeconds { get; init; } = 300;

    public string KeepAlive { get; init; } = "30m";
}
