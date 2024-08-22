//day.1. 4 candle green then 1 candle red then sell
//       4 candle red then 1 candle green then buy

#include<Trade/Trade.mqh>
#include<Trade/PositionInfo.mqh>

//////////////////Inputs///////////////////////////
input group " ==== General ==== "
input int       InpMagicnumber     = 532156;     //magic number
input double    InpLotSize         = 0.01;       //lot size

input group " ==== Trading ==== "
input ENUM_TIMEFRAMES       InpTimeframe     = PERIOD_CURRENT;  //time frame
input int                   InpStopLoss      = 100;             //stoploss(points)
input int                   InpTakeProfit    = 400;             //take profit(points)

input int                   InpTrendBars     = 3;
/////////////////Global variable///////////////////
CTrade trade;
int barsTotal; //i want to open one position at current condition happen

///////////////////////Function////////////////////
int OnInit(){
    return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){
}

void OnTick(){

    int bars = iBars(_Symbol,PERIOD_CURRENT);
    if(barsTotal != bars){
        barsTotal = bars;

        double open1  = iOpen(_Symbol, InpTimeframe, 1);
        double close1 = iClose(_Symbol, InpTimeframe, 1);

        if(open1 < close1){//last bar was green
            bool isTrend = true;
            for(int i=2; i<InpTrendBars + 2; i++){
                double openi  = iOpen(_Symbol, InpTimeframe, i);
                double closei = iClose(_Symbol, InpTimeframe, i);

                if(openi < closei) isTrend = false; //no green candle allow
            }
            if(isTrend){
                double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
                double tp = ask + InpTakeProfit*_Point;
                double sl = iLow(_Symbol, PERIOD_CURRENT, iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, InpTrendBars+1, 1));

                trade.Buy(InpLotSize, _Symbol, ask, sl, tp);
            }
        }else if(open1 > close1){
            //last bar was red
            bool isTrend = true;
            for(int i=2; i<InpTrendBars + 2; i++){
                double openi  = iOpen(_Symbol, InpTimeframe, i);
                double closei = iClose(_Symbol, InpTimeframe, i);

                if(openi > closei) isTrend = false; //no red candle allow
            }
            if(isTrend){
                double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
                double tp = bid - InpTakeProfit*_Point;
                double sl = iHigh(_Symbol, PERIOD_CURRENT, iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, InpTrendBars+1, 1));

                trade.Sell(InpLotSize, _Symbol, bid, sl, tp);
            }
        }
    }
}


//Normalization of price(sl/tp)
bool NormalizePrice(double &price){

    double tickSize = 0;
    if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
        Print("Failed to get tick size");
        return false;
    }
    price = NormalizeDouble((price/tickSize)*tickSize, _Digits);

    return true;
}