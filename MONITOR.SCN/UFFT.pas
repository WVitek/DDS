unit UFFT;

interface

uses
  Windows; //use PSingle type

procedure MyFFT(Src,Dst:PSingle; n,nCutOffHigh:Integer);

procedure FFT(var Ar,Ai:array of double; Order:Integer; Inverse:Boolean);

implementation

procedure MyFFT(Src,Dst:PSingle; n,nCutOffHigh:Integer);
var
  Ar,Ai:array of Double;
  i,Order,L:Integer;
begin
  Order:=1;
  while (1 shl Order) < n do Inc(Order);
  L:=1 shl Order;
  SetLength(Ar,L); FillChar(Ar[0],L*SizeOf(Ar[0]),0);
  SetLength(Ai,L); FillChar(Ai[0],L*SizeOf(Ai[0]),0);
  for i:=0 to n-1 do begin
    Ar[i]:=Src^; Inc(Src);
  end;
  FFT(Ar,Ai,Order,False);
  for i:=n-nCutOffHigh to n-1 do begin Ar[i]:=0; Ai[i]:=0; end;
  FFT(Ar,Ai,Order,True);
  for i:=0 to n-1 do begin
    Dst^:=Ar[i]; Inc(Dst);
  end;
end;

procedure FFT(var Ar,Ai:array of double; Order:Integer; Inverse:Boolean);
var
  Le,Le1,jt,it,ip,lt,kt:Integer;
  Tr,Ti,Ur,Ui,Wr,Wi,Sign,Z:Double;
  n:Integer;
begin
  if Inverse then Sign:=-1 else Sign:=1;
  n:=1 shl Order;
  for it:=0 to n-1 do begin
    kt:=n shr 1;
    jt:=0;
    Le:=1;
    Le1:=it;
    for lt:=1 to Order do begin
      if kt<=Le1 then begin
        jt:=jt+Le;
        Le1:=Le1-kt;
      end;
      Le:=Le shl 1;
      kt:=kt shr 1;
    end;
    if it<jt then begin
      Tr:=Ar[jt];Ti:=Ai[jt];
      Ar[jt]:=Ar[it];Ai[jt]:=Ai[it];
      Ar[it]:=Tr;Ai[it]:=Ti;
    end;
  end;

  for lt:=1 to Order do begin
    Le:=1 shl lt;
    Le1:=Le shr 1;
    Ur:=1.0;
    Ui:=0.0;
    Z:=Pi/Le1;
    asm
      fld  Z
      fsincos
      fstp Wr  // cos
      fld  Sign
      fmul     // sin*Sign
      fstp Wi
    end;
//    Wr:=cos(Z);
//    Wi:=sin(Z)*Sign;
    for jt:=0 to Le1-1 do begin
      it:=jt;
      while it<n-Le1 do begin
        ip:=it+Le1;
        Tr:=Ar[ip]*Ur-Ai[ip]*Ui;
        Ti:=Ar[ip]*Ui+Ai[ip]*Ur;
        Ar[ip]:=Ar[it]-Tr;
        Ai[ip]:=Ai[it]-Ti;
        Ar[it]:=Ar[it]+Tr;
        Ai[it]:=Ai[it]+Ti;
        it:=it+Le;
      end;
      Tr:=Ur*Wr-Ui*Wi;
      Ti:=Ur*Wi+Ui*Wr;
      Ur:=Tr;
      Ui:=Ti;
    end;
  end;
  if Inverse then begin
    Z:=1/n;
    for it:=0 to n-1 do begin
      Ar[it]:=Ar[it]*Z;
      Ai[it]:=Ai[it]*Z;
    end;
  end;
end;

end.
