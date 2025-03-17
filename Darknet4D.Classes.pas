{.$DEFINE DOCRICR}
unit Darknet4D.Classes;
interface
uses Types,
     Classes,

     Generics.Collections,
     Generics.Defaults,

     vcl.Graphics,
     DOcrIcr.Info,

     Darknet4D


{$IFDEF DOCRICR}
     , DOcrIcr.Interfaces
{$ENDIF}

     ;

type

{$IFNDEF DOCRICR}
     float  = single;
     pFloat = ^float;

     floatptr = ^float;
     floatarr = array [0..1024] of float;
     pfloatarr = ^floatarr;

     TDetection = record
          i : Integer; // temporärer index
          s : Single;  // temporärer Überlappungswert
          r : TRect;
          c : String;
       conf : Single;
     end;

     TDetectionList  = TList<TDetection>;
     TDetectionsList = TDictionary<String,TDetection>;
{$ENDIF}


     TByteMatrix = array of array of integer;

     detection_array  = array [0..1024] of detection;
     pDetection_array = ^detection_array;

     ///<summary>Nimmt ein Bild bzw. einen Bildausschnitt auf zusammen mit
     ///  den Koordinaten bzw. Daten des Bildes in dem das Bild vorhanden
     ///  ist</summary>
     TDetectionWithImage = class(TObject)
     public
      img : TBitmap;
      det : TDetection;
     end;

     ///<summary>TDNetwork repräsentiert die Metadaten eines Darknet-Netzwerks
     /// und ist in der Lage diese in einem Stream zu schreiben</summary>
     TDNetwork = class(TObject)
     private
      FWeights    : AnsiString;
      FConfig     : AnsiString;
      FNamesFile  : AnsiString;
      FThreshFile : AnsiString;
      FThresholds : TStringList;

      FIsLocal    : Boolean;
     protected
      procedure SetThreshFile(const Value: AnsiString);               virtual;
     public
      Constructor CreateFromStream(aStream : TStream);                virtual;

      Constructor Create
          (const awgtFile, acnfgFile, anamesFile : AnsiString);       virtual;

      Destructor Destroy; override;
      ///<summary>Thresholds werden außerhalb des Streams in einer eigenen
      ///  Datei gespeichert. Die Methode SaveThresholds wird allerdings
      ///  innerhalb von SaveToStream aufgerufen</summary>
      procedure SaveThresholds;
      ///<summary>Thresholds werden außerhalb des Streams in einer eigenen
      ///  Datei gespeichert. Die Methode LoadThreshold wird allerdings
      ///  innerhalb von LoadFromStream aufgerufen</summary>
      procedure LoadThresholds;
      ///<summary>Schreibt den Namen der Dateien in denen die Gewichte,
      ///  Konfiguration und die Namen gespeichert sind in einen Stream</summary>
      procedure SaveToStream (aStream : TStream);   virtual;
      ///<summary>Liest den Namen der Dateien in denen die Gewichte,
      ///  Konfiguration und die Namen gespeichert sind in einen Stream</summary>
      procedure LoadFromStream(aStream : TStream);  virtual;
     ///<summary>Name der Datei mit den Gewichten</summary>
     property
      Weights : AnsiString
       read FWeights;
     ///<summary>Name der Konfigurationsdatei</summary>
     property
      Config : AnsiString
       read FConfig;
     ///<summary>Name der Datei mit den Klassennamen</summary>
     property
      NamesFile : AnsiString
       read FNamesFile;
     ///<summary>Name der Datei mit den individuellen Grenzen je Klasse</summary>
     property
     ThreshFile : AnsiString
      read FThreshFile write SetThreshFile;
     ///<summary>Die Grenzen als StringListe, werden aus ThreshFile geladen</summary>
     property
      Thresholds : TStringList
       read FThresholds;

     ///<summary> Default True, gibt an ob das Netzwerk local, d.h. innerhalb
     ///  der gleichen Komponente, oder remote, also in einer anderen Komponente
     ///  oder einem anderen Prozess/Rechner abgefragt werden kann</summary>
     property
      IsLocal : Boolean
       read FIsLocal write FIsLocal;
     end;

     ///<summary> TDarknet kapselt und implementiert die Aufrufe der
     ///  Darknet .dLL/.so und erweitert diese:
     ///</summary>
     TDarknet = class(TComponent)
     private
      Darknet        : Pointer;
      FCurrent       : String;
      FNetworks      : TStringList;
      FThresh        : TStringList;
      FFilter        : TStringList;
      FMappings      : TStringList;

      FScaleImage    : Boolean;
      FLoaded        : Boolean;

      FWidth         : Integer;
      FHeight        : Integer;
      FChannels      : Integer;
      FBatchSize     : Integer;
      FWeights       : AnsiString;
      FConfig        : AnsiString;
      FNamesFile     : AnsiString;
      FThresholds    : AnsiString;

      FImage         : Image;
      FNames         : TStringList;

      FOverlapped    : Integer;
      FLastWidth,
      FLastHeight    : Integer;

      FLimitBB       : Boolean;
      FOffset        : Integer;
      FThreshold     : Integer;
     protected
      // Kopie des Pointers des Bildes welcher durch CopyImageFromBitmap24
      // angefertigt wird. ZUgriff macht nur dann Sinn solange der Pointer
      // existiert
      Copied : TByteMatrix;

      procedure FreeNetworkList;

      function getClassCount : Integer;                   inline;
      function getCurrentImage : pImage;                  inline;
      function getClassName(aIndex : Integer):String;     inline;

      function  getOverlapped: Integer;                   virtual;
      procedure SetOverlapped(const Value: Integer);      virtual;
      procedure SetLoaded(aValue : Boolean);              virtual;
      function  getLoaded : Boolean;                      virtual;

      function  getWidth  : Integer;
      function  getHeight : Integer;
      function  getChannels : Integer;
      function  getNamesFile : AnsiString;
      procedure setNamesFile(const aFile : AnsiString);
      function getWeightsFile : AnsiString;
      procedure setWeightsFile(const aFile : AnsiString);
      function getConfigFile : AnsiString;
      procedure setConfigFile(const aFile : AnsiString);

      function getThresholds : AnsiString;
      procedure setThresholds(const aFile : AnsiString);
      function getClassThreshold(const aName : String) : Double;

      function removeNegatives
         (detections : pDetection_array; num : Integer;
           SimplyTheBest : Boolean): TDetectionList;

      property
        Filter : TStringList
         read FFilter;

      property
        Mappings : TStringList
         read FMappings;

     public
      Constructor Create(aOwner : TComponent);            override;
      Destructor Destroy;                                 override;

      ///<summary> Ermöglicht es die Ergebnisliste zu "filtern", so dass
      /// nur Klassen die in der Filterliste enthalten sind angezeigt
      /// werden. Filter und Mappings werden durch SaveToStream nicht
      /// gespeichert</summary>
      procedure AddFilter(const aFilter : String);        virtual;

      ///<summary> Ermöglicht ein Mapping zwischen zwei Klassen. Dabei wird
      /// die erkannte Klasse c zu m gemappt. Mappings werden vor Filtern
      /// angewendet. Filter und Mappings werden durch SaveToStream nicht
      /// gespeichert</summary>
      procedure AddMapping(const c,m : String); virtual;
      ///<summary> Ermöglicht es die Liste der Netzwerke in einen Stream
      ///  und andere Eigenschaften zu schreiben </summary>
      procedure SaveToStream (aStream : TStream);         virtual;
      ///<summary> Ermöglicht es die Liste der Netzwerke und andere Eigenschaften
      ///  aus einem Stream zu lesen </summary>
      procedure LoadFromStream(aStream : TStream);        virtual;

      ///<summary>Liefert eine Liste von detections in einem bild zurück.</summary>
      function Detections
        (var lst : TDetectionList; nms : Boolean = True;
         thresh : Float = 0.85; hier_thresh : float = 0.7 ) : Integer;  virtual;
      ///<summary> Depredicated, not working with darknet v 3.0 </summary>
      //function Classification(var confidence : Single) : String;

      ///<summary>Wird verwendet um das zu verarbeitende Bild in den Speicher
      /// zu laden. Je nach Einstellung, insbesondere abhängig von der
      /// Eigenschaft ScaleImage, werden Bilder ggf. passend skaliert.
      ///
      /// Wird das Bild intern skaliert dann wird der Parameter
      /// freeScaled true, was bedeutet das der Aufrufer das zurückgegebene
      /// Bitmap freigeben muss. Ist freeScaled nicht wahr, dann darf das
      /// zurückgegebene Bild nicht freigegeben werden</summary>
      function CopyImageFromBitmap24
                  (aBitmap : TBitmap; var freeScaled : Boolean) : TBitmap;

      ///<summary>AdjustDetected kann eíngesetzt werden um eine BoundingBox
      /// um einen klar abgrenzbaren Bereich zu ermitteln um so die
      /// Erkennungsgenauigkeit zu steigern</summary>
      procedure AdjustDetected(var r : TRect);

      ///<summary> Liefert zu einer vorhanden Box die Koordinaten der Box
      ///  in den Originalkoordinaten zurück. Funktioniert mit skalierten
      ///  Bildern</summary>
      function ScaleRect(r : TRect) : TRect;                  overload; inline;
      function ScaleRect(dx,dy : Integer; r : TRect) : TRect; overload; inline;

      procedure ClearNetworks;  virtual;
      ///<summary> Liefert zu einem Namen den Index, wenn vorhanden, des
      /// zugehörigen, registrierten Netzwerkes zurück</summary>
      function isRegisteredNetwork(const n : String) : Integer;         inline;

      ///<summary>Erlaubt es die Informationen zu einem Netzwerk in einer
      ///  Liste zu speichern und fortan mit den gespeicherten Namen zu
      ///  arbeiten. Liefert im Erfolgsfall die entsprechende Komponente
      ///  zurück.</summary>
      function RegisterNetwork
       (const aName : String; wgtFile, cnfgFile, namesFile : AnsiString) : TDNetwork; virtual;

      ///<summary>Löscht ein Netzwerk bzw. dessen Paramter aus der Liste
      ///  der verfügbaren Netzwerke</summary>
      procedure DeleteNetwork(const aName : String);

      ///<summary>Wählt ein Netzwerk aus der Liste der Netzwerke aus und
      ///  lädt es in den Speicher. Liefert nil zurück wenn der Name
      ///  nicht registriert ist.</summary>
      function SelectNetwork(const aName : String) : TDNetwork; overload;
      function SelectNetwork(idx : Integer): TDNetwork; overload;


      procedure setClassThreshold(const aName : String; aValue : Double); virtual;
      function CheckOverlapped  (var lst : TDetectionList) : Integer;
     property
      CurrentImage : pImage
       read getCurrentImage;
     ///<summary>Nachdem ein Netzwerk geladen ist kann hiermit die Breite
     /// der ursrünglichen Trainingsbilder ausgelesen werden</summary>
     property
      Width : Integer
       read getWidth;
     ///<summary>Nachdem ein Netzwerk geladen ist kann hiermit die Höhe
     /// der ursrünglichen Trainingsbilder ausgelesen werden</summary>
     property
      Height : Integer
       read getHeight;
     ///<summary>Nachdem ein Netzwerk geladen ist kann hiermit die Anzahl
     /// der Farbkanäle der ursrünglichen Trainingsbilder ausgelesen
     /// werden</summary>
     property
      Channels : Integer
       read getChannels;
     ///<summary>Gibt in Abhängigkeit des Indexes den Namen der entsprechenden
     ///  Klasse zurück.</summary>
     property
      ClassName [index : Integer] : String
       read getClassName;
     property
      ClassThreshold [const index : String] : Double
       read getClassThreshold;
     ///<summary>Anzahl der vorhandenen Klassen</summary>
     property
      ClassCount : Integer
       read getClassCount;
     ///<summary> Metadaten: Name der Datei mit den Namen/Klassen des
     /// Netzwerkes. Wird beim laden des Netzwerkes ausgewertet</summary>
     property
      NamesFile : AnsiString
       read getNamesFile write setNamesFile;
     ///<summary> Dateipfad/Name mit den Gewichten des trainierten Netzwerkes. </summary>
     property
      WeightsFile : AnsiString
       read getWeightsFile write setWeightsFile;
     ///<summary> Dateipfad/Name mit der Konfiguration des trainierten Netzwerkes</sumamry>
     property
      ConfigFile : AnsiString
       read getConfigFile write setConfigFile;

     property
       Thresholds : AnsiString
        read getThresholds write setThresholds;
     ///<summary>Damit lässt sich bestimmen ob das Bild auf die Größe des
     /// Netzwerkes skaliert wird oder nicht. Bilder welche größersind als
     ///  die Maße des Netzwerkes müssen häufig skaliert werden um überhaupt
     ///  vernünftig verarbeitet werden zu können </summary>
     property
      ScaleImage : Boolean
       read FScaleImage write FScaleImage;
     ///<summary>Bestimmt wie sehr zwei Objekte der gleichen Klasse überlappen
     /// müssen um als unterschiedlich zu gelten. Die Werte sind Prozentangaben.
     /// 0 bedeutet das eine Prüfung auf überlappung unterbleibt  </summary>
     property
      Overlapped : Integer // 0-11
       read getOverlapped write SetOverlapped;
     ///<summary>Zeigt an ob das Netzwerk erfolgreich geladen wurde</summary>
     property
      Loaded : Boolean
       read getLoaded write SetLoaded;
     ///<summary>Kann verwendet
     /// werden um die gefundenen Boxen auf den Bereich zu limitieren der
     /// vom Hintergrund abweicht. Wird meist in Zusammenhang mit der
     /// Verarbeitung von Dokumenten verwendet. So kann beispielsweise
     /// ein Textfeld so verkleinert werden das tatsächlich nur der
     /// der Text innerhalb der Box existiert.</summary>
     property
      LimitBB : Boolean
       read FLimitBB write FLimitBB;
     ///<summary>Falls LimitBB wahr ist, gibt LimitOffset den Bereich an
     /// um den die erkannte Box vergrößert wird, damit der Suchbereich
     /// groß genug ist.
     ///
     /// LimitBB
     property
      Offset : Integer
       read FOffset write FOffset;
     ///<summary>Da es sich bei den
     property
      Threshold : Integer
       read FThreshold write FThreshold;
     property
      __Networks : TStringList
       read FNetworks;
     end;

