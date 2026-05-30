@echo off
setlocal EnableExtensions

if /i "%~1"=="-h" goto :usage
if /i "%~1"=="--help" goto :usage

set "DOMAIN=%~1"
if not defined DOMAIN set "DOMAIN=google.com"

REM ===============================================================
REM DNSRecords.bat
REM Windows 8 built-in tools only (cmd + PowerShell + nslookup)
REM   - domain: google.com (default)
REM   - records: A, AAAA, CNAME, MX, NS, SOA, TXT
REM   - prints:
REM       <blank line>
REM       Record response <TYPE>
REM       ------------------------------------
REM       <values... | error | No records found>
REM ===============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { " ^
  "  $ErrorActionPreference='Stop'; " ^
  "  $domain = '%DOMAIN%'; " ^
  "  $records = @('A','AAAA','CNAME','MX','NS','SOA','TXT'); " ^
  "  $dash = '-' * 36; " ^
  "" ^
  "  function Invoke-Nslookup([string]$type,[string]$name,[int]$timeoutSec){ " ^
  "    $psi = New-Object System.Diagnostics.ProcessStartInfo; " ^
  "    $psi.FileName = 'nslookup.exe'; " ^
  "    $psi.Arguments = ('-type={0} -timeout={1} -retry=1 {2}' -f $type, $timeoutSec, $name); " ^
  "    $psi.RedirectStandardOutput = $true; " ^
  "    $psi.RedirectStandardError  = $true; " ^
  "    $psi.UseShellExecute = $false; " ^
  "    $psi.CreateNoWindow  = $true; " ^
  "    $p = [System.Diagnostics.Process]::Start($psi); " ^
  "    $out = $p.StandardOutput.ReadToEnd(); " ^
  "    $err = $p.StandardError.ReadToEnd(); " ^
  "    $p.WaitForExit(); " ^
  "    return @{ Out=$out; Err=$err; Text=($out + \"`n\" + $err) } " ^
  "  } " ^
  "" ^
  "  function Classify-Error([string]$text){ " ^
  "    if($text -match 'DNS request timed out|Request to .* timed-out'){ return 'timeout or no nameservers' } " ^
  "    if($text -match 'No response from server|connection timed out|Network is unreachable|Server failed|SERVFAIL|Refused'){ return 'timeout or no nameservers' } " ^
  "    # NXDOMAIN / NoAnswer should be treated as empty list " ^
  "    if($text -match 'Non-existent domain|NXDOMAIN'){ return $null } " ^
  "    if($text -match 'No answer'){ return $null } " ^
  "    if($text -match \"can't find\" -and $text -match 'No answer'){ return $null } " ^
  "    if($text -match \"can't find\" -and $text -match 'NXDOMAIN'){ return $null } " ^
  "    # Other nslookup failures " ^
  "    if($text -match \"can't find|UnKnown|No such host is known\"){ return 'dns error' } " ^
  "    return $null " ^
  "  } " ^
  "" ^
  "  function Parse-A([string]$out){ " ^
  "    $ips = New-Object System.Collections.Generic.List[string]; " ^
  "    $inAnswer = $false; " ^
  "    foreach($line in ($out -split \"`r?`n\")){ " ^
  "      if($line -match '^\s*Name:\s*'){ $inAnswer = $true; continue } " ^
  "      if(-not $inAnswer){ continue } " ^
  "      if($line -match '^\s*Address(?:es)?:\s*(.+)$'){ " ^
  "        foreach($tok in ($Matches[1] -split '\s+')){ " ^
  "          if($tok -match '^\d{1,3}(?:\.\d{1,3}){3}$' -and -not $ips.Contains($tok)){ [void]$ips.Add($tok) } " ^
  "        } " ^
  "      } elseif($line -match '^\s+(.+)$'){ " ^
  "        foreach($tok in ($Matches[1] -split '\s+')){ " ^
  "          if($tok -match '^\d{1,3}(?:\.\d{1,3}){3}$' -and -not $ips.Contains($tok)){ [void]$ips.Add($tok) } " ^
  "        } " ^
  "      } " ^
  "    } " ^
  "    return $ips.ToArray() " ^
  "  } " ^
  "" ^
  "  function Parse-AAAA([string]$out){ " ^
  "    $ips = New-Object System.Collections.Generic.List[string]; " ^
  "    $inAnswer = $false; " ^
  "    foreach($line in ($out -split \"`r?`n\")){ " ^
  "      if($line -match '^\s*Name:\s*'){ $inAnswer = $true; continue } " ^
  "      if(-not $inAnswer){ continue } " ^
  "      if($line -match '^\s*Address(?:es)?:\s*(.+)$'){ " ^
  "        foreach($tok in ($Matches[1] -split '\s+')){ " ^
  "          if($tok -match ':' -and -not $ips.Contains($tok)){ [void]$ips.Add($tok) } " ^
  "        } " ^
  "      } elseif($line -match '^\s+(.+)$'){ " ^
  "        foreach($tok in ($Matches[1] -split '\s+')){ " ^
  "          if($tok -match ':' -and -not $ips.Contains($tok)){ [void]$ips.Add($tok) } " ^
  "        } " ^
  "      } " ^
  "    } " ^
  "    return $ips.ToArray() " ^
  "  } " ^
  "" ^
  "  function Parse-CNAME([string]$out){ " ^
  "    $vals = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in ($out -split \"`r?`n\")){ " ^
  "      if($line -match 'canonical name\s*=\s*(.+)$'){ " ^
  "        $v = $Matches[1].Trim(); if($v.EndsWith('.')){ $v = $v.TrimEnd('.') } " ^
  "        if($v){ [void]$vals.Add($v) } " ^
  "      } " ^
  "    } " ^
  "    return $vals.ToArray() " ^
  "  } " ^
  "" ^
  "  function Parse-MX([string]$out){ " ^
  "    $vals = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in ($out -split \"`r?`n\")){ " ^
  "      if($line -match 'mail exchanger\s*=\s*(.+)$'){ " ^
  "        $v = $Matches[1].Trim(); if($v.EndsWith('.')){ $v = $v.TrimEnd('.') } " ^
  "        if($v){ [void]$vals.Add($v) } " ^
  "      } " ^
  "    } " ^
  "    return $vals.ToArray() " ^
  "  } " ^
  "" ^
  "  function Parse-NS([string]$out){ " ^
  "    $vals = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in ($out -split \"`r?`n\")){ " ^
  "      if($line -match 'nameserver\s*=\s*(.+)$'){ " ^
  "        $v = $Matches[1].Trim(); if($v.EndsWith('.')){ $v = $v.TrimEnd('.') } " ^
  "        if($v){ [void]$vals.Add($v) } " ^
  "      } " ^
  "    } " ^
  "    return $vals.ToArray() " ^
  "  } " ^
  "" ^
  "  function Parse-SOA([string]$out){ " ^
  "    # nslookup SOA output varies; capture structured fields when possible. " ^
  "    $mname=$rname=$serial=$refresh=$retry=$expire=$minimum=$null; " ^
  "    $lines = $out -split \"`r?`n\"; " ^
  "    foreach($line in $lines){ " ^
  "      $t = $line.Trim(); if(-not $t){ continue } " ^
  "      if($t -match 'primary\s+name\s+server\s*=\s*(.+)$'){ $mname=$Matches[1].Trim().TrimEnd('.'); continue } " ^
  "      if($t -match 'responsible\s+mail\s+addr\s*=\s*(.+)$'){ $rname=$Matches[1].Trim().TrimEnd('.'); continue } " ^
  "      if($t -match '^serial\s*=\s*([0-9]+)'){ $serial=$Matches[1]; continue } " ^
  "      if($t -match '^refresh\s*=\s*([0-9]+)'){ $refresh=$Matches[1]; continue } " ^
  "      if($t -match '^retry\s*=\s*([0-9]+)'){ $retry=$Matches[1]; continue } " ^
  "      if($t -match '^expire\s*=\s*([0-9]+)'){ $expire=$Matches[1]; continue } " ^
  "      if($t -match '^minimum\s*=\s*([0-9]+)'){ $minimum=$Matches[1]; continue } " ^
  "      if($t -match '^soa\s*\(\s*([^\s]+)\s+([^\s]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s*\)'){ " ^
  "        $mname=$Matches[1].Trim().TrimEnd('.'); $rname=$Matches[2].Trim().TrimEnd('.'); $serial=$Matches[3]; $refresh=$Matches[4]; $retry=$Matches[5]; $expire=$Matches[6]; $minimum=$Matches[7]; continue " ^
  "      } " ^
  "    } " ^
  "    if($mname -and $rname -and $serial -and $refresh -and $retry -and $expire -and $minimum){ " ^
  "      return @((\"{0} {1} {2} {3} {4} {5} {6}\" -f $mname,$rname,$serial,$refresh,$retry,$expire,$minimum)) " ^
  "    } " ^
  "    $vals = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in $lines){ " ^
  "      $t=$line.Trim(); if(-not $t){ continue } " ^
  "      if($t -match 'primary\s+name\s+server\s*=|responsible\s+mail\s+addr\s*=|^serial\s*=|^refresh\s*=|^retry\s*=|^expire\s*=|^minimum\s*='){ [void]$vals.Add($t) } " ^
  "    } " ^
  "    return $vals.ToArray() " ^
  "  } " ^
  "" ^
  "  function Parse-TXT([string]$out){ " ^
  "    $vals = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($line in ($out -split \"`r?`n\")){ " ^
  "      if($line -match 'text\s*=\s*(.+)$'){ " ^
  "        $v = $Matches[1].Trim(); " ^
  "        # strip surrounding quotes if present " ^
  "        if($v.StartsWith('\"') -and $v.EndsWith('\"') -and $v.Length -ge 2){ $v = $v.Substring(1,$v.Length-2) } " ^
  "        if($v){ [void]$vals.Add($v) } " ^
  "      } " ^
  "    } " ^
  "    return $vals.ToArray() " ^
  "  } " ^
  "" ^
  "  function Query-Record([string]$name,[string]$type){ " ^
  "    if($type -eq 'PTR'){ return @{ error = 'PTR requires reverse lookup name' } } " ^
  "    $r = Invoke-Nslookup -type $type -name $name -timeoutSec 2; " ^
  "    $errClass = Classify-Error $r.Text; " ^
  "    if($errClass){ return @{ error = $errClass } } " ^
  "    switch($type){ " ^
  "      'A'     { return (Parse-A $r.Out) } " ^
  "      'AAAA'  { return (Parse-AAAA $r.Out) } " ^
  "      'CNAME' { return (Parse-CNAME $r.Out) } " ^
  "      'MX'    { return (Parse-MX $r.Out) } " ^
  "      'NS'    { return (Parse-NS $r.Out) } " ^
  "      'SOA'   { return (Parse-SOA $r.Out) } " ^
  "      'TXT'   { return (Parse-TXT $r.Out) } " ^
  "      default { return @() } " ^
  "    } " ^
  "  } " ^
  "" ^
  "  foreach($t in $records){ " ^
  "    Write-Host \"\"; " ^
  "    Write-Host (\"Record response {0}\" -f $t); " ^
  "    Write-Host $dash; " ^
  "    $values = Query-Record -name $domain -type $t; " ^
  "    if($values -is [hashtable] -and $values.ContainsKey('error')){ " ^
  "      Write-Host $values['error']; " ^
  "    } elseif($values -and $values.Count -gt 0){ " ^
  "      foreach($v in $values){ Write-Host $v } " ^
  "    } else { " ^
  "      Write-Host 'No records found'; " ^
  "    } " ^
  "  } " ^
  "}"

exit /b %ERRORLEVEL%


:usage
echo Usage: %~nx0 [domain]
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 google.com
echo   %~nx0 openai.com
exit /b 0
