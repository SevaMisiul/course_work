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
    TimeStart, TimeEnd, StartAngle, EndAngle, StartHeight, StartWidth, EndHeight, EndWidth: Integer;
    IsPropStart, IsPropEnd: Boolean;
    StartPoint, EndPoint, ThirdPoint: TPoint;
    CircleCenterX, CircleCenterY, Radius: Extended;
  end;

  PActionLI = ^TActionLI;

  TActionLI = record
    Info: TACtionInfo;
    Next: PActionLI;
  end;

  TRGB = record
    R, G, B: Byte;
  end;

  TPixelArray = array [0 .. 32768] of TRGBTriple;
  PPixelArray = ^TPixelArray;

  TOnActionListChanged = procedure(Header: PActionLI) of object;

  TOnActionDelete = procedure of object;

  TOnActionChanged = procedure(Act: TACtionInfo) of object;

  TObjectImage = class(TImage)
    procedure ObjectImageDblClick(Sender: TObject);
    procedure ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FCurrCoordinatesX, FCurrCoordinatesY: Extended;
    FCurrAction: PActionLI;
    FOriginPicture: TPicture;
    FAspectRatio: TAspectFrac;
    FAngle: Integer;
    FActionList, FEndList: PActionLI;
    FIsPng: Boolean;
    FIndex: Integer;
    FUpdateActionList: TOnActionListChanged;
    FUpdateActionAfterDelete: TOnActionDelete;
    FUpdateOneAction: TOnActionChanged;
    FExplicitH, FExplicitW: Integer;
    procedure SetUpdateActionList(const Value: TOnActionListChanged);
    procedure SetUpdateAfterDelete(const Value: TOnActionDelete);
    procedure SetUpdateOneAction(const Value: TOnActionChanged);
    function GetActionItem(Index: Integer): PActionLI;
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture; IsPngExtension: Boolean);
    destructor Destroy;
    procedure Rotate(var DestPicture: TPicture; Angle: Integer);
    procedure Resize(var DestPicture: TPicture; NewWidth, NewHeight: Integer);
    procedure ViewImage(Pict: TGraphic);
    procedure AddAction(Act: TACtionInfo);
    procedure SetAction(P: PActionLI; Act: TACtionInfo);
    procedure DeleteAction(Index: Integer);
    { properties }
    property UpdateOneAction: TOnActionChanged read FUpdateOneAction write SetUpdateOneAction;
    property UpdateActionAfterDelete: TOnActionDelete read FUpdateActionAfterDelete write SetUpdateAfterDelete;
    property UpdateActionList: TOnActionListChanged read FUpdateActionList write SetUpdateActionList;

    property ExplicitH: Integer read FExplicitH;
    property ExplicitW: Integer read FExplicitW;
    property CurrX: Extended read FCurrCoordinatesX write FCurrCoordinatesX;
    property CurrY: Extended read FCurrCoordinatesY write FCurrCoordinatesY;
    property CurrAction: PActionLI read FCurrAction write FCurrAction;
    property ActionList[Index: Integer]: PActionLI read GetActionItem;
    property EndActionList: PActionLI read FEndList;
    property Angle: Integer read FAngle;
    property AspectRatio: TAspectFrac read FAspectRatio;
    property OriginPicture: TPicture read FOriginPicture;
    property IsPng: Boolean read FIsPng;
  end;

const
  ActionNames: array [TActionType] of string[20] = ('Linear move', 'Circular movement');

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

procedure CalcCenter(var Act: TACtionInfo);
var
  X1, X2, X3, Y1, Y2, Y3, X0, Y0: Extended;
