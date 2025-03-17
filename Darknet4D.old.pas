unit Darknet4D.old;
interface
uses System.types;

type float = single;
     pFloat = ^float;

     floatptr = ^float;
     floatarr = array [0..1024] of float;
     pfloatarr = ^floatarr;


     intptr = ^integer;

     box = record
      x,y,w,h : Float;
     end;

     detection = record
      // __fields__=
       bbox    : box;
       classes : integer;
       best_class_idx : integer;
       prob : pfloatarr;
       mask : pfloatarr;
       objectness : float;
       sort_class : Integer;
       uc : floatPtr;
       points : integer;
       embeddings : float;
       embeddings_size : Integer;
       sim : float;
       track_id : integer;
     end;

     pDetection = ^Detection;

     detection_array  = array [0..1024] of detection;
     pDetection_array = ^detection_array;

     detnumpair = record
      // __fields__ =
      num  : integer;
      dets : floatptr;
     end;

     image = record
       // _fields__ =
       w    : integer;
       h    : integer;
       c    : integer;
       data : floatPtr;
     end;

     pImage = ^Image;

     metadata = record
       classes : integer;
       names   : pAnsiChar;
     end;

     pMetadata = ^metadata;

     network = Pointer;

     TDetection = record
          r : TRect;
          c : String;
       conf : Single;
     end;

var network_width         : function(network : pointer) : integer;
    network_height        : function(network : pointer) : integer;

    //load_network          : function(config,weights : PAnsiChar;
    //load_net.argtypes = (ct.c_char_p, ct.c_char_p, ct.c_int)
    //load_net.restype = ct.c_void_p
    load_network_custom   :
      function(config, weights : PAnsiChar; stat, batchSize : Integer) : network;

    get_metadata          : function ( fileName : pAnsiChar) : metadata;
    network_predict_image : function ( network : Pointer; img : image) : floatptr;
    network_predict_ptr   : function (network : Pointer; arg : FloatPtr) : floatptr;

    get_network_boxes : function
     (net : Pointer; width, height : Integer; thresh, hier_thresh : Float;
      p : pInteger; z : Integer; p2 : pInteger; z2 : Integer) : pDetection;

   {make_network_boxes = function( network
    make_network_boxes.argtypes = (ct.c_void_p,)
    make_network_boxes.restype = DETECTIONPtr}
  free_detections : procedure(p : pDetection; i : Integer);
  {reset_rnn = lib.reset_rnn
   reset_rnn.argtypes = (ct.c_void_p,)}
  {free_batch_detections = lib.free_batch_detections
  free_batch_detections.argtypes = (DETNUMPAIRPtr, ct.c_int)}

  free_network_ptr : function(network : Pointer) : Pointer;

  {do_nms_obj = lib.do_nms_obj
  do_nms_obj.argtypes = (DETECTIONPtr, ct.c_int, ct.c_int, ct.c_float)}
  do_nms_sort : procedure( p : pDetection; c1, c2 : Integer; f : float);
  free_image : procedure(img : IMAGE);

  make_image : function (height, width, depht : Integer) : Image;

  letterbox_image : function(img : IMAGE; width, height : Integer) : Image;

  network_predict_image_letterbox : function (p : Pointer; img : Image): FloatPtr;



{network_predict_batch = lib.network_predict_batch
network_predict_batch.argtypes = (ct.c_void_p, IMAGE, ct.c_int, ct.c_int, ct.c_int,
                                  ct.c_float, ct.c_float, IntPtr, ct.c_int, ct.c_int)
network_predict_batch.restype = DETNUMPAIRPtr}

    copy_image_from_bytes : procedure(bild : image; b : pByte);

function bbox2points(bbox : box; w,h : Integer) : TRect; inline

function loadNetwork
 (config_file, weights : pAnsiChar; batch_size : Integer): Network;


{def network_width(net):
    return lib.network_width(net)


def network_height(net):
    return lib.network_height(net)}


procedure LoadLibDarknet(const P: String; raiseError : Boolean = True);

implementation
uses SysUtils,
  Math,
  Windows;

var
  Handle: HModule = 0;
  module: String = '';

function ProcAddress(h: HModule; lpProcName: LPCWSTR): FarProc;
begin
  result := GetProcAddress(h, lpProcName);
  if result = nil then
    raise Exception.Create(lpProcName + ' not in module ' + module);
end;


procedure LoadLibDarknet(const P: String; raiseError : Boolean = True);
var
  ret: Integer;
  err: String;
begin
  // Laden nur wenn noch nicht geladen
  if Handle <> 0 then
    exit;

  module := P;
  Handle := SafeLoadLibrary(P,SEM_FAILCRITICALERRORS);
  if Handle = 0 then
  begin
    ret := GetLastError();
    err := SysErrorMessage(ret);
    if raiseError then
       raise Exception.Create(err)
    else
       Writeln(err);
  end; // ...

  network_width  := ProcAddress(Handle, 'network_width');
  network_height := ProcAddress(Handle, 'network_height');

  //load_network          : function(config,weights : PAnsiChar;
  //load_net.argtypes = (ct.c_char_p, ct.c_char_p, ct.c_int)
  //load_net.restype = ct.c_void_p

  load_network_custom := ProcAddress(Handle, 'load_network_custom');

  get_metadata := ProcAddress(Handle, 'get_metadata');
  network_predict_image := ProcAddress(Handle, 'network_predict_image');
  network_predict_ptr := ProcAddress(Handle, 'network_predict_ptr');
  get_network_boxes := ProcAddress(Handle, 'get_network_boxes');
  make_image := ProcAddress(Handle, 'make_image');

   {make_network_boxes = function( network
    make_network_boxes.argtypes = (ct.c_void_p,)
    make_network_boxes.restype = DETECTIONPtr}

  free_detections := ProcAddress(Handle, 'free_detections');

  {reset_rnn = lib.reset_rnn
   reset_rnn.argtypes = (ct.c_void_p,)}
  {free_batch_detections = lib.free_batch_detections
  free_batch_detections.argtypes = (DETNUMPAIRPtr, ct.c_int)}
  {do_nms_obj = lib.do_nms_obj
  do_nms_obj.argtypes = (DETECTIONPtr, ct.c_int, ct.c_int, ct.c_float)}

  free_network_ptr := ProcAddress(Handle, 'free_network_ptr');
  do_nms_sort := ProcAddress(Handle, 'do_nms_sort');
  free_image := ProcAddress(Handle, 'free_image');
  letterbox_image := ProcAddress(Handle, 'letterbox_image');
  network_predict_image_letterbox := ProcAddress(Handle, 'network_predict_image_letterbox');

{network_predict_batch = lib.network_predict_batch
network_predict_batch.argtypes = (ct.c_void_p, IMAGE, ct.c_int, ct.c_int, ct.c_int,
                                  ct.c_float, ct.c_float, IntPtr, ct.c_int, ct.c_int)
network_predict_batch.restype = DETNUMPAIRPtr}

  copy_image_from_bytes  := ProcAddress(Handle, 'copy_image_from_bytes');

  SetExceptionMask(exAllArithmeticExceptions);
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



///<summary>load model description and weights from config files
/// args:
///    config_file (str): path to .cfg model file
///    weights (str): path to weights
///  returns:
///    network: trained model

function loadNetwork
  (config_file, weights : PAnsiChar; batch_size : Integer): Network;
begin
 result := load_network_custom(config_file, weights, 0, batch_size);
end;

end.
