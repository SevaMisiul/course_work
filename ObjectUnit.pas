unit ObjectUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.ExtDlgs, Math;

type
  TActionType = (actLineMove = 0, actCircleMove = 1);

  TAspectFrac = record
    Width, Height: Integer;
  end;

  TACtionInfo = record
    ActType: TActionType;
    TimeStart, TimeEnd: Integer;
    StartPoint, EndPoint: TPoint;
  end;

  PActionLI = ^TActionLI;

  TActionLI = record
    Info: TACtionInfo;
    Next: PActionLI;
  end;

  TPixelArray = array [0 .. 32768] of TRGBTriple;
  PPixelArray = ^TPixelArray;

  TObjectImage = class(TImage)
    Timer: TTimer;
    procedure ObjectImageDblClick(Sender: TObject);
    procedure ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TimerAction(Sender: TObject);
  private
    FCurrCoordinates: TPoint;
    FCurrAction: PActionLI;
    FOriginPicture: TPicture;
    FAspectRatio: TAspectFrac;
    FAngle: Integer;
    FActionList, FEndList: PActionLI;
    FIsPng: Boolean;
    FCurrTime: Integer;
    FIndex: Integer;
    procedure SetCurrCoordinates(const Value: TPoint);
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture; IsPngExtension: Boolean);
    destructor Destroy;
    procedure Rotate(Angle: Real);
    procedure Resize(NewHeight, NewWidth: Integer; IsProportional: Boolean);
    procedure ViewImage(Pict: TGraphic);
    procedure AddAction(Act: TACtionInfo);
    { properties }
    property CurrCoordinates: TPoint read FCurrCoordinates write SetCurrCoordinates;
    property CurrAction: PActionLI read FCurrAction write FCurrAction;
    property CurrTime: Integer read FCurrTime write FCurrTime;
    property ActionList: PActionLI read FActionList write FActionList;
    property Angle: Integer read FAngle;
    property AspectRatio: TAspectFrac read FAspectRatio;
    property OriginPicture: TPicture read FOriginPicture;
    property IsPng: Boolean read FIsPng;
  end;

const
  ActionNames: array [TActionType] of string[20] = ('Line move', 'Circle move');

implementation

uses
  ObjectOptionsUnit, MainUnit, BackMenuUnit;

function GCD(A, B: Integer): Integer;
begin
  if B = 0 then
    result := A
  else
    result := GCD(B, A mod B);
end;

procedure ReduceFraction(var Frac: TAspectFrac);
var
  Tmp: Integer;
begin
  Tmp := GCD(Frac.Width, Frac.Height);
  Frac.Width := Frac.Width div Tmp;
  Frac.Height := Frac.Height div Tmp;
end;

procedure FillActionOptionsForm(const Obj: TObjectImage);
var
  Tmp: PActionLI;
begin
  with ObjectOptionsForm do
  begin
    WidthRatio := Obj.AspectRatio.Width;
    HeightRatio := Obj.AspectRatio.Height;
    chbIsProportional.Checked := Obj.Proportional;
    edtHeight.Text := IntToStr(Obj.OriginPicture.Height);
    edtWidth.Text := IntToStr(Obj.OriginPicture.Width);
    edtTop.Text := IntToStr(Obj.Top + Obj.Height div 2);
    edtLeft.Text := IntToStr(Obj.Left + Obj.Width div 2);
    edtAngle.Text := IntToStr(Obj.Angle);
    Pict.Assign(Obj.OriginPicture);
    ObjectOwner := Obj;

    Tmp := Obj.ActionList^.Next;
    lvActions.Clear;
    while Tmp <> nil do
    begin
      AddListViewItem(Tmp^.Info.ActType, Tmp^.Info.TimeStart, Tmp^.Info.TimeEnd);
      Tmp := Tmp^.Next;
    end;
  end;
end;

procedure SetChanges(var Obj: TObjectImage);
begin
  with ObjectOptionsForm do
  begin
    if (Obj.OriginPicture.Height <> StrToInt(edtHeight.Text)) or (Obj.OriginPicture.Width <> StrToInt(edtWidth.Text))
    then
      Obj.Resize(StrToInt(edtHeight.Text), StrToInt(edtWidth.Text), chbIsProportional.Checked);
    if Obj.Angle <> StrToInt(edtAngle.Text) then
    begin
      Obj.FAngle := StrToInt(edtAngle.Text);
      Obj.Rotate(Obj.Angle);
    end;
    Obj.Top := StrToInt(edtTop.Text) - Obj.Height div 2;
    Obj.Left := StrToInt(edtLeft.Text) - Obj.Width div 2;
  end;
end;

