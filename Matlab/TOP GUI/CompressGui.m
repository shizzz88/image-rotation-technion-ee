function varargout = CompressGui(varargin)
% COMPRESSGUI M-file for CompressGui.fig
%      COMPRESSGUI, by itself, creates a new COMPRESSGUI or raises the existing
%      singleton*.
%
%      H = COMPRESSGUI returns the handle to a new COMPRESSGUI or the handle to
%      the existing singleton*.
%
%      COMPRESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMPRESSGUI.M with the given input arguments.
%
%      COMPRESSGUI('Property','Value',...) creates a new COMPRESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CompressGui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CompressGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help CompressGui

% Last Modified by GUIDE v2.5 26-Jan-2012 14:22:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CompressGui_OpeningFcn, ...
                   'gui_OutputFcn',  @CompressGui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before CompressGui is made visible.
function CompressGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CompressGui (see VARARGIN)

% Choose default command line output for CompressGui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CompressGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = CompressGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonLoadImage.
function buttonLoadImage_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% My program
%Load image:
[FileN, DirN] = uigetfile({'*.bmp; *.png; *.jpg; *.gif', 'Picture File (*.bmp, *.png, *.jpg, *.gif)'; '*.*', 'All files (*.*)'}, 'Choose Image Files', 'MultiSelect', 'on');
set(handles.listbox_files,'Value', 1); %Add files into list
set(handles.listbox_files,'String', FileN); %Add files into list
set(handles.edit_dir,'String', DirN);
%%End my program


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end




% --- Executes on button press in buttonClear.
function buttonClear_Callback(hObject, eventdata, handles)
% hObject    handle to buttonClear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla(handles.axes1); %Clear Axes 1
cla(handles.axes2); %Clear Axes 2
set(handles.edit1, 'String', ' '); %Clear File name



% --- Executes on button press in buttonCompress. --Compress button
function buttonCompress_Callback(hObject, eventdata, handles)
% hObject    handle to buttonCompress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DirN=get(handles.edit_dir,'String');
Files=get(handles.listbox_files, 'String');

if sum(class(Files(get(handles.listbox_files, 'Value')))=='char')==4 %String, and not cell
    set(handles.edit1, 'String', [DirN, Files] )
else
    set(handles.edit1, 'String', [DirN, cell2mat(Files(get(handles.listbox_files, 'Value')))] )
end
clear Files;
OriginalImg=imread(get(handles.edit1,'String'));
ImgSize = [size(OriginalImg,2) size(OriginalImg,1)];

%Display image size:
sbytesorig=whos('OriginalImg');
set(handles.text_decmp_byte, 'String', [num2str(sbytesorig.bytes) ' Bytes']);

%Show image:
axes(handles.axes1);
imshow(OriginalImg);
colormap(gray);

%Compress image
tic;
CmpImg = compress_img(get(handles.edit1,'String'),1);%cmp ratio RAN URI
set(handles.text_cmp_img, 'String', [num2str(toc) ' Seconds']);
sbytescmp=whos('CmpImg'); %Compressed image size
set(handles.text_cmp_byte, 'String', [num2str(sbytescmp.bytes) ' Bytes']);

%Compression Ratio:
set(handles.text_ratio, 'String', ['Compression Ratio: 1 : ' num2str(ceil(sbytesorig.bytes/sbytescmp.bytes))]);

%Deallocate whos
clear('sbytesorig', 'sbytescmp');

%Decompress Image
tic;
DecompImg = decompress_img(CmpImg,ImgSize);
set(handles.text_dec_img, 'String', [num2str(toc) ' Seconds']);

%Show decompressed image
axes(handles.axes2);
imshow(DecompImg);

% --- Executes on selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_files


% --- Executes during object creation, after setting all properties.
function listbox_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dir_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dir as text
%        str2double(get(hObject,'String')) returns contents of edit_dir as a double


% --- Executes during object creation, after setting all properties.
function edit_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sof_edit_Callback(hObject, eventdata, handles)
% hObject    handle to sof_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sof_edit as text
%        str2double(get(hObject,'String')) returns contents of sof_edit as a double


% --- Executes during object creation, after setting all properties.
function sof_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sof_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eof_edit_Callback(hObject, eventdata, handles)
% hObject    handle to eof_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eof_edit as text
%        str2double(get(hObject,'String')) returns contents of eof_edit as a double