function SmoothResize(abmp:TBitmap; NuWidth,NuHeight:integer) : TBitmap;

procedure Register;

implementation
uses sysUtils,

     vasold.basics.strings,

     Darknet4D.strings;


type TRGBTriple = record
      rgbtBlue: Byte;
      rgbtGreen: Byte;
      rgbtRed: Byte;
     end;


     TRGBArray = ARRAY[0..32767] OF TRGBTriple;
     pRGBArray = ^TRGBArray;
     pRGBTriple = ^TRGBTriple;

 { Source: Resize a JPEG image. (re-post) on borland.public.delphi.graphics
   Author (most likely)
   Charles Hacker
   Lecturer in Electronics and Computing
   Australia }


function SmoothResize(abmp:TBitmap; NuWidth,NuHeight:integer) : TBitmap;
var xscale, yscale : Single;
  sfrom_y, sfrom_x : Single;
  ifrom_y, ifrom_x : Integer;
  to_y, to_x : Integer;
  weight_x, weight_y : array[0..1] of Single;

  weight : Single;
  new_red, new_green : Integer;
  new_blue : Integer;
  total_red, total_green : Single;
  total_blue : Single;
  ix, iy : Integer;
  sli, slo : pRGBArray;
  slArray: array[0..1] of pRGBArray;

