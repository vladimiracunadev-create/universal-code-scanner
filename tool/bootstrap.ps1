$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (Get-Command py -ErrorAction SilentlyContinue) {
    py -3 tool/bootstrap.py @args
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    python tool/bootstrap.py @args
} else {
    throw "Python 3 no está instalado o no está disponible en PATH."
}
