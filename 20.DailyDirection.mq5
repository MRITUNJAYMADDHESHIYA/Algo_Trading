


#include<Trade/Trade.mqh>
///////////////////////Inputs///////////////////
input double         InpLotSize              = 0.01;      //lot size
input int            InpStopLoss             = 100;       //stoploss(0=off)
input int            InpTakeProfit           = 300;       //take profit
input int            InpTurnaroundDistPoints = 100;       //turning point

input string         InpTradeTime            = "01:00";   //trade time
input double         InpMartingalFactor      = 1;         //martingal factor

input int            InpTriggerPoint         = 100;       //if tp is this
input int            InpTrailingSL           = 50;        //trailing sl
////////////////////Global Variable//////////////
CTrade trade;
int totalbars;
ulong posTicket;
///////////////////Function/////////////////////
int OnInit(){
    totalbars = iBars(_Symbol, PERIOD_D1);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int rrason){

}

void OnTick(){

    int bars = iBars(_Symbol, PERIOD_D1);
    ///update the daily bar everyday
    if(totalbars != bars){

        ////////////////previous candle direction
        double open  = iOpen(_Symbol, PERIOD_D1, 1);
        double close = iClose(_Symbol, PERIOD_D1, 1);
        int prevBarDirection = 0;
        if(open < close) prevBarDirection = 1;
        if(open > close) prevBarDirection = -1;

        
        /////if we found a position then we have to decied 
        //close the position or give them some condition and contiune the bars
        if(posTicket > 0){
            if(trade.PositionClose(posTicket)){
                posTicket = 0;
            }else{

                //
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                if((posType == POSITION_TYPE_BUY && prevBarDirection < 0) ||
                    (posType == POSITION_TYPE_SELL && prevBarDirection > 0)){
                        ///////////close the position if direction has changed
                        if(trade.PositionClose(posTicket)){
                            posTicket = 0;
                        }
                    }
                    //////////////////keep the position open if the direction hasn't changed
                    else{
                        totalbars = bars;
                    }
            }
        }

        datetime tradeTime = StringToTime(InpTradeTime); //trade open after the one hour
        /////////If there is no position open
        if(posTicket <= 0 && TimeCurrent() > tradeTime){

            if(prevBarDirection > 0){
                //buy
                trade.Buy(InpLotSize);
            }else if(prevBarDirection < 0){
                //sell
                trade.Sell(InpLotSize);
            }

           /////////////if open a position then update the bars and positionTicket
            if(trade.ResultOrder() > 0){
                totalbars = bars;
                posTicket = int(trade.ResultOrder());
            }
        }

        //////////////////////Turning points trade/////////////
        /////if previous day bullish and 100 points lower than opening current bar then sell the position and sell a new position
        /////if previous day bullish and 100 points lower than opening current bar then sell the position and sell a new position
        if(posTicket > 0){
            if(PositionSelectByTicket(posTicket)){
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);


                double posPricOpen   = PositionGetDouble(POSITION_PRICE_OPEN);
                double posStopLoss   = PositionGetDouble(POSITION_SL);
                double posTakeProfit = PositionGetDouble(POSITION_TP);
                double posVolume     = PositionGetDouble(POSITION_VOLUME);
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
 
                double lots = posVolume * InpMartingalFactor;
                lots = NormalizeDouble(lots, 2);

                if(posType == POSITION_TYPE_BUY){
                    //////////////////trailing sl//////////////
                    if(InpTrailingSL > 0 && bid > posPricOpen + InpTriggerPoint * _Point){
                        double sl = bid - InpTrailingSL * _Point;
                        sl = NormalizeDouble(sl,_Digits);
                        if(sl > posStopLoss){
                            trade.PositionModify(posTicket,sl, posTakeProfit);
                        }
                    }
                    ////////////////////open position in opposite////////////////
                    if(bid < posPricOpen - InpTurnaroundDistPoints*_Point){
                        if(trade.PositionClose(posTicket)){
                            if(trade.Sell(lots)){
                                posTicket = trade.ResultOrder();
                            }
                        }
                    }
                }else if(posType == POSITION_TYPE_SELL){
                    ////////////////trailing sl///////////
                    if(InpTrailingSL > 0 && ask < posPricOpen - InpTriggerPoint * _Point){
                        double sl = ask + InpTrailingSL * _Point;
                        sl = NormalizeDouble(sl,_Digits);
                        if(sl < posStopLoss){
                            trade.PositionModify(posTicket,sl, posTakeProfit);
                        }
                    }
                    ////////////////open a position in opposite///////////
                    if(ask > posPricOpen + InpTurnaroundDistPoints*_Point){
                        if(trade.PositionClose(posTicket)){
                            if(trade.Buy(lots)){
                                posTicket = trade.ResultOrder();
                            }
                        }
                    }
                }
            }
        }
    }

    Comment("\n Order: #", posTicket);
}