begin
  result := TBitmap.Create;
  result.PixelFormat := pf24bit;
  result.Width  := NuWidth;
  result.Height := NuHeight;

  xscale := result.Width / (abmp.Width-1);
  yscale := result.Height / (abmp.Height-1);

  for to_y := 0 to result.Height-1 do
    begin
      sfrom_y := to_y / yscale;
      ifrom_y := Trunc(sfrom_y);
      weight_y[1] := sfrom_y - ifrom_y;
      weight_y[0] := 1 - weight_y[1];

      slArray[0] := abmp.Scanline[ifrom_y];
      slArray[1] := abmp.Scanline[ifrom_y + 1];
      slo := result.ScanLine[to_y];
      for to_x := 0 to result.Width-1 do
        begin
          sfrom_x := to_x / xscale;
          ifrom_x := Trunc(sfrom_x);
          weight_x[1] := sfrom_x - ifrom_x;
          weight_x[0] := 1 - weight_x[1];
          total_red := 0.0;
          total_green := 0.0;
          total_blue := 0.0;
          for ix := 0 to 1 do
            for iy := 0 to 1 do
              begin
                sli := slArray[iy];
                new_red := sli[ifrom_x + ix].rgbtRed;
                new_green := sli[ifrom_x + ix].rgbtGreen;
                new_blue := sli[ifrom_x + ix].rgbtBlue;
                weight := weight_x[ix] * weight_y[iy];
                total_red := total_red + new_red * weight;
                total_green := total_green + new_green * weight;
                total_blue := total_blue + new_blue * weight;
              end;
          slo[to_x].rgbtRed   := Trunc(total_red);
          slo[to_x].rgbtGreen := Trunc(total_green);
          slo[to_x].rgbtBlue  := Trunc(total_blue);
        end;
    end;