% --- Executes during object creation, after setting all properties.
function eof_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eof_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function type_edit_Callback(hObject, eventdata, handles)
% hObject    handle to type_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of type_edit as text
%        str2double(get(hObject,'String')) returns contents of type_edit as a double


% --- Executes during object creation, after setting all properties.
function type_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function addr_msb_edit_Callback(hObject, eventdata, handles)
% hObject    handle to addr_msb_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of addr_msb_edit as text
%        str2double(get(hObject,'String')) returns contents of addr_msb_edit as a double


% --- Executes during object creation, after setting all properties.
function addr_msb_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to addr_msb_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function addr_mid_edit_Callback(hObject, eventdata, handles)
% hObject    handle to addr_mid_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of addr_mid_edit as text
%        str2double(get(hObject,'String')) returns contents of addr_mid_edit as a double


% --- Executes during object creation, after setting all properties.
function addr_mid_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to addr_mid_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function addr_lsb_edit_Callback(hObject, eventdata, handles)
% hObject    handle to addr_lsb_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of addr_lsb_edit as text
%        str2double(get(hObject,'String')) returns contents of addr_lsb_edit as a double


% --- Executes during object creation, after setting all properties.
function addr_lsb_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to addr_lsb_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function crc_force_val_edit_Callback(hObject, eventdata, handles)
% hObject    handle to crc_force_val_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of crc_force_val_edit as text
%        str2double(get(hObject,'String')) returns contents of crc_force_val_edit as a double


% --- Executes during object creation, after setting all properties.
function crc_force_val_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to crc_force_val_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in crc_checkbox.
function crc_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to crc_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of crc_checkbox




% --- Executes on button press in pushbutton_tx_data. -- TRANSMIT IMAGE button
function pushbutton_tx_data_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_tx_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc;

%% Get Image
DirN=get(handles.edit_dir,'String');
Files=get(handles.listbox_files, 'String');

if sum(class(Files(get(handles.listbox_files, 'Value')))=='char')==4 %String, and not cell
    set(handles.edit1, 'String', [DirN, Files] )
else
    set(handles.edit1, 'String', [DirN, cell2mat(Files(get(handles.listbox_files, 'Value')))] )
end
clear Files;
OriginalImg=imread(get(handles.edit1,'String')); %read image
% % %test image
% a=[10 20 30 40 50]
% b=[ 0 0 0 0 0]
% c=[a b]
% for i=1:64
%     for j=1:10
%     row(j+10*(i-1))=c(j);
%     end
% end
% for i=1:480
%     Imagetest(i,:)=row;
% end;
% OriginalImg=uint8(Imagetest);
% %end of test image
%Display image size:
sbytesorig=whos('OriginalImg');
set(handles.text_decmp_byte, 'String', [num2str(sbytesorig.bytes) ' Bytes']);

%Show image:
axes(handles.axes1);
imshow((OriginalImg));
colormap(gray);

%Compress image
tic;

%display rotated image
rotangle=str2double(get(handles.RotAngle,'String'));
zoom=str2double(get(handles.ZoomFactor,'String'));
xstart=str2double(get(handles.Xstart,'String'));
ystart=str2double(get(handles.Ystart,'String'));
rotimg=Imrotate5(OriginalImg,rotangle,zoom,xstart,ystart,600,800);
axes(handles.axes2);
imshow(rotimg);
colormap(gray);

% CmpImg = compress_img(get(handles.edit1,'String'),1);%cmp ratio RAN URI
CmpImg = OriginalImg';% don't compress image
set(handles.text_cmp_img, 'String', [num2str(toc) ' Seconds']);
sbytescmp=whos('CmpImg'); %Compressed image size
set(handles.text_cmp_byte, 'String', [num2str(sbytescmp.bytes) ' Bytes']);

%Compression Ratio:
% set(handles.text_ratio, 'String', ['Compression Ratio: 1 : ' num2str(ceil(sbytesorig.bytes/sbytescmp.bytes))]);

%Deallocate whos
clear('sbytesorig', 'sbytescmp');
%END IMAGE COMPRESION

