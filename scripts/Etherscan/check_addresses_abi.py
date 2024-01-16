import json
import os
import csv
from time import sleep
from etherscan import Etherscan

INPUT_FILE = ''
OUTPUT_FILE = ''
DATA_DIR = ''

REQUESTS_PER_SECOND = 5  # Adjust based on the Etherscan API limits
API_KEY = '' # Etherscan API key

eth = Etherscan(API_KEY)

def check_and_write_events(out, contract_address, abi):
    for element in abi:
        if element["type"] == "event":
            event_name = element["name"]
            event_inputs = element["inputs"]
            if event_name == "ProxyUpdated" and len(event_inputs) == 2 and event_inputs[0]["type"] == event_inputs[1]["type"] == "address":
                out.write(contract_address + '\n')
            elif event_name == "Upgraded" and len(event_inputs) == 1 and event_inputs[0]["type"] == "address":
                out.write(contract_address + '\n')

def main():
    input_file_path = os.path.join(DATA_DIR, INPUT_FILE)
    output_file_path = os.path.join(DATA_DIR, OUTPUT_FILE)

    with open(input_file_path, 'r') as csv_file:
        with open(output_file_path, 'w') as out:
            csv_reader = csv.reader(csv_file, delimiter='\n')
            for index, row in enumerate(csv_reader):
                contract_address = row[0]
                res = eth.get_contract_abi(contract_address)
                abi = json.loads(res)
                check_and_write_events(out, contract_address, abi)
                sleep(1/REQUESTS_PER_SECOND)

if __name__ == "__main__":
    main()
