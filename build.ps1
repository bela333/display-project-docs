Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
pandoc --top-level-division chapter --filter pandoc-minted.py -s --bibliography main.bib --citeproc -o build/main.tex .\main.md .\metadata.yaml
pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex
pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex