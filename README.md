# nanoQC
This script is designed to automate the quality control (QC) analysis of Nanopore sequencing data files. It reads a table of barcodes and sample names, concatenates `*.fastq.gz` files, renames them according to sample names, and generates a comprehensive QC summary report using NanoPlot.

## Table of Contents
- [Installation](#installation)
- [Requirements](#requirements)
- [Input table format](#input-table-format)
- [Usage](#usage)
- [Output](#output)
- [Contact](#contact)

## Installation
Just download the script.

## Requirements
- [porechop](https://github.com/rrwick/Porechop)
- [NanoPlot](https://github.com/wdecoster/NanoPlot)
- [kraken2](https://github.com/DerrickWood/kraken2)
 
 Ensure this tools are installed and accessible in your PATH.
 Be kind and please acknowledge these great authors too!

## Input table format
The input table must have two columns:
- The first column contains the names of the barcodes you wish to analyze.
- The second column contains the sample names corresponding to those barcodes.
  Example:
  ```
  barcode-1 sample_name-1
  barcode-2 sample_name-2
  barcode-3 sample_name-3
  ...
  barcode-n sample_name-n
  ```

## Usage
Execute the script at the `fastq_pass` directory or where the barcode directories are.
To run the script, use the following command:
```bash
./nanoQC.sh -t <TABLE> -g <GENOME_SIZE> -o <OUTPUT_BASENAME>
```

### Options
- `-t` Table file OR path to the table file containing barcodes and sample names.
- `-g` Genome size for depth calculation. An integer > 0.
- `-o` Output file basename.
- `-h` Display usage information.

### Example
```bash
./nanoQC.sh -t E_coli_barcodes.tsv -g 5000000 -o E_coli
```

## Output
- A fastq_raw directory where the `*_fastq.gz` files are.
- A fastq_trimmed directory where the `*_trimmed.fastq.gz` files are. Inside this directory you will also find a summary table for all the samples named `output_basename_nanoplot_summary.tsv` and two subdirectories: nanoplot and kraken2.
  - `nanoplot` directory contains the Nanoplot report for each sample.
  - `kraken2` directory contains the kraken2 report for each sample.

## Contact
For questions or issues, please open an issue in this repository or contact facundogcuba@gmail.com.
