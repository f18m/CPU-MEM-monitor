#!/bin/bash

decimationFactor=10

echo "Removing previous script results (if any)"
rm decimated-*.gz >/dev/null 2>&1

for csvFile in *.csv; do
    num_lines=$(wc -l $csvFile | cut -f 1 -d " ")

    num_fields=$(cat $csvFile | awk -F ';' '{print NF}' | uniq)
    num_fields_no_newline=$(echo "$num_fields" | tr '\n' ' ')

    result=$(echo "$num_fields" | wc -l)
    if (( $result > 1 )); then
        echo "The CSV file '$csvFile' has a variable number of columns: $num_fields. Discarding it."
    else
        newName="decimated-$csvFile"
        awk "NR == 1 || NR % $decimationFactor == 0" $csvFile >$newName
        
        num_lines_after=$(wc -l $newName | cut -f 1 -d " ")
        gzip $newName
        
        echo "Decimated CSV file '$csvFile' keeping 1 line every $decimationFactor lines (from $num_lines to $num_lines_after lines)... saved compressed result into '$newName.gz'"
    fi
done

echo "Decimation script completed"