begin
  X1 := Act.StartPoint.X;
  Y1 := Act.StartPoint.Y;
  X2 := Act.ThirdPoint.X;
  Y2 := Act.ThirdPoint.Y;
  X3 := Act.EndPoint.X;
  Y3 := Act.EndPoint.Y;
  Y0 := ((sqr(X1) - sqr(X3) + sqr(Y1) - sqr(Y3)) / (2 * (Y1 - Y3)) + (sqr(X1) - sqr(X2) + sqr(Y1) - sqr(Y2)) /
    (2 * (X1 - X2)) * (X3 - X1) / (Y1 - Y3)) / (1 - (Y2 - Y1) * (X3 - X1) / ((X1 - X2) * (Y1 - Y3)));
  X0 := (sqr(X1) - sqr(X2) + sqr(Y1) - sqr(Y2)) / (2 * (X1 - X2)) + Y0 * (Y2 - Y1) / (X1 - X2);

  Act.Radius := sqrt(sqr(X1 - X0) + sqr(Y1 - Y0));
  Act.CircleCenterX := X0;
  Act.CircleCenterY := Y0;
end;

procedure TObjectImage.AddAction(Act: TACtionInfo);
var
  TmpNew, Tmp: PActionLI;
begin
  new(TmpNew);
  if Act.ActType = actCircleMove then
    CalcCenter(Act);
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
  FExplicitH := Height;
  FExplicitW := Width;
  Top := Y - Height div 2;
  Left := X - Width div 2;

  OnDblClick := ObjectImageDblClick;
  OnMouseDown := ObjectImageMouseDown;

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
  IsProportional, IsChanged: Boolean;
  TmpPict: TPicture;
begin
  H := FExplicitH;
  W := FExplicitW;
  L := Left;
  T := Top;
  AngleP := Self.Angle;
  IsProportional := Self.Proportional;
  Res := ObjectOptionsForm.ShowForEdit(Self, FExplicitH, FExplicitW, L, T, AngleP, IsProportional);

  if Res = mrAbort then
    Self.Destroy
  else if Res = mrOk then
  begin
    IsChanged := False;
    TmpPict := TPicture.Create;
    TmpPict.Assign(OriginPicture);
    if (H <> FExplicitH) or (W <> FExplicitW) or (AngleP <> Self.Angle) then
    begin
      IsChanged := True;
      Resize(TmpPict, FExplicitW, FExplicitH);
      ViewImage(TmpPict.Graphic);
    end;
    if IsChanged or (AngleP <> Self.Angle) then
    begin
      Rotate(TmpPict, AngleP);
      ViewImage(TmpPict.Graphic);
    end;
    TmpPict.Destroy;
    FAngle := AngleP;
    Proportional := IsProportional;
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

procedure TObjectImage.Resize(var DestPicture: TPicture; NewWidth, NewHeight: Integer);
var
  ScaleX, ScaleY: Single;
  sfrom_y, sfrom_x: Single;
  ifrom_y, ifrom_x: Integer;
  to_y, to_x: Integer;
  weight_x, weight_y: array [0 .. 1] of Single;
  weight: Single;
  new_red, new_green: Integer;
  new_blue, new_alpha: Integer;
  new_colortype: Integer;
  total_red, total_green: Single;
  total_blue, total_alpha: Single;
  IsAlpha: Boolean;
  ix, iy: Integer;
  DestPict, SourcePict: TPNGObject;
  DestBmp, SourceBmp: TBitMap;
  sli, slo: PRGBLine;
  ali, alo: PByteArray;
