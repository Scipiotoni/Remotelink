# RemoteLink one-line installer for Windows. Press Win+R, paste this line and press Enter:
#   powershell -ep bypass -c "irm https://scipiotoni.github.io/Remotelink/install.ps1 | iex"
# Downloads RemoteLink.zip, puts the PC app in %LOCALAPPDATA%\Programs\RemoteLink, installs it (no admin
# rights needed) and opens the setup window. Running it again updates RemoteLink and keeps your settings.
& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $dir = Join-Path $env:LOCALAPPDATA 'Programs\RemoteLink'
  $tmp = Join-Path $env:TEMP ('rl-get-' + [guid]::NewGuid().ToString('N'))
  try {
    Write-Host ''
    Write-Host '  Downloading RemoteLink...' -ForegroundColor Cyan
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $zip = Join-Path $tmp 'RemoteLink.zip'
    Invoke-WebRequest 'https://scipiotoni.github.io/Remotelink/RemoteLink.zip' -OutFile $zip -UseBasicParsing
    Expand-Archive $zip (Join-Path $tmp 'x') -Force
    $src = Join-Path $tmp 'x\RemoteLink\host'
    if (-not (Test-Path (Join-Path $src 'install.ps1'))) { throw 'The download looks incomplete.' }

    # stop a running copy from this folder so its files can be replaced
    Get-Process electron -ErrorAction SilentlyContinue |
      Where-Object { $_.Path -and $_.Path.StartsWith($dir, [StringComparison]::OrdinalIgnoreCase) } |
      Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1

    New-Item -ItemType Directory -Force $dir | Out-Null
    # mirror the app files; keep the already-downloaded engine (node_modules, .node) for fast updates
    robocopy $src $dir /MIR /XD node_modules .node /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Copying the files to $dir failed." }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'install.ps1')
  } catch {
    Write-Host ''
    Write-Host ('  Install failed: ' + $_.Exception.Message) -ForegroundColor Red
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Read-Host '  Press Enter to close'
  }
}
