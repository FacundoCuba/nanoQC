# README under construction

# nanoQC
This script is designed to automate the processing and quality control (QC) analysis of Nanopore sequencing data files. It reads a table of barcodes and sample names, concatenates `*.fastq.gz` files, renames them according to sample names, and generates a comprehensive QC summary report using NanoPlot.

## Table of Contents
- [Installation](#installation)
- [Requirements](#requirements)
- [Input table format](#input-table-format)
- [Usage](#usage)
- [Output](#output)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

## Installation
Just download the script.

## Requirements
 [NanoPlot](https://github.com/wdecoster/NanoPlot): Ensure NanoPlot is installed and accessible in your PATH.
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
Execute the script at the `fastq_pass` directory.
To run the script, use the following command:
```bash
./script_name.sh -t <TABLE> -g <GENOME_SIZE>
```

### Options
- `-t` Table file OR path to the table file containing barcodes and sample names.
- `-g` Genome size for depth calculation. An integer > 0.
- `-h` Display usage information.

### Example
```bash
./script_name.sh -t barcode_sample_table.tsv -g 5000000
```

## Output
- A `fastq.gz` file named according to the sample name and barcode number.
- A summary table for all the samples named `nanoplot_summary.tsv` containing the following columns: sample_name, number_of_reads, number_of_bases, median_read_length, mean_read_length, read_length_stdv, n50, mean_qual, median_qual, and mean_depth.

## Contact
For questions or issues, please open an issue in this repository or contact facundogcuba@gmail.com.

## Acknowledgments
