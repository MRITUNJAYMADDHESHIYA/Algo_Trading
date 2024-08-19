//day.1.Calculating start time + end time + close time and Objects

//day.2.Draw high and Low
   //2.1.Breakout then open position
   //2.2.close the position

//day.3.tp and sl
   //3.1.close time optional
   //3.2.day_of_week on range 
   //3.3.One breakout per range

#include <Trade/Trade.mqh>
/////////////////////Inputs////////////////////
input group "==== Range Inputs ===="
input int InpRangeStart      = 600;      //range start time in minutes
input int InpRangeDuration   = 120;      //range duration in mintes
input int InpRangeClose      = 1200;     //range close time(-1=off)

input group "==== General Inputs ===="
input double InpLots         = 0.01;     //In lots
input long InpMagicNumber    = 1235;     //magic number
input int InpStopLoss        = 150;      //stop loss in % of the range(0=off)
input int InpTakeProfit      = 200;      //take profit int % of the range(0=off)

input group "==== Day of week filter ===="
input bool InpMonday         = true;     //range on monday
input bool InpTuesday        = true;     //range on tuesday
input bool InpWednesday      = true;     //range on wednesday
input bool InpThursday       = true;     //range on thursday
input bool InpFriday         = true;     //range on friday

input group "==== One/Two signal ===="
enum BREAKOUT_MODE_ENUM {
   ONE_SIGNAL,                           //one breakout per trade
   TWO_SIGNAL                            //high and low breakout
};
input BREAKOUT_MODE_ENUM InpBreakoutMode = ONE_SIGNAL;   //breakout mode

///////////////////Global Variable////////////
struct RANGE_STRUCT{
   datetime start_time;      //start of the range
   datetime end_time;        //end of the range
   datetime close_time;      //close time

   double high;              //high of range
   double low;               //low of range
   bool f_entry;             //flag if we are inside the range
   bool f_high_breakout;     //flag if a high breakout occured
   bool f_low_breakout;      //flag if a low breakout occured
   
   RANGE_STRUCT(): start_time(0),end_time(0),close_time(0),high(0),low(DBL_MAX),f_entry(false),f_high_breakout(false),f_low_breakout(false) {};
};


RANGE_STRUCT range;
MqlTick prevTick, lastTick;
CTrade trade;


///////////////////////Initialization////////////////////
int OnInit(){

   ///////////check inputs//////////////////////
   if(!CheckInputs()){return INIT_PARAMETERS_INCORRECT;}

   ///////////Set Magic number///////////////
   trade.SetExpertMagicNumber(InpMagicNumber);

   //////////calculate new range if inputs changed
   if(_UninitReason==REASON_PARAMETERS && CountOpenPositions()==0){   //no position open ++++
      CalculateRange();
   }

   //draw objects
   DrawObjects();
   
   return(INIT_SUCCEEDED);
 }



void OnDeinit(const int reason){
   //delete objects
   ObjectsDeleteAll(NULL,"range");
}


////////////////////////////Function//////////////////////////
void OnTick(){

   /////////get current tick
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);


   ////////////////range calculation high and low  if Inside the range
   if(lastTick.time >= range.start_time && lastTick.time < range.end_time){
      //set flag
      range.f_entry = true;
      //new high
      if(lastTick.ask > range.high){
         range.high = lastTick.ask;
         DrawObjects();
      }
      //new low
      if(lastTick.bid < range.low){
         range.low = lastTick.bid;
         DrawObjects();
      }
   }


   ////////////////////////close position////////////////////////
   if(InpRangeClose>=0 && lastTick.time >= range.close_time){
      if(!ClosePositions()){return;}
   }


   ///////////////calculate new range if.../////////////////////
   if(((InpRangeClose >= 0 && lastTick.time >= range.close_time) ||                 //close time reached
      (range.f_high_breakout && range.f_low_breakout) ||                            //both breakout flag are true
      (range.end_time == 0) ||                                                      //range not calculated yet
      (range.end_time != 0 && lastTick.time > range.end_time && !range.f_entry))    //there was a range calculated but no tick inside
      && CountOpenPositions() == 0){

      CalculateRange();
      }

      /////////check for breakouts///////////////////////
      CheckBreakouts();
}


