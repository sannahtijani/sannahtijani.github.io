#!/bin/bash

# Usage:
# ./generate_notesheet.sh [directory] [vspace] [right_margin]

# Check if a directory is provided as the first argument; if not, default to the current directory
if [ -z "$1" ]; then
    dir="."
else
    dir="$1"
fi

# Ensure the specified directory exists
if [ ! -d "$dir" ]; then
    echo "Error: Directory '$dir' does not exist."
    exit 1
fi

# Check if a vspace value is provided as the second argument; if not, default to 1.5
if [ -z "$2" ]; then
    vspace_value="1.5"
else
    vspace_value="$2"
fi

# Check if a right margin value is provided as the third argument; if not, default to 9
if [ -z "$3" ]; then
    right_margin="9"
else
    right_margin="$3"
fi

# Change to the specified directory
cd "$dir" || exit

# Create the "notesheets" directory inside the specified directory if it doesn't exist
[ ! -d "notesheets" ] && mkdir "notesheets"

# Get current date and time
timestamp=$(date +"%Y%m%d_%H%M")

# Output filename
output_file="notesheets/notesheet_${timestamp}.pdf"

# Get list of PDFs in the specified directory, sorted alphabetically
mapfile -t pdf_files < <(find . -maxdepth 1 -type f -name "*.pdf" -printf "%P\n" | sort)

# Start writing the LaTeX file
cat > notesheet_temp.tex << EOF
\documentclass[a4paper]{article}
\usepackage[left=0.5cm,right=${right_margin}cm,top=2cm,bottom=2cm]{geometry}
\usepackage{graphicx}
\usepackage{xfp} % For calculations
\usepackage{pgffor} % For looping
\usepackage{pdfpages} % To get total page count
\pagestyle{empty}

\begin{document}
EOF

# Loop over each PDF and include its pages
for pdf in "${pdf_files[@]}"; do
    echo "% Processing file: $pdf" >> notesheet_temp.tex
    echo "\\pdfximage{$pdf}" >> notesheet_temp.tex
    echo "\\edef\\npages{\\the\\pdflastximagepages}" >> notesheet_temp.tex
    echo "\\foreach \\pagenumber in {1,...,\\npages} {" >> notesheet_temp.tex
    echo "    \\begin{center}" >> notesheet_temp.tex
    echo "        \\includegraphics[page=\\pagenumber,width=\\linewidth]{$pdf}" >> notesheet_temp.tex
    echo "    \\end{center}" >> notesheet_temp.tex
    echo "    \\vspace{${vspace_value}em}" >> notesheet_temp.tex
    echo "}" >> notesheet_temp.tex
done

# End the LaTeX document
echo "\\end{document}" >> notesheet_temp.tex

# Run pdflatex to compile the LaTeX file
pdflatex -interaction=nonstopmode notesheet_temp.tex

# Move the output PDF to the desired location
mv notesheet_temp.pdf "$output_file"

# Clean up temporary files
rm notesheet_temp.tex notesheet_temp.aux notesheet_temp.log

echo "Note sheet created at $dir/$output_file with vspace of ${vspace_value}em and right margin of ${right_margin}cm."