end;

function bbox2points(bbox : box; w,h : Integer) : TRect; inline
var w2, h2 : Integer;
begin
  w2 := round(bbox.w)+1;
  h2 := round(bbox.h)+1;

  result.Left   := round(bbox.x) - (w2 DIV 2);
  result.Top    := round(bbox.y) - (h2 DIV 2);
  result.Right  := result.Left + w2;
  result.Bottom := result.Top + h2;

  if result.Top < 0 then
     result.Top := 0 else
  if result.Bottom > h then
     result.Bottom := h-1;
  if result.Left < 0 then
     result.Left := 0 else
  if result.Right > w then
     result.Right := w-1;
end;

function allocMat(sx,sy : Integer) : TByteMatrix;
var i,j : Integer;
begin
  SetLength(result,sy);
  for i := 0 to sy-1 do
  begin
     SetLength(result[i],sx);
     for j := 0 to sx-1 do
         result[i,j] := 0;
  end;
end;

// -----------------------------------------------------------------------------

Constructor TDarknet.Create(aOwner : TComponent);
begin
  inherited Create(aOwner);
  FNetworks  := TStringList.Create;
  FNames     := TStringList.Create;
  FFilter    := TStringList.Create;
  FMappings  := TStringList.Create;

  FThresh    := nil;
  FLoaded    := False;
  FWeights   := '';
  FConfig    := '';
  FBatchSize := 1;
  FWidth     := -1;
  FHeight    := -1;
  FLastWidth := -1;
  FLastHeight:= -1;
  FChannels  := -1;
  FOverlapped := 0;
end;

Destructor TDarknet.Destroy;
begin
  if Loaded then
     Loaded := False;
  FFilter.Free;
  FMappings.Free;
  FNames.Free;
  FreeNetworkList;
  inherited Destroy;
end;

