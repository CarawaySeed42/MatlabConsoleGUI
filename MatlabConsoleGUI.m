function varargout = MatlabConsoleGUI(varargin)
% MatlabConsoleGUI MATLAB code for MatlabConsoleGUI.fig
%      MatlabConsoleGUI, by itself, creates a new MatlabConsoleGUI or raises the existing
%      singleton*.
%
%      H = MatlabConsoleGUI returns the handle to a new MatlabConsoleGUI or the handle to
%      the existing singleton*.
%
%      MatlabConsoleGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MatlabConsoleGUI.M with the given input arguments.
%
%      MatlabConsoleGUI('Property','Value',...) creates a new MatlabConsoleGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MatlabConsoleGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MatlabConsoleGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MatlabConsoleGUI

% Last Modified by GUIDE v2.5 22-May-2025 23:34:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MatlabConsoleGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MatlabConsoleGUI_OutputFcn, ...
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


% --- Executes just before MatlabConsoleGUI is made visible.
function MatlabConsoleGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MatlabConsoleGUI (see VARARGIN)

% Choose default command line output for MatlabConsoleGUI
handles.output = hObject;

set(handles.text_history, 'FontUnits', 'normalized');

% Set up the workspace table
set(handles.uitable_workspace, 'ColumnName', {'Name', 'Value', 'Type'});
set(handles.uitable_workspace, 'RowName', {});
refreshVariableList(handles);

% Se up statement cache
handles.code_cache_size = 30;
handles.code_cache = cellfun(@(x) char(x), cell(handles.code_cache_size, 1), 'UniformOutput', false);
handles.code_cache_index = 1;
handles.code_cache_start = 1;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MatlabConsoleGUI wait for user response (see UIRESUME)
% uiwait(handles.MatlabConsoleGUI);


% --- Outputs from this function are returned to the command line.
function varargout = MatlabConsoleGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close MatlabConsoleGUI.
function MatlabConsoleGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to MatlabConsoleGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Delete created variables
evalin('base', 'clearvars -except app hObject eventdata handles')

% Hint: delete(hObject) closes the figure
delete(hObject);


function index = incrementCodeCacheIndex(index, increment, handles)
index = index + increment;
index = wrapCodeCacheIndex(index, handles);


function index = wrapCodeCacheIndex(index, handles)
if index > handles.code_cache_size
    index = 1;
elseif index < 1
    index = handles.code_cache_size;
end


