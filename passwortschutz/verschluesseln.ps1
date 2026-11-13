# Verschluesselt Kommunikationskit.html mit einem Passwort und schreibt index.html
# (die Seite, die auf GitHub Pages veroeffentlicht wird).
#
# Aufruf (fragt das Passwort ab):
#   powershell -ExecutionPolicy Bypass -File passwortschutz\verschluesseln.ps1
#
# Nach jeder Aenderung an Kommunikationskit.html erneut ausfuehren.
# Neues Passwort = Skript mit neuem Passwort ausfuehren; gespeicherte Anmeldungen verfallen dann.

param(
  [string]$Passwort,
  [string]$Quelle = (Join-Path $PSScriptRoot '..\Kommunikationskit.html'),
  [string]$Ziel   = (Join-Path $PSScriptRoot '..\index.html')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Security

if (-not $Passwort) {
  $s1 = Read-Host 'Passwort' -AsSecureString
  $s2 = Read-Host 'Passwort wiederholen' -AsSecureString
  $plain = { param($s) [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)) }
  $Passwort = & $plain $s1
  if ($Passwort -ne (& $plain $s2)) { throw 'Die Passwoerter stimmen nicht ueberein.' }
}
if ($Passwort.Length -lt 6) { throw 'Bitte mindestens 6 Zeichen verwenden.' }

$utf8 = New-Object System.Text.UTF8Encoding($false)
$iter = 600000
$rng  = [Security.Cryptography.RandomNumberGenerator]::Create()
$salt = New-Object byte[] 16; $rng.GetBytes($salt)

# Schluessel ableiten: 32 Byte fuer AES-256, 32 Byte fuer HMAC-SHA256
$kdf  = New-Object Security.Cryptography.Rfc2898DeriveBytes($utf8.GetBytes($Passwort), $salt, $iter, [Security.Cryptography.HashAlgorithmName]::SHA256)
$bits = $kdf.GetBytes(64)
$encKey = $bits[0..31]; $macKey = $bits[32..63]

$aes = [Security.Cryptography.Aes]::Create()
$aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'; $aes.Key = $encKey; $aes.GenerateIV()
$klar = $utf8.GetBytes([IO.File]::ReadAllText((Resolve-Path $Quelle), $utf8))
$ct  = $aes.CreateEncryptor().TransformFinalBlock($klar, 0, $klar.Length)
$hmac = New-Object Security.Cryptography.HMACSHA256(,$macKey)
$mac = $hmac.ComputeHash([byte[]]($aes.IV + $ct))

$payload = '{"iter":' + $iter + ',"salt":"' + [Convert]::ToBase64String($salt) + '","iv":"' + [Convert]::ToBase64String($aes.IV) +
           '","ct":"' + [Convert]::ToBase64String($ct) + '","mac":"' + [Convert]::ToBase64String($mac) + '"}'
$vorlage = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'passwort-seite.html'), $utf8)
$zielPfad = [IO.Path]::GetFullPath($Ziel)
[IO.File]::WriteAllText($zielPfad, $vorlage.Replace('__PAYLOAD__', $payload), $utf8)
Write-Host "Fertig: $zielPfad"