%% Transmit Data
% Prepare serial port
% serial_port= instrfind('Port','COM1'); %Close any COM1 serial connection
% if numel(serial_port) ~= 0
%     fclose(serial_port);
% end
% serial_port = serial('COM1','BaudRate', 115200,'Parity', 'none', 'DataBits', 8, 'StopBits', 1,'Timeout', 2, 'OutputBufferSize', 1024 + 7, 'InputBufferSize', 1024 + 7);
% fopen(serial_port); %Open serial port
sof = hex2dec(get(handles.sof_edit, 'String'));
eof = hex2dec(get(handles.eof_edit, 'String'));
fid = fopen('h:\uart_tx_1.txt', 'w');  % open the file with write permission

%% write Angle to register file
    fprintf(fid, '#Chunk\r\n'); 
    fprintf(fid, '#SOF\r\n'); %write #SOF 
    fprintf(fid, '%02X\r\n',sof ); %write SOF value
    fprintf(fid, '#Type\r\n'); %write #Type
    fprintf(fid, '%02X\r\n',128 ); %write Type value - type=0x80 -> write to register 
    fprintf(fid, '#Address\r\n'); %write #Adress
    fprintf(fid, '%02X\r\n',12 ); %write #Adress Value
    fprintf(fid, '#Length\r\n'); %write #Length
    fprintf(fid, '%02X\t%02X\r\n',00,01 ); %write lenghth of angle - 2 bytes - we write is length-1 by def. length of angle is 2 bytes.
    fprintf(fid, '#Payload\r\n'); %write #Payload
    fprintf(fid, '%02X\r\n',floor( rotangle/256), mod( rotangle, 256) ); %write angle value to file in 2 bytes hex
    fprintf(fid, '#CRC\r\n'); %write color repetitions to file
        crc = (mod((floor(rotangle/256))+(mod(rotangle, 256)) + 128 + 1 + 12 , 256)); % calcultae crc= (angle + type +length + address) mod 256
    fprintf(fid, '%02X\r\n',crc ); %write color repetitions to file
    fprintf(fid, '#EOF\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',eof ); %write color repetitions to file 
%% write X_start to register file
    fprintf(fid, '#Chunk\r\n'); 
    fprintf(fid, '#SOF\r\n'); %write #SOF 
    fprintf(fid, '%02X\r\n',sof ); %write SOF value
    fprintf(fid, '#Type\r\n'); %write #Type
    fprintf(fid, '%02X\r\n',128 ); %write Type value - type=0x80 -> write to register 
    fprintf(fid, '#Address\r\n'); %write #Adress
    fprintf(fid, '%02X\r\n',14 ); %write #Adress Value
    fprintf(fid, '#Length\r\n'); %write #Length
    fprintf(fid, '%02X\t%02X\r\n',00,01 ); %write lenghth of angle - 2 bytes - we write is length-1 by def. length of angle is 2 bytes.
    fprintf(fid, '#Payload\r\n'); %write #Payload
    fprintf(fid, '%02X\r\n',floor( xstart/256), mod( xstart, 256) ); %write xstart value to file in 2 bytes hex
    fprintf(fid, '#CRC\r\n'); %write color repetitions to file
        crc = (mod((floor(xstart/256))+(mod(xstart, 256)) + 128 + 1 + 14 , 256)); % calcultae crc= (xstart + type +length + address) mod 256
    fprintf(fid, '%02X\r\n',crc ); %write color repetitions to file
    fprintf(fid, '#EOF\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',eof ); %write color repetitions to file

