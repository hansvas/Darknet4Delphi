unit Darknet4D.Grayscale;
interface
  function ConvertToGrayscale(const aBitmap: TBitmap; const aMethod : TAlgorithm=algnone) : TBitmap; overload;
  function ConvertToGrayscale(const FileName : String; const aMethod : TAlgorithm=algnone) : TBitmap; overload;
  function ConvertToGrayscale(const aStream : TMemoryStream ; const aMethod : TAlgorithm=algnone) : TBitmap; overload;

implementation


end.