////////////////////////Check Inputs///////////////////////
bool CheckInputs(){

   if(InpMagicNumber <= 0){
      Alert("Magicnumber <= 0");
      return false;
   }
   if(InpLots <= 0 || InpLots > 1){
      Alert("Lots <= 0 or > 1");
      return false;
   }
   if(InpStopLoss < 0 || InpStopLoss > 1000){
      Alert("stop loss <0 or stoploss > 1000");
      return false;
   }
   if(InpTakeProfit < 0 || InpTakeProfit > 1000){
      Alert("Take profit < 0 or >=1000");
      return false;
   }
   if(InpRangeClose < 0 && InpStopLoss == 0){
      Alert("Close time and stoploss is off");
      return false;
   }
   
   //Max value for one day in min. 
   if(InpRangeStart < 0 || InpRangeStart >= 1440){
      Alert("Range start < 0 or >= 1440");
      return false;
   }
   if(InpRangeDuration < 0 || InpRangeDuration >= 1440){
      Alert("Range Duration <= 0 or >= 1440");
      return false;
   }
   if(InpRangeClose >= 1440 || (InpRangeStart + InpRangeDuration)%1440 == InpRangeClose){
      Alert("Close time < 0 or >= 1440 or end time == close time");
      return false;
   }

   if(InpMonday+InpTuesday+InpWednesday+InpThursday+InpFriday == 0){
      Alert("Range is prohibited on all days of the week");
      return false;
   }

   return true;
}


////////////////////calculate a new range///////////////////////////////
void CalculateRange(){
   //reset range variable
   range.start_time = 0;
   range.end_time = 0;
   range.close_time = 0;
   range.high = 0.0;
   range.low = DBL_MAX;
   range.f_entry = false;
   range.f_high_breakout = false;
   range.f_low_breakout = false;
   
   int time_cycle = 86400;


   //calculate range start time
   range.start_time = (lastTick.time - (lastTick.time % time_cycle)) + InpRangeStart*60;
   ////////saturday + sunday have to be pass then stating range is Monday
   for(int i=0; i<8; i++){
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if(lastTick.time >= range.start_time || dow == 6 || dow == 0 || (dow==1 && !InpMonday) || 
         (dow==2 && !InpTuesday)|| (dow==3 && !InpWednesday)|| (dow==4 && !InpThursday)|| (dow==5 && !InpFriday)){
         range.start_time += time_cycle;
      }
   }
   
   
   //calculate range end time
   range.end_time = range.start_time + InpRangeDuration*60;
   ////////saturday + sunday have to be pass then Ending range is Monday
   for(int i=0; i<2; i++){
      MqlDateTime tmp;
      TimeToStruct(range.end_time, tmp);
      int dow = tmp.day_of_week;
      if(dow == 6 || dow == 0){
         range.end_time += time_cycle;
      }
   }


   //calculate range close
   if(InpRangeClose>=0){
      range.close_time = (range.end_time - (range.end_time % time_cycle)) + InpRangeClose*60;
      ////////saturday + sunday have to be pass then range CLOSE is Monday
      for(int i=0; i<3; i++){
         MqlDateTime tmp;
         TimeToStruct(range.close_time, tmp);
         int dow = tmp.day_of_week;
         if(range.close_time <= range.end_time || dow == 6 || dow == 0){
            range.close_time += time_cycle;
         }
      }
   }

   /////////////draw objects////////////////////////
   DrawObjects();
}


///////////////////////////Count the open position///////////////////////////
int CountOpenPositions(){

   int counter = 0;
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){
         Print("Failed to get position ticket"); 
         return -1;
      }
      if(!PositionSelectByTicket(ticket)){
         Print("Failed to select position");
         return -1;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){
         Print("Failed to get position magicnumber");
         return -1;
      }
      if(magic == InpMagicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){
               Print("Failed to get position type");
               return -1;
         }
      }
   }
   return counter;
}



/////////////////////////Breakout and open the position/////////////////////
void CheckBreakouts(){

   //check if we are after the range end
   if(lastTick.time >= range.end_time && range.end_time >0 && range.f_entry){

      /////check for high breakout
      if(!range.f_high_breakout && lastTick.ask >= range.high){
         range.f_high_breakout = true;

         //if high_breakout open then no low_breakout
         if(InpBreakoutMode == ONE_SIGNAL){range.f_low_breakout = true;}

         //calculate stoploss and take profit
         double sl = InpStopLoss == 0 ? 0 : NormalizeDouble(lastTick.bid - ((range.high - range.low)*InpStopLoss*0.01),_Digits);
         double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.bid + ((range.high - range.low)*InpTakeProfit*0.01),_Digits);

         //open buy position
         trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLots,lastTick.ask,sl,tp,"Time range");
      }

      /////check for low breakout
      if(!range.f_low_breakout && lastTick.bid <= range.low){
         range.f_low_breakout = true;

         //if low_brakout open then no high_breakout
         if(InpBreakoutMode == ONE_SIGNAL){range.f_high_breakout = true;}

         //calculate stoploss and take profit
         double sl = InpStopLoss == 0 ? 0 : NormalizeDouble(lastTick.ask + ((range.high - range.low)*InpStopLoss*0.01),_Digits);
         double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.ask - ((range.high - range.low)*InpTakeProfit*0.01),_Digits);

         //open sell position
         trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLots,lastTick.bid,sl,tp,"Time range");
      }
   }

}


