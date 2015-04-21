#!/bin/bash

for csvFile in *.csv; do

    num_lines=$(wc -l $csvFile | cut -f 1 -d " ")

    num_fields=$(cat $csvFile | awk -F ';' '{print NF}' | uniq)
    num_fields_no_newline=$(echo "$num_fields" | tr '\n' ' ')
    
    result=$(echo "$num_fields" | wc -l)
    
    if (( $result > 1 )); then
        echo "The CSV file '$csvFile' is invalid: variable number of columns: $num_fields_no_newline."
    else
        echo "The CSV file '$csvFile' is ok ($num_lines lines)."
    fi
done

