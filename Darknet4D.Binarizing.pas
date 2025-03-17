unit Darknet4D.Binarizing;
interface
uses  vcl.Graphics;

type FloatImageLine = array of Single;
     FloatMatrix    = array of FloatImageLine;

function  flMat(h,w : Integer) : FloatMatrix;
procedure freeMat(m : FloatMatrix);


function WolfJolion
  (im : TBitmap; winx, winy : Integer; k : Double; black, white : Byte) : TBitmap;

implementation


function flMat(h,w : Integer) : FloatMatrix;
begin
  SetLength(result,h);
  for var i := 0 to h-1 do
      SetLength(result[i],w);
end;

procedure freeMat(m : FloatMatrix);
begin
  for var i := 0 to Length(m)-1 do
      SetLength(m[i],0);
  SetLength(m,0);
end;

procedure MinMax(const inp : TBitmap; var mn,mx : Byte); inline;
var i,j    : Integer;
    source : PByte;
    val : Byte;
begin
 mx  := 0;
 mn  := 0;

 for I := 0 to inp.Height-1 do
 begin
  source := inp.ScanLine[i];
  for J := 0 to inp.Width-1 do
    begin
     val := source^;
     if val > mx then
        mx := val;
     if val < mn then
        mn := val;
     inc(source);
    end;
 end;
end;


{.$R-}
function calcLocalStats
  ( im : TBitmap; map_m, map_s : FloatMatrix; winx, winy : integer) : double;

var  m,s,max_s, sum, sum_sq : double;
     wxh, wyh, x_firstth, y_lastth, y_firstth : integer;
     winarea    : double;
     j,i,wy,wx  : Integer;
     jIdx : Integer;

     source, source1  : pByte;
begin
	wxh	:= winx DIV 2;
	wyh	:= winy DIV 2;
	x_firstth := wxh;
	y_lastth  := im.height-wyh-1;
	y_firstth := wyh;
	winarea   := winx*winy;
	max_s     := 0;  // checked

  for j := y_firstth to y_lastth do
  begin
		// Calculate the initial window at the beginning of the line
		sum    := 0;
    sum_sq := 0;

    for wy := 0 to winy-1 do
    begin
     source := im.ScanLine[wy];
     for wx := 0 to winx-1 do
      begin
				//foo    := im.__Data[wy][wx];
				sum    := sum    + source^;
				sum_sq := sum_sq + (source^*source^);
        inc(source);
			end;
    end;

		m  := sum / winarea;
		s  := sqrt ((sum_sq - (sum*sum)/winarea)/winarea);
		if (s > max_s) then
		  	max_s := s;

    map_m[j,x_firstth] := m;
    map_s[j,x_firstth] := s;

		// Shift the window, add and remove	new/old values to the histogram
    for i := 1 to (im.width-winx) do
    begin
      for wy := 0 to winy-1 do
      begin
        jIdx   := j-wyh+wy;
        source1 := im.ScanLine[jIdx];
				// foo    := im.__Data[jIdx,i-1];
        source := source1;
        inc(source,i-1);

				sum    := sum - source^ ;
				sum_sq := sum_sq - (source^*source^);

        // foo    := im.__Data[jIdx,i+winx-1];
        inc(source1,i+winx-1);
				sum    := sum + source1^;
				sum_sq := sum_sq + (source1^*source1^);
			end;

			m  := sum / winarea;
			s  := sqrt ((sum_sq - (sum*sum)/winarea)/winarea);
			if (s > max_s) then
				max_s := s;
      map_m[j,i+wxh] := m;
      map_s[j,i+wxh] := s;
		end;
	end;
	result := max_s;
end;

{.$R+}

function WolfJolion
  (im : TBitmap; winx, winy : Integer; k : Double; black, white : Byte) : TBitmap;

var m, s, max_s  : Double;
	th             : Double;

	min_I, max_I : Byte;
	wxh,
	wyh,
	x_firstth,
	x_lastth,
	y_lastth,
	y_firstth : Integer;

  map_m,
	map_s,
  thSurf : FloatMatrix;

  i,j,ii,u : Integer;

  source   : PByte;
  target   : PByte;
begin
  th        := 0;

	wxh      	:= winx DIV 2;
	wyh	      := winy DIV 2;

	x_firstth := wxh;
	x_lastth  := im.width  - wxh-1;
	y_lastth  := im.height - wyh-1;
	y_firstth := wyh;


	// Create local statistics and store them in a double matrices
	map_m := flMat(im.height,im.width);
	map_s := flMat(im.height,im.width);

	max_s := calcLocalStats (im, map_m, map_s, winx, winy);
  MinMax(im, min_i, max_i);
	thsurf := flMat(im.height, im.width);

	// Create the threshold surface, including border processing
	// ----------------------------------------------------
  for j := y_firstth to y_lastth do
  begin


   for i := 0 to  im.width-winx do
     begin
  		// NORMAL, NON-BORDER AREA IN THE MIDDLE OF THE WINDOW:
			m  := map_m[j,i+wxh];
  		s  := map_s[j,i+wxh];
      // calculate the threshold
      th := m + k * (s/max_s-1) * (m-min_I);
      thsurf[j,i+wxh] := th;
  		if (i=0) then
         begin
        		// LEFT BORDER
            for ii := 0 to x_firstth do
                thsurf[j,ii] := th;

        		// LEFT-UPPER CORNER
        		if (j=y_firstth) then
              for u := 0 to y_firstth-1 do
               for ii := 0 to x_firstth do
         				  thsurf[u,ii] := th;

        		// LEFT-LOWER CORNER
        		if (j=y_lastth) then
              for u := y_lastth+1 to im.height-1 do
               for ii := 0 to x_firstth do
        				thsurf[u,ii] := th;
    		end;

			// UPPER BORDER
			if (j=y_firstth) then
        for u := 0 to y_firstth-1 do
					thsurf[u,i+wxh] := th;

			// LOWER BORDER

 			if (j=y_lastth) then
         for u := y_lastth+1 to im.height-1 do
					thsurf[u,i+wxh] := th;

		end; // th ist nicht definiert

		// RIGHT BORDER
    for ii := x_lastth to im.width-1 do
        thsurf[j,ii] := th;

  		// RIGHT-UPPER CORNER
		if (j=y_firstth) then
     for u := 0 to y_firstth-1 do
       for ii := x_lastth to im.width-1 do
				thsurf[u,ii] := th;

		// RIGHT-LOWER CORNER
		if (j=y_lastth) then
     for u := y_lastth+1 to im.height-1 do
       for ii := x_lastth to im.width-1 do
				thsurf[u,ii] := th;
	end;


  for j := 0 to im.height-1 do
  begin
   source :=     im.ScanLine[j];
   target := result.ScanLine[j];
   for i  := 0 to im.width-1 do
   begin
    if (source^ > thsurf[j,i]) then target^ := black
                               else target^ := white;
    inc(source);
    inc(target);
   end;
  end;

  FreeMat(thSurf);
  FreeMat(map_m);
  FreeMat(map_s);
end;


end.
