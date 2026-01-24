@echo off
setlocal EnableExtensions

REM ===============================================================
REM learnPort.bat
REM Windows 8 built-in tools only (cmd + PowerShell 3.0)
REM From-scratch port of 7_learnPort.py (TCP/UDP port study + game)
REM ===============================================================

set "SELF=%~f0"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { " ^
  "  $self = $env:SELF; " ^
  "  if(-not $self) { $self = '%~f0' } " ^
  "  if(-not (Test-Path -LiteralPath $self)) { Write-Host '[!] Cannot locate script file.'; exit 3 } " ^
  "  $raw = Get-Content -LiteralPath $self -Raw; " ^
  "  $parts = [regex]::Split($raw, '### POWERSHELL BELOW ###\r?\n', 2); " ^
  "  if($parts.Count -lt 2) { Write-Host '[!] Missing embedded PowerShell section.'; exit 3 } " ^
  "  Invoke-Expression $parts[1]; " ^
  "}"

exit /b %ERRORLEVEL%

### POWERSHELL BELOW ###

# Best-effort: avoid weird console encoding issues
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# ------------------ DATA ------------------

$LISTTCP = [ordered]@{
  'FTP' = 21
  'SSH' = 22
  'TELNET' = 23
  'SMTP' = 25
  'DNS' = 53
  'HTTP' = 80
  'POP3' = 110
  'RPCBIND' = 111
  'MSRPC' = 135
  'NETBIOS SSN' = 139
  'IMAP' = 143
  'HTTPS' = 443
  'MICROSOFT DS' = 445
  'IMAPS' = 993
  'POP3S' = 995
  'PPTP' = 1723
  'MYSQL' = 3306
  'MS TERM SERVER' = 3389
  'VNC' = 5900
  'HTTP PROXY' = 8080
}

$LISTUDP = [ordered]@{
  'DNS' = 53
  'DHCPS' = 67
  'DHCPC' = 68
  'TFTP' = 69
  'NTP' = 123
  'MSRPC' = 135
  'NETBIOS NS' = 137
  'NETBIOS DGM' = 138
  'NETBIOS SSN' = 139
  'SNMP' = 161
  'SNMPTRAP' = 162
  'MICROSOFT DS' = 445
  'ISAKMP' = 500
  'SYSLOG' = 514
  'RIP' = 520
  'IPP' = 631
  'MS SQL DS' = 1434
  'UPNP' = 1900
  'NAT T IKE' = 4500
  'VARIES' = 49152
}

$TCPDESC = @{
  'FTP'='File Transfer Protocol'
  'SSH'='Secure Shell'
  'TELNET'='Client/Server Protocol'
  'SMTP'='Simple Mail Transfer Protocol'
  'DNS'='Domain Name Server'
  'HTTP'='Hypertext Transfer Protocol (Unsecured)'
  'POP3'='Post Office Protocol Version 3 for email retrieval (insecure)'
  'RPCBIND'='Maps SunRPC program numbers to their current TCP or UDP ports'
  'MSRPC'='Common Port For Windows Services'
  'NETBIOS SSN'='Communications for NetBIOS Session Service'
  'IMAP'='Internet Message Access Protocol version 2'
  'HTTPS'='Hypertext Transfer Protocol Secured'
  'MICROSOFT DS'='SMB Over IP With Windows services'
  'IMAPS'='IMAP over SSL/TLS'
  'POP3S'='POP3 over SSL/TLS'
  'PPTP'='Point To Point Tunneling Protocol'
  'MYSQL'='Communication with MySQL databases'
  'MS TERM SERVER'='Microsoft Terminal Services port'
  'VNC'='A Graphical Desktop Sharing System'
  'HTTP PROXY'='Commonly Used For HTTP Proxies'
}

$UDPDESC = @{
  'DNS'='Domain Name Systems Server'
  'DHCPS'='Dynamic Host Configuration Protocol Server'
  'DHCPC'='DHCP Client port'
  'TFTP'='Trivial File Transfer Protocol'
  'NTP'='Network Time Protocol'
  'MSRPC'='Windows Services Port'
  'NETBIOS NS'='UDP Port For Windows'
  'NETBIOS DGM'='Another Windows Service'
  'NETBIOS SSN'='Another Windows Service'
  'SNMP'='Simple Network Manage Protocol'
  'SNMPTRAP'='Simple Network Management Protocol'
  'MICROSOFT DS'='Windows Services Port'
  'ISAKMP'='Internet Security Association And Key Management'
  'SYSLOG'='Standard UNIX Log Daemon'
  'RIP'='Routing Information Protocol'
  'IPP'='Internet Printing Protocol'
  'MS SQL DS'='Microsoft SQL Browser/Discovery'
  'UPNP'='Simple Service Discovery Protocol (SSDP)'
  'NAT T IKE'='NAT traversal during IPsec IKE'
  'VARIES'='Start of IANA dynamic/private (ephemeral) range'
}

# Aliases to match the Python script's looser inputs in TCP/UDP menus
$TCPALIASES = @{
  'pop 3'='POP3'
  'rpc bind'='RPCBIND'
  'rpc-bind'='RPCBIND'
  'netbios ssn'='NETBIOS SSN'
  'netbios-ssn'='NETBIOS SSN'
  'netbios_ssn'='NETBIOS SSN'
  'netbiosssn'='NETBIOS SSN'
  'netbiossnn'='NETBIOS SSN'
  'microsoft ds'='MICROSOFT DS'
  'microsoft-ds'='MICROSOFT DS'
  'microsoft_ds'='MICROSOFT DS'
  'microsoftds'='MICROSOFT DS'
  'pop ssl'='POP3S'
  'my sql'='MYSQL'
  'my-sql'='MYSQL'
  'my_sql'='MYSQL'
  'ms term server'='MS TERM SERVER'
  'ms-term-server'='MS TERM SERVER'
  'ms_term_server'='MS TERM SERVER'
  'mstermserver'='MS TERM SERVER'
  'http proxy'='HTTP PROXY'
  'http-proxy'='HTTP PROXY'
  'http_proxy'='HTTP PROXY'
  'httpproxy'='HTTP PROXY'
}

$UDPALIASES = @{
  'netbios ns'='NETBIOS NS'
  'netbiosns'='NETBIOS NS'
  'netbios dgm'='NETBIOS DGM'
  'netbiosdgm'='NETBIOS DGM'
  'netbios ssn'='NETBIOS SSN'
  'netbiosssn'='NETBIOS SSN'
  'msds'='MICROSOFT DS'
  'microsoft ds'='MICROSOFT DS'
  'microsoft-ds'='MICROSOFT DS'
  'ms sql ds'='MS SQL DS'
  'mssql ds'='MS SQL DS'
  'mssql'='MS SQL DS'
  'nat t ike'='NAT T IKE'
  'natt ike'='NAT T IKE'
  'nat-t ike'='NAT T IKE'
  'ephemeral'='VARIES'
  'varies'='VARIES'
}

# ------------------ HELPERS ------------------

function Norm([string]$s) {
  if($null -eq $s) { return '' }
  $s = $s.Trim().ToLowerInvariant()
  $s = $s.Replace('_',' ').Replace('-',' ')
  $s = ($s -split '\s+') -join ' '
  return $s
}

function Show-ProtocolInfo([string]$name,[int]$number,[string]$desc) {
  Write-Host ''
  Write-Host ("{0} - {1} - {2}" -f $name, $number, $desc)
  Write-Host ''
}

function Print-List([hashtable]$list) {
  Write-Host ''
  foreach($k in $list.Keys) { Write-Host ("{0} {1}" -f $k, $list[$k]) }
  Write-Host ''
}

# ------------------ MENUS ------------------

function Tcp-Menu {
  $bad = 0
  while($bad -le 3) {
    $answer = Norm (Read-Host "(B)ack? (L)ist? (Q)uit?`n-- Which TCP protocol")
    if($answer -eq 'b' -or $answer -eq 'back') { return }
    if($answer -eq 'q' -or $answer -eq 'quit') { Write-Host ('-'*23); exit 0 }
    if($answer -eq 'l' -or $answer -eq 'list') { Print-List $LISTTCP; $bad = 0; continue }
    if($answer -eq 'help') {
      Write-Host ''
      Write-Host 'Examples: ftp, 21, pop 3, rpc-bind, microsoft-ds, ms term server, http proxy'
      Write-Host ''
      $bad = 0; continue
    }

    # port number?
    if($answer -match '^\d+$') {
      $p = [int]$answer
      $name = ($LISTTCP.GetEnumerator() | Where-Object { $_.Value -eq $p } | Select-Object -First 1).Key
      if($name) { Show-ProtocolInfo $name $p $TCPDESC[$name]; $bad = 0; continue }
    }

    # name/alias
    $canonical = $null
    if($TCPALIASES.ContainsKey($answer)) { $canonical = $TCPALIASES[$answer] }
    else {
      # try exact normalized match to a key
      foreach($k in $LISTTCP.Keys) {
        if(Norm $k -eq $answer) { $canonical = $k; break }
      }
    }

    if($canonical -and $LISTTCP.ContainsKey($canonical)) {
      Show-ProtocolInfo $canonical $LISTTCP[$canonical] $TCPDESC[$canonical]
      $bad = 0
    } else {
      Write-Host 'Incorrect input. Try again'
      $bad += 1
    }
  }
}

function Udp-Menu {
  $bad = 0
  while($bad -le 3) {
    $answer = Norm (Read-Host "(B)ack? (L)ist? (Q)uit?`n-- Which UDP protocol")
    if($answer -eq 'b' -or $answer -eq 'back') { return }
    if($answer -eq 'q' -or $answer -eq 'quit') { Write-Host ('-'*23); exit 0 }
    if($answer -eq 'l' -or $answer -eq 'list') { Print-List $LISTUDP; $bad = 0; continue }
    if($answer -eq 'help') {
      Write-Host ''
      Write-Host 'Examples: dns, 53, netbios ns, ms sql ds, nat t ike, varies'
      Write-Host ''
      $bad = 0; continue
    }

    if($answer -match '^\d+$') {
      $p = [int]$answer
      $name = ($LISTUDP.GetEnumerator() | Where-Object { $_.Value -eq $p } | Select-Object -First 1).Key
      if($name) { Show-ProtocolInfo $name $p $UDPDESC[$name]; $bad = 0; continue }
    }

    $canonical = $null
    if($UDPALIASES.ContainsKey($answer)) { $canonical = $UDPALIASES[$answer] }
    else {
      foreach($k in $LISTUDP.Keys) {
        if(Norm $k -eq $answer) { $canonical = $k; break }
      }
    }

    if($canonical -and $LISTUDP.ContainsKey($canonical)) {
      Show-ProtocolInfo $canonical $LISTUDP[$canonical] $UDPDESC[$canonical]
      $bad = 0
    } else {
      Write-Host 'Incorrect input. Try again'
      $bad += 1
    }
  }
}

function Game-Menu {
  $score = 0
  $total = 0

  $tcp_name_by_port = @{}
  foreach($k in $LISTTCP.Keys){ $tcp_name_by_port[[int]$LISTTCP[$k]] = $k }

  $udp_name_by_port = @{}
  foreach($k in $LISTUDP.Keys){ $udp_name_by_port[[int]$LISTUDP[$k]] = $k }

  while($true) {
    Write-Host ''
    Write-Host ("Score: {0}/{1}" -f $score, $total)
    $ask = Norm (Read-Host "(P)lay? (R)eset score? (B)ack?")
    if($ask -eq 'b' -or $ask -eq 'back') { return }
    if($ask -eq 'r' -or $ask -eq 'reset') { $score = 0; $total = 0; Write-Host 'Score reset.'; continue }
    if($ask -ne 'p' -and $ask -ne 'play') { Write-Host 'Incorrect input. Try again'; continue }

    $total += 1
    $tcpOrUdp = Get-Random -Minimum 1 -Maximum 3  # 1 or 2
    if($tcpOrUdp -eq 1) {
      $port = Get-Random -InputObject @($LISTTCP.Values)
      $correct = $tcp_name_by_port[[int]$port]
      $user = Read-Host ("What is TCP port {0}?" -f $port)
      $userNorm = Norm $user
      $isCorrect = ($userNorm -eq (Norm $correct)) -or (($user.Trim() -match '^\d+$') -and ([int]$user.Trim() -eq [int]$port))
      if($isCorrect) { $score += 1; Write-Host 'Correct.' } else { Write-Host ("Incorrect. Answer: {0}." -f $correct) }
    } else {
      $port = Get-Random -InputObject @($LISTUDP.Values)
      $correct = $udp_name_by_port[[int]$port]
      $user = Read-Host ("What is UDP port {0}?" -f $port)
      $userNorm = Norm $user
      $isCorrect = ($userNorm -eq (Norm $correct)) -or (($user.Trim() -match '^\d+$') -and ([int]$user.Trim() -eq [int]$port))
      if($isCorrect) { $score += 1; Write-Host 'Correct.' } else { Write-Host ("Incorrect. Answer: {0}." -f $correct) }
    }
  }
}

function Main {
  Write-Host ''
  $bad = 0
  while($bad -le 3) {
    Write-Host ('-'*23)
    $ask = Norm (Read-Host "(G)ame? (Q)uit?`nUDP or TCP ports?")
    if($ask -eq 'tcp') { Write-Host ('-'*23); Tcp-Menu; $bad = 0; continue }
    if($ask -eq 'udp') { Write-Host ('-'*23); Udp-Menu; $bad = 0; continue }
    if($ask -eq 'g' -or $ask -eq 'game') { Game-Menu; $bad = 0; continue }
    if($ask -eq 'q' -or $ask -eq 'quit') { Write-Host ('-'*23); exit 0 }
    if($ask -eq 'help') {
      Write-Host ''
      Write-Host 'Type: tcp, udp, game (or g), quit (or q)'
      Write-Host ''
      $bad = 0; continue
    }
    Write-Host 'Incorrect input. Try again.'
    $bad += 1
  }
}

try { Main } catch { exit 0 }
