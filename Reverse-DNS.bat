@echo off
setlocal EnableExtensions

REM ===============================================================
REM Reverse-DNS.bat
REM Windows 8 built-in tools only (cmd + PowerShell + nslookup)
REM From-scratch port of 5_reverseDNS.py main():
REM   - IP hardcoded to 142.250.31.101
REM   - prints 36 dashes, reverse-name, result, 36 dashes
REM   - result formatting matches Python list/dict repr closely
REM Notes:
REM   - dnspython timeout/lifetime are approximated via nslookup timeout/retry.
REM ===============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { " ^
  "  $ErrorActionPreference='Stop'; " ^
  "  $ip = '142.250.31.101'; " ^
  "  $dash = '-' * 36; " ^
  "  function To-ReverseName([string]$ipv4){ " ^
  "    $parts = $ipv4.Split('.'); " ^
  "    if($parts.Count -ne 4){ throw 'IPv4 required' } " ^
  "    return ('{0}.{1}.{2}.{3}.in-addr.arpa.' -f $parts[3],$parts[2],$parts[1],$parts[0]) " ^
  "  } " ^
  "  function Format-PyList([string[]]$items){ " ^
  "    if(-not $items -or $items.Count -eq 0){ return '[]' } " ^
  "    $q = $items | ForEach-Object { \"'\" + ($_.Replace(\"'\",\"\\'\")) + \"'\" } " ^
  "    return ('[' + ($q -join ', ') + ']') " ^
  "  } " ^
  "  function Format-PyErrorDict([string]$err){ return (\"{'error': '{0}'}\" -f $err) } " ^
  "  function Ptr-Lookup([string]$ipv4,[int]$timeoutSec){ " ^
  "    $psi = New-Object System.Diagnostics.ProcessStartInfo; " ^
  "    $psi.FileName = 'nslookup.exe'; " ^
  "    $psi.Arguments = ('-type=PTR -timeout={0} -retry=1 {1}' -f $timeoutSec, $ipv4); " ^
  "    $psi.RedirectStandardOutput = $true; " ^
  "    $psi.RedirectStandardError  = $true; " ^
  "    $psi.UseShellExecute = $false; " ^
  "    $psi.CreateNoWindow  = $true; " ^
  "    $p = [System.Diagnostics.Process]::Start($psi); " ^
  "    $out = $p.StandardOutput.ReadToEnd(); " ^
  "    $err = $p.StandardError.ReadToEnd(); " ^
  "    $p.WaitForExit(); " ^
  "    $text = ($out + \"`n\" + $err); " ^
  "    # Map common failures to dnspython-like error names " ^
  "    if($text -match 'DNS request timed out|Request to .* timed-out') { return @{ error = 'Timeout' } } " ^
  "    if($text -match 'No response from server|connection timed out|Network is unreachable|Server failed|SERVFAIL|Refused') { return @{ error = 'NoNameservers' } } " ^
  "    if($text -match 'Non-existent domain|NXDOMAIN') { return @() } " ^
  "    if($text -match 'No answer') { return @() } " ^
  "    if($text -match 'can''t find|UnKnown|No such host is known') { return @{ error = 'DNSException' } } " ^
  "    # Parse PTR target(s): typically 'name = something.' " ^
  "    $lines = $out -split \"`r?`n\"; " ^
  "    $ptrs = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in $lines){ " ^
  "      if($line -match 'name\s*=\s*(.+)$'){ " ^
  "        $t = $Matches[1].Trim(); " ^
  "        if($t.EndsWith('.')){ $t = $t.TrimEnd('.') } " ^
  "        if($t){ $ptrs.Add($t) | Out-Null } " ^
  "      } " ^
  "    } " ^
  "    # De-duplicate preserving order " ^
  "    $seen=@{}; $uniq=New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($x in $ptrs){ if(-not $seen.ContainsKey($x)){ $seen[$x]=$true; $uniq.Add($x) | Out-Null } } " ^
  "    return $uniq.ToArray(); " ^
  "  } " ^
  "  Write-Host $dash; " ^
  "  $rev = To-ReverseName $ip; " ^
  "  Write-Host $rev; " ^
  "  $res = Ptr-Lookup -ipv4 $ip -timeoutSec 2; " ^
  "  if($res -is [hashtable] -and $res.ContainsKey('error')){ " ^
  "    Write-Host (Format-PyErrorDict $res['error']); " ^
  "  } else { " ^
  "    Write-Host (Format-PyList $res); " ^
  "  } " ^
  "  Write-Host $dash; " ^
  "}"

exit /b %ERRORLEVEL%