begin
  IsAlpha := False;

  if IsPng then
  begin
    SourcePict := TPNGObject.Create;
    SourcePict.Assign(DestPicture.Graphic);
    IsAlpha := (SourcePict.Header.ColorType = COLOR_RGBALPHA);
  end
  else
  begin
    SourceBmp := TBitMap.Create;
    SourceBmp.Assign(DestPicture.Graphic);
  end;

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

  ScaleX := NewWidth / (DestPicture.Width - 1);
  ScaleY := NewHeight / (DestPicture.Height - 1);

  for to_y := 0 to NewHeight - 1 do
  begin
    sfrom_y := to_y / ScaleY;
    ifrom_y := Trunc(sfrom_y);
    weight_y[1] := sfrom_y - ifrom_y;
    weight_y[0] := 1 - weight_y[1];
    for to_x := 0 to NewWidth - 1 do
    begin
      sfrom_x := to_x / ScaleX;
      ifrom_x := Trunc(sfrom_x);
      weight_x[1] := sfrom_x - ifrom_x;
      weight_x[0] := 1 - weight_x[1];

      total_red := 0.0;
      total_green := 0.0;
      total_blue := 0.0;
      total_alpha := 0.0;
      for ix := 0 to 1 do
      begin
        for iy := 0 to 1 do
        begin
          if IsPng then
            sli := SourcePict.ScanLine[ifrom_y + iy]
          else
            sli := SourceBmp.ScanLine[ifrom_y + iy];
          if IsPng and IsAlpha then
            ali := SourcePict.AlphaScanline[ifrom_y + iy];
          new_red := sli[ifrom_x + ix].rgbtRed;
          new_green := sli[ifrom_x + ix].rgbtGreen;
          new_blue := sli[ifrom_x + ix].rgbtBlue;
          if IsAlpha then
            new_alpha := ali[ifrom_x + ix];
          weight := weight_x[ix] * weight_y[iy];
          total_red := total_red + new_red * weight;
          total_green := total_green + new_green * weight;
          total_blue := total_blue + new_blue * weight;
          if IsAlpha then
            total_alpha := total_alpha + new_alpha * weight;
        end;
      end;
      if IsPng then
        slo := DestPict.ScanLine[to_y]
      else
        slo := DestBmp.ScanLine[to_y];
      if IsPng and IsAlpha then
        alo := DestPict.AlphaScanline[to_y];
      slo[to_x].rgbtRed := Round(total_red);
      slo[to_x].rgbtGreen := Round(total_green);
      slo[to_x].rgbtBlue := Round(total_blue);
      if IsAlpha then
        alo[to_x] := Round(total_alpha);
    end;
  end;
  if IsPng then
  begin
    DestPicture.Assign(DestPict);
    SourcePict.Free;
    DestPict.Free;
  end
  else
  begin
    DestPicture.Assign(DestBmp);
    SourceBmp.Free;
    DestBmp.Free;
  end;
end;

procedure TObjectImage.Rotate(var DestPicture: TPicture; Angle: Integer);

  function IntToByte(I: Integer): Byte;
  begin
    if I > 255 then
      result := 255
    else if I < 0 then
      result := 0
    else
      result := I;
  end;

  function TrimInt(I, Min, Max: Integer): Integer;
  begin
    if I > Max then
      result := Max
    else if I < Min then
      result := Min
    else
      result := I;
  end;

var
  SinRad, CosRad, AngleRad, T, B, dltX, dltY, srcX, srcY: Extended;
  DestRow, R1, R2: PByteArray;
  Y, X, I, DestColorType: Integer;
  srcPoint, SourceCenter, DestCenter, MaxP, MinP, N: TPoint;
  Corners: array [1 .. 4] of TPoint;
  SourcePict, DestPict: TPNGObject;
  SourceBmp, DestBmp: TBitMap;
  DestAlpha, A1, A2: PByteArray;
  IsAlpha: Boolean;
  nw, ne, sw, se: TRGB;
  anw, ane, asw, ase: Byte;
