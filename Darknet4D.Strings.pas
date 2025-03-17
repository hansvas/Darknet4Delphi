unit Darknet4d.Strings;
interface
uses classes;

///<summary>Pr�ft das letzte Zeichen eines Strings darauf ob es einen
///  Slash oder Backslash enth�lt. Wenn das nicht der Fall ist wird
///  der in default definierte Charakter hinzugef�hgt. Dieses
///  ist normalerweise ein / da Windows normalerweise Slash und
///  Backslash versteht, unixoide Systeme nur einen Slash in
///  Pfadangaben g�ltig sind</summary>
function AddSlash(const dir : String; const default : Char = '/') : String; inline;

implementation
uses //vasold.basics.strings,
     Windows, SysUtils;

function AddSlash(const dir : String; const default : Char = '/') : String; inline;
begin
  if (dir[length(dir)] in ['\','/']) then
    result := dir
  else
    result := dir + default;
end;


end.
