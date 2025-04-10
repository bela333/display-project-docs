Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
pandoc --top-level-division chapter --filter pandoc-minted.py -s --bibliography main.bib --citeproc -o build/main.tex .\main.md .\metadata.yaml
if ($LASTEXITCODE -gt 0) {
    throw "pandoc execution failed"
}
pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex
if ($LASTEXITCODE -gt 0) {
    throw "pdflatex first execution failed"
}
pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex
if ($LASTEXITCODE -gt 0) {
    throw "pdflatex second execution failed"
}