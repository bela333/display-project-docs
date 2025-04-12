Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
pandoc --top-level-division chapter -f markdown+implicit_figures --filter pandoc-crossref --filter pandoc-minted.py -s --bibliography main.bib --citeproc -o build/main.tex .\main.md .\metadata.yaml
if ($LASTEXITCODE -gt 0) {
    throw "pandoc execution failed"
}
pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex
pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex