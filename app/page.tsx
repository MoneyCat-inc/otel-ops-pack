// Simple Home Page
export default function Home() {
  return (
    <div style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1>Resonai Backend</h1>
      <p>OpenTelemetry-enabled Next.js application</p>
      
      <div style={{ marginTop: '2rem' }}>
        <h2>API Endpoints</h2>
        <ul>
          <li><a href="/api/health">Health Check</a></li>
          <li><a href="/api/auth/session">Auth Session</a></li>
        </ul>
      </div>

      <div style={{ marginTop: '2rem' }}>
        <h2>Observability</h2>
        <ul>
          <li><a href="http://localhost:8080" target="_blank">SigNoz UI</a></li>
          <li><a href="http://localhost:8080/logs" target="_blank">Logs</a></li>
          <li><a href="http://localhost:8080/traces" target="_blank">Traces</a></li>
        </ul>
      </div>
    </div>
  );
}



