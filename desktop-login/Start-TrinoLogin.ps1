# Serve the fixed sign-in page on loopback for the Desktop OAuth test.
$ErrorActionPreference = 'Stop'
$page = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'index.html'))
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 18765)
$listener.ExclusiveAddressUse = $true
try {
    $listener.Start()
    Write-Host 'Ready at http://127.0.0.1:18765/index.html. Leave this window open through sign-in. Press Ctrl+C to stop.'
    while ($true) {
        if (-not $listener.Pending()) {
            Start-Sleep -Milliseconds 100
            continue
        }
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 3000
            $client.SendTimeout = 3000
            $stream = $client.GetStream()
            # Read through the header terminator with a fixed size limit.
            $buffer = [byte[]]::new(8192)
            $count = 0
            do {
                $read = $stream.Read($buffer, $count, $buffer.Length - $count)
                if ($read -eq 0) { break }
                $count += $read
                $request = [Text.Encoding]::ASCII.GetString($buffer, 0, $count)
            } while ($count -lt $buffer.Length -and -not $request.Contains("`r`n`r`n"))
            if ($read -eq 0 -or -not $request.Contains("`r`n`r`n")) { continue }

            $body = [byte[]]::new(0)
            $status = '404 Not Found'
            if ($request -cmatch '^GET /index\.html HTTP/1\.[01]\r\n') {
                $status = '200 OK'
                $body = $page
            }
            $headers = "HTTP/1.1 $status`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
            $bytes = [Text.Encoding]::ASCII.GetBytes($headers)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Write($body, 0, $body.Length)
        } catch [System.IO.IOException] {
            # Browsers can close a speculative connection before sending a request.
        } finally {
            $client.Dispose()
        }
    }
} finally {
    $listener.Stop()
}