%% write Y_start to register file
    fprintf(fid, '#Chunk\r\n'); 
    fprintf(fid, '#SOF\r\n'); %write #SOF 
    fprintf(fid, '%02X\r\n',sof ); %write SOF value
    fprintf(fid, '#Type\r\n'); %write #Type
    fprintf(fid, '%02X\r\n',128 ); %write Type value - type=0x80 -> write to register 
    fprintf(fid, '#Address\r\n'); %write #Adress
    fprintf(fid, '%02X\r\n',16 ); %write #Adress Value
    fprintf(fid, '#Length\r\n'); %write #Length
    fprintf(fid, '%02X\t%02X\r\n',00,01 ); %write lenghth of angle - 2 bytes - we write is length-1 by def. length of angle is 2 bytes.
    fprintf(fid, '#Payload\r\n'); %write #Payload
    fprintf(fid, '%02X\r\n',floor( ystart/256), mod( ystart, 256) ); %write angle value to file in 2 bytes hex
    fprintf(fid, '#CRC\r\n'); %write color repetitions to file
        crc = (mod((floor(ystart/256))+(mod(ystart, 256)) + 128 + 1 + 16 , 256)); % calcultae crc= (ystart + type +length + address) mod 256
    fprintf(fid, '%02X\r\n',crc ); %write color repetitions to file
    fprintf(fid, '#EOF\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',eof ); %write color repetitions to file

 %% write zoom to register file
    fprintf(fid, '#Chunk\r\n'); 
    fprintf(fid, '#SOF\r\n'); %write #SOF 
    fprintf(fid, '%02X\r\n',sof ); %write SOF value
    fprintf(fid, '#Type\r\n'); %write #Type
    fprintf(fid, '%02X\r\n',128 ); %write Type value - type=0x80 -> write to register 
    fprintf(fid, '#Address\r\n'); %write #Adress
    fprintf(fid, '%02X\r\n',18 ); %write #Adress Value
    fprintf(fid, '#Length\r\n'); %write #Length
    fprintf(fid, '%02X\t%02X\r\n',00,01 ); %write lenghth of angle - 2 bytes - we write is length-1 by def. length of angle is 2 bytes.
    fprintf(fid, '#Payload\r\n'); %write #Payload
    fprintf(fid, '%02X\r\n',floor( zoom/256), mod( zoom, 256) ); %write angle value to file in 2 bytes hex
    fprintf(fid, '#CRC\r\n'); %write color repetitions to file
        crc = (mod((floor(zoom/256))+(mod(zoom, 256)) + 128 + 1 + 18 , 256)); % calcultae crc= (\oom + type +length + address) mod 256
    fprintf(fid, '%02X\r\n',crc ); %write color repetitions to file
    fprintf(fid, '#EOF\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',eof ); %write color repetitions to file







% Prepare data
sof = hex2dec(get(handles.sof_edit, 'String'));
eof = hex2dec(get(handles.eof_edit, 'String'));
type = 4*get(handles.checkbox_synthetic, 'Value');
addr = 0;
total_data_len = numel (CmpImg);
cmp_data_pos = 1; %position in compressed image
% Transmit data
while (total_data_len > 0)
    len = min([1024, total_data_len]) - 1; %Maximum of 1024 bytes = 1KBytes to transmit 
    total_data_len = total_data_len - len - 1;  %Decrease trasmitted data
    payload = CmpImg (cmp_data_pos : cmp_data_pos + len); %Prepare payload to transmit
    cmp_data_pos = cmp_data_pos + len + 1; %Increment position in compressed image
    if get(handles.crc_checkbox, 'Value') == 1 
        crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
    else
        crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
    end
    fprintf(fid, '#Chunk\r\n'); 
    dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
    fprintf(fid, '#SOF\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',sof ); %write color repetitions to file
    fprintf(fid, '#Type\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',type ); %write color repetitions to file
    fprintf(fid, '#Address\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',addr ); %write color repetitions to file
    fprintf(fid, '#Length\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\t%02X\r\n', floor(len/256), mod(len, 256) ); %write color repetitions to file
    fprintf(fid, '#Payload\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',payload ); %write color repetitions to file
    fprintf(fid, '#CRC\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',crc ); %write color repetitions to file
    fprintf(fid, '#EOF\r\n'); %write color repetitions to file
    fprintf(fid, '%02X\r\n',eof ); %write color repetitions to file
    %fwrite(serial_port, dataToSend);
end

%Prepare summary chunk
clear payload;
type = type + 2;
data =  numel (CmpImg);
counter = ceil (log(data)/log(256));
len = counter - 1;
while (counter > 0)
    payload(counter) = mod (data, 256);
    data = floor (data / 256);
    counter = counter - 1;
end
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
fprintf(fid, '#Summay\r\n'); %Write summary chunk
dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
fprintf(fid, '%02X\r\n',dataToSend ); %write summary chunk
% fwrite(serial_port, dataToSend);
%% End of transaction
uiwait(msgbox('Image Transmission is DONE!!!','Status'));
fclose (fid);
fclose(serial_port);

function edit_dbg_addr_msb_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dbg_addr_msb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dbg_addr_msb as text
%        str2double(get(hObject,'String')) returns contents of edit_dbg_addr_msb as a double


% --- Executes during object creation, after setting all properties.
function edit_dbg_addr_msb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dbg_addr_msb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_left_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_left_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_left_frame as text
%        str2double(get(hObject,'String')) returns contents of edit_left_frame as a double


