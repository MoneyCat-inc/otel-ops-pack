// Gate #026: minimal ASP.NET Core target for k6 performance gates (port 5555)

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => new
{
    service = "dotnet-test-gate026",
    status = "running",
    gate = "026"
});

app.MapGet("/health", () => new
{
    status = "healthy",
    service = "dotnet-test-gate026",
    timestamp = DateTime.UtcNow
});

app.MapGet("/test", () => new
{
    status = "ok",
    service = "dotnet-test-gate026"
});

app.Run("http://0.0.0.0:5555");