//////////////////////close the position/////////////////////////
bool ClosePositions(){

   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);   //select position
      if(ticket<=0){Print("Failed to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)){Print("Failed to select position"); return false;}

      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}
      if(magic == InpMagicNumber){
         trade.PositionClose(ticket);
         if(trade.ResultRetcode() != TRADE_RETCODE_DONE){
            Print("Failed to close position. Result:"+(string)trade.ResultRetcode()+":"+trade.ResultRetcodeDescription());
            return false;
         }
      }
   }
   return true;
}



///////////////////////Draw the Objects////////////////////
void DrawObjects(){

   //start time
   ObjectDelete(NULL, "range start");
   if(range.start_time > 0){
      ObjectCreate(NULL, "range start", OBJ_VLINE, 0, range.start_time,0);
      ObjectSetString(NULL, "range star", OBJPROP_TOOLTIP,"start of the range \n"+TimeToString(range.start_time,TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL,"range start", OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(NULL,"range start", OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range start", OBJPROP_BACK,true);
   }

   //end time
   ObjectDelete(NULL, "range end");
   if(range.end_time > 0){
      ObjectCreate(NULL, "range end", OBJ_VLINE, 0, range.end_time,0);
      ObjectSetString(NULL, "range end", OBJPROP_TOOLTIP,"end of the range \n"+TimeToString(range.end_time,TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL,"range end", OBJPROP_COLOR,C'144,144,249');
      ObjectSetInteger(NULL,"range end", OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range end", OBJPROP_BACK,true);
   }

   //close time
   ObjectDelete(NULL, "range close");
   if(range.close_time > 0){
      ObjectCreate(NULL, "range close", OBJ_VLINE, 0, range.close_time,0);
      ObjectSetString(NULL, "range close", OBJPROP_TOOLTIP,"close of the range \n"+TimeToString(range.close_time,TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL,"range close", OBJPROP_COLOR,C'246,9,9');
      ObjectSetInteger(NULL,"range close", OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range close", OBJPROP_BACK,true);
   }

   //high
   ObjectsDeleteAll(NULL, "range high");
   if(range.high > 0){
      ObjectCreate(NULL, "range high", OBJ_TREND, 0, range.start_time, range.high, range.end_time, range.high);
      ObjectSetString(NULL, "range high", OBJPROP_TOOLTIP,"high of the range \n"+DoubleToString(range.high, _Digits));
      ObjectSetInteger(NULL,"range high", OBJPROP_COLOR,C'68,9,246');
      ObjectSetInteger(NULL,"range high", OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range high", OBJPROP_BACK,true);

      ObjectCreate(NULL, "range high ", OBJ_TREND, 0, range.end_time, range.high, InpRangeClose>=0 ? range.close_time : INT_MAX, range.high);
      ObjectSetString(NULL, "range high ", OBJPROP_TOOLTIP,"high of the range \n"+DoubleToString(range.high, _Digits));
      ObjectSetInteger(NULL,"range high ", OBJPROP_COLOR,C'89,9,247');
      ObjectSetInteger(NULL,"range high ", OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(NULL,"range high ", OBJPROP_BACK,true);
   }

   //low
   ObjectsDeleteAll(NULL, "range low");
   if(range.low < DBL_MAX){
      ObjectCreate(NULL, "range low", OBJ_TREND, 0, range.start_time, range.low, range.end_time, range.low);
      ObjectSetString(NULL, "range low", OBJPROP_TOOLTIP,"low of the range \n"+DoubleToString(range.low, _Digits));
      ObjectSetInteger(NULL,"range low", OBJPROP_COLOR,C'68,9,246');
      ObjectSetInteger(NULL,"range low", OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range low", OBJPROP_BACK,true);

      ObjectCreate(NULL, "range low ", OBJ_TREND, 0, range.end_time, range.low, InpRangeClose>=0 ? range.close_time : INT_MAX, range.low);
      ObjectSetString(NULL, "range low ", OBJPROP_TOOLTIP,"low of the range \n"+DoubleToString(range.low, _Digits));
      ObjectSetInteger(NULL,"range low ", OBJPROP_COLOR,C'68,9,246');
      ObjectSetInteger(NULL,"range low ", OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(NULL,"range low ", OBJPROP_BACK,true);
   }

   //refresh chart
   ChartRedraw();
}

