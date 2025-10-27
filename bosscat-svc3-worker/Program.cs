// Gate #029: bosscat-svc3-worker - Background Worker Service
// Authority: BossCat OEM | Executor: Cursor{Implementer}

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Background worker simulation
var workerTask = Task.Run(async () =>
{
    while (true)
    {
        Console.WriteLine($"[Worker] Heartbeat at {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss}");
        await Task.Delay(TimeSpan.FromSeconds(10));
    }
});

app.MapGet("/", () => new
{
    service = "bosscat-svc3-worker",
    status = "running",
    gate = "029",
    port = 5557,
    worker_active = workerTask.Status == TaskStatus.Running
});

app.MapGet("/health", () => new
{
    status = "healthy",
    service = "bosscat-svc3-worker",
    timestamp = DateTime.UtcNow,
    worker_active = true
});

app.Run();
