#!/bin/bash

threshold=100


for csvFile in *.csv; do

    num_lines=$(wc -l $csvFile | cut -f 1 -d " ")
    
    if (( $num_lines < $threshold )); then
        echo "The CSV file '$csvFile' is too small: $num_lines lines; deleting it."
        rm $csvFile
    else
        echo "The CSV file '$csvFile' is ok ($num_lines lines)."
    fi
done