procedure TDarknet.FreeNetworkList;
begin
  for var i := 0 to FNetworks.Count-1 do
   begin
     if Assigned(FNetworks.Objects[i]) then
     begin
       FNetworks.Objects[i].Free;
       FNetworks.Objects[i] := nil;
     end;
   end;
end;

procedure TDarknet.SaveToStream (aStream : TStream);
var cnt : Integer;
    net : TDNetwork;
begin
 cnt := FNetworks.Count;
 aStream.Write(cnt, SizeOf(Integer));
 for var i := 0 to cnt-1 do
  begin
    net := TDNetwork(FNetworks.Objects[i]);
    WriteStringToStream(aStream, FNetworks[i]);
    net.SaveToStream(aStream)
  end;
end;

procedure TDarknet.LoadFromStream(aStream : TStream);
var cnt : Integer;
    net : TDNetwork;
    s   : String;
begin
 FreeNetworkList;
 aStream.Read(cnt, SizeOf(Integer));
 for var i := 0 to cnt-1 do
  begin
    ReadStringFromStream(aStream, s);
    net := TDNetwork.CreateFromStream(aStream);
    FNetworks.AddObject(s,net);
  end;
end;

function TDarknet.isRegisteredNetwork(const n : String) : Integer;
begin
  result := FNetworks.IndexOf(n);
end;

procedure TDarknet.ClearNetworks;
begin
  FNetworks.Clear;
end;

function TDarknet.RegisterNetwork
       (const aName : String; wgtFile, cnfgFile, namesFile : AnsiString) : TDNetwork;
var idx : Integer;
    net : TDNetwork;
begin
 result := nil;
 if FileExists(wgtFile)  and
    FileExists(cnfgFile) and
    FileExists(namesFile) then
    begin
     idx := IsRegisteredNetwork(aName);
     if idx >= 0 then
      begin
        net := TDNetwork(FNetworks.Objects[idx]);
        if Assigned(net) then
           net.Free;
        FNetworks.Delete(idx);
      end;
      net    := TDNetwork.Create(wgtFile,cnfgFile,namesFile);
      FNetworks.AddObject(aName, net);
      result := net;
    end;
end;

procedure TDarknet.DeleteNetwork(const aName : String);
var idx : Integer;
    net : TDNetwork;
begin
     idx := FNetworks.IndexOf(aName);
     if idx >= 0 then
      begin
        net := TDNetwork(FNetworks.Objects[idx]);
        if Assigned(net) then
           net.Free;
      end;
end;

function TDarknet.SelectNetwork(idx : Integer) : TDNetwork;
var net : TDNetwork;
begin
  result := nil;
  if idx >= 0 then
      begin
       net := TDNetwork(FNetworks.Objects[idx]);
       FCurrent    := FNetworks[idx];
       //--------------------------------------
       Loaded      := False;
       ConfigFile  := net.Config;
       WeightsFile := net.Weights;
       NamesFile   := net.NamesFile;
       Thresholds  := net.ThreshFile;
       if Assigned(net.Thresholds) then
          FThresh := net.Thresholds;
       result := net;
       Loaded := True;
      end;
end;

function TDarknet.SelectNetwork(const aName : String) : TDNetwork;
var idx : Integer;
    net : TDNetwork;
begin
  result := nil;
  idx := FNetworks.IndexOf(aName);
  if idx >= 0 then
      begin
       net := TDNetwork(FNetworks.Objects[idx]);
       FCurrent    := FNetworks[idx];
       //--------------------------------------
       Loaded      := False;
       ConfigFile  := net.Config;
       WeightsFile := net.Weights;
       NamesFile   := net.NamesFile;
       Thresholds  := net.ThreshFile;
       if Assigned(net.Thresholds) then
          FThresh := net.Thresholds;
       result := net;
       Loaded := True;
      end;
end;

function TDarknet.getConfigFile: AnsiString;
begin
 result := FConfig;
end;

procedure TDarknet.setClassThreshold(const aName: String; aValue: Double);
begin
 if Assigned(FThresh) then
    FThresh.Values[aName] := FloatToStr(aValue);
end;

function TDarknet.getClassThreshold(const aName: String): Double;
var s : String;
begin
 result := -1;
 if Assigned(FThresh) then
  begin
   s := FThresh.Values[aName];
   if s <> '' then
     result := StrToFloat(s);
  end;
end;

procedure TDarknet.setConfigFile(const aFile: AnsiString);
begin
 FConfig := aFile;
end;

function TDarknet.ScaleRect(dx,dy : Integer; r : TRect) : TRect;
var xScale, yScale : Single;
begin
  xscale := dx / (Width-1);
  yscale := dy / (Height-1);

  result.Left  := Round(r.Left   * xScale);
  result.Right := Round(r.Right  * xScale);
  result.Top   := Round(r.Top    * yScale);
  result.Bottom:= Round(r.Bottom * yScale);
end;

function TDarknet.ScaleRect(r : TRect) : TRect;
begin
  result := ScaleRect(FLastWidth, FLastHeight, r );
