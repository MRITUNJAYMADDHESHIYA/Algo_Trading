import ccxt
import math
import pandas as pd
import time
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')
import numpy as np


#############Inputs###########
symbol = 'uBTCUSD'
size = 30000
lockout_losee = 3000 #dollar
mo_size = size/4
leverage = 10
num_order = 2
max_time = 4200 #mintue
max_daily_trades = 3
size_usd = 1000

target = 8
max_loss = -3.7

tp_spread = 2
target_multiple = 3
params = {'timeInForce': 'PostOnly',}

########################Account##########

phemex = ccxt.phemex({
    'enableRateLimit':True,
    'apiKey': '***************',
    'secret': '************************************************'
})

def ask_bid(symbol=symbol):
    ob = phemex.fetch_order_book(symbol)

    bid = ob['bids'][0][0]
    ask = ob['asks'][0][0]
    print(f'bid: {bid} ask: {ask}')

    bid_liq = ob['bids'][0][1]
    ask_liq = ob['asks'][0][1]
    print(f'bid liq: {bid_liq} ask liq: {ask_liq}')

    return ask, bid, ob, ask_liq, bid_liq

def pos_info(symbol=symbol):
    params = {'type':'swap', 'code':'USD'}

    balance = phemex.fetch_balance(params=params)
    open_positions = balance['info']['data']['positions']

    pos_df = pd.DataFrame.from_dict(open_positions)


    pos_cost = pos_df.loc[pos_df['symbol']==symbol, 'postCost'].values[0]
    side = pos_df.loc[pos_df['symbol']==symbol, 'side'].values[0]
    pos_cost = float(pos_cost)

    pos_size = pos_df.loc[pos_df['symbol']==symbol, 'size'].values[0]
    size = float(pos_size)
    entryPrice = pos_df.loc[pos_df['symbol']==symbol, 'avgEntryPrice'].values[0]
    entry_price = float(entryPrice)
    leverage = pos_df.loc[pos_df['symbol']==symbol, 'leverage'].values[0]
    leverage = float(leverage)


    print(f'symbol: {symbol} side: {side} lev: {leverage} size: {size} entry: {entry_price}')
    return pos_cost, side, size, entry_price, leverage

timeframe = '4h'
limit = 100
sma = 20
def df_sma(symbol=symbol, timeframe=timeframe, limit=limit, sma=sma):

    bars = phemex.fetch_ohlcv(symbol, timeframe=timeframe, limit=limit)
    #print(bars)
    df_sma = pd.DataFrame(bars,columns=['timestamp','open','high','low','close','volume'])
    df_sma['timestamp'] = pd.to_datetime(df_sma['timestamp'],unit='ms')


    #daily sma 20
    df_sma[f'sma{sma}_{timeframe}'] = df_sma.close.rolling(sma).mean()

    #if bid < the 20 day sma then bearish
    #if bid > the 20 day sma then bullish
    bid = ask_bid(symbol)[1]

    #if sma>bid = sell, if sma < bid = buy
    df_sma.loc[df_sma[f'sma{sma}_{timeframe}']>bid, 'sig'] = 'SELL'
    df_sma.loc[df_sma[f'sma{sma}_{timeframe}']<bid, 'sig'] = 'BUY'

    df_sma['support'] = df_sma[:-2]['close'].min()
    df_sma['resistance'] = df_sma[:-2]['close'].max()

    df_sma['PC'] = df_sma['close'].shift(1)

    #last close bigger than previous close
    #going to add this to ensure we only open 
    #order on reversal confirmation

    df_sma.loc[df_sma['close']>df_sma['PC'],'lcBpc'] = True
                 #2.981>2.966 = true
    df_sma.loc[df_sma['close']<df_sma['PC'], 'lcBpc'] = False
                #2.980<2.981 == False
                #2.966<2.967 == False
    
    return df_sma
    

sd_time = '4h'
def supply_demand_zones(sd_time = sd_time):
    #get OHLCV data
    sd_limit = 200 #candles
    sd_sma = 20

    df = df_sma(symbol, sd_time, sd_limit, sd_sma)
    print(df)

supply_demand_zones()