# bm-tk
Simple pipeline for predicting bacterial **b**ase **m**odification from PacBio HiFi
sequencing data with kinetics tags.

Currently the output design is to store the output BAMs alongside the input files,
with the prefix `fibertools_predict.{input_bam}`. We implement a custom 
check for whether output already exists, and filter any inputs which have output
files in the expected location. These will be logged by the pipeline. This behaviour
can be disabled by setting `--clobber true`.

Currently, the pipeline will
1. Filter out BAMs which seem irrelevant by name 
(contain `fail`, `unassigned`, `subread`, `scrap`, `fibertools_preidct`), or which have existing
output files.
2. Filter out any BAMS which do not contain the required kinetics tags 
(`CHECK_KINETICS`)
3. Predict 6ma base modification using [fibertools](https://fiberseq.github.io/fibertools/) (`PREDICT_FIBERTOOLS`)
4. Extract modifications to table using [modkit](https://github.com/nanoporetech/modkit) (`EXTRACT_CALLS`).
This extraction is optional, and is not done by default for space reasons. Enable by settting
`--extract_calls true`.

The default install of fibertools is from conda, and will not support use of
the GPU.
If you want to use GPU to improve speed of prediction, refer to the installation
instructions in the fibertools documentation.

## Installation notes
Installing fibertools with GPU features requires cmake, FindBin.pm, git.