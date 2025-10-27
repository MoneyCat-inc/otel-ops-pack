// Gate #029: bosscat-svc2-api - Simple HTTP API Service
// Authority: BossCat OEM | Executor: Cursor{Implementer}

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => new
{
    service = "bosscat-svc2-api",
    status = "running",
    gate = "029",
    port = 5556
});

app.MapGet("/health", () => new
{
    status = "healthy",
    service = "bosscat-svc2-api",
    timestamp = DateTime.UtcNow
});

app.MapGet("/test", async () =>
{
    // Simulate outbound call
    using var client = new HttpClient();
    var response = await client.GetStringAsync("http://localhost:8080/api/v1/version");
    
    return new
    {
        status = "ok",
        service = "bosscat-svc2-api",
        outbound_call = "success",
        response_preview = response.Length > 100 ? response.Substring(0, 100) : response
    };
});

app.Run();
