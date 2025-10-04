$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:7721/signoz/")
$listener.Start()
Write-Host "Listening on :7721/signoz/..." -ForegroundColor Green
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $body = New-Object IO.StreamReader($ctx.Request.InputStream, $ctx.Request.ContentEncoding)
  $json = $body.ReadToEnd()
  Write-Host "Webhook payload: $json" -ForegroundColor Cyan
  $resp = [Text.Encoding]::UTF8.GetBytes("ok")
  $ctx.Response.OutputStream.Write($resp,0,$resp.Length)
  $ctx.Response.Close()
}

