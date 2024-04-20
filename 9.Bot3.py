'''
ToDo:-
1.get the df2 file 
2.working on kill_swicth, size_kill, active_orders












'''
import ccxt
import pandas as pd
import time
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')


#####################Inputs###############
size=3
symbol = 'uBTCUSD'
perc_from_lh = .35
close_seconds = 60*47
max_lh = 800
timeframe = '1m'
num_bars = 180
max_risk = 1000 #in 1000$
sl_perc = 0.002
max_tr = 550
quartile = 0.33
time_limit = 60
sleep = 30

#######################Account########################

phemex = ccxt.phemex({
    'enableRateLimit':True,
    'apiKey': "b8888888888888888888888888888888lvegcJtt3",
    'secret': "voDsh************************************1AqCpm3"
})

####################################################

def kill_switch():
    pass

#for risk if size ever gets too big
def size_kill():
    pass


#it's find the position is open or close 
#it's only work on balance
def open_positions():
    params = {'type':'swap', 'code':'USD'}
    all_phe_balance = phemex.fetch_balance(params=params)
    open_position = all_phe_balance['info']['data']['positions']
    #print(open_position)
    openpos_side = open_position[3]['side']
    openpos_size = open_position[3]['size']
    print(f'DEBUGGING ======= openpos_side: {openpos_side}')


    if openpos_side == ('Buy'):
        openpos_bool = True
        long = True

    elif openpos_side == ('Sell'):
        openpos_bool = True
        long = False

    else:
        openpos_bool = False

    return open_positions, openpos_bool, openpos_size, long


#get the bid and ask
def get_ask_bid(symbol=symbol):
    ob = phemex.fetch_order_book(symbol)

    bid = ob['bids'][0][0]
    ask = ob['asks'][0][0]
    print(f'bid: {bid} ask: {ask}')

    bid_liq = ob['bids'][0][1]
    ask_liq = ob['asks'][0][1]
    print(f'bid liq: {bid_liq} ask liq: {ask_liq}')

    return ask, bid, ob, ask_liq, bid_liq



def active_orders():
    pass

def active_orders2():
    pass


##########For Volatility#####
###find the true range
def tr(data):
    data['previous_close'] = data['close'].shift(1)
    data['high-low'] = abs(data['high'] - data['low'])
    data['high-pc'] = abs(data['high'] - data['previous_close'])
    data['low-pc'] = abs(data['low'] - data['previous_close'])
    tr = data[['high-low', 'high-pc', 'low-pc']].max(axis=1)
    return tr
#we are calculating the ATR
def atr(data, period):
    data['tr'] = tr(data)
    atr = data['tr'].rolling(period).mean()
    return atr
#No trade atr
def no_trade_atr(data):
    data['no_trade_atr'] = (data['tr'] > max_tr).any()
    no_trade_atr = data['no_trade_atr']

    return no_trade_atr


def frame(df, period=7):
    df['atr'] = atr(df, period)

    return df


########################
####################BOT########
########################

def bot():
    
    size_kill() #close the position if ever over max_risk

    df2 = pd.DataFrame()
    #df2 = pd.read_csv('')


    now = datetime.now()
    dt_string = now.strftime("%m/%d/%Y %H:%M:%S")
    print(dt_string)
    comptime = int(time.time())
    print(comptime)

    ##looking for last close was and making sure we do not overtrade
    try:
        last_close_time = df2['close_time'].values[-1]
        last_close_time = int(last_close_time)
        print(last_close_time)
    except:
        print('we are fine but we had to go 2 close times')
        print('this is not good fix, need to see what happened with ')
        last_close_time = df2['close_time'].values[-2]
        last_close_time = int(last_close_time)
        print(last_close_time)

        bid_ask = get_ask_bid()
        ask = bid_ask[0]
        bid = bid_ask[1]

        open_pos = open_positions()
        activeorders2 = active_orders2()
        print(f'sl_n_close_bool, need_sl, need_close_order, already_limit_to_open')

        sl_n_close_bool = activeorders2[0]
        need_sl = activeorders2[1]
        need_close = activeorders2[2]
        already_limit_to_open = activeorders2[3]