end;

function TDarknet.getClassName(aIndex : Integer):String;
begin
 try
   result := FNames[aIndex];
 except
   if (FNames.Count = 0) and (FNamesFile<>'') then
    begin
       FNames.LoadFromFile(FNamesFile);
       result := FNames[aIndex];
    end
   else
       raise;
 end;
end;

function TDarknet.getCurrentImage : pImage;
begin
  result := @fimage;
end;

function TDarknet.getChannels: Integer;
begin
 result  := FChannels;
end;

function TDarknet.getHeight: Integer;
begin
 result := FHeight;
end;

function TDarknet.getClassCount : Integer;
begin
  result := FNames.Count;
  if result = 0 then
   begin
     { TODO : load classes from metadata if any }
     raise Exception.Create('No Classes');
   end;
end;

function TDarknet.getLoaded : Boolean;
begin
  result := FLoaded;
end;

function TDarknet.getNamesFile: AnsiString;
begin
 result := FNamesFile;
end;

procedure TDarknet.SetLoaded(aValue : Boolean);
begin
  if aValue <> FLoaded then
   begin
     if FLoaded and Assigned(Darknet) then
       begin
         free_network_ptr(Darknet);
         Darknet := nil;
       end;
     if aValue then
      begin
        Darknet := darknet_load_neural_network
          (PAnsiChar(Fconfig), PAnsiChar(FNamesFile), PAnsiChar(Fweights));
        darknet_network_dimensions(Darknet, FWidth, FHeight, FChannels);
        if FNamesFile<>'' then
           FNames.LoadFromFile(FNamesFile, TEncoding.ANSI);
        fImage := Image(make_image(Height,Width,3));
      end;
      FLoaded := aValue;
    end;
end;

procedure TDarknet.setNamesFile(const aFile: AnsiString);
begin
 FNamesFile := aFile;
end;

function TDarknet.getOverlapped : Integer;
begin
  result := FOverlapped;
end;

function TDarknet.getThresholds: AnsiString;
begin
 result := FThresholds;
end;

function TDarknet.getWeightsFile: AnsiString;
begin
 result := FWeights;
end;

function TDarknet.getWidth: Integer;
begin
 result := FWidth;
end;

procedure TDarknet.SetOverlapped(const Value: Integer);
begin
 if Value <> FOverlapped then
 begin
  if Value < 0   then FOverlapped :=  0 else
  if Value > 100 then FOverlapped := 100
  else FOverlapped := Value;
 end;
end;

procedure TDarknet.setThresholds(const aFile: AnsiString);
begin
 FThresholds := aFile;
end;

procedure TDarknet.setWeightsFile(const aFile: AnsiString);
begin
 FWeights := aFile;
end;

procedure TDarknet.AddFilter(const aFilter: String);
begin
 if FFilter.IndexOf(aFilter) < 0 then
    FFilter.Add(aFilter);
end;

procedure TDarknet.AddMapping(const c, m: String);
begin
 var s : String := c + '=' + m;
 if Mappings.IndexOf(s)<0 then
    Mappings.Add(s);
end;

function TDarknet.CheckOverlapped(var lst : TDetectionList) : Integer;
var new_list,
    delete_list : TDetectionList;
    det, det2   : TDetection;
    ovr         : Single;
    add         : Boolean;
    iSize       : Integer;
begin
      ovr         := overlapped / 100;
      new_list    := TDetectionList.Create;
      delete_list := TDetectionList.Create;

      for var index := 0 to lst.count-1 do
       begin
        delete_list.clear;

        det   := lst[index];
        det.i := index;
        det.s := Round(det.r.Width * det.r.Height * ovr);
        add   := True;

        for det2 in new_list do
         if (det.c = det2.c) and
            (det.i <> det2.i) then
           begin
            if (det2.r = det.r) or
               (det2.r.Contains(det.r)) then add := False
            else
            if det.r.Contains(det2.r) then
              delete_list.add(det2)
            else begin
             var rr := TRect.intersect(det.r, det2.r);
             if rr.IsEmpty then add := True
                           else begin
                            iSize := rr.Width * rr.Height;
                            if iSize >= det2.s then
                               delete_list.Add(det2) else
                            if det.s < iSize   then
                               add := False;
                           end;
            end;
           end;

        for det2  in delete_list do
            new_list.remove(det2);
        if add then
           new_list.Add(det);
       end;
       delete_list.free;
       lst.free;
       lst := new_list;
       result := lst.count;
  if result > 0 then
    lst.Sort(TComparer<TDetection>.Construct(
     function (const left, right : TDetection) : Integer
     begin
      result := CompareStr(Left.c, right.c);
     end
     )
   )
end;

procedure TDarknet.AdjustDetected(var r : TRect);
var j,i : Integer;
    r2 : TRect;
    fnd : Boolean;
