unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, UModem, CommInt;

type
  TFormMain = class(TForm)
    Panel1: TPanel;
    cbDSR: TCheckBox;
    cbCTS: TCheckBox;
    cbRLSD: TCheckBox;
    Panel2: TPanel;
    Memo: TMemo;
    edComName: TEdit;
    btnOpen: TButton;
    Label1: TLabel;
    Modem: TModem;
    pnlConnect: TPanel;
    edConnectCmd: TEdit;
    btnConnect: TButton;
    procedure CommCts(Sender: TObject);
    procedure CommDsr(Sender: TObject);
    procedure CommRlsd(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure CommRxChar(Sender: TObject; Count: Integer);
    procedure ModemModemResponse(Sender: TObject; Code: Integer);
    procedure btnConnectClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.DFM}

procedure TFormMain.CommCts(Sender: TObject);
begin
  cbCTS.Checked:=Modem.CTS;
end;

procedure TFormMain.CommDsr(Sender: TObject);
begin
  cbDSR.Checked:=Modem.DSR;
end;

procedure TFormMain.CommRlsd(Sender: TObject);
begin
  cbRLSD.Checked:=Modem.RLSD;
  Memo.SelText:='[RLSD]'#13#10;
end;

procedure TFormMain.btnOpenClick(Sender: TObject);
begin
  if Modem.Enabled then begin
    Modem.Close;
    btnOpen.Caption:='Open';
  end
  else begin
    Modem.DeviceName:=edComName.Text;
    try
      Modem.Open;
      Modem.PurgeIn;
      Modem.DoCmd('AT E0');
      cbDSR.Checked:=Modem.DSR;
      cbCTS.Checked:=Modem.CTS;
      cbRLSD.Checked:=Modem.RLSD;
      btnOpen.Caption:='Close';
    except
      on E:Exception do
      Application.MessageBox(PChar(E.Message),'Opening error',MB_OK or MB_ICONHAND);
    end;
  end;
end;

procedure TFormMain.CommRxChar(Sender: TObject; Count: Integer);
var
  S:String;
begin
  SetLength(S,Count);
  Modem.Read(S[1],Count);
  Memo.SelText:=S;
end;

procedure TFormMain.ModemModemResponse(Sender: TObject; Code: Integer);
begin
  Memo.SelText:=Modem.ModemResponse+'[Code '+IntToStr(Code)+']'#13#10;
end;

procedure TFormMain.btnConnectClick(Sender: TObject);
begin
  Modem.Connect(edConnectCmd.Text);
end;

end.
