
#!/usr/bin/env bash
# Extract modification calls from a BAM to a one line format, for input
# into extract_calls.pl
#
# usage: extract_call.sh bam
bam_file="$1"

samtools view "$bam_file" -@ 8 | \
    awk '{
        read_id = $1
        seq = $10
        mm = ""; ml = ""
        # parse tags (fields from 12 onwards)
        for (i=12; i<=NF; i++) {
            if ($i ~ /^MM:Z:/) mm = substr($i,6)
            if ($i ~ /^ML:B:C,/) ml = substr($i,8)
        }
        if (mm != "" && ml != "")
            print read_id"\t"seq"\t"mm"\t"ml
    }'