begin
 if Assigned(Copied) then
  begin
   r2.top := r.top - Offset;
   if r2.top < 0 then
      r2.top := 0;
   r2.bottom := r.Bottom + Offset;
   r2.Left := r.Left - Offset;
   if r2.Left < 0 then
      r2.Left := 0;
   r2.Right := r.Right + Offset;
   // oben
   fnd := False;
   for j := r2.Top to r2.Bottom-1 do
   begin
    for i := r2.left to r2.Right-1 do
      if copied[j,i] > 0 then
          begin
            fnd   := True;
            r.Top := j;
            break;
          end;
    if fnd then
       break;
   end;

   // unten
   fnd := False;
   for  j := r2.Bottom-1 downto r2.Top do
   begin
    for i := r2.left to r2.Right-1 do
      if copied[j,i] > 0 then
          begin
            fnd := True;
            r.bottom := j;
            break;
          end;
    if fnd then
       break;
   end;

   // links
   fnd := False;
   for i := r2.left to r2.Right-1 do
   begin
     for j := r2.Top to r2.Bottom-1 do
       if copied[j,i] > 0 then
          begin
            fnd := True;
            r.left := i;
            break;
          end;
     if fnd then
        break;
   end;


   // rechts
   fnd := True;
   for i := r.Right-1 downto r.left do
   begin
     for j := r2.Top to r2.Bottom-1 do
      if copied[j,i] > 0 then
          begin
            fnd := True;
            r.right := i;
            break;
          end;
     if fnd then
        break;
   end;

  end;
end;

function TDarknet.Detections
  (var lst : TDetectionList; nms : Boolean = True;
       thresh : Float = 0.85; hier_thresh : float = 0.7) : Integer;

var detection_list : pDetection_array;
    pnt  : Pointer;
    lst2 : TDetectionList;
    d    : TDetection;
    clst : Double;
    s    : String;
begin
 result := 0;

 if Assigned(CurrentImage) then
  begin
   network_predict_image(darknet, Darknet4D.DarknetImage(CurrentImage^));
   detection_list := pointer(get_network_boxes
     (darknet, width, height, thresh, hier_thresh, NIL, 0, @result, 0));
   if nms then
       do_nms_sort(pDetection(detection_list), result, ClassCount, 1);
   if Assigned(lst) then
    begin
     lst2 := removeNegatives (detection_list, result, True);
     lst.AddRange(lst2);
     lst2.Free;
    end
   else
    lst := removeNegatives (detection_list, result, True);
   free_detections(pointer(detection_list), result);

   // Mappings prüfen
   if Mappings.Count > 0 then
    begin
      var val : String;
      for var i := lst.Count-1 downto 0 do
       begin
         d    := lst[i];
         val  := Mappings.Values[d.c];
         if val <> '' then
            d.c := val;
       end;
    end;
   // Filter prüfen
   if Filter.Count > 0 then
    begin
     for var i := lst.Count-1 downto 0 do
      begin
       d    := lst[i];
       //s  := Trim(lst[i].c);
       if Filter.IndexOf(d.c)>=0 then
          lst.Delete(i);
      end;
    result := lst.Count;
    end;

   // Individuelle Threshold prüfen (falls vorhanden)
   if (Assigned(FThresh)) and
      (FThresh.Count > 0) then
   begin
     for var i := lst.Count-1 downto 0 do
      begin
       d    := lst[i];
       clst := getClassThreshold(d.c);
       if clst>0 then
        if d.conf < clst then
           lst.Delete(i);
      end;
    result := lst.Count;
   end;

   { TODO :
    in eigene Unterfunktion auslagern, in schön machen, vergleiche (contains etc.)
    anstatt in 3 eigenen Vergleichen in eine methode mit 3 unterscheidungen und
    wenn möglich nur einer berechnung. }
   if Overlapped>0 then
      result := CheckOverlapped(lst)
   else
   if result > 0 then
    lst.Sort(TComparer<TDetection>.Construct(
     function (const left, right : TDetection) : Integer
     begin
      result := CompareStr(Left.c, right.c);
     end
     )
   )
  end;
end;


function TDarknet.removeNegatives
   (detections : pDetection_array; num : Integer; SimplyTheBest : Boolean): TDetectionList;
var current : Detection;
    d       : TDetection;
    prob    : pFloat;
    p, best : Float;
    i       : Integer;

begin
  result  := TDetectionList.Create;

  for var j := 0 to num-1 do
   begin
      current := detections[j];
      i       := 0;
      if (current.classes > 0) and
         (current.classes <= classCount)  then
      begin
       prob := Pointer(current.prob);
       best := 0;

       while (Assigned(prob) and
             (i < current.classes)) do
       begin
        p := prob^;

        if p > best then
         begin
           d.c    := ClassName[i];
           d.conf := p;
           d.r    := bbox2points(current.bbox, width, height);

           if simplyTheBest then
              best := p
           else
              result.Add(d);

         end;
        inc(prob);
        i := i + 1;
       end;

       if (best>0) and
          (simplyTheBest) then
           result.Add(d);
      end;
   end;
