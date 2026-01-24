<#
.SYNOPSIS
  piiScan.ps1 - Scan a text file for emails, phone numbers, and SSN-like patterns.

.DESCRIPTION
  Scans a text file line-by-line and reports matches for:
    - Email addresses
    - US phone numbers (optional +1, separators, ext/x)
    - SSN-like patterns (###-##-####)

  By default, results are deduplicated and masked for safer viewing.
  Can optionally write the same report to a file.

.PARAMETER Path
  Path to the input text file.

.PARAMETER Output
  Optional path to write the report (UTF-8 without BOM). Overwrites if exists.

.PARAMETER NoMask
  If set, prints raw values (no masking).

.PARAMETER NoDedupe
  If set, keeps duplicates in output.

.PARAMETER MaxResults
  Maximum total matches to collect across all categories (default 5000).

.PARAMETER Encoding
  Text encoding name used to read the file (default utf-8). If invalid, falls back to UTF-8.

.PARAMETER Help
  Show detailed help and exit.

.EXAMPLE
  .\piiScan.ps1 .\searchText.txt

.EXAMPLE
  .\piiScan.ps1 "C:\logs\app.log" -Output .\pii_report.txt

.EXAMPLE
  .\piiScan.ps1 .\searchText.txt -NoMask -Output .\raw_pii.txt

.EXAMPLE
  .\piiScan.ps1 -Help

.NOTES
  Exit codes:
    0 = completed (even if no matches), or help displayed
    2 = invalid arguments / file not found / read error / write error
#>

[CmdletBinding(PositionalBinding=$true)]
param(
  [Parameter(Position=0)]
  [Alias('File')]
  [string]$Path,

  [Parameter(Mandatory=$false)]
  [Alias('h','?')]
  [switch]$Help,

  [Parameter(Mandatory=$false)]
  [Alias('o','OutFile')]
  [string]$Output,

  [Parameter(Mandatory=$false)]
  [switch]$NoMask,

  [Parameter(Mandatory=$false)]
  [switch]$NoDedupe,

  [Parameter(Mandatory=$false)]
  [ValidateRange(1,2147483647)]
  [int]$MaxResults = 5000,

  [Parameter(Mandatory=$false)]
  [string]$Encoding = 'utf-8'
)

$ErrorActionPreference = 'Stop'

function Exit-With([int]$Code, [string]$Message = $null) {
  if ($Message) { Write-Error $Message }
  exit $Code
}

# ---- Help handling (also supports common BAT-style tokens passed as first arg) ----
if ($Help -or -not $Path -or ($Path -in @('--help','-h','/?','-?'))) {
  Get-Help $MyInvocation.MyCommand.Path -Detailed
  exit 0
}

# ---- Resolve and validate paths ----
try {
  $fullPath = [IO.Path]::GetFullPath($Path)
} catch {
  Exit-With 2 "Invalid path: $Path"
}

if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
  Exit-With 2 "File not found: $fullPath"
}

$fullOut = $null
if ($Output -and $Output.Trim().Length -gt 0) {
  try { $fullOut = [IO.Path]::GetFullPath($Output) } catch { Exit-With 2 "Invalid output path: $Output" }
}

# ---- Get encoding ----
try {
  $enc = [Text.Encoding]::GetEncoding($Encoding)
} catch {
  $enc = [Text.Encoding]::UTF8
}

