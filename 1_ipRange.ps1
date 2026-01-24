# _16_IPRange.ps1
# Windows 8–safe silent ping sweep (UP hosts only)
# Usage:
#   .\_16_IPRange.ps1 10.211.55

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidatePattern('^(?:\d{1,3}\.){2}\d{1,3}$')]
  [string]$Address,

  [ValidateRange(0,255)]
  [int]$Start = 1,

  [ValidateRange(0,255)]
  [int]$End = 255,

  [ValidateRange(50,5000)]
  [int]$TimeoutMs = 500
)

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference   = 'SilentlyContinue'
$ConfirmPreference    = 'None'

# Validate octets 0–255 (silent failure)
$octets = $Address.Split('.')
foreach ($o in $octets) {
  if ([int]$o -lt 0 -or [int]$o -gt 255) { exit 2 }
}
if ($Start -gt $End) { exit 2 }

for ($ip = $Start; $ip -le $End; $ip++) {
  $target = "$Address.$ip"

  & ping.exe -n 1 -w $TimeoutMs $target > $null 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Output $target
  }
}