end;

{$R-}

function TDarknet.CopyImageFromBitmap24
       (aBitmap : TBitmap; var freeScaled : Boolean) : TBitmap;
var w,h : Integer;

    i,j : Integer;
    g   : byte;

    wh,
    whh    : Integer;

    data   : pfloatarr;
    dataR,
    dataG,
    dataB  : pFloat;
    source : pRGBTriple;

    inv : Float;
begin
 inv := 1 / 255;
 if aBitmap.PixelFormat <> pf24Bit then
    aBitmap.PixelFormat := pf24Bit;
 FLastWidth := aBitmap.Width;
 FLastHeight:= aBitmap.Height;
 FreeScaled := False;

 if ScaleImage then
  begin
   w := Width;
   h := Height;
   if (aBitmap.Height <> Height) or
      (aBitmap.Width <> Width) then
      begin
       freeScaled := True;
       result := SmoothResize(aBitmap, Width, Height);
      end
    else
      result := aBitmap;
  end
 else
  begin
   result := aBitmap;
   if aBitmap.Width < Width then
      w := aBitmap.Width
   else
      w := Width;
   if aBitmap.Height < Height then
      h := aBitmap.Height
   else
      h := Height;
  end;

  if limitBB then
     Copied := allocMat(aBitmap.Width, aBitmap.Height)
  else
     Copied := nil;

  wh  := w * h;
  whh := w * (h+h);
  data  := pfloatarr(fImage.data);
  dataR := Pointer(data);
  dataG := Pointer(data);
  inc(dataG, wh);
  dataB := Pointer(data);
  inc(dataB, whh);

  if Assigned(Copied) then
   for j := 0 to h-1 do
     begin
      source := result.ScanLine[j];
      for i := 0 to w-1 do
        begin
         g := (source^.rgbtRed + source^.rgbtGreen + source^.rgbtBlue) DIV 3;
         if g <= Threshold then Copied[j,i] := 1
                           else Copied[j,i] := 0;
         dataR^ := source^.rgbtRed   * inv;
         inc(dataR);
         dataG^ := source^.rgbtGreen * inv;
         inc(dataG);
         dataB^ := source^.rgbtBlue  * inv;
         inc(dataB);
         inc(source);
        end;
     end
  else
   for j := 0 to h-1 do
     begin
      source := result.ScanLine[j];
      for i := 0 to w-1 do
        begin
         dataR^ := source^.rgbtRed   * inv;
         inc(dataR);
         dataG^ := source^.rgbtGreen * inv;
         inc(dataG);
         dataB^ := source^.rgbtBlue  * inv;
         inc(dataB);
         inc(source);
        end;
     end;

end;

// -----------------------------------------------------------------------------

Constructor TDNetwork.Create
    (const awgtFile, acnfgFile, anamesFile : AnsiString);
begin
  inherited Create;
  FWeights    := awgtFile;
  FConfig     := acnfgFile;
  FNamesFile  := anamesFile;
  FThreshFile := '';
  FThresholds := TStringList.Create;
end;

Destructor TDNetwork.Destroy;
begin
  if FThreshFile <> '' then
     FThresholds.SaveToFile(FThreshFile);
  FThresholds.free;
  inherited Destroy;
end;

Constructor TDNetwork.CreateFromStream(aStream : TStream);
begin
  inherited Create;
  FThresholds := TStringList.Create;
  LoadFromStream(aStream);
end;

procedure TDNetwork.SaveToStream (aStream : TStream);
begin
  WriteStringToStream(aStream, FWeights );
  WriteStringToStream(aStream, FConfig   );
  WriteStringToStream(aStream, FNamesFile);
  WriteStringToStream(aStream, FThreshFile);
  SaveThresholds;
end;

procedure TDNetwork.SetThreshFile(const Value: AnsiString);
begin
  if Value <> FThreshFile then
   begin
    FThreshFile := Value;
    if FileExists(FThreshFile) then
       FThresholds.LoadFromFile(FThreshFile);
   end;
end;

procedure TDNetwork.LoadFromStream(aStream : TStream);
var s : String;
begin
 ReadStringFromStream(aStream, s);
 FWeights := s;
 ReadStringFromStream(aStream, s);
 FConfig := s;
 ReadStringFromStream(aStream, s);
 FNamesFile := s;
 ReadStringFromStream(aStream, s);
 FThreshFile := s;
 LoadThresholds;
end;

procedure TDNetwork.SaveThresholds;
begin
  if FThreshFile <> '' then
     FThresholds.SaveToFile(FThreshFile);
end;

procedure TDNetwork.LoadThresholds;
begin
 if (FThreshFile <> '') and
    (FileExists(FThreshFile)) then
     FThresholds.LoadFromFile(FThreshFile);
end;

procedure Register;
begin
  registerComponents('Vasold', [TDarknet]);
end;

end.
