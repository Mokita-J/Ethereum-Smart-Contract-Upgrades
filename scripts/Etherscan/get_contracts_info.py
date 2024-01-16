import json
import os
import csv
import re
from time import sleep
from etherscan import Etherscan

INPUT_FILE = ''
DATA_DIR = ''
OUTPUT_DIR = ''

REQUESTS_PER_SECOND = 5  # Adjust based on the Etherscan API limits
API_KEY = '' # Etherscan API key

eth = Etherscan(API_KEY)

def process_source_code(code, contract_address, parent_path, index):
    source_code = code["SourceCode"]

    if source_code == "":
        return

    path = os.path.join(parent_path, contract_address)
    os.makedirs(path, exist_ok=True)

    if source_code[0] == '{':
        sources = json.loads(source_code[1:len(source_code)-1])["sources"]
        for name, content in sources.items():
            raw = content['content']
            filtered = re.sub(r'^import.*\n?', '', raw, flags=re.MULTILINE)
            simple_name = re.findall(r'/(?P<found_string>[^/]+\.sol)', name)[0]
            with open(os.path.join(path, f"{index}_{simple_name}"), "w") as file:
                file.write(filtered)
    else:
        with open(os.path.join(path, f"{index}.sol"), "w") as file:
            file.write(source_code)

    with open(os.path.join(path, f"{index}.abi"), "w") as file:
        file.write(code["ABI"])

    version_raw = code["CompilerVersion"]
    version = re.findall("\d.*\+", version_raw)[0][0:-1]
    with open(os.path.join(path, f"{index}.version"), "w") as file:
        file.write(version)

    with open(os.path.join(path, f"{index}.json"), "w") as file:
        json.dump(code, file)

def main():
    with open(os.path.join(DATA_DIR, INPUT_FILE)) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter='\n')
        for index, row in enumerate(csv_reader):
            contract_address = row[0]
            res = eth.get_contract_source_code(contract_address)

            for index, code in enumerate(res):
                process_source_code(code, contract_address, OUTPUT_DIR, index)
                
            sleep(1/REQUESTS_PER_SECOND)

if __name__ == "__main__":
    main()