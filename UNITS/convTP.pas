unit ConvTP;

interface

procedure func(const kod_t,kod_p:Double; var f1,f2:Double; const t,p,x,y:array of Double);

var
  IterCounter:Integer;

implementation

const
  Coeff:Double=1/32;

{       ¬ычисление рассто€ни€ между точками.     }

function distance (
  const ksi,eta,kod_t,kod_p:Double;
  var dx, dy:Double; const x,y:array of Double
):Double;
var
  xk,yk:Double;
  N1,N2, N3,N4, N5,N6, N7,N8, N9,N10, N11,N12:Double;
begin
  N1  :=  (1-ksi)*(1-eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N2  :=  9*(1-eta)*(1-ksi*ksi)*(1-3*ksi)*Coeff;
  N3  :=  9*(1-eta)*(1-ksi*ksi)*(1+3*ksi)*Coeff;
  N4  :=  (1+ksi)*(1-eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N5  :=  9*(1+ksi)*(1-eta*eta)*(1-3*eta)*Coeff;
  N6  :=  9*(1+ksi)*(1-eta*eta)*(1+3*eta)*Coeff;
  N7  :=  (1+ksi)*(1+eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N8  :=  9*(1+eta)*(1-ksi*ksi)*(1+3*ksi)*Coeff;
  N9  :=  9*(1+eta)*(1-ksi*ksi)*(1-3*ksi)*Coeff;
  N10 :=  (1-ksi)*(1+eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N11 :=  9*(1-ksi)*(1-eta*eta)*(1+3*eta)*Coeff;
  N12 :=  9*(1-ksi)*(1-eta*eta)*(1-3*eta)*Coeff;
  xk := N1*x[1] + N2*x[2] + N3*x[3] + N4*x[4] + N5*x[5] + N6*x[6] +
        N7*x[7] + N8*x[8] + N9*x[9] + N10*x[10] + N11*x[11] + N12*x[12];
  yk := N1*y[1] + N2*y[2] + N3*y[3] + N4*y[4] + N5*y[5] + N6*y[6] +
        N7*y[7] + N8*y[8] + N9*y[9] + N10*y[10] + N11*y[11] + N12*y[12];
  dx := kod_t - xk;
  dy := kod_p - yk;
  distance:=dx*dx + dy*dy;
end;

procedure  func;
{ ¬ычисл€ет абсолютные значени€ температуры и давлени€
     по двум кодам с прибора, использу€ семейство кривых
     зависимости этих кодов от температуры и давлени€.
}
var
  DT,DP:Double;
  N1,N2,N3,N4,N5,N6,N7,N8,N9,N10,N11,N12:Double;
  ksi,eta:Double;
  dx,dy:Double;
{ ¬ычисление значений локальных координат (ksi, eta)
  по глобальным (kod_t, kod_p) координатам.            }
begin
  ksi := 0;
  eta := 0;
  DT := 50000;
  DP := 50000;
  IterCounter:=0;
  repeat
    if (distance (ksi, eta,  kod_t, kod_p, dx, dy, x,y)< 1000)
    then break;
    ksi := ksi+dx / DT;
    eta := eta+dy / DP;
    Inc(IterCounter);
  until IterCounter>10000;
  { ¬ычисление значений функций.  }
  N1  :=  (1-ksi)*(1-eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N2  :=  9*(1-eta)*(1-ksi*ksi)*(1-3*ksi)*Coeff;
  N3  :=  9*(1-eta)*(1-ksi*ksi)*(1+3*ksi)*Coeff;
  N4  :=  (1+ksi)*(1-eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N5  :=  9*(1+ksi)*(1-eta*eta)*(1-3*eta)*Coeff;
  N6  :=  9*(1+ksi)*(1-eta*eta)*(1+3*eta)*Coeff;
  N7  :=  (1+ksi)*(1+eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N8  :=  9*(1+eta)*(1-ksi*ksi)*(1+3*ksi)*Coeff;
  N9  :=  9*(1+eta)*(1-ksi*ksi)*(1-3*ksi)*Coeff;
  N10 :=  (1-ksi)*(1+eta)*(-10+9*(ksi*ksi+eta*eta))*Coeff;
  N11 :=  9*(1-ksi)*(1-eta*eta)*(1+3*eta)*Coeff;
  N12 :=  9*(1-ksi)*(1-eta*eta)*(1-3*eta)*Coeff;
  f1 := (N1+N10+N11+N12)*t[1] + (N2+N9)*t[2] + (N3+N8)*t[3] + (N4+N5+N6+N7)*t[4];
  f2 := (N1+N2+N3+N4)*p[1] + (N5+N12)*p[2] + (N6+N11)*p[3] + (N7+N8+N9+N10)*p[4];
end;

end.