begin
  IsAlpha := False;
  AngleRad := Angle * PI / 180;
  SinRad := sin(AngleRad);
  CosRad := cos(AngleRad);

  if IsPng then
  begin
    SourcePict := TPNGObject.Create;
    SourcePict.Assign(DestPicture.Graphic);
    IsAlpha := (SourcePict.Header.ColorType = COLOR_RGBALPHA);
  end
  else
  begin
    SourceBmp := TBitMap.Create;
    SourceBmp.Assign(DestPicture.Graphic);
  end;

  SourceCenter.Y := DestPicture.Height div 2;
  SourceCenter.X := DestPicture.Width div 2;

  Corners[1].X := -SourceCenter.X;
  Corners[1].Y := -SourceCenter.Y;
  Corners[2].X := Corners[1].X;
  Corners[2].Y := DestPicture.Height - SourceCenter.Y;
  Corners[3].X := DestPicture.Width - SourceCenter.X;
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
      DestRow := DestPict.ScanLine[Y + DestCenter.Y]
    else
      DestRow := DestBmp.ScanLine[Y + DestCenter.Y];
    if IsPng and IsAlpha then
      DestAlpha := DestPict.AlphaScanline[Y + DestCenter.Y];
    for X := MinP.X to MaxP.X - 1 do
    begin
      srcX := CosRad * X - SinRad * Y + SourceCenter.X;
      srcY := SinRad * X + CosRad * Y + SourceCenter.Y;

      srcPoint.X := Round(srcX);
      srcPoint.Y := Round(srcY);

      if (srcPoint.X >= 0) and (srcPoint.X < DestPicture.Width) and (srcPoint.Y >= 0) and
        (srcPoint.Y < DestPicture.Height) then
      begin

        if srcY > 40 then
          MainForm.Caption := '';

        dltX := srcX - srcPoint.X;
        dltY := srcY - srcPoint.Y;

        N.X := TrimInt(srcPoint.X + 1, 0, DestPicture.Width - 1);
        N.Y := TrimInt(srcPoint.Y + 1, 0, DestPicture.Height - 1);

        if IsPng then
        begin
          R1 := SourcePict.ScanLine[srcPoint.Y];
          R2 := SourcePict.ScanLine[N.Y];
        end
        else
        begin
          R1 := SourceBmp.ScanLine[srcPoint.Y];
          R2 := SourceBmp.ScanLine[N.Y];
        end;

        if IsPng and IsAlpha then
        begin
          A1 := SourcePict.AlphaScanline[srcPoint.Y];
          A2 := SourcePict.AlphaScanline[N.Y];
        end;

        nw.R := R1[srcPoint.X * 3];
        nw.G := R1[srcPoint.X * 3 + 1];
        nw.B := R1[srcPoint.X * 3 + 2];
        if IsPng and IsAlpha then
          anw := A1[srcPoint.X];
        ne.R := R1[N.X * 3];
        ne.G := R1[N.X * 3 + 1];
        ne.B := R1[N.X * 3 + 2];
        if IsPng and IsAlpha then
          ane := A1[N.X];
        sw.R := R2[srcPoint.X * 3];
        sw.G := R2[srcPoint.X * 3 + 1];
        sw.B := R2[srcPoint.X * 3 + 2];
        if IsPng and IsAlpha then
          asw := A2[srcPoint.X];
        se.R := R2[N.X * 3];
        se.G := R2[N.X * 3 + 1];
        se.B := R2[N.X * 3 + 2];
        if IsPng and IsAlpha then
          ase := A2[N.X];

        T := nw.B + dltX * (ne.B - nw.B);
        B := sw.B + dltX * (se.B - sw.B);
        DestRow[(X + DestCenter.X) * 3 + 2] := IntToByte(Round(T + dltY * (B - T)));
        T := nw.G + dltX * (ne.G - nw.G);
        B := sw.G + dltX * (se.G - sw.G);
        DestRow[(X + DestCenter.X) * 3 + 1] := IntToByte(Round(T + dltY * (B - T)));
        T := nw.R + dltX * (ne.R - nw.R);
        B := sw.R + dltX * (se.R - sw.R);
        DestRow[(X + DestCenter.X) * 3] := IntToByte(Round(T + dltY * (B - T)));

        if IsPng and IsAlpha then
        begin
          T := anw + dltX * (ane - anw);
          B := asw + dltX * (ase - asw);
          DestAlpha[(X + DestCenter.X)] := IntToByte(Round(T + dltY * (B - T)));
        end;
      end;
    end;
  end;

  if IsPng then
  begin
    DestPicture.Assign(DestPict);
    DestPict.Free;
    SourcePict.Free;
  end
  else
  begin
    DestPicture.Assign(DestBmp);
    DestBmp.Free;
    SourceBmp.Free;
  end;
end;

procedure TObjectImage.SetAction(P: PActionLI; Act: TACtionInfo);
begin
  if Act.ActType = actCircleMove then
    CalcCenter(Act);
  P^.Info := Act;
  if Assigned(UpdateOneAction) then
    UpdateOneAction(Act);
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

procedure TObjectImage.ViewImage(Pict: TGraphic);
begin
  Picture.Assign(Pict);
  Height := Pict.Height;
  Width := Pict.Width;
end;

end.
