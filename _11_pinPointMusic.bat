@echo off
setlocal EnableExtensions

REM ===============================================================
REM PinPointMusic.bat
REM Windows 8 built-in tools only (cmd + PowerShell 3.0)
REM Single-file port of 2_pinPointMusic.py (data embedded below)
REM ===============================================================

set "SELF=%~f0"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { " ^
  "  $self = '%~f0'; " ^
  "  $self = $env:SELF; " ^
  "  if(-not (Test-Path -LiteralPath $self)) { Write-Host '[!] Cannot locate script file.'; exit 3 } " ^
  "  $raw = Get-Content -LiteralPath $self -Raw; " ^
  "  $parts = [regex]::Split($raw, '### POWERSHELL BELOW ###\r?\n', 2); " ^
  "  if($parts.Count -lt 2) { Write-Host '[!] Missing embedded PowerShell section.'; exit 3 } " ^
  "  Invoke-Expression $parts[1]; " ^
  "}"

exit /b %ERRORLEVEL%

### POWERSHELL BELOW ###

$SCALE_POSITION = @('I', 'II', 'III', 'IV', 'V', 'VI', 'VII')
$CHORD_POSITION = @('I', 'III', 'V')
$MAJOR_TRIADS   = @('Major', 'minor', 'minor', 'Major', 'Major', 'minor', 'diminished')
$MINOR_TRIADS   = @('minor', 'diminished', 'Major', 'minor', 'minor', 'Major', 'Major')

$SCALES = @{
  'a major' = @('a', 'b', 'c#', 'd', 'e', 'f#', 'g#')
  'a minor' = @('a', 'b', 'c', 'd', 'e', 'f', 'g')
  'a# major' = @('a#', 'b#', 'c##', 'd#', 'e#', 'f##', 'g##')
  'a# minor' = @('a#', 'b#', 'c#', 'd#', 'e#', 'f#', 'g#')
  'ab major' = @('a♭', 'b♭', 'c', 'd♭', 'e♭', 'f', 'g')
  'ab minor' = @('a♭', 'b♭', 'c♭', 'd♭', 'e♭', 'f♭', 'g♭')
  'b major' = @('b', 'c#', 'd#', 'e', 'f#', 'g#', 'a#')
  'b minor' = @('b', 'c#', 'd', 'e', 'f#', 'g', 'a')
  'b# major' = @('b#', 'c##', 'd##', 'e#', 'f##', 'g##', 'a##')
  'b# minor' = @('b#', 'c##', 'd#', 'e#', 'f##', 'g#', 'a#')
  'bb major' = @('b♭', 'c', 'd', 'e♭', 'f', 'g', 'a')
  'bb minor' = @('b♭', 'c', 'd♭', 'e♭', 'f', 'g♭', 'a♭')
  'c major' = @('c', 'd', 'e', 'f', 'g', 'a', 'b')
  'c minor' = @('c', 'd', 'e♭', 'f', 'g', 'a♭', 'b♭')
  'c# major' = @('c#', 'd#', 'e#', 'f#', 'g#', 'a#', 'b#')
  'c# minor' = @('c#', 'd#', 'e', 'f#', 'g#', 'a', 'b')
  'cb major' = @('c♭', 'd♭', 'e♭', 'f♭', 'g♭', 'a♭', 'b♭')
  'cb minor' = @('c♭', 'd♭', 'e♭♭', 'f♭', 'g♭', 'a♭♭', 'b♭♭')
  'd major' = @('d', 'e', 'f#', 'g', 'a', 'b', 'c#')
  'd minor' = @('d', 'e', 'f', 'g', 'a', 'b♭', 'c')
  'd# major' = @('d#', 'e#', 'f##', 'g#', 'a#', 'b#', 'c##')
  'd# minor' = @('d#', 'e#', 'f#', 'g#', 'a#', 'b', 'c#')
  'db major' = @('d♭', 'e♭', 'f', 'g♭', 'a♭', 'b♭', 'c')
  'db minor' = @('d♭', 'e♭', 'f♭', 'g♭', 'a♭', 'b♭♭', 'c♭')
  'e major' = @('e', 'f#', 'g#', 'a', 'b', 'c#', 'd#')
  'e minor' = @('e', 'f#', 'g', 'a', 'b', 'c', 'd')
  'e# major' = @('e#', 'f##', 'g##', 'a#', 'b#', 'c##', 'd##')
  'e# minor' = @('e#', 'f##', 'g#', 'a#', 'b#', 'c#', 'd#')
  'eb major' = @('e♭', 'f', 'g', 'a♭', 'b♭', 'c', 'd')
  'eb minor' = @('e♭', 'f', 'g♭', 'a♭', 'b♭', 'c♭', 'd♭')
  'f major' = @('f', 'g', 'a', 'b♭', 'c', 'd', 'e')
  'f minor' = @('f', 'g', 'a♭', 'b♭', 'c', 'd♭', 'e♭')
  'f# major' = @('f#', 'g#', 'a#', 'b', 'c#', 'd#', 'e#')
  'f# minor' = @('f#', 'g#', 'a', 'b', 'c#', 'd', 'e')
  'fb major' = @('f♭', 'g♭', 'a♭', 'b♭♭', 'c♭', 'd♭', 'e♭')
  'fb minor' = @('f♭', 'g♭', 'a♭♭', 'b♭♭', 'c♭', 'd♭♭', 'e♭♭')
  'g major' = @('g', 'a', 'b', 'c', 'd', 'e', 'f#')
  'g minor' = @('g', 'a', 'b♭', 'c', 'd', 'e♭', 'f')
  'g# major' = @('g#', 'a#', 'b#', 'c#', 'd#', 'e#', 'f##')
  'g# minor' = @('g#', 'a#', 'b', 'c#', 'd#', 'e', 'f#')
  'gb major' = @('g♭', 'a♭', 'b♭', 'c♭', 'd♭', 'e♭', 'f')
  'gb minor' = @('g♭', 'a♭', 'b♭♭', 'c♭', 'd♭', 'e♭♭', 'f♭')
}
$CHORDS = @{
  'a diminished' = @('a', 'c', 'e♭')
  'a major' = @('a', 'c#', 'e')
  'a minor' = @('a', 'c', 'e')
  'a# diminished' = @('a#', 'c#', 'e')
  'a# major' = @('a#', 'c##', 'e#')
  'a# minor' = @('a#', 'c#', 'e#')
  'ab diminished' = @('a♭', 'c♭', 'e♭♭')
  'ab major' = @('a♭', 'c', 'e♭')
  'ab minor' = @('a♭', 'c♭', 'e♭')
  'b diminished' = @('b', 'd', 'f')
  'b major' = @('b', 'd#', 'f#')
  'b minor' = @('b', 'd', 'f#')
  'b# diminished' = @('b#', 'd#', 'f#')
  'b# major' = @('b#', 'd##', 'f##')
  'b# minor' = @('b#', 'd#', 'f##')
  'bb diminished' = @('b♭', 'd♭', 'f♭')
  'bb major' = @('b♭', 'd', 'f')
  'bb minor' = @('b♭', 'd♭', 'f')
  'c diminished' = @('c', 'e♭', 'g♭')
  'c major' = @('c', 'e', 'g')
  'c minor' = @('c', 'e♭', 'g')
  'c# diminished' = @('c#', 'e', 'g')
  'c# major' = @('c#', 'e#', 'g#')
  'c# minor' = @('c#', 'e', 'g#')
  'd diminished' = @('d', 'f', 'a♭')
  'd major' = @('d', 'f#', 'a')
  'd minor' = @('d', 'f', 'a')
  'd# diminished' = @('d#', 'f#', 'a')
  'd# major' = @('d#', 'f##', 'a#')
  'd# minor' = @('d#', 'f#', 'a#')
  'db diminished' = @('d♭', 'f♭', 'a♭♭')
  'db major' = @('d♭', 'f', 'a♭')
  'db minor' = @('d♭', 'f♭', 'a♭')
  'e diminished' = @('e', 'g', 'b♭')
  'e major' = @('e', 'g#', 'b')
  'e minor' = @('e', 'g', 'b')
  'e# diminished' = @('e#', 'g#', 'b')
  'e# major' = @('e#', 'g##', 'b#')
  'e# minor' = @('e#', 'g#', 'b#')
  'eb diminished' = @('e♭', 'g♭', 'b')
  'eb major' = @('e♭', 'g', 'b♭')
  'eb minor' = @('e♭', 'g♭', 'b♭')
  'f diminished' = @('f', 'a♭', 'c♭')
  'f major' = @('f', 'a', 'c')
  'f minor' = @('f', 'a♭', 'c')
  'f# diminished' = @('f#', 'a', 'c')
  'f# major' = @('f#', 'a#', 'c#')
  'f# minor' = @('f#', 'a', 'c#')
  'fb diminished' = @('f♭', 'a♭♭', 'c♭♭')
  'fb major' = @('f♭', 'a♭', 'c♭')
  'fb minor' = @('f♭', 'a♭♭', 'c♭')
  'g diminished' = @('g', 'b♭', 'd♭')
  'g major' = @('g', 'b', 'd')
  'g minor' = @('g', 'b♭', 'd')
  'g# diminished' = @('g#', 'b', 'd')
  'g# major' = @('g#', 'b#', 'd#')
  'g# minor' = @('g#', 'b', 'd#')
  'gb diminished' = @('g♭', 'b♭♭', 'd♭♭')
  'gb major' = @('g♭', 'b♭', 'd♭')
  'gb minor' = @('g♭', 'b♭♭', 'd♭')
}
$FREQS  = @{
  'a#0' = 29.1353
  'a#1' = 58.2705
  'a#2' = 116.541
  'a#3' = 233.082
  'a#4' = 466.164
  'a#5' = 932.328
  'a#6' = 1864.66
  'a#7' = 3729.31
  'a#8' = 7458.6
  'a#9' = 14917.0
  'a0' = 27.5
  'a1' = 55.0
  'a2' = 110.0
  'a3' = 220.0
  'a4' = 440.0
  'a5' = 880.0
  'a6' = 1760.0
  'a7' = 3520.0
  'a8' = 7040.0
  'a9' = 14080.0
  'ab0' = 25.957
  'ab1' = 51.913
  'ab2' = 103.826
  'ab3' = 207.652
  'ab4' = 415.305
  'ab5' = 830.609
  'ab6' = 1661.22
  'ab7' = 3322.44
  'ab8' = 6644.9
  'ab9' = 13290.0
  'b0' = 30.8677
  'b1' = 61.7354
  'b2' = 123.471
  'b3' = 246.942
  'b4' = 493.883
  'b5' = 987.767
  'b6' = 1975.53
  'b7' = 3951.07
  'b8' = 7902.1
  'b9' = 15804.0
  'bb0' = 29.1353
  'bb1' = 58.2705
  'bb2' = 116.541
  'bb3' = 233.082
  'bb4' = 466.164
  'bb5' = 932.328
  'bb6' = 1864.66
  'bb7' = 3729.31
  'bb8' = 7458.6
  'bb9' = 14917.0
  'c#1' = 34.6479
  'c#10' = 17740.0
  'c#2' = 69.2957
  'c#3' = 138.591
  'c#4' = 277.183
  'c#5' = 554.365
  'c#6' = 1108.73
  'c#7' = 2217.46
  'c#8' = 4434.9
  'c#9' = 8869.8
  'c1' = 32.7032
  'c10' = 16744.0
  'c2' = 65.4064
  'c3' = 130.813
  'c4' = 261.626
  'c5' = 523.251
  'c6' = 1046.5
  'c7' = 2093.0
  'c8' = 4186.01
  'c9' = 8372.0
  'd#1' = 38.8909
  'd#10' = 19912.0
  'd#2' = 77.7817
  'd#3' = 155.563
  'd#4' = 311.127
  'd#5' = 622.254
  'd#6' = 1244.51
  'd#7' = 2489.02
  'd#8' = 4978.0
  'd#9' = 9956.1
  'd1' = 36.7081
  'd10' = 18795.0
  'd2' = 73.4162
  'd3' = 146.832
  'd4' = 293.665
  'd5' = 587.33
  'd6' = 1174.66
  'd7' = 2349.32
  'd8' = 4698.6
  'd9' = 9397.3
  'db1' = 34.6479
  'db10' = 17740.0
  'db2' = 69.2957
  'db3' = 138.591
  'db4' = 277.183
  'db5' = 554.365
  'db6' = 1108.73
  'db7' = 2217.46
  'db8' = 4434.9
  'db9' = 8869.8
  'e0' = 20.602
  'e1' = 41.2035
  'e2' = 82.4069
  'e3' = 164.814
  'e4' = 329.628
  'e5' = 659.255
  'e6' = 1318.51
  'e7' = 2637.02
  'e8' = 5274.0
  'e9' = 10548.0
  'eb1' = 38.8909
  'eb10' = 19912.0
  'eb2' = 77.7817
  'eb3' = 155.563
  'eb4' = 311.127
  'eb5' = 622.254
  'eb6' = 1244.51
  'eb7' = 2489.02
  'eb8' = 4978.0
  'eb9' = 9956.1
  'f#0' = 23.125
  'f#1' = 46.2493
  'f#2' = 92.4986
  'f#3' = 184.997
  'f#4' = 369.994
  'f#5' = 739.989
  'f#6' = 1479.98
  'f#7' = 2959.96
  'f#8' = 5919.9
  'f#9' = 11840.0
  'f0' = 21.827
  'f1' = 43.6536
  'f2' = 87.3071
  'f3' = 174.614
  'f4' = 349.228
  'f5' = 698.456
  'f6' = 1396.91
  'f7' = 2793.83
  'f8' = 5587.7
  'f9' = 11175.0
  'g#0' = 25.957
  'g#1' = 51.913
  'g#2' = 103.826
  'g#3' = 207.652
  'g#4' = 415.305
  'g#5' = 830.609
  'g#6' = 1661.22
  'g#7' = 3322.44
  'g#8' = 6644.9
  'g#9' = 13290.0
  'g0' = 24.5
  'g1' = 48.9995
  'g2' = 97.9989
  'g3' = 195.998
  'g4' = 391.995
  'g5' = 783.991
  'g6' = 1567.98
  'g7' = 3135.96
  'g8' = 6271.9
  'g9' = 12544.0
  'gb0' = 23.125
  'gb1' = 46.2493
  'gb2' = 92.4986
  'gb3' = 184.997
  'gb4' = 369.994
  'gb5' = 739.989
  'gb6' = 1479.98
  'gb7' = 2959.96
  'gb8' = 5919.9
  'gb9' = 11840.0
}



# Best-effort console encoding (Windows 8):
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# ------------------ NORMALIZATION ------------------

function Normalize([string]$s) {
  if($null -eq $s) { return "" }
  $s = $s.Trim().ToLowerInvariant()
  $s = ($s -split '\s+') -join ' '
  return $s
}

function Normalize-Accidentals([string]$s) {
  # accept words + unicode symbols, unify to # / b
  $s = $s.Replace('sharp','#').Replace('flat','b')
  $s = $s.Replace('♯','#').Replace('♭','b')
  return $s
}


function Format-Note([string]$s) {
  if($null -eq $s) { return "" }
  # Ensure output is ASCII-friendly for cmd.exe consoles:
  # convert unicode accidentals to plain b/# and collapse any spaces.
  $s = Normalize-Accidentals $s
  $s = $s.Replace('♭','b').Replace('♯','#')
  return $s
}

function Normalize-KeyName([string]$s) {
  $s = Normalize $s
  $s = Normalize-Accidentals $s

  # allow "cmajor" / "cminor" / "cdiminished" (no space)
  foreach($qual in @('major','minor','diminished')) {
    if($s.EndsWith($qual) -and ($s -notmatch '\s')) {
      $root = $s.Substring(0, $s.Length - $qual.Length)
      $s = ($root + ' ' + $qual).Trim()
      break
    }
  }
  return (Normalize $s)
}

function Normalize-NoteOctave([string]$s) {
  $s = Normalize $s
  $s = Normalize-Accidentals $s

  $word_oct = @{
    'zero'='0'; 'one'='1'; 'two'='2'; 'three'='3'; 'four'='4';
    'five'='5'; 'six'='6'; 'seven'='7'; 'eight'='8'; 'nine'='9'; 'ten'='10'
  }

  $parts = $s -split '\s+'
  if($parts.Count -eq 2) {
    if($word_oct.ContainsKey($parts[1])) { return ($parts[0] + $word_oct[$parts[1]]) }
    if($parts[1] -match '^\d+$') { return ($parts[0] + $parts[1]) }
  }

  foreach($w in $word_oct.Keys) {
    if($s.EndsWith($w)) {
      return ($s.Substring(0, $s.Length - $w.Length) + $word_oct[$w])
    }
  }

  return ($s -replace '\s','')
}

function Validate-Data {
  foreach($k in $SCALES.Keys) {
    if($SCALES[$k].Count -ne 7) { throw ("Scale '{0}' must have 7 notes, has {1}" -f $k, $SCALES[$k].Count) }
  }
  foreach($k in $CHORDS.Keys) {
    if($CHORDS[$k].Count -ne 3) { throw ("Chord '{0}' must have 3 notes, has {1}" -f $k, $CHORDS[$k].Count) }
  }
}

# ------------------ UI HELP ------------------

function Help-Main {
  Write-Host ""
  Write-Host "Menu options:"
  Write-Host "  1 = Key notes + diatonic triad qualities"
  Write-Host "  2 = Chord notes (root/third/fifth)"
  Write-Host "  3 = Note frequency (Hz)"
  Write-Host ""
  Write-Host "Global commands at any prompt:"
  Write-Host "  help  back  quit"
  Write-Host ""
}

function Help-Key {
  Write-Host ""
  Write-Host "Key examples:"
  Write-Host "  c major"
  Write-Host "  f minor"
  Write-Host "  d# minor"
  Write-Host "  eb major"
  Write-Host ""
  Write-Host "Accidentals accepted: #, b, sharp, flat, ♯, ♭"
  Write-Host "Type back to return to the main menu."
  Write-Host ""
}

function Help-Chord {
  Write-Host ""
  Write-Host "Chord examples:"
  Write-Host "  c major"
  Write-Host "  c minor"
  Write-Host "  e diminished"
  Write-Host "  gb major"
  Write-Host ""
  Write-Host "Accidentals accepted: #, b, sharp, flat, ♯, ♭"
  Write-Host "Type back to return to the main menu."
  Write-Host ""
}

function Help-Freq {
  Write-Host ""
  Write-Host "Frequency examples:"
  Write-Host "  a4"
  Write-Host "  a 4"
  Write-Host "  a four"
  Write-Host "  c#4"
  Write-Host "  eb 4"
  Write-Host ""
  Write-Host "Accidentals accepted: #, b, sharp, flat, ♯, ♭"
  Write-Host "Supported octaves in data set: 0 through 10 (where defined)."
  Write-Host "Type back to return to the main menu."
  Write-Host ""
}

# ------------------ FEATURES ------------------

function Show-Key {
  while($true) {
    $raw = Read-Host "What key do you want to see?"
    $cmd = Normalize $raw

    if($cmd -eq 'quit') { exit }
    if($cmd -eq 'back') { return }
    if($cmd -eq 'help') { Help-Key; continue }

    $key = Normalize-KeyName $raw
    if(-not $SCALES.ContainsKey($key)) {
      Write-Host ""
      Write-Host "Incorrect input. Type help if confused."
      Write-Host ""
      continue
    }

    $notes = $SCALES[$key]
    $qualities = if($key.EndsWith('major')) { $MAJOR_TRIADS } else { $MINOR_TRIADS }

    Write-Host ""
    for($i=0; $i -lt 7; $i++) {
      $pos = $SCALE_POSITION[$i]
      $note = (Format-Note $notes[$i].ToString()).ToUpperInvariant()
      $qual = $qualities[$i]
      Write-Host ("{0}`t {1}`t {2}" -f $pos, $note, $qual)
    }
    Write-Host ""
    return
  }
}

function Show-Chord {
  while($true) {
    $raw = Read-Host "What chord do you want to see?"
    $cmd = Normalize $raw

    if($cmd -eq 'quit') { exit }
    if($cmd -eq 'back') { return }
    if($cmd -eq 'help') { Help-Chord; continue }

    $chord = Normalize-KeyName $raw
    if(-not $CHORDS.ContainsKey($chord)) {
      Write-Host ""
      Write-Host "Incorrect input. Type help if confused."
      Write-Host ""
      continue
    }

    $notes = $CHORDS[$chord]
    Write-Host ""
    for($i=0; $i -lt 3; $i++) {
      $pos = $CHORD_POSITION[$i]
      $note = (Format-Note $notes[$i].ToString()).ToUpperInvariant()
      Write-Host ("{0}`t {1}" -f $pos, $note)
    }
    Write-Host ""
    return
  }
}

function Show-Freq {
  while($true) {
    $raw = Read-Host "What note do you want to see the frequency of?"
    $cmd = Normalize $raw

    if($cmd -eq 'quit') { exit }
    if($cmd -eq 'back') { return }
    if($cmd -eq 'help') { Help-Freq; continue }

    $note = Normalize-NoteOctave $raw
    if(-not $FREQS.ContainsKey($note)) {
      Write-Host ""
      Write-Host "Incorrect input. Type help if confused."
      Write-Host ""
      continue
    }

    Write-Host ("{0} Hz" -f $FREQS[$note])
    return
  }
}

function Main {
  Validate-Data

  Write-Host ""
  Write-Host "------------------------------------------------------------------"
  Write-Host "                   Pin Point Music (BAT)                          "
  Write-Host "------------------------------------------------------------------"
  Write-Host "Choose: 1 = Key, 2 = Chord, 3 = Frequency"
  Write-Host "Type help if confused. Type quit to exit."
  Write-Host ""

  while($true) {
    $ans = Normalize (Read-Host "Where would you like to go?")
    switch($ans) {
      '1' { Show-Key }
      '2' { Show-Chord }
      '3' { Show-Freq }
      'help' { Help-Main }
      'quit' { exit }
      default {
        Write-Host ""
        Write-Host "Incorrect response. Type help if confused."
        Write-Host ""
      }
    }
  }
}

Main

