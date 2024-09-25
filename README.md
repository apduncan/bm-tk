# bm-tk
Simple pipeline for predicting bacterial **b**ase **m**odification from PacBio HiFi
sequencing data with kinetics tags.

Currently, the pipeline will
1. Filter out BAMs which seem irrelevant by name 
(contain `fail`, `unassigned`, `subread`, `scrap`)
2. Filter out any BAMS which do not contain the required kinetics tags 
(`CHECK_KINETICS`)
3. Predict 6ma base modification using fibertools (`PREDICT_FIBERTOOLS`)
4. Extract modifications to table using modkit (`EXTRACT_CALLS`)

The default install of fibertools is from conda, and will not support use of
the GPU.
If you want to use GPU to improve speed of prediction, refer to the installation
instructions in the fibertools documentation.