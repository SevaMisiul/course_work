unit ObjectUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.ExtDlgs, Math;

type
  TActionType = (actLineMove = 0, actCircleMove = 1);

  TCenterPos = (posUp = 0, posDown = 1);

  TAspectFrac = record
    Width, Height: Integer;
  end;

  TACtionInfo = record
    ActType: TActionType;
    TimeStart, TimeEnd: Integer;
    StartPoint, EndPoint, CircleCenter: TPoint;
    CenterPos: TCenterPos;
    Radius: Integer;
  end;

  PActionLI = ^TActionLI;

  TActionLI = record
    Info: TACtionInfo;
    Next: PActionLI;
  end;

  TPixelArray = array [0 .. 32768] of TRGBTriple;
  PPixelArray = ^TPixelArray;

  TOnActionListChanged = procedure(Header: PActionLI) of object;

  TOnActionDelete = procedure of object;

  TOnActionChanged = procedure(Act: TACtionInfo) of object;

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
    FActionBuff: TBitmap;
    FUpdateActionList: TOnActionListChanged;
    FUpdateActionAfterDelete: TOnActionDelete;
    FUpdateOneAction: TOnActionChanged;
    procedure SetCurrCoordinates(const Value: TPoint);
    procedure SetUpdateActionList(const Value: TOnActionListChanged);
    procedure SetUpdateAfterDelete(const Value: TOnActionDelete);
    procedure SetUpdateOneAction(const Value: TOnActionChanged);
    function GetActionItem(Index: Integer): PActionLI;
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture; IsPngExtension: Boolean);
    destructor Destroy;
    procedure Rotate(Angle: Integer);
    procedure Resize(NewHeight, NewWidth: Integer; IsProportional: Boolean);
    procedure ViewImage(Pict: TGraphic);
    procedure AddAction(Act: TACtionInfo);
    procedure SetAction(P: PActionLI; Act: TACtionInfo);
    procedure DeleteAction(Index: Integer);
    { properties }
    property UpdateOneAction: TOnActionChanged read FUpdateOneAction write SetUpdateOneAction;
    property UpdateActionAfterDelete: TOnActionDelete read FUpdateActionAfterDelete write SetUpdateAfterDelete;
    property UpdateActionList: TOnActionListChanged read FUpdateActionList write SetUpdateActionList;

    property CurrCoordinates: TPoint read FCurrCoordinates write SetCurrCoordinates;
    property CurrAction: PActionLI read FCurrAction write FCurrAction;
    property CurrTime: Integer read FCurrTime write FCurrTime;
    property ActionList[Index: Integer]: PActionLI read GetActionItem;
    property EndActionList: PActionLI read FEndList;
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

procedure CalcCircleCenter(var Act: TACtionInfo);
var
  ChordCenter: TPoint;
  Chord, X11, X12, Y11, Y12, Normal, A, B, C, D, Y2, Y3, X2, X3, R: Extended;
begin
  X2 := Act.StartPoint.X;
  Y2 := Act.StartPoint.Y;
  X3 := Act.EndPoint.X;
  Y3 := Act.EndPoint.Y;
  R := Act.Radius;

  if (X2 = X3) and (Y2 <> Y3) then
  begin
    Act.CircleCenter.Y := Round((Y2 + Y3) / 2);
    if Act.CenterPos = posUp then
      Act.CircleCenter.X := Round(X2 + sqrt(sqr(Act.Radius) - sqr((Y3 - Y2) / 2)))
    else if Act.CenterPos = posDown then
      Act.CircleCenter.X := Round(X2 - sqrt(sqr(Act.Radius) - sqr((Y3 - Y2) / 2)));
  end
  else if X2 <> X3 then
  begin
    A := 4 * sqr(Y2) - 8 * Y2 * Y3 + 4 * sqr(Y3) + 4 * sqr(X2 - X3);
    B := 4 * (X2 - X3) * X3 * Y2 - 4 * (X2 - X3) * X3 * Y3 - 4 * Y2 * Y2 * Y2 + 4 * sqr(Y2) * Y3 + 4 * Y2 * sqr(Y3) - 4
      * (X2 - X3) * X2 * Y2 - 4 * Y3 * Y3 * Y3 + 4 * (X2 - X3) * X2 * Y3 - 8 * Y3 * sqr(X2 - X3);
    C := sqr(X2) * sqr(X2 - X3) + sqr(sqr(Y2)) - 2 * sqr(Y2) * sqr(Y3) - 2 * (X2 - X3) * X3 * sqr(Y2) + 2 * (X2 - X3) *
      X2 * sqr(Y2) + sqr(sqr(Y3)) + 2 * (X2 - X3) * X3 * sqr(Y3) - 2 * (X2 - X3) * X2 * sqr(Y3) - 2 * X2 * X3 *
      (X2 - X3) + sqr(X3) * sqr(X2 - X3) + 4 * sqr(Y3) * sqr(X2 - X3) - sqr(R) * 4 * sqr(X2 - X3);
    D := sqr(B) - 4 * A * C;

    Y11 := (-B + sqrt(D)) / (2 * A);
    Y12 := (-B - sqrt(D)) / (2 * A);

    X11 := (X2 + X3) / 2 + (Y2 - Y3) * (Y2 + Y3 - 2 * Y11) / ((X2 - X3) * 2);
    X12 := (X2 + X3) / 2 + (Y2 - Y3) * (Y2 + Y3 - 2 * Y12) / ((X2 - X3) * 2);
    if Act.CenterPos = posUp then
      if Y11 > Y12 then
      begin
        Act.CircleCenter.X := Round(X11);
        Act.CircleCenter.Y := Round(Y11);
      end
      else
      begin
        Act.CircleCenter.X := Round(X12);
        Act.CircleCenter.Y := Round(Y12);
      end
    else if Act.CenterPos = posDown then
      if Y11 > Y12 then
      begin
        Act.CircleCenter.X := Round(X12);
        Act.CircleCenter.Y := Round(Y12);
      end
      else
      begin
        Act.CircleCenter.X := Round(X11);
        Act.CircleCenter.Y := Round(Y11);
      end
  end;