function edit_console_Callback(hObject, eventdata, handles)
% hObject    handle to edit_console (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_console as text
%        str2double(get(hObject,'String')) returns contents of edit_console as a double


% --- Executes during object creation, after setting all properties.
function edit_console_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_console (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in pb_run.
function pb_run_Callback(hObject, eventdata, handles)
% Evaluate command in edit_console

% Get the user input from the GUI text box
drawnow;
cmd = get(handles.edit_console, 'String');

% Insert command into cache
handles = addCommandToCache(handles, cmd);
guidata(hObject, handles);

% Escape single quotes
cmd = strrep(cmd, '''', '''''');

% Clear the input field
set(handles.edit_console, 'String', '');

% clc should clear the window
if strcmp(strtrim(cmd), 'clc')
    set(handles.text_history, 'String', {});
end

% Evaluate the command in the base workspace and capture any printed output
try
    output = evalc(['evalin(''base'', ''' cmd ''');']);
catch ME
    output = getReport(ME, 'extended', 'hyperlinks', 'off');
end

% Append the output to the output display area
prev_output = get(handles.text_history, 'String');
if ischar(prev_output)
    prev_output = {prev_output};
end

% Combine previous output with new output
if ~(strcmp(get(handles.ScrollUp, 'Checked'), 'on'))
    
    new_output = [prev_output; {['>> ' cmd]}; cellstr(output);{''}];
    
    % Add to text history and retrieve it again to get correct formating
    set(handles.text_history, 'String', new_output);
    new_output = get(handles.text_history, 'String');
    
    % Remove the excess lines from the beginning
    fontSize = get(handles.text_history, 'FontSize');
    lineHeight = fontSize * 1.25;
    maxLines = floor(1 / lineHeight);
    
    if numel(new_output) > maxLines
        new_output = new_output(end-maxLines+1:end);
    end
    
else
    new_output = [{['>> ' cmd]}; cellstr(output);{''};prev_output];
end

% Update the display box
set(handles.text_history, 'String', new_output);

refreshVariableList(handles);
guidata(hObject, handles);
drawnow;


function handles = addCommandToCache(handles, cmd)
% Insert command into command cache but only if it is not cached already
insert = true;
try %#ok
   insert = ~ismember(cmd, handles.code_cache);
end

if ~insert
    return;
end

handles.code_cache_start = incrementCodeCacheIndex(handles.code_cache_start, +1, handles);
handles.code_cache_index = handles.code_cache_start + 1; 
handles.code_cache{handles.code_cache_start} = cmd;


% --- Executes on key press with focus on edit_console and none of its controls.
function edit_console_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_console (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if isprop(eventdata, 'Key') && strcmp(eventdata.Key, 'return')
    pb_run_Callback(hObject, eventdata, handles);
    return;
    
elseif isprop(eventdata, 'Key') && strcmp(eventdata.Key, 'uparrow')
    handles = setNextCommandFromCache(handles, -1);
    
elseif isprop(eventdata, 'Key') && strcmp(eventdata.Key, 'downarrow')
    handles = setNextCommandFromCache(handles, +1);
else
    
   handles.code_cache_index = handles.code_cache_start + 1; 
end

guidata(hObject, handles);

% Pause execution shortly to give Matlab time to catch up on the GUI
pause(0.05);
drawnow;
pause(0.05);


function handles = setNextCommandFromCache(handles, direction)
% Set next cache entry to edit_console. This can be buggy and skip entries, 
% because sometimes Matlab refuses to update the text box. Probably because
% this function gets evaluated before Matlab does its own stuff

% Go to next filled cache entry
for i = handles.code_cache_index:direction:(handles.code_cache_index-direction+direction*handles.code_cache_size)
    handles.code_cache_index = incrementCodeCacheIndex(handles.code_cache_index, direction, handles);
    
    if ~isempty(handles.code_cache{handles.code_cache_index})
        break;
    end
end

set(handles.edit_console, 'String', handles.code_cache{handles.code_cache_index});


function refreshVariableList(handles)
% Get info about variables in the base workspace
vars = evalin('base', 'whos');

% Prepare table data
data = cell(length(vars), 3);  % {Name, Preview, Type}

for i = 1:length(vars)
    varName = vars(i).name;
    varClass = vars(i).class;
    varSize = vars(i).size;
    
    % Get the variable itself from the base workspace
    try
        val = evalin('base', varName);
    catch
        val = [];
    end
    
    % Decide on the preview
    preview = getPreview(val, varSize, varClass);
    
    % Fill table row
    data{i, 1} = varName;
    data{i, 2} = preview;
    data{i, 3} = varClass;
end

% Update table data
set(handles.uitable_workspace, 'Data', data);


function preview = getPreview(val, varSize, varClass)
% Get a preview of the value if it makes sense to preview it
% Scalars and char row arrays are always shown. Row arrays of numerical
% values are shown if small enough
try
    if isnumeric(val) && isscalar(val)
        preview = num2str(val);
    elseif ischar(val) && isrow(val)
        preview = val;
    elseif isstring(val) && isscalar(val)
        preview = char(val);
    elseif islogical(val) && isscalar(val)
        preview = mat2str(val);
    elseif isnumeric(val) && isrow(val) && length(val) < 5
        preview = mat2str(val);
    else
        % Fallback: show size and type
        preview = sprintf('%dx%d %s', varSize(1), varSize(2), varClass);
    end
catch
    % Catch-all fallback
    preview = sprintf('%dx%d %s', varSize(1), varSize(2), varClass);
end


% --------------------------------------------------------------------
function MenuSettings_Callback(hObject, eventdata, handles)
% hObject    handle to MenuSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ScrollUp_Callback(hObject, eventdata, handles)
% hObject    handle to ScrollUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(hObject.Checked, 'on')
    set(hObject, 'Checked', 'off');
else
   set(hObject, 'Checked', 'on'); 
end
