import pandas as pd 
import datetime
import requests
import time, json
import pprint
import re as reggie

import os
from dotenv import load_dotenv
load_dotenv()
api_key = os.environ.get('API_KEY')
api_secret = os.environ.get('API_SECRET')


#7 -Token List - Grads all the tokens on solana
def token_list():
    #url = "https://public-api.birdeye.so/defi/tokenlist"
    url = "https://public-api.birdeye.so/defi/tokenlist?sort_by=v24hUSD&sort_type=desc"

    headers = {'x-chain': 'solana', 'X-API-KEY': api_key}

    tokens = []
    offset = 0
    limit = -1
    total_tokens = 0
    num_tokens = 20000

    params = {'sort_by': 'v24hChangePercent', 'sort_type': 'desc', 'offset': offset}
    response = requests.get(url, headers=headers, params=params)

    if response.status_code == 200:
        data = response.json()
        print("API Response:")
        print(data)
    else:
        print("Error accessing API:")
        print(response.text)

token_list()
