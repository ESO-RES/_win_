@echo off
setlocal EnableExtensions

REM ===============================================================
REM Resolve-DNS.bat
REM Windows 8 built-in tools only (cmd + PowerShell + nslookup)
REM From-scratch port of 4_resolveDNS.py main():
REM   - queries AAAA records for google.com and microsoft.com
REM   - prints results or "No AAAA records" or "AAAA error: <ErrorName>"
REM Notes:
REM   - dnspython's "lifetime" concept has no direct nslookup equivalent;
REM     this script approximates using nslookup timeout/retry.
REM ===============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { " ^
  "  $ErrorActionPreference='Stop'; " ^
  "  $hosts = @('google.com','microsoft.com'); " ^
  "  $timeoutSec = 2; " ^
  "  $dash = '-' * 36; " ^
  "  function Query-AAAA([string]$host,[int]$timeout){ " ^
  "    $psi = New-Object System.Diagnostics.ProcessStartInfo; " ^
  "    $psi.FileName = 'nslookup.exe'; " ^
  "    $psi.Arguments = ('-type=AAAA -timeout={0} -retry=1 {1}' -f $timeout, $host); " ^
  "    $psi.RedirectStandardOutput = $true; " ^
  "    $psi.RedirectStandardError  = $true; " ^
  "    $psi.UseShellExecute = $false; " ^
  "    $psi.CreateNoWindow  = $true; " ^
  "    $p = [System.Diagnostics.Process]::Start($psi); " ^
  "    $out = $p.StandardOutput.ReadToEnd(); " ^
  "    $err = $p.StandardError.ReadToEnd(); " ^
  "    $p.WaitForExit(); " ^
  "    $text = ($out + \"`n\" + $err); " ^
  "    # Map common nslookup failures to dnspython-like error names " ^
  "    if($text -match 'DNS request timed out|Request to .* timed-out') { return @{ error = 'Timeout' } } " ^
  "    if($text -match 'No response from server|connection timed out|Network is unreachable|Server failed|SERVFAIL|Refused') { return @{ error = 'NoNameservers' } } " ^
  "    if($text -match 'Non-existent domain|NXDOMAIN') { return @() } " ^
  "    if($text -match 'No answer') { return @() } " ^
  "    if($text -match 'can''t find|UnKnown|No such host is known') { return @{ error = 'DNSException' } } " ^
  "    # Parse IPv6 answers from the answer section " ^
  "    $lines = $out -split \"`r?`n\"; " ^
  "    $inAnswer = $false; " ^
  "    $ips = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in $lines){ " ^
  "      if($line -match '^(Non-authoritative answer:|Authoritative answers?:)') { $inAnswer = $true; continue } " ^
  "      if($line -match '^Name:\s') { $inAnswer = $true; continue } " ^
  "      if(-not $inAnswer) { continue } " ^
  "      if($line -match '^\s*Addresses:\s*(.+)$'){ " ^
  "        foreach($tok in ($Matches[1] -split '\s+')){ if($tok -match ':'){ $ips.Add($tok) | Out-Null } } " ^
  "        continue " ^
  "      } " ^
  "      if($line -match '^\s*Address:\s*(.+)$'){ " ^
  "        $tok = $Matches[1].Trim(); if($tok -match ':'){ $ips.Add($tok) | Out-Null } " ^
  "        continue " ^
  "      } " ^
  "      if($line -match '^\s*([0-9A-Fa-f:]+)\s*$'){ " ^
  "        $tok = $Matches[1].Trim(); if($tok -match ':'){ $ips.Add($tok) | Out-Null } " ^
  "      } " ^
  "    } " ^
  "    # De-duplicate while preserving order " ^
  "    $seen = @{}; $uniq = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($ip in $ips){ if(-not $seen.ContainsKey($ip)){ $seen[$ip]=$true; $uniq.Add($ip) | Out-Null } } " ^
  "    return $uniq.ToArray(); " ^
  "  } " ^
  "  foreach($h in $hosts){ " ^
  "    Write-Host \"\"; " ^
  "    Write-Host ($h); " ^
  "    Write-Host ($dash); " ^
  "    $v = Query-AAAA -host $h -timeout $timeoutSec; " ^
  "    if($v -is [hashtable] -and $v.ContainsKey('error')){ " ^
  "      Write-Host (\"AAAA error: {0}\" -f $v['error']); " ^
  "    } elseif($v -and $v.Count -gt 0){ " ^
  "      foreach($item in $v){ Write-Host $item } " ^
  "    } else { " ^
  "      Write-Host 'No AAAA records'; " ^
  "    } " ^
  "    Write-Host ($dash); " ^
  "  } " ^
  "}"

exit /b %ERRORLEVEL%
