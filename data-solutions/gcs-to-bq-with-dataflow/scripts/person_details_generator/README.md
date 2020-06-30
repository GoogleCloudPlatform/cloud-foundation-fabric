# Create random Person PII data

In this example you can find a Python script to generate Person PII data in a CSV file format.

To know how to use the script run:

```hcl
python3 person_details_generator.py --help
```

## Example
To create a file 'person.csv' with 10000 of random person details data you can run:
```hcl
python3 person_details_generator.py \
--count 10000 \
--output person.csv 
```