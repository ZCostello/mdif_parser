function [fileNum,filePath,fileName,outputFile] = importfile(varargin)
% ---- Imports files to function ----
% If no input arguments are given, IE importfile(), then a UI will open and the files can be selected
% Otherwise the files can be specified, EG importfile("LMBA_41228.mat")
%
% The output arguments are:
% fileNum = Number of input files
% fileName = The name of each file (without its extension), the same as the name of the input files unless changed
% filePath = The path of the input files (if not specified then the current directory will be used)
% outputFile = The output file, this is the variable to use in the rest of the script
%
% If multiple files are used then the outputs will be arrays, EG outputFile(fileNum) will be the last file in the array

if  isempty(varargin{1})	% If no file/path included, open UI
    [fileName,filePath] = uigetfile({'*.*',  'All Files (*.*)'},'.','MultiSelect', 'on');
    
    % If only one file is selected, the filetype is a char array. If > 1 it is a cell array. To make sure the mdfFile variable works 
    % for one file, convert from char array to a string
    if ~iscell(fileName)
        fileName = convertCharsToStrings(fileName);
    end
    
    fileNum = numel(fileName);
    
    filePath = convertCharsToStrings(filePath);
    for currentFile = 1:fileNum
        outputFile{currentFile}=fileName{currentFile};
        fileName{currentFile} = convertStringsToChars(fileName{currentFile}); % Convert fileName from a string to a char array (for later when
                                                                              % .mat files are saved
        fileName{currentFile} = extractBefore(fileName{currentFile},'.');
        filePath{currentFile} = filePath{1};
    end
        
else	% Otherwise create variable called 'mdfFile' which is the imported file
    fileNum = numel(varargin);
    for currentFile = 1:fileNum
        % Check for multiple files
        [filePath{currentFile},fileName{currentFile},ext{currentFile}] = fileparts(varargin{1,1}{currentFile});
        fileName{currentFile} = convertStringsToChars(fileName{currentFile});   % Convert fileName from a string to a char array (for later when
                                                                                % .mat files are saved        
        outputFile{currentFile}=strcat(fileName{currentFile},ext{currentFile}); % Create 'mdfFile' variable by concatenating fileName and the file extension
        
        % If file path is not specified, change file path to the current directory
        if (filePath{currentFile} == "")
            filePath{currentFile} = pwd;
            filePath{currentFile} = strcat(filePath{currentFile},'\');
        end
    end
end