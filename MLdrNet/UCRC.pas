unit UCRC;

interface

function ModBus_CRC16(const Data; DataSize:Integer):Word;
function PPP_FCS16(const Data; Len:Integer):Word;
function FCS_is_OK(const Packet; Size:Cardinal):Boolean;

implementation

function FCS_is_OK(const Packet; Size:Cardinal):Boolean;
type
  PWord = ^Word;
begin
  Result:=
    (Size>=2) and
    (PPP_FCS16(Packet,Size-2) = PWord(Cardinal(@Packet)+Size-2)^);
end;

const
// PPP FCS lookup table (RFC1662)
  FCSTab:array[0..255] of Word = (
$0000, $1189, $2312, $329b, $4624, $57ad, $6536, $74bf,
$8c48, $9dc1, $af5a, $bed3, $ca6c, $dbe5, $e97e, $f8f7,
$1081, $0108, $3393, $221a, $56a5, $472c, $75b7, $643e,
$9cc9, $8d40, $bfdb, $ae52, $daed, $cb64, $f9ff, $e876,
$2102, $308b, $0210, $1399, $6726, $76af, $4434, $55bd,
$ad4a, $bcc3, $8e58, $9fd1, $eb6e, $fae7, $c87c, $d9f5,
$3183, $200a, $1291, $0318, $77a7, $662e, $54b5, $453c,
$bdcb, $ac42, $9ed9, $8f50, $fbef, $ea66, $d8fd, $c974,
$4204, $538d, $6116, $709f, $0420, $15a9, $2732, $36bb,
$ce4c, $dfc5, $ed5e, $fcd7, $8868, $99e1, $ab7a, $baf3,
$5285, $430c, $7197, $601e, $14a1, $0528, $37b3, $263a,
$decd, $cf44, $fddf, $ec56, $98e9, $8960, $bbfb, $aa72,
$6306, $728f, $4014, $519d, $2522, $34ab, $0630, $17b9,
$ef4e, $fec7, $cc5c, $ddd5, $a96a, $b8e3, $8a78, $9bf1,
$7387, $620e, $5095, $411c, $35a3, $242a, $16b1, $0738,
$ffcf, $ee46, $dcdd, $cd54, $b9eb, $a862, $9af9, $8b70,
$8408, $9581, $a71a, $b693, $c22c, $d3a5, $e13e, $f0b7,
$0840, $19c9, $2b52, $3adb, $4e64, $5fed, $6d76, $7cff,
$9489, $8500, $b79b, $a612, $d2ad, $c324, $f1bf, $e036,
$18c1, $0948, $3bd3, $2a5a, $5ee5, $4f6c, $7df7, $6c7e,
$a50a, $b483, $8618, $9791, $e32e, $f2a7, $c03c, $d1b5,
$2942, $38cb, $0a50, $1bd9, $6f66, $7eef, $4c74, $5dfd,
$b58b, $a402, $9699, $8710, $f3af, $e226, $d0bd, $c134,
$39c3, $284a, $1ad1, $0b58, $7fe7, $6e6e, $5cf5, $4d7c,
$c60c, $d785, $e51e, $f497, $8028, $91a1, $a33a, $b2b3,
$4a44, $5bcd, $6956, $78df, $0c60, $1de9, $2f72, $3efb,
$d68d, $c704, $f59f, $e416, $90a9, $8120, $b3bb, $a232,
$5ac5, $4b4c, $79d7, $685e, $1ce1, $0d68, $3ff3, $2e7a,
$e70e, $f687, $c41c, $d595, $a12a, $b0a3, $8238, $93b1,
$6b46, $7acf, $4854, $59dd, $2d62, $3ceb, $0e70, $1ff9,
$f78f, $e606, $d49d, $c514, $b1ab, $a022, $92b9, $8330,
$7bc7, $6a4e, $58d5, $495c, $3de3, $2c6a, $1ef1, $0f78
);

// CRC16 Table High byte
  CRC16Hi:array[0..255] of Byte = (
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40
);

// CRC16 Table Low byte
  CRC16Lo:array[0..255] of Byte = (
$00, $C0, $C1, $01, $C3, $03, $02, $C2, $C6, $06, $07, $C7, $05, $C5, $C4, $04,
$CC, $0C, $0D, $CD, $0F, $CF, $CE, $0E, $0A, $CA, $CB, $0B, $C9, $09, $08, $C8,
$D8, $18, $19, $D9, $1B, $DB, $DA, $1A, $1E, $DE, $DF, $1F, $DD, $1D, $1C, $DC,
$14, $D4, $D5, $15, $D7, $17, $16, $D6, $D2, $12, $13, $D3, $11, $D1, $D0, $10,
$F0, $30, $31, $F1, $33, $F3, $F2, $32, $36, $F6, $F7, $37, $F5, $35, $34, $F4,
$3C, $FC, $FD, $3D, $FF, $3F, $3E, $FE, $FA, $3A, $3B, $FB, $39, $F9, $F8, $38,
$28, $E8, $E9, $29, $EB, $2B, $2A, $EA, $EE, $2E, $2F, $EF, $2D, $ED, $EC, $2C,
$E4, $24, $25, $E5, $27, $E7, $E6, $26, $22, $E2, $E3, $23, $E1, $21, $20, $E0,
$A0, $60, $61, $A1, $63, $A3, $A2, $62, $66, $A6, $A7, $67, $A5, $65, $64, $A4,
$6C, $AC, $AD, $6D, $AF, $6F, $6E, $AE, $AA, $6A, $6B, $AB, $69, $A9, $A8, $68,
$78, $B8, $B9, $79, $BB, $7B, $7A, $BA, $BE, $7E, $7F, $BF, $7D, $BD, $BC, $7C,
$B4, $74, $75, $B5, $77, $B7, $B6, $76, $72, $B2, $B3, $73, $B1, $71, $70, $B0,
$50, $90, $91, $51, $93, $53, $52, $92, $96, $56, $57, $97, $55, $95, $94, $54,
$9C, $5C, $5D, $9D, $5F, $9F, $9E, $5E, $5A, $9A, $9B, $5B, $99, $59, $58, $98,
$88, $48, $49, $89, $4B, $8B, $8A, $4A, $4E, $8E, $8F, $4F, $8D, $4D, $4C, $8C,
$44, $84, $85, $45, $87, $47, $46, $86, $82, $42, $43, $83, $41, $81, $80, $40
);

function PPP_FCS16(const Data; Len:Integer):Word;
var
  FCS:Cardinal;
  pData:^Byte;
begin
  FCS:=$FFFF;
  pData:=Addr(Data);
  while (Len>0) do begin
//    FCS = (FCS >> 8) ^ fcstab[(U8)FCS ^ *Bytes++];
    FCS:=(FCS shr 8) xor FCSTab[Byte(FCS) xor pData^];
    Inc(pData);
    Dec(Len);
  end;
  Result:=FCS;
end;

function ModBus_CRC16(const Data; DataSize:Integer):Word;
var
  Index:Byte;
  CRCHi,CRCLo:Byte;
  pData:^Byte;
begin
  pData:=Addr(Data);
  CRCHi:=$FF; // high byte of CRC16 initialized
  CRCLo:=$FF; // low byte of CRC16 initialized
  while (DataSize>0) do begin
    Index:=CRCHi xor pData^ ; // calculate the CRC16
    CRCHi:=CRCLo xor CRC16Hi[Index] ;
    CRCLo:=CRC16Lo[Index] ;
    Inc(pData);
    Dec(DataSize);
  end;
  Result:=(CRCHi shl 8) or CRCLo;
end;
//*)

end.
