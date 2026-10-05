<#
.SYNOPSIS
  Runs the Bookly test suite.

.DESCRIPTION
  Each test file gets its own `flutter test` process.

  This is not stylistic. A single `flutter test` invocation with several
  suites in it makes `testWidgets` cases die silently: they report
  "did not complete" after about two seconds with no error text, and the
  behaviour is consistent across a full run while the very same files pass
  when run alone. Plain `test()` cases are never affected, which is what
  makes the failure so misleading - the count looks almost right.

  Verified: 3/3 full multi-suite runs failed with 8 tests never completing,
  while every file run in its own process passed, twice running.

  Set -PassThru to capture each file's output instead of only printing the
  failures.

.EXAMPLE
  powershell -File tool/test.ps1
#>
[CmdletBinding()]
param(
  # Print full output for every file, not just the ones that fail.
  [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$files = Get-ChildItem -Recurse -Filter '*_test.dart' -Path test |
  Sort-Object FullName

if ($files.Count -eq 0) {
  Write-Host 'No test files found under test/.' -ForegroundColor Red
  exit 1
}

$failed = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
  $capture = Join-Path ([System.IO.Path]::GetTempPath()) 'bookly_test_out.txt'
  & flutter test -j 1 $file.FullName > $capture 2>&1
  $exit = $LASTEXITCODE
  $output = Get-Content $capture -Raw

  $result = if ($exit -eq 0) { 'ok' } else { 'FAIL' }
  $colour = if ($exit -eq 0) { 'Green' } else { 'Red' }
  Write-Host ('  {0,-44} {1}' -f $file.Name, $result) -ForegroundColor $colour

  if ($exit -ne 0) {
    $failed.Add($file.FullName)
  }
  if ($PassThru -or $exit -ne 0) {
    Write-Host $output
  }
}

Write-Host ''
if ($failed.Count -gt 0) {
  Write-Host ("{0} of {1} test file(s) failed:" -f $failed.Count, $files.Count) `
    -ForegroundColor Red
  $failed | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  exit 1
}

Write-Host ("All {0} test file(s) passed." -f $files.Count) -ForegroundColor Green
exit 0
