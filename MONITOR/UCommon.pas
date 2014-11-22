unit UCommon;

interface

uses
  Classes;
{
type

  IMonitorMaster=interface
    procedure QueryArcView(Time:TDateTime);
    procedure NotifyActivity(Sender:TObject);
  end;

  IMonitorSlave=interface
    procedure Set_SpyMode(const Value:Boolean);
    function Get_SpyMode:Boolean;
    procedure Set_ArcEndTime(const Value:TDateTime);
    function Get_ArcEndTime:TDateTime;
    function Get_SpyEndTime:TDateTime;
    procedure Set_TimeCapacity(const Value: TDateTime);
    function Get_TimeCapacity: TDateTime;
    procedure Set_Negative(const Value:Boolean);
    procedure MyPaintTo(dc:HDC; X,Y:Integer);
    //
    property SpyMode:Boolean read Get_SpyMode write Set_SpyMode;
    property ArcEndTime:TDateTime read Get_ArcEndTime write Set_ArcEndTime;
    property SpyEndTime:TDateTime read Get_SpyEndTime;
    property TimeCapacity:TDateTime read Get_TimeCapacity write Set_TimeCapacity;
    property Negative:Boolean write Set_Negative;
    procedure TimerProc;
  end;
}
implementation

end.