procedure TObjectImage.AddAction(Act: TACtionInfo);
var
  Tmp: PActionLI;
begin
  new(Tmp);
  Tmp^.Info := Act;
  Tmp^.Next := nil;
  FEndList^.Next := Tmp;
  FEndList := Tmp;
end;

constructor TObjectImage.Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture; IsPngExtension: Boolean);
var
  Tmp: PActionLI;
begin
  inherited Create(AOwner);

  if TMainForm(AOwner).ObjectList <> nil then
    FIndex := TMainForm(AOwner).ObjectList^.ObjectImage.FIndex + 1
  else
    FIndex := 0;
  Parent := TWinControl(AOwner);
  Proportional := True;
  Stretch := True;
  Center := True;
  Picture.Assign(Pict);
  Height := Picture.Graphic.Height;
  Width := Picture.Graphic.Width;
  Top := Y - Height div 2;
  Left := X - Width div 2;

  OnDblClick := ObjectImageDblClick;
  OnMouseDown := ObjectImageMouseDown;

  Timer := TTimer.Create(AOwner);
  Timer.Enabled := False;
  Timer.OnTimer := TimerAction;

  FIsPng := IsPngExtension;
  new(FActionList);
  FEndList := FActionList;
  FActionList^.Next := nil;
  FAspectRatio.Width := Width;
  FAspectRatio.Height := Height;
  ReduceFraction(FAspectRatio);
  FOriginPicture := TPicture.Create;
  FOriginPicture.Assign(Pict.Graphic);

  TMainForm(AOwner).AddObject(Self);
end;

destructor TObjectImage.Destroy;
var
  TmpAct: PActionLI;
  TmpObj, TmpDel: PObjectLI;
begin
  TmpObj := (Parent as TMainForm).ObjectList;

  if TmpObj^.ObjectImage.FIndex = FIndex then
  begin
    (Parent as TMainForm).ObjectList := TmpObj^.Next;
    Dispose(TmpObj);
  end
  else
  begin
    while TmpObj^.Next^.ObjectImage.FIndex <> FIndex do
      TmpObj := TmpObj^.Next;
    TmpDel := TmpObj^.Next;
    TmpObj^.Next := TmpObj^.Next^.Next;
    Dispose(TmpDel);
  end;

  FOriginPicture.Destroy;
  Timer.Destroy;

  while FActionList <> nil do
  begin
    TmpAct := FActionList;
    FActionList := FActionList.Next;
    Dispose(TmpAct);
  end;

  inherited Destroy;
end;

procedure TObjectImage.ObjectImageDblClick(Sender: TObject);
begin
  with ObjectOptionsForm do
  begin
    FillActionOptionsForm(Self);
    ShowModal;
    if ISDeleting then
      Self.Destroy;
    if IsConfirm then
    begin
      SetChanges(Self);
    end;
  end;
end;

procedure TObjectImage.ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Sleep(100);
  if (GetKeyState(VK_LBUTTON) and $8000) <> 0 then
    TControl(Sender).BeginDrag(False);
end;

procedure TObjectImage.Resize(NewHeight, NewWidth: Integer; IsProportional: Boolean);
var
  RowSource, RowDest: PPixelArray;
  Y, X, I, DestColorType: Integer;
  SourcePoint, SourceCenter, DestCenter: TPoint;
  SourcePict, DestPict: TPNGObject;
  SourceBmp, DestBmp: TBitMap;
  DestAlpha, SourceAlpha: PByteArray;
  IsAlpha: Boolean;
  ScaleX, ScaleY: Real;