end;

procedure TObjectImage.AddAction(Act: TACtionInfo);
var
  TmpNew, Tmp: PActionLI;
begin
  new(TmpNew);
  CalcCircleCenter(Act);
  TmpNew^.Info := Act;
  Tmp := FActionList;
  while (Tmp^.Next <> nil) and (Tmp^.Next^.Info.TimeStart < Act.TimeStart) do
    Tmp := Tmp^.Next;
  TmpNew^.Next := Tmp^.Next;
  Tmp^.Next := TmpNew;
  if FEndList = Tmp then
    FEndList := TmpNew;
  if Assigned(UpdateActionList) then
    UpdateActionList(FActionList^.Next);
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

  FActionBuff := TBitmap.Create;
  FActionBuff.SetSize(TMainForm(AOwner).ClientWidth, TMainForm(AOwner).ClientHeight);
  FIsPng := IsPngExtension;
  new(FActionList);
  FEndList := FActionList;
  FActionList^.Next := nil;
  FAspectRatio.Width := Width;
  FAspectRatio.Height := Height;
  ReduceFraction(FAspectRatio);
  FOriginPicture := TPicture.Create;
  FOriginPicture.Assign(Pict.Graphic);
  UpdateActionList := ObjectOptionsForm.UpdateActionList;
  UpdateActionAfterDelete := ObjectOptionsForm.UpdateAfterDelete;
  UpdateOneAction := ObjectOptionsForm.UpdateSelectedAction;

  TMainForm(AOwner).AddObject(Self);
end;

procedure TObjectImage.DeleteAction(Index: Integer);
var
  TmpPrev, Tmp: PActionLI;
  I: Integer;
begin
  TmpPrev := FActionList;
  I := 0;
  while (TmpPrev^.Next <> nil) and (I <> Index) do
  begin
    Inc(I);
    TmpPrev := TmpPrev^.Next;
  end;
  if TmpPrev^.Next <> nil then
  begin
    Tmp := TmpPrev^.Next;
    TmpPrev^.Next := Tmp^.Next;
    if Tmp = FEndList then
      FEndList := TmpPrev;
    Dispose(Tmp);
  end;
  if Assigned(UpdateActionAfterDelete) then
    UpdateActionAfterDelete;
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

function TObjectImage.GetActionItem(Index: Integer): PActionLI;
var
  I: Integer;
begin
  result := FActionList^.Next;
  I := 0;
  while (result <> nil) and (I <> Index) do
  begin
    result := result^.Next;
    Inc(I);
  end;
end;

procedure TObjectImage.ObjectImageDblClick(Sender: TObject);
var
  Res: TModalResult;
  H, W, L, T, AngleP: Integer;
  IsProportional: Boolean;