# ---- Patterns ----
$EMAIL_RE = [regex]'(?<![\w.+-])([a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,63})(?![\w.+-])'
$PHONE_RE = New-Object System.Text.RegularExpressions.Regex('(?<!\d)(?:\+?1[\s.\-]?)?(?:\(?(\d{3})\)?[\s.\-]?)(\d{3})[\s.\-]?(\d{4})(?:\s*(?:ext\.?|x)\s*(\d{2,5}))?(?!\d)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$SSN_RE   = [regex]'(?<!\d)(\d{3}-\d{2}-\d{4})(?!\d)'
function Normalize-Phone([string]$a,[string]$e,[string]$s,[string]$x) {
  if ($x) { return "$a-$e-$s x$x" }
  return "$a-$e-$s"
}

# ---- Masking ----
function Mask-Email([string]$email) {
  $parts = $email.Split('@',2)
  if ($parts.Count -ne 2) { return $email }
  $local = $parts[0]; $domain = $parts[1]
  if ($local.Length -le 1) { return "*@$domain" }
  if ($local.Length -eq 2) { return ($local.Substring(0,1) + "*@" + $domain) }
  $mid = '*' * ($local.Length - 2)
  return ($local.Substring(0,1) + $mid + $local.Substring($local.Length-1,1) + '@' + $domain)
}

function Mask-Phone([string]$phone) {
  $parts = $phone -split ' x',2
  $main = $parts[0]
  $ext  = if ($parts.Count -eq 2) { ' x' + $parts[1] } else { '' }
  $digits = ($main -replace '\D','')
  if ($digits.Length -ge 10) {
    return ("***-***-" + $digits.Substring($digits.Length-4,4) + $ext)
  }
  return ("***-***-****" + $ext)
}

function Mask-SSN([string]$ssn) {
  if ($ssn.Length -ge 4) { return ("***-**-" + $ssn.Substring($ssn.Length-4,4)) }
  return "***-**-****"
}

# ---- Collect results (streaming) ----
$emails = New-Object 'System.Collections.Generic.List[string]'
$phones = New-Object 'System.Collections.Generic.List[string]'
$ssns   = New-Object 'System.Collections.Generic.List[string]'

$seenE = $null; $seenP = $null; $seenS = $null
if (-not $NoDedupe) {
  $seenE = New-Object 'System.Collections.Generic.HashSet[string]'
  $seenP = New-Object 'System.Collections.Generic.HashSet[string]'
  $seenS = New-Object 'System.Collections.Generic.HashSet[string]'
}

function Add-Item([string]$item, $list, $seen) {
  if ($null -ne $seen) {
    if (-not $seen.Add($item)) { return }
  }
  [void]$list.Add($item)
}

$total = 0

try {
  $sr = New-Object IO.StreamReader($fullPath, $enc, $true)
  try {
    while (-not $sr.EndOfStream) {
      $line = $sr.ReadLine()

      foreach ($m in $EMAIL_RE.Matches($line)) {
        Add-Item $m.Groups[1].Value $emails $seenE
        $total++
        if ($total -ge $MaxResults) { break }
      }
      if ($total -ge $MaxResults) { break }

      foreach ($m in $PHONE_RE.Matches($line)) {
        $p = Normalize-Phone $m.Groups[1].Value $m.Groups[2].Value $m.Groups[3].Value $m.Groups[4].Value
        Add-Item $p $phones $seenP
        $total++
        if ($total -ge $MaxResults) { break }
      }
      if ($total -ge $MaxResults) { break }

      foreach ($m in $SSN_RE.Matches($line)) {
        Add-Item $m.Groups[1].Value $ssns $seenS
        $total++
        if ($total -ge $MaxResults) { break }
      }
      if ($total -ge $MaxResults) { break }
    }
  } finally {
    $sr.Close()
  }
} catch {
  Exit-With 2 ("Read error: " + $_.Exception.Message)
}

# ---- Build and emit report (console + optional file) ----
$report = New-Object 'System.Collections.Generic.List[string]'
function Add-Line([string]$s='') { [void]$report.Add($s); Write-Host $s }

function Show-Section([string]$title, $items, [scriptblock]$maskFn) {
  Add-Line ''
  Add-Line ('-'*45)
  if ($items.Count -gt 0) {
    Add-Line $title
    Add-Line ('-'*30)
    foreach ($i in $items) {
      $out = if ($NoMask) { $i } else { & $maskFn $i }
      Add-Line $out
    }
  } else {
    Add-Line ('No ' + ($title -replace ' found:','').ToLower())
  }
}

Show-Section 'Emails found:' $emails ${function:Mask-Email}
Show-Section 'Phone numbers found:' $phones ${function:Mask-Phone}
Show-Section 'SSN-like patterns found:' $ssns ${function:Mask-SSN}
Add-Line ''
Add-Line ('-'*45)
Add-Line ''

if ($fullOut) {
  try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllLines($fullOut, $report.ToArray(), $utf8NoBom)
  } catch {
    Exit-With 2 ("Failed to write output file: " + $_.Exception.Message)
  }
}

exit 0