begin
  Proportional := IsProportional;

  if IsPng then
  begin
    SourcePict := TPNGObject.Create;
    SourcePict.Assign(OriginPicture.Graphic);
    IsAlpha := (SourcePict.Header.ColorType = COLOR_RGBALPHA);
  end
  else
  begin
    SourceBmp := TBitMap.Create;
    SourceBmp.Assign(OriginPicture.Graphic);
  end;

  SourceCenter.Y := OriginPicture.Height div 2;
  SourceCenter.X := OriginPicture.Width div 2;

  ScaleX := OriginPicture.Width / NewWidth;
  ScaleY := OriginPicture.Height / NewHeight;

  if IsPng then
  begin
    DestPict := TPNGObject.Create;
    DestPict.CreateBlank(COLOR_RGBALPHA, 8, NewWidth, NewHeight);
  end
  else
  begin
    DestBmp := TBitMap.Create;
    DestBmp.SetSize(NewWidth, NewHeight);
    DestBmp.PixelFormat := pf24bit;
  end;

  DestCenter.X := NewWidth div 2;
  DestCenter.Y := NewHeight div 2;

  for Y := -DestCenter.Y to NewHeight - DestCenter.Y - 1 do
  begin
    if IsPng then
      RowDest := DestPict.ScanLine[Y + DestCenter.Y]
    else
      RowDest := DestBmp.ScanLine[Y + DestCenter.Y];
    if IsPng and IsAlpha then
      SourceAlpha := DestPict.AlphaScanline[Y + DestCenter.Y];
    for X := -DestCenter.X to NewWidth - DestCenter.X - 1 do
    begin
      SourcePoint.X := Round(ScaleX * X) + SourceCenter.X;
      SourcePoint.Y := Round(ScaleY * Y) + SourceCenter.Y;
      if (SourcePoint.X >= 0) and (SourcePoint.X < OriginPicture.Width) and (SourcePoint.Y >= 0) and
        (SourcePoint.Y < OriginPicture.Height) then
      begin
        if IsPng then
          RowSource := SourcePict.ScanLine[SourcePoint.Y]
        else
          RowSource := SourceBmp.ScanLine[SourcePoint.Y];
        RowDest[X + DestCenter.X] := RowSource[SourcePoint.X];

        if IsPng and IsAlpha then
        begin
          DestAlpha := SourcePict.AlphaScanline[SourcePoint.Y];
          SourceAlpha[X + DestCenter.X] := DestAlpha[SourcePoint.X];
        end;
      end;
    end;
  end;

  if IsPng then
  begin
    OriginPicture.Assign(DestPict);
    ViewImage(DestPict);
    DestPict.Free;
    SourcePict.Free;
  end
  else
  begin
    OriginPicture.Assign(DestBmp);
    ViewImage(DestBmp);
    DestBmp.Free;
    SourceBmp.Free;
  end;
end;

procedure TObjectImage.Rotate(Angle: Real);
var
  SinRad, CosRad, AngleRad: Real;
  RowSource, RowDest: PPixelArray;
  Y, X, I, DestColorType: Integer;
  SourcePoint, SourceCenter, DestCenter, MaxP, MinP: TPoint;
  Corners: array [1 .. 4] of TPoint;
  SourcePict, DestPict: TPNGObject;
  SourceBmp, DestBmp: TBitMap;
  DestAlpha, SourceAlpha: PByteArray;
  IsAlpha: Boolean;
begin
  AngleRad := Angle * Pi / 180;
  SinRad := Sin(AngleRad);
  CosRad := Cos(AngleRad);

  if IsPng then
  begin
    SourcePict := TPNGObject.Create;
    SourcePict.Assign(OriginPicture.Graphic);
    IsAlpha := (SourcePict.Header.ColorType = COLOR_RGBALPHA);
  end
  else
  begin
    SourceBmp := TBitMap.Create;
    SourceBmp.Assign(OriginPicture.Graphic);
  end;

  SourceCenter.Y := OriginPicture.Height div 2;
  SourceCenter.X := OriginPicture.Width div 2;

  Corners[1].X := -SourceCenter.X;
  Corners[1].Y := -SourceCenter.Y;
  Corners[2].X := Corners[1].X;
  Corners[2].Y := OriginPicture.Height - SourceCenter.Y;
  Corners[3].X := OriginPicture.Width - SourceCenter.X;
  Corners[3].Y := Corners[2].Y;
  Corners[4].X := Corners[3].X;
  Corners[4].Y := Corners[1].Y;

  for I := 1 to 4 do
  begin
    X := Corners[I].X;
    Y := Corners[I].Y;
    Corners[I].X := Round(CosRad * X + SinRad * Y);
    Corners[I].Y := Round(-SinRad * X + CosRad * Y);
  end;
  MaxP.X := Max(Max(Max(Corners[1].X, Corners[2].X), Corners[3].X), Corners[4].X);
  MinP.X := Min(Min(Min(Corners[1].X, Corners[2].X), Corners[3].X), Corners[4].X);
  MaxP.Y := Max(Max(Max(Corners[1].Y, Corners[2].Y), Corners[3].Y), Corners[4].Y);
  MinP.Y := Min(Min(Min(Corners[1].Y, Corners[2].Y), Corners[3].Y), Corners[4].Y);

  if IsPng then
  begin
    DestPict := TPNGObject.Create;
    DestPict.CreateBlank(COLOR_RGBALPHA, 8, MaxP.X - MinP.X + 1, MaxP.Y - MinP.Y + 1);
  end
  else
  begin
    DestBmp := TBitMap.Create;
    DestBmp.SetSize(MaxP.X - MinP.X + 1, MaxP.Y - MinP.Y + 1);
    DestBmp.PixelFormat := pf24bit;
  end;

  DestCenter.X := (MaxP.X - MinP.X + 1) div 2;
  DestCenter.Y := (MaxP.Y - MinP.Y + 1) div 2;

  for Y := MinP.Y to MaxP.Y - 1 do
  begin
    if IsPng then
      RowDest := DestPict.ScanLine[Y + DestCenter.Y]
    else
      RowDest := DestBmp.ScanLine[Y + DestCenter.Y];
    if IsPng and IsAlpha then
      SourceAlpha := DestPict.AlphaScanline[Y + DestCenter.Y];
    for X := MinP.X to MaxP.X - 1 do
    begin
      SourcePoint.X := Round(CosRad * X - SinRad * Y) + SourceCenter.X;
      SourcePoint.Y := Round(SinRad * X + CosRad * Y) + SourceCenter.Y;
      if (SourcePoint.X >= 0) and (SourcePoint.X < OriginPicture.Width) and (SourcePoint.Y >= 0) and
        (SourcePoint.Y < OriginPicture.Height) then
      begin
        if IsPng then
          RowSource := SourcePict.ScanLine[SourcePoint.Y]
        else
          RowSource := SourceBmp.ScanLine[SourcePoint.Y];
        RowDest[X + DestCenter.X] := RowSource[SourcePoint.X];

        if IsPng and IsAlpha then
        begin
          DestAlpha := SourcePict.AlphaScanline[SourcePoint.Y];
          SourceAlpha[X + DestCenter.X] := DestAlpha[SourcePoint.X];
        end;
      end;
    end;
  end;

  if IsPng then
  begin
    ViewImage(DestPict);
    DestPict.Free;
    SourcePict.Free;
  end
  else
  begin
    ViewImage(DestBmp);
    DestBmp.Free;
    SourceBmp.Free;
  end;
