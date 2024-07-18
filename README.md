# README under construction

# nanoQC
This script is designed to automate the processing and quality control (QC) analysis of sequencing data files. It reads a table of barcodes and sample names, concatenates `*.fastq.gz` files, renames them according to sample names, and generates comprehensive QC summary report using NanoPlot.

## Table of Contents
- [Installation](#installation)
- [Requirements](#requirements)
- [Input table format](#input-table-format)
- [Usage](#usage)
- [The Output](#the-output)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

## Installation
Just download the script.

## Requirements
 [NanoPlot](https://github.com/wdecoster/NanoPlot): Ensure NanoPlot is installed and accessible in your PATH.
 Be kind and please acknowledge these great authors too!

## Input table format

## Usage
Execute the script at the `fastq_pass` directory.
To run the script, use the following command:
```bash
./script_name.sh -t <TABLE> -g <GENOME_SIZE>
```

### Options
- `-t` Table file or path to the table file containing barcodes and sample names.
- `-g` Genome size for depth calculation. An integer > 0.
- `-h` Display usage information.

### Example
```bash
./script_name.sh -t barcode_sample_table.tsv -g 5000000
```

## The Output

## Contact
For questions or issues, please open an issue in this repository or contact facundogcuba@gmail.com.

## Acknowledgments
