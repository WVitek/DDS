unit USortedList;

interface

uses
  Classes;

type
  TSortedList = class(TList)
  private
    FSorted:Boolean;
    FDuplicates: TDuplicates;
    FCompareFunc: TListSortCompare;
    procedure QuickSort(L, R: Integer; Compare: TListSortCompare);
    procedure SetSorted(Value: Boolean);
    procedure SetCompareFunc(const Value: TListSortCompare);
  public
    function Add(Item:Pointer):Integer;reintroduce;
    function FindAndDelete(Item:Pointer):Boolean;
    function Find(Item:Pointer; var Index: Integer): Boolean;
    procedure CustomSort(Compare: TListSortCompare);
    procedure RemoveLast;
    procedure RemoveFirst;
    procedure Sort;
    property Duplicates: TDuplicates read FDuplicates write FDuplicates;
    property Sorted: Boolean read FSorted write SetSorted;
    property CompareFunc:TListSortCompare read FCompareFunc write SetCompareFunc;
  end;

implementation

uses SysUtils;

function NoCompareFunc(Item1,Item2:Pointer):Integer;
begin
  raise Exception.Create('TSortedList - no CompareFunc specified');
  Result:=0;
end;

{ TSortedList }

function TSortedList.Add(Item:Pointer): Integer;
begin
  if not Sorted then
    Result := Count
  else
    if Find(Item, Result) then
      case Duplicates of
        dupIgnore: Exit;
        dupError: Error('dupError', 0);
      end;
  inherited Insert(Result, Item);
end;

function TSortedList.Find(Item:Pointer; var Index:Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  if not Sorted then begin
    I:=IndexOf(Item);
    Index:=I;
    Result:=I>=0;
    exit;
  end;
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := FCompareFunc(Items[I], Item);
    if C < 0 then L := I + 1 else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        if Duplicates <> dupAccept then L := I;
      end;
    end;
  end;
  Index := L;
end;

procedure TSortedList.QuickSort(L, R: Integer; Compare: TListSortCompare);
var
  I, J, P: Integer;
  IP:Pointer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      IP:=Items[P];
      while Compare(Items[I], IP) < 0 do Inc(I);
      while Compare(Items[J], IP) > 0 do Dec(J);
      if I <= J then begin
        IP:=Items[I]; Items[I]:=Items[J]; Items[J]:=IP;
        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J, Compare);
    L := I;
  until I >= R;
end;

procedure TSortedList.SetSorted(Value: Boolean);
begin
  if FSorted <> Value then
  begin
    if Value then Sort;
    FSorted := Value;
  end;
end;

procedure TSortedList.Sort;
begin
  CustomSort(FCompareFunc);
end;

procedure TSortedList.CustomSort(Compare: TListSortCompare);
begin
  if not Sorted and (Count > 1) then begin
    QuickSort(0, Count - 1, Compare);
  end;
end;

procedure TSortedList.SetCompareFunc(const Value: TListSortCompare);
begin
  if @Value<>@FCompareFunc then begin
    FCompareFunc := Value;
    if Sorted then begin
      FSorted:=False; Sort; FSorted:=True;
    end;
  end;
end;

procedure TSortedList.RemoveFirst;
begin
  Delete(0);
end;

procedure TSortedList.RemoveLast;
begin
  Delete(Count-1);
end;

function TSortedList.FindAndDelete(Item: Pointer): Boolean;
var
  Index:Integer;
begin
  Result:=Find(Item,Index);
  if Result then Delete(Index);
end;

end.