end;

procedure TObjectImage.SetCurrCoordinates(const Value: TPoint);
begin
  FCurrCoordinates := Value;
end;

procedure TObjectImage.TimerAction(Sender: TObject);
var
  Buff: TBitMap;
  Tmp: PObjectLI;
  TimeInc, TimeLeft, XLeft, YLeft: Integer;
begin
  if CurrAction = nil then
    Timer.Enabled := False
  else if CurrTime >= CurrAction^.Info.TimeEnd * 1000 then
  begin
    FCurrAction := CurrAction^.Next;
    if FCurrAction <> nil then
      FCurrCoordinates := FCurrAction^.Info.StartPoint;
  end;
  if (CurrAction <> nil) and (CurrTime >= CurrAction^.Info.TimeStart * 1000) then
  begin
    Buff := TBitMap.Create;
    Buff.SetSize((Parent as TMainForm).ClientWidth, (Parent as TMainForm).ClientHeight);
    Buff.Canvas.StretchDraw(Rect(0, 0, (Parent as TMainForm).ClientWidth, (Parent as TMainForm).ClientHeight),
      BackMenuForm.BkPict.Graphic);
    Tmp := (Parent as TMainForm).ObjectList;
    if CurrAction^.Info.ActType = actLineMove then
    begin
      TimeLeft := (CurrAction^.Info.TimeEnd * 1000 - CurrTime);
      XLeft := (CurrAction^.Info.EndPoint.X - CurrCoordinates.X);
      YLeft := (CurrAction^.Info.EndPoint.Y - CurrCoordinates.Y);
      if (Abs(XLeft) <> 0) or (Abs(YLeft) <> 0) then
      begin
        TimeInc := Round(TimeLeft / Abs(XLeft));
        while TimeInc <= 15 do
          TimeInc := TimeInc + Round(TimeLeft / Abs(XLeft));
        Inc(FCurrCoordinates.X, Round(XLeft / TimeLeft * TimeInc));
        Inc(FCurrCoordinates.Y, Round(YLeft / TimeLeft * TimeInc));
        Timer.Interval := TimeInc;
      end;
      Inc(FCurrTime, TimeInc);
      while Tmp <> nil do
      begin
        with Tmp^.ObjectImage do
          Buff.Canvas.Draw(CurrCoordinates.X - Picture.Width div 2, CurrCoordinates.Y - Picture.Height div 2,
            Picture.Graphic);
        Tmp := Tmp^.Next;
      end;
      (Parent as TMainForm).Canvas.Draw(0, 0, Buff);
    end
    else if CurrAction^.Info.ActType = actCircleMove then
    begin

    end;
  end;
end;

procedure TObjectImage.ViewImage(Pict: TGraphic);
begin
  Picture.Assign(Pict);
  Height := Pict.Height;
  Width := Pict.Width;
end;

end.
