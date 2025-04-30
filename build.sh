#!/bin/bash
PANDOC_ACRONYMS_ACRONYMS=acronyms.json
./pandoc-3.6.4/bin/pandoc --top-level-division chapter -f markdown+implicit_figures --filter pandoc-crossref --filter pandoc-minted.py --filter pandoc-acronyms -s --citeproc -o build/main.tex main.md metadata.yaml &&
 docker run --rm -v ./:/workdir danteev/texlive /bin/bash -c "pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex && pdflatex -shell-escape -interaction=batchmode -output-directory build build/main.tex"

