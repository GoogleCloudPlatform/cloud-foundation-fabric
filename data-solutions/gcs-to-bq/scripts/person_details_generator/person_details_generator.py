# Copyright 2020 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""`person_details_generator.py` is a Python script to generate random 
Person PII (name, surname and age) having as input an array of 
names and an array of surnames.
"""

import click
import logging
import random


@click.command()
@click.option("--count", default=100, help="Number of generated names.")
@click.option("--output", default=False, help="Name of the output file. Content will be overwriten. If not defined, standard output will be used.")
@click.option("--first_names", default="Lorenzo,Giacomo,Chiara,Miriam", help="String of Names, comma separated. Default 'Lorenzo,Giacomo,Chiara,Miriam'")
@click.option("--last_names", default="Rossi, Bianchi,Brambilla,Caggioni", help="String of Names, comma separated. Default 'Rossi,Bianchi,Brambilla,Caggioni'")
def main(count, output, first_names, last_names):
    generated_names = "".join(random.choice(first_names.split(',')) + "," +
                              random.choice(last_names.split(',')) + "," +
                              str(random.randint(1, 100)) + "\n" for _ in range(count))[:-1]
    if output:
        f = open(output, "w")
        f.write(generated_names)
        f.close()
    else:
        print(generated_names)


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    main()