begin
  H := OriginPicture.Height;
  W := OriginPicture.Width;
  L := Left;
  T := Top;
  AngleP := Self.Angle;
  IsProportional := Self.Proportional;
  Res := ObjectOptionsForm.ShowForEdit(Self, H, W, L, T, AngleP, IsProportional);

  if Res = mrAbort then
    Self.Destroy
  else if Res = mrOk then
  begin
    if (H <> OriginPicture.Height) or (W <> OriginPicture.Width) then
      Resize(H, W, IsProportional);
    if (AngleP <> Self.Angle) then
      Rotate(AngleP);
    Left := L - Width div 2;
    Top := T - Height div 2;
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
  SourceBmp, DestBmp: TBitmap;
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
    SourceBmp := TBitmap.Create;
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
    DestBmp := TBitmap.Create;
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

procedure TObjectImage.Rotate(Angle: Integer);
var
  SinRad, CosRad, AngleRad: Real;
  RowSource, RowDest: PPixelArray;
  Y, X, I, DestColorType: Integer;
  SourcePoint, SourceCenter, DestCenter, MaxP, MinP: TPoint;
  Corners: array [1 .. 4] of TPoint;
  SourcePict, DestPict: TPNGObject;
  SourceBmp, DestBmp: TBitmap;
  DestAlpha, SourceAlpha: PByteArray;
  IsAlpha: Boolean;
begin
  Self.FAngle := Angle;

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
    SourceBmp := TBitmap.Create;
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
    DestBmp := TBitmap.Create;
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

procedure TObjectImage.SetAction(P: PActionLI; Act: TACtionInfo);
begin
  CalcCircleCenter(Act);
  P^.Info := Act;
  if Assigned(UpdateOneAction) then
    UpdateOneAction(Act);
end;

procedure TObjectImage.SetCurrCoordinates(const Value: TPoint);
begin
  FCurrCoordinates := Value;
end;

procedure TObjectImage.SetUpdateActionList(const Value: TOnActionListChanged);
begin
  FUpdateActionList := Value;
end;

procedure TObjectImage.SetUpdateAfterDelete(const Value: TOnActionDelete);
begin
  FUpdateActionAfterDelete := Value;
end;

procedure TObjectImage.SetUpdateOneAction(const Value: TOnActionChanged);
begin
  FUpdateOneAction := Value;
end;

procedure TObjectImage.TimerAction(Sender: TObject);
var
  Tmp: PObjectLI;
  TimeLeft, XLeft, YLeft: Integer;
  TimeInc, PixelTime: Real;
begin
  Inc(FCurrTime, Timer.Interval);
  if CurrAction = nil then
    Timer.Enabled := False
  else if CurrTime < CurrAction^.Info.TimeStart * 1000 then
    Timer.Interval := CurrAction^.Info.TimeStart * 1000 - CurrTime
  else if CurrTime = CurrAction^.Info.TimeStart * 1000 then
    FCurrCoordinates := FCurrAction^.Info.StartPoint
  else if CurrTime >= CurrAction^.Info.TimeEnd * 1000 then
    FCurrAction := CurrAction^.Next;
  if (CurrAction <> nil) and (CurrTime >= CurrAction^.Info.TimeStart * 1000) then
  begin
    FActionBuff.Canvas.StretchDraw(Rect(0, 0, (Parent as TMainForm).ClientWidth, (Parent as TMainForm).ClientHeight),
      BackMenuForm.BkPict.Graphic);
    Tmp := (Parent as TMainForm).ObjectList;
    if CurrAction^.Info.ActType = actLineMove then
    begin
      TimeLeft := (CurrAction^.Info.TimeEnd * 1000 - CurrTime);
      XLeft := (CurrAction^.Info.EndPoint.X - CurrCoordinates.X);
      YLeft := (CurrAction^.Info.EndPoint.Y - CurrCoordinates.Y);
      if (Abs(XLeft) <> 0) or (Abs(YLeft) <> 0) then
      begin
        PixelTime := TimeLeft / Max(Abs(XLeft), Abs(YLeft));
        TimeInc := 0;
        while (TimeInc <> TimeLeft) and (TimeInc < 20) do
          TimeInc := Min(TimeLeft, TimeInc + PixelTime);
        Inc(FCurrCoordinates.X, Round(XLeft / TimeLeft * Round(TimeInc)));
        Inc(FCurrCoordinates.Y, Round(YLeft / TimeLeft * Round(TimeInc)));
        Timer.Interval := Round(TimeInc);
      end;
      while Tmp <> nil do
      begin
        with Tmp^.ObjectImage do
          FActionBuff.Canvas.Draw(CurrCoordinates.X - Picture.Width div 2, CurrCoordinates.Y - Picture.Height div 2,
            Picture.Graphic);
        Tmp := Tmp^.Next;
      end;
      (Parent as TMainForm).Canvas.Draw(0, 0, FActionBuff);
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
