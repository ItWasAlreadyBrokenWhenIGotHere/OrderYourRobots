#!/usr/bin/env python3


def calculate_csv_row_count(csv_file_name):

    # Calculate CSV row count and return result
    with open(csv_file_name) as f:
        rowcount = sum(1 for line in f)
        rowcount = rowcount - 1  # need to -1 from row count as 1st row is for headers
        return rowcount
