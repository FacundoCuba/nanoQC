#!/bin/bash

# Function to display script usage
function display_usage() {
    echo "Usage: $0 -t TABLE -k KRAKEN_DB -g INTEGER -o STRING [-h]"
    echo ""
    echo "Options:"
    echo "  -t TABLE     Table file OR path to the table file"
    echo "  -k KRAKEN_DB Directory OR path to the directory of the Kraken2 database"
    echo "  -g INTEGER   Genome size"
    echo "  -o STRING    Output file basename"
    echo "  -h           Display this help message"
    echo ""
    exit 0
}

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        log_message "ERROR: File $1 not found"
        exit 1
    fi
}

# Function to check if directory exists
check_dir_exists() {
    if [ ! -d "$1" ]; then
        log_message "ERROR: Directory $1 not found"
        exit 1
    fi
}

# Initialize variables
barcode_sample_table=""
kraken_db=""
genome_size=0
output_basename=""

# Parse options using getopts
while getopts "t:k:g:o:h" option; do
    case "$option" in
        t) 
            if [[ "$OPTARG" = /* ]]; then
                barcode_sample_table="$OPTARG"
            else
                barcode_sample_table="$PWD/$OPTARG"
            fi
            ;;
        k) 
            if [[ "$OPTARG" = /* ]]; then
                kraken_db="$OPTARG"
            else
                kraken_db="$PWD/$OPTARG"
            fi
            ;;
        g) 
            if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                genome_size="$OPTARG"
            else
                echo "Error: Genome size must be a positive integer"
                exit 1
            fi
            ;;
        o) output_basename="$OPTARG";;
        h) display_usage;;
        :) printf "missing argument for -%s\n" "$OPTARG" >&2; display_usage >&2; exit 1;;
        \?) printf "illegal option: -%s\n" "$OPTARG" >&2; display_usage >&2; exit 1;;
    esac
done

# Check if required arguments are provided
if [ -z "$barcode_sample_table" ] || [ -z "$kraken_db" ] || [ "$genome_size" -eq 0 ] || [ -z "$output_basename" ]; then
    echo "Error: Arguments -t, -k, -g, and -o must be provided."
    display_usage
fi

# Validate input files and directories
check_file_exists "$barcode_sample_table"
check_dir_exists "$kraken_db"

log_message "Starting nanopore analysis pipeline"
log_message "Table file: $barcode_sample_table"
log_message "Kraken DB: $kraken_db"
log_message "Genome size: $genome_size"
log_message "Output basename: $output_basename"

# Ensure required tools are installed
for tool in NanoPlot porechop kraken2 bc; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        log_message "ERROR: $tool is required but not installed. Aborting."
        exit 1
    fi
done

# Create main working directory
mkdir -p "${output_basename}_analysis"
cd "${output_basename}_analysis" || exit 1

# Ensure the table file has a newline at the end
sed -i -e '$a\ ' "$barcode_sample_table"

# Step 1: Concatenate fastq files from barcode directories
log_message "Step 1: Concatenating FASTQ files from barcode directories"
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    barcode=$(echo "$line" | awk '{print $1}')
    if [ -n "$barcode" ] && [ -d "../$barcode" ]; then
        log_message "Processing barcode directory: $barcode"
        (
            cd "../$barcode" || exit 1
            if ls *.fastq.gz >/dev/null 2>&1; then
                cat *.fastq.gz > "../${output_basename}_analysis/${barcode}.fastq.gz"
                log_message "Files from $barcode directory concatenated as ${barcode}.fastq.gz"
            else
                log_message "WARNING: No .fastq.gz files found in $barcode directory"
            fi
        )
    else
        log_message "WARNING: Directory $barcode not found, skipping..."
    fi
done < "$barcode_sample_table"

# Step 2: Rename files based on sample names
log_message "Step 2: Renaming files based on sample names"
while IFS=$'\t' read -r barcode sample_name; do
    # Skip empty lines and comments
    [[ -z "$barcode" || "$barcode" =~ ^[[:space:]]*# ]] && continue
    
    if [ -f "${barcode}.fastq.gz" ] && [ -n "$sample_name" ]; then
        mv "${barcode}.fastq.gz" "${sample_name}.fastq.gz"
        log_message "Renamed ${barcode}.fastq.gz to ${sample_name}.fastq.gz"
    else
        log_message "WARNING: File ${barcode}.fastq.gz not found or sample name empty, skipping rename..."
    fi
done < "$barcode_sample_table"

# Step 3: Perform adapter trimming using Porechop
log_message "Step 3: Performing adapter trimming with Porechop"
for f in *.fastq.gz; do
    if [ -f "$f" ]; then
        log_message "Trimming adapters from $f"
        porechop -i "$f" -o "${f%.fastq.gz}_trimmed.fastq.gz" --threads 8
        if [ $? -eq 0 ]; then
            log_message "Successfully trimmed $f"
        else
            log_message "ERROR: Failed to trim $f"
            exit 1
        fi
    fi
done

# Step 4: Organize files into directories
log_message "Step 4: Organizing files into directories"
mkdir -p fastq_raw fastq_trimmed
for f in *_trimmed.fastq.gz; do
    [ -f "$f" ] && mv "$f" fastq_trimmed/
done
for f in *.fastq.gz; do
    [ -f "$f" ] && mv "$f" fastq_raw/
done

# Step 5: Perform QC analysis using NanoPlot
log_message "Step 5: Performing QC analysis with NanoPlot"
cd fastq_trimmed || exit 1
mkdir -p nanoplot

for f in *_trimmed.fastq.gz; do
    if [ -f "$f" ]; then
        log_message "Creating NanoPlot report for sample ${f%_trimmed.fastq.gz}"
        NanoPlot -o "nanoplot/${f%.fastq.gz}_nanoplot" -t 8 --tsv_stats --only-report --info_in_report --N50 --no_static -p "${f%.fastq.gz}_" --fastq "$f"
        if [ $? -eq 0 ]; then
            log_message "NanoPlot completed for ${f%_trimmed.fastq.gz}"
        else
            log_message "WARNING: NanoPlot failed for $f"
        fi
    fi
done

# Step 6: Generate summary report
log_message "Step 6: Generating NanoPlot summary report"
cd nanoplot/ || exit 1
output_file="${output_basename}_nanoplot_summary.tsv"

# Write the header to the output file
echo -e "sample_name\tnumber_of_reads\tnumber_of_bases\tmedian_read_length\tmean_read_length\tread_length_stdev\tn50\tmean_qual\tmedian_qual\tmean_depth" > "$output_file"

# Loop through the input files and append the results to the output file
export LC_NUMERIC=C
for f in */*_NanoStats.txt; do
    if [ -f "$f" ]; then
        sample_name=$(basename "${f%_NanoStats.txt}")
        
        # Extract individual values from specific lines
        number_of_reads=$(awk 'NR==2 {print $2}' "$f" 2>/dev/null)
        number_of_bases=$(awk 'NR==3 {print $2}' "$f" 2>/dev/null)
        median_read_length=$(awk 'NR==4 {print $2}' "$f" 2>/dev/null)
        mean_read_length=$(awk 'NR==5 {print $2}' "$f" 2>/dev/null)
        read_length_stdev=$(awk 'NR==6 {print $2}' "$f" 2>/dev/null)
        n50=$(awk 'NR==7 {print $2}' "$f" 2>/dev/null)
        mean_qual=$(awk 'NR==8 {print $2}' "$f" 2>/dev/null)
        median_qual=$(awk 'NR==9 {print $2}' "$f" 2>/dev/null)
        
        # Calculate depth
        if [ -n "$number_of_bases" ] && [ "$number_of_bases" != "0" ]; then
            depth=$(echo "scale=2; $number_of_bases / $genome_size" | bc -l 2>/dev/null)
            
            # Write all values in a single line with tab separation
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\n" \
                "$sample_name" "$number_of_reads" "$number_of_bases" \
                "$median_read_length" "$mean_read_length" "$read_length_stdev" \
                "$n50" "$mean_qual" "$median_qual" "$depth" >> "$output_file"
            
            log_message "Processed statistics for $sample_name"
        else
            log_message "WARNING: Could not calculate depth for $sample_name - invalid number of bases"
        fi
    fi
done
unset LC_NUMERIC

log_message "NanoPlot summary report created: $output_file"
mv "$output_file" ../
cd ../

# Step 7: Perform taxonomic classification using Kraken2
log_message "Step 7: Performing taxonomic classification with Kraken2"
mkdir -p kraken2
for f in *_trimmed.fastq.gz; do
    if [ -f "$f" ]; then
        log_message "Running Kraken2 classification for $f"
        kraken2 --db "$kraken_db" --threads 8 --gzip-compressed --report "kraken2/${f%.fastq.gz}_kraken2.txt" --use-names "$f"
        if [ $? -eq 0 ]; then
            log_message "Kraken2 completed for ${f%_trimmed.fastq.gz}"
        else
            log_message "ERROR: Kraken2 failed for $f"
            exit 1
        fi
    fi
done

cd ../

log_message "Pipeline completed successfully!"
log_message "Results are available in: $(pwd)"
