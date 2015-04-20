#!/bin/bash

decimationFactor=10

echo "Removing previous script results"
rm decimated-*.gz

for csvFile in *.csv; do

    num_fields=$(cat $csvFile | awk -F ';' '{print NF}' | uniq)
    result=$(echo "$num_fields" | wc -l)
    if (( $result > 1 )); then
        echo "The CSV file '$csvFile' has a variable number of columns: $num_fields. Discarding it."
    else
        newName="decimated-$csvFile"
        
        echo "Decimating CSV file '$csvFile' keeping 1 line every $decimationFactor lines... saving result into '$newName'"
        awk "NR == 1 || NR % $decimationFactor == 0" $csvFile >$newName
        
        echo "Compressing file '$newName'"
        gzip $newName
    fi
done

echo "Decimation script completed"

