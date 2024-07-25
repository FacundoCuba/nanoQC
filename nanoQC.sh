#!/bin/bash

# Function to display script usage
function display_usage() {
    echo "Usage: $0 -t TABLE -g INTEGER -o STRING [-h]"
    echo ""
    echo "Options:"
    echo "  -t TABLE     Table file OR path to the table file"
    echo "  -g INTEGER   Genome size"
    echo "  -o STRING    Output file basename"
    echo "  -h           Display this help message"
    exit 0
}

# Initialize variables
barcode_sample_table=""
genome_size=0
output_basename=""

# Parse options using getopts
while getopts "t:g:o:h" option; do
    case "$option" in
        t) barcode_sample_table=$PWD/$OPTARG;;
        g) genome_size=$OPTARG;;
        o) output_basename=$OPTARG;;
        h) display_usage;;
        :) printf "missing argument for -%s\n" "$OPTARG" >&2; display_usage >&2; exit 1;;
        \?) printf "illegal option: -%s\n" "$OPTARG" >&2; display_usage >&2; exit 1;;
    esac
done

# Check if required arguments are provided
if [ -z "$barcode_sample_table" ] || [ -z "$genome_size" ] || [ -z "$output_basename" ]; then
    echo "Error: Arguments -t, -g, and -o must be provided."
    display_usage
fi

# Ensure required tools are installed
command -v NanoPlot >/dev/null 2>&1 || { echo >&2 "NanoPlot is required but it's not installed. Aborting."; exit 1; }

# Read the file line by line for column 1 - barcodes
while IFS= read -r line; do
    # Extract the specified column using awk
    barcode=$(echo "$line" | awk -v col=1 '{print $col}')
    if [ -d "$barcode" ]; then
        cd "$barcode" || exit
        cat *.fastq.gz > "../${barcode}.fastq.gz"
        echo "Files at ${barcode} directory concatenated as ${barcode}.fastq.gz"
        cd ..
    else
        echo "Directory $barcode not found, skipping..."
    fi
done < "$barcode_sample_table"
echo ""

# Read the file line by line for both columns - barcodes & sample names
while IFS=$'\t' read -r barcode sample_name; do
    if [ -f "${barcode}.fastq.gz" ]; then
        mv "${barcode}.fastq.gz" "${sample_name}.fastq.gz"
        echo "Renamed ${barcode}.fastq.gz to ${sample_name}.fastq.gz"
    else
        echo "File ${barcode}.fastq.gz not found, skipping rename..."
    fi
done < "$barcode_sample_table"
echo ""

# Perform a QC analysis using NanoPlot
mkdir -p nanoplot
for f in *.fastq.gz; do 
    echo "Creating NanoPlot report for sample ${f%.fastq.gz}"
    NanoPlot -o "nanoplot/${f%.fastq.gz}_nanoplot" -t 8 --tsv_stats --only-report --info_in_report --N50 --no_static -p "${f%.fastq.gz}_" --fastq "$f"
done
echo ""

cd nanoplot/ || exit
output_file="${output_basename}_nanoplot_summary.tsv"

# Write the header to the output file
echo -e "sample_name\tnumber_of_reads\tnumber_of_bases\tmedian_read_length\tmean_read_length\tread_length_stdev\tn50\tmean_qual\tmedian_qual\tmean_depth" > "$output_file"

# Loop through the input files and append the results to the output file
for f in */*_NanoStats.txt; do
    sample_name=$(basename "${f%_NanoStats.txt}")
    
    # Set the locale to C to handle decimal points correctly
    export LC_NUMERIC=C

    # Extract values from line 2 to line 9 at column 2
    values=$(awk 'NR>=2 && NR<=9 {print $2}' "$f")

    # Extract the value at line 3, column 2
    line3_value=$(awk 'NR==3 {print $2}' "$f")

    # Calculate the new value (line 3 value divided by the integer provided)
    depth=$(echo "$line3_value / $genome_size" | bc -l)

    # Print the extracted values formatted as tsv along with the new value and sample name
    printf "%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n" "$sample_name" $values $depth >> "$output_file"

    # Reset the locale to the default
    unset LC_NUMERIC
done
echo "Full summary report at $output_file"
echo ""

mv "$output_file" ../
cd ../
