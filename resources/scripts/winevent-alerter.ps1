# === Configuration: edit these lists and parameters ===
$targetEventIds = @(5152,5157)            # Event IDs to consider; edit to add/remove IDs
$excludeRemote = @('10.0.0.1','192.168.1.0/24','203.0.113.5')   # remote IPs or CIDR to ignore
$excludeLocal  = @('127.0.0.1')                                # local addresses to ignore
$excludeProcs  = @('svchost.exe')                              # process names to ignore
$alertLog      = 'C:\Logs\FirewallAlerts.log'
$lookbackSec   = 60                                            # how far back to search for the triggering event

# === Helper functions ===
function Test-CidrMatch {
  param($ip, $cidr)
  try {
    if ($cidr -notmatch '/') { return $false }
    $parts = $cidr.Split('/')
    $netIp = [System.Net.IPAddress]::Parse($parts[0]).GetAddressBytes()
    [Array]::Reverse($netIp)
    $addr = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    [Array]::Reverse($addr)
    $maskLen = [int]$parts[1]
    $mask = [uint32]0
    if ($maskLen -ne 0) { $mask = ([uint32]0xFFFFFFFF) -shl (32 - $maskLen) }
    $netVal = [BitConverter]::ToUInt32($netIp,0)
    $addrVal = [BitConverter]::ToUInt32($addr,0)
    return (($netVal -band $mask) -eq ($addrVal -band $mask))
  } catch { return $false }
}

function Test-IpMatch {
  param($ip, $patterns)
  if (-not $ip) { return $false }
  foreach($p in $patterns) {
    if ($p -match '/') {
      if (Test-CidrMatch -ip $ip -cidr $p) { return $true }
    } elseif ($ip -eq $p) { return $true }
  }
  return $false
}

# === Find most recent matching event within lookback window ===
$now = Get-Date
$startTime = $now.AddSeconds(-$lookbackSec)

# Build filter hashtable for Operational channel
$filterOps = @{
  LogName = 'Microsoft-Windows-Windows Defender Firewall/Operational'
  Id = $targetEventIds
  StartTime = $startTime
}
$evt = Get-WinEvent -FilterHashtable $filterOps -MaxEvents 1 -ErrorAction SilentlyContinue

# Fallback to Security log if nothing found in Operational
if (-not $evt) {
  $filterSec = @{
    LogName = 'Security'
    Id = $targetEventIds
    StartTime = $startTime
  }
  $evt = Get-WinEvent -FilterHashtable $filterSec -MaxEvents 1 -ErrorAction SilentlyContinue
}
if (-not $evt) { exit 0 }

# === Parse event for fields ===
$xml = [xml]$evt.ToXml()
$remote = ($xml.Event.EventData.Data | Where-Object { $_.Name -match 'RemoteAddress|RemoteIP' }).'#text'
$local  = ($xml.Event.EventData.Data | Where-Object { $_.Name -match 'LocalAddress|LocalIP' }).'#text'
$proc   = ($xml.Event.EventData.Data | Where-Object { $_.Name -match 'ProcessName|Application|Process' }).'#text'
$port   = ($xml.Event.EventData.Data | Where-Object { $_.Name -match 'RemotePort|LocalPort' }).'#text'

# Fallback to message parsing if XML fields absent
if (-not $remote) {
  $msg = $evt.Message
  if ($msg -match 'Remote Address:\s*([0-9.:]+)') { $remote = $matches[1] }
  if ($msg -match 'Local Address:\s*([0-9.:]+)')  { $local  = $matches[1] }
  if ($msg -match 'Process Name:\s*([^\r\n]+)')   { $proc   = $matches[1].Trim() }
  if ($msg -match 'Remote Port:\s*([0-9]+)')     { $port   = $matches[1] }
}

# === Apply exclusion checks ===
if ($remote) {
  if (Test-IpMatch -ip $remote -patterns $excludeRemote) { exit 0 }
}
if ($local) {
  if (Test-IpMatch -ip $local -patterns $excludeLocal) { exit 0 }
}
if ($proc) {
  foreach ($p in $excludeProcs) { if ($proc -like "*$p*") { exit 0 } }
}

# === Not excluded: log and notify ===
$time = (Get-Date).ToString('o')
$entry = "$time - EventId:$($evt.Id) - Remote:$remote - Local:$local - Proc:$proc - Port:$port"
$logDir = Split-Path $alertLog -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$entry | Out-File -FilePath $alertLog -Append -Encoding UTF8

try {
  Add-Type -AssemblyName PresentationFramework
  [System.Windows.MessageBox]::Show($entry,'Firewall Blocked','OK','Warning') | Out-Null
} catch {
  # non-interactive session: no popup
}
