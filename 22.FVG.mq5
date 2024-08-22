/*
1.It's not completed->something in this video I can't understand
2.how much gap in points
3.
*/

#property indicator_chart_window

#include<Arrays/ArrayObj.mqh>
////////////////////////Inputs///////////////////////////
enum ENUM_FVG_TYPE {
    FVG_UP,
    FVG_DOWN
};

input int FvgMinPoints    = 10;   //minPointsFVG
input int FvgMaxPoints    = 50;   //maxPointsFVG
input int FvgMaxLength    = 20;   //maxlengthFVG

CArrayObj FvgGapStore;
//////////////////////Class/////////////////////////////
class CFairValueGap : public CObject {  //OPPs
    public:
        ENUM_FVG_TYPE type;
        datetime      time;
        double        high;
        double        low;

        void draw(datetime time2){
            string objName = "fvg "+TimeToString(time);
            if(ObjectFind(0,objName) < 0){
                ObjectCreate(0,objName,OBJ_RECTANGLE,0,time,high,time2,low);
                ObjectSetInteger(0,objName,OBJPROP_FILL, true);
                ObjectSetInteger(0,objName,OBJPROP_COLOR,(type == FVG_UP ?clrLightBlue:clrOrange));
            }
            ObjectSetInteger(0,objName, OBJPROP_TIME, 1, time2);
        }
};

int OnInit(){

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
    ObjectsDeleteAll(0,"fvg");
}


///////Calculations based on the current timeframe timeseries
//////The function is called in the indicators when the Calculate event occurs for processing price data changes.
int OnCalculate(const int rates_total,  //total bars
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[]){
    
    ArraySetAsSeries(time,true);
    ArraySetAsSeries(high,true);
    ArraySetAsSeries(low,true);

    int limit =  rates_total - prev_calculated;
    //////Initially 3 bars exits
    if(limit > rates_total-2){
        limit = rates_total - 3;
    }

    for(int i=limit; i>=1; i++){
        bool isFvgUp = low[i]-high[i+2] > FvgMinPoints*_Point && high[i+2]-low[i] < FvgMaxPoints*_Point;
        bool isFvgDown = low[i+2]-high[i] > FvgMinPoints*_Point && low[i+2]-high[i] < FvgMaxPoints*_Point;

        if(isFvgUp || isFvgDown){
            CFairValueGap* fvg = new CFairValueGap();  //OOPs
            fvg.type = isFvgUp ? FVG_UP : FVG_DOWN;
            fvg.time = time[i];
            fvg.high = isFvgUp ? low[i] : low[i+2];
            fvg.low  = isFvgUp ? high[i+2] : high[i];

            //fvg.draw(time[i] + PeriodSeconds(PERIOD_CURRENT)*FvgMaxLength);

            FvgGapStore.Add(fvg);
        }

        for(int j=FvgGapStore.Total()-1; j>=0; j--){
            CFairValueGap* fvg = FvgGapStore.At(j); //store all fvg in FvgGapStore

            fvg.draw(time[i]);
            if(time[i] > fvg.time + PeriodSeconds(PERIOD_CURRENT)*FvgMaxLength) FvgGapStore.Delete(j);
            else if(fvg.type == FVG_UP && low[i] <= fvg.low) FvgGapStore.Delete(j);
            else if(fvg.type == FVG_DOWN && high[i] >= fvg.high) FvgGapStore.Delete(j);
        }
    }

    return(rates_total);
}