% --- Executes during object creation, after setting all properties.
function edit_left_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_left_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_right_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_right_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_right_frame as text
%        str2double(get(hObject,'String')) returns contents of edit_right_frame as a double


% --- Executes during object creation, after setting all properties.
function edit_right_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_right_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_upper_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_upper_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_upper_frame as text
%        str2double(get(hObject,'String')) returns contents of edit_upper_frame as a double


% --- Executes during object creation, after setting all properties.
function edit_upper_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_upper_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_lower_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lower_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lower_frame as text
%        str2double(get(hObject,'String')) returns contents of edit_lower_frame as a double


% --- Executes during object creation, after setting all properties.
function edit_lower_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lower_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_synthetic.
function checkbox_synthetic_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_synthetic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_synthetic


% --- Executes on button press in checkbox_debug.
function checkbox_debug_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_debug


% --- Executes on button press in pushbutton_update_regs.
function pushbutton_update_regs_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_update_regs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc;
%% Transmit Data
% Prepare serial port
% serial_port= instrfind('Port','COM1'); %Close any COM1 serial connection
% if numel(serial_port) ~= 0
%     fclose(serial_port);
% end
% serial_port = serial('COM1','BaudRate', 115200,'Parity', 'none', 'DataBits', 8, 'StopBits', 1,'Timeout', 2, 'OutputBufferSize', 1024 + 7, 'InputBufferSize', 1024 + 7);
% fopen(serial_port); %Open serial port
%fid = fopen('uart_tx_1.txt', 'w');  % open the file with write permission

% Prepare data
sof = hex2dec(get(handles.sof_edit, 'String'));
eof = hex2dec(get(handles.eof_edit, 'String'));
type = 4*get(handles.checkbox_synthetic, 'Value') + 128; %128 for Registers transmission
% Transmit Debug Register data
clear payload;
payload = zeros(1,3);
addr = 2;
len = 2; %2 = 3 address data
payload(1) = hex2dec(get(handles.edit_dbg_addr_msb, 'String')) ; %Prepare payload to transmit
payload(2) = hex2dec(get(handles.edit_dbg_addr_mid, 'String')) ; %Prepare payload to transmit
payload(3) = hex2dec(get(handles.edit_dbg_addr_lsb, 'String')) ; %Prepare payload to transmit
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
%fprintf(fid, '#Debug Register\r\n'); 
dataToSend=[sof     type    addr   0      len       payload    crc     eof];
%fprintf(fid, '%02X\r\n',dataToSend ); %write color repetitions to file
% fwrite(serial_port, dataToSend);

% Transmit Frames Register data
clear payload;
addr = 5;
len = 0; %0 = 1 address data
payload = str2num(get(handles.edit_left_frame, 'String')) ; %Prepare payload to transmit
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
%fprintf(fid, '#Left Frame Register\r\n'); 
dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
%fprintf(fid, '%02X\r\n',dataToSend ); %write color repetitions to file
fwrite(serial_port, dataToSend);

addr = 6;
len = 0; %0 = 1 address data
payload = str2num(get(handles.edit_right_frame, 'String')) ; %Prepare payload to transmit
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
%fprintf(fid, '#Right Frame Register\r\n'); 
dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
%fprintf(fid, '%02X\r\n',dataToSend ); %write color repetitions to file
% fwrite(serial_port, dataToSend);

addr = 7;
len = 0; %0 = 1 address data
payload = str2num(get(handles.edit_upper_frame, 'String')) ; %Prepare payload to transmit
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
%fprintf(fid, '#Upper Frame Register\r\n'); 
dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
%fprintf(fid, '%02X\r\n',dataToSend ); %write color repetitions to file
% fwrite(serial_port, dataToSend);

addr = 8;
len = 0; %0 = 1 address data
payload = str2num(get(handles.edit_lower_frame, 'String')) ; %Prepare payload to transmit
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
%fprintf(fid, '#Lower Frame Register\r\n'); 
dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
%fprintf(fid, '%02X\r\n',dataToSend ); %write color repetitions to file
% fwrite(serial_port, dataToSend);

%% End of transaction
uiwait(msgbox('Registers Transmission is DONE!!!','Status'));
%fclose (fid);
%fclose(serial_port);




