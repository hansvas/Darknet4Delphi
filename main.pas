unit main;
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.ExtDlgs,

  Darknet4D, Darknet4D.Classes, Vcl.NumberBox, Vcl.Samples.Spin;

type
  TFrmDarknet = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    edConfig: TEdit;
    ScrollBox: TScrollBox;
    Label3: TLabel;
    edNames: TEdit;
    edWeights: TEdit;
    spOpenWeights: TSpeedButton;
    spOpenConfig: TSpeedButton;
    spOpenImage: TSpeedButton;
    OpenDialog: TOpenDialog;
    Image: TImage;
    btnLoadNetwork: TButton;
    btnLoadImage: TButton;
    btnDetect: TButton;
    OpenPictureDialog: TOpenPictureDialog;
    lb: TListBox;
    nbThresh: TNumberBox;
    Label4: TLabel;
    cbRegisteredNetwork: TComboBox;
    btnRegisterNetwork: TButton;
    spOverlapped: TSpinEdit;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure spOpenWeightsClick(Sender: TObject);
    procedure spOpenConfigClick(Sender: TObject);
    procedure spOpenImageClick(Sender: TObject);
    procedure btnLoadNetworkClick(Sender: TObject);
    procedure btnLoadImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
    procedure btnRegisterNetworkClick(Sender: TObject);
    procedure cbRegisteredNetworkChange(Sender: TObject);
  private
    function AppPath : String;
  public
    { Public-Deklarationen }
    loaded : Boolean;
    Darknet : TDarknet;
    ImageFileName : String;
  end;

var
  FrmDarknet: TFrmDarknet;


implementation
uses {vasold.basics.strings,
     DOcrIcr.Interfaces, }
     Darknet4d.Strings,

     Vcl.Imaging.jpeg;

{$R *.dfm}

procedure TFrmDarknet.FormDestroy(Sender: TObject);
var fs : TFileStream;
begin
  fs := TFileStream.Create(appPath + 'Networks.str', fmCreate);
  try
   Darknet.SaveToStream(fs);
  finally
   fs.free;
  end;
end;

function TFrmDarknet.AppPath : String;
begin
  result := AddSlash(ExtractFilePath(Application.ExeName));
end;

procedure TFrmDarknet.btnDetectClick(Sender: TObject);
var lst : TDetectionList;
  found : Integer;
  r,r2 : TBitmap;
  d : TDetection;
  free : Boolean;

  freq     : Int64;
  startTime: Int64;
  endTime  : Int64;

begin
 if not Darknet.Loaded then
 begin
   Darknet.ConfigFile  := edConfig.Text;
   Darknet.WeightsFile := edWeights.Text;
   Darknet.NamesFile   := edNames.Text;
   Darknet.Loaded      := True;
   Darknet.Overlapped  := spOverlapped.Value;
 end;
 lb.Items.Clear;
 lst := nil;

 Darknet.ScaleImage := True;
 r := Darknet.CopyImageFromBitmap24(Image.Picture.Bitmap, free);

 QueryPerformanceFrequency(freq);
 QueryPerformanceCounter(startTime);

 found := Darknet.Detections(lst, True, nbThresh.Value, nbThresh.Value);

 QueryPerformanceCounter(endTime);

 if found>0 then
  begin
   for var i := 0 to lst.Count-1 do
    begin
     d := lst[i];
     lb.Items.Add(d.c);
     r.Canvas.Rectangle(d.r);
     Image.Picture.Bitmap.Canvas.FrameRect(Darknet.ScaleRect(d.r));
    end;
  ShowMessage
   ('Die Routine benötigte etwa ' +
      IntToStr((endTime - startTime) * 1000 div freq) + 'ms');
  end else
  MessageDlg('no objects detected', mtWarning, [mbOK], 0);

 lst.Free;
 if free then
    r.Free;
end;

procedure TFrmDarknet.btnLoadImageClick(Sender: TObject);
begin
 if OpenPictureDialog.Execute() then
 begin
    ImageFileName := OpenPictureDialog.FileName;
    Image.Picture.LoadFromFile(imageFileName);
 end;
end;

procedure TFrmDarknet.btnLoadNetworkClick(Sender: TObject);
begin
 Darknet.Loaded := False;
 Darknet.ConfigFile := edConfig.Text;
 Darknet.WeightsFile := edWeights.Text;
 Darknet.NamesFile   := edNames.Text;
 Darknet.Loaded := True;
end;

procedure TFrmDarknet.btnRegisterNetworkClick(Sender: TObject);
var s : String;
begin
 s := cbRegisteredNetwork.Text;
 if cbRegisteredNetwork.Items.IndexOf(s)<0 then
   Darknet.RegisterNetwork( s,
        edWeights.Text,
        edConfig.Text,
        edNames.Text );
 cbRegisteredNetwork.Items.Add(s);
end;

procedure TFrmDarknet.cbRegisteredNetworkChange(Sender: TObject);
var s : String;
begin
 if cbRegisteredNetwork.Items.Count > 0 then
  begin
   s := cbRegisteredNetwork.Text;
   if cbRegisteredNetwork.Items.IndexOf(s)>= 0 then
   begin
      Darknet.SelectNetwork(s);
      edWeights.Text := Darknet.WeightsFile;
      edConfig.Text  := Darknet.ConfigFile;
      edNames.Text   := Darknet.NamesFile;
      Darknet.Overlapped := spOverlapped.Value;
      lb.Items.Clear;
      Image.Picture := nil;
   end;
  end;
end;

procedure TFrmDarknet.FormCreate(Sender: TObject);
var p : String;
   fs : TFileStream;
begin
 p := appPath + 'darknet.dll';
 LoadLibDarknet( appPath + 'darknet.dll', True);

 Darknet := TDarknet.Create(self);
 Darknet.ScaleImage := True;

 if FileExists(appPath + 'Networks.str') then
 begin
    fs := TFileStream.Create(appPath + 'Networks.str', fmOpenRead);
    try
     Darknet.LoadFromStream(fs);
    finally
      fs.free;
    end;
 end;

 cbRegisteredNetwork.Items.Assign(Darknet.__Networks);
end;

procedure TFrmDarknet.spOpenConfigClick(Sender: TObject);
begin
  openDialog.FileName := '';
 if openDialog.Execute then
  edConfig.Text := OpenDialog.FileName;
end;

procedure TFrmDarknet.spOpenImageClick(Sender: TObject);
begin
 openDialog.FileName := '';
 if openDialog.Execute then
  begin
   edNames.Text := openDialog.FileName;
  end;
end;

procedure TFrmDarknet.spOpenWeightsClick(Sender: TObject);
begin
 openDialog.FileName := '';
 if openDialog.Execute() then
  edWeights.Text := openDialog.FileName;
end;

end.
