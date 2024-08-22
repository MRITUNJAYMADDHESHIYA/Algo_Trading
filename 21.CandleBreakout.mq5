/*
1.create high/low fo previous bar




*/


#include<Trade/Trade.mqh>
///////////////////Inputs/////////////////////////
input double          InpLotsize          = 0.01;    //lotsize
input int             InpStopLoss         = 100;     //stop loss
input int             InpTakeProfit       = 300;     //take profit
////////////////////Global variable///////////////
int lastBreakout = 0;
CTrade trade;


int OnInit(){
    return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){

}

void OnTick(){

    double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
    high = NormalizeDouble(high, _Digits);
    double low  = iLow(_Symbol, PERIOD_CURRENT, 1);
    low = NormalizeDouble(low, _Digits);


    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    //double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    if(lastBreakout <= 0 && bid > high){
        Print(__FUNCTION__," > Buy Signal");
        lastBreakout = 1;

        double sl = NormalizeDouble(low, _Digits);

        trade.Buy(InpLotsize, _Symbol, 0, sl);

    }else if(lastBreakout >= 0 && bid < low){
        Print(__FUNCTION__," > Sell Signal");
        lastBreakout = -1;

        double sl = NormalizeDouble(high, _Digits);

        trade.Sell(InpLotsize,_Symbol, 0, sl);
    }

    ///////////Trailing sl//////////////////////
    ///move sl high and low of the last candle
    for(int i=PositionsTotal()-1; i>=0; i--){
        ulong posTicket = PositionGetTicket(i); //index selection of position
        CPositionInfo pos;
        if(pos.SelectByTicket(posTicket)){
            if(pos.PositionType() == POSITION_TYPE_BUY){
                if(low > pos.StopLoss()){
                    trade.PositionModify(pos.Ticket(), low, pos.TakeProfit());
                }
            }else if(pos.PositionType() == POSITION_TYPE_SELL){
                if(high < pos.StopLoss()){
                    trade.PositionModify(pos.Ticket(), high, pos.TakeProfit());
                }
            }
        }
    }

    Comment("\nBid: ", bid,
            "\nHigh: ", high,
            "\nLow:  ", low);
}