function edit_dbg_addr_mid_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dbg_addr_mid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dbg_addr_mid as text
%        str2double(get(hObject,'String')) returns contents of edit_dbg_addr_mid as a double


% --- Executes during object creation, after setting all properties.
function edit_dbg_addr_mid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dbg_addr_mid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dbg_addr_lsb_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dbg_addr_lsb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dbg_addr_lsb as text
%        str2double(get(hObject,'String')) returns contents of edit_dbg_addr_lsb as a double


% --- Executes during object creation, after setting all properties.
function edit_dbg_addr_lsb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dbg_addr_lsb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% TX Debug

% Executes on button press in pushbutton_tx_dbg.
function pushbutton_tx_dbg_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_tx_dbg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Prepare serial port
clc;
% serial_port= instrfind('Port','COM1'); %Close any COM1 serial connection
% if numel(serial_port) ~= 0
%     fclose(serial_port);
% end
%serial_port = serial('COM1','BaudRate', 115200,'Parity', 'none', 'DataBits', 8, 'StopBits', 1,'Timeout', 2, 'OutputBufferSize', 1024 + 7, 'InputBufferSize', 1024 + 7);
%fopen(serial_port); %Open serial port
%fid = fopen('uart_tx_1.txt', 'w');  % open the file with write permission

% Prepare data
sof = hex2dec(get(handles.sof_edit, 'String'));
eof = hex2dec(get(handles.eof_edit, 'String'));
type = 1 + 4*get(handles.checkbox_synthetic, 'Value');
addr = 0;
total_data_len =str2num(get(handles.edit_dbg_elements, 'String'));
len = total_data_len-1;
% Transmit data
payload=zeros(1, min([1024, total_data_len]));
%Prepare payload
for idx=1:min([1024, total_data_len])
    len = min([1024, total_data_len]) - 1; %Maximum of 1024 bytes = 1KBytes to transmit 
    payload(idx) = mod(idx-1,256); %Prepare payload to transmit
end
if get(handles.crc_checkbox, 'Value') == 1 
    crc = mod(sum(payload) + type + floor(len/256) + mod(len, 256) + addr, 256);
else
    crc = hex2dec(get(handles.crc_force_val_edit, 'String')) ;
end
%fprintf(fid, '#Debug Chunk\r\n'); 
dataToSend=[sof     type    addr   floor(len/256)      mod(len, 256)       payload    crc     eof];
%fprintf(fid, '%02X\r\n',dataToSend ); %write color repetitions to file
%fwrite(serial_port, dataToSend);
%% End of transaction
uiwait(msgbox('Debug Transmission is DONE!!!','Status'));
%fclose (fid);
%fclose(serial_port);

function edit_dbg_elements_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dbg_elements (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dbg_elements as text
%        str2double(get(hObject,'String')) returns contents of edit_dbg_elements as a double


% --- Executes during object creation, after setting all properties.
function edit_dbg_elements_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dbg_elements (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes_background_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_background
backgroundImage = importdata('background.jpg');
image(backgroundImage);



% --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2



function RotAngle_Callback(hObject, eventdata, handles)
% hObject    handle to RotAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RotAngle as text
%        str2double(get(hObject,'String')) returns contents of RotAngle as a double

% --- Executes during object creation, after setting all properties.
function RotAngle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RotAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ZoomFactor_Callback(hObject, eventdata, handles)
% hObject    handle to ZoomFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZoomFactor as text
%        str2double(get(hObject,'String')) returns contents of ZoomFactor as a double
% Read user input parameters

% --- Executes during object creation, after setting all properties.
function ZoomFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ZoomFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Xstart_Callback(hObject, eventdata, handles)
% hObject    handle to Xstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Xstart as text
%        str2double(get(hObject,'String')) returns contents of Xstart as a double
% Read user input parameters

% --- Executes during object creation, after setting all properties.
function Xstart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Xstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Ystart_Callback(hObject, eventdata, handles)
% hObject    handle to Ystart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Ystart as text
%        str2double(get(hObject,'String')) returns contents of Ystart as a double
% Read user input parameters

% --- Executes during object creation, after setting all properties.
function Ystart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ystart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over crc_checkbox.
function crc_checkbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to crc_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function background_CreateFcn(hObject, eventdata, handles)
% hObject    handle to background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate background
axes(hObject)
imshow('background.jpg');
