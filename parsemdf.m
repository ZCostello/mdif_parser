function [output] = parsemdf(varargin)
% Script to parse ADS-generated .mdf file into a MATLAB structure

% ---- Open File ----

[fileNum,filePath,fileName,mdfFile] = importfile(varargin);

for currentFile = 1:fileNum
    % Clear cell called 'data' if it already exists in the workspace
    if exist('data')
        clear('data');
    end
    %{
    --------------------------------------------------------------------------
    1 - Import data from file
    --------------------------------------------------------------------------
    %}
    importedFile = fopen(mdfFile{currentFile}, 'rt');                         	% Open the imported file (rt = open file for reading in text mode, the variable 'importedFile' is the file)
    rawData = textscan(importedFile, '%s', 'Delimiter', '\r\n', 'CommentStyle', '!');	% Returns n x 1 cell, C, delimiter is a new line ('\r\n'), comments are marked by '!'
    fclose(importedFile);                                                      	% Close the file
    startIdx = find(~cellfun(@isempty, regexp(rawData{1}, 'BEGIN', 'match')));  % Returns an array containing the locations of all instances of 'BEGIN' in the cell C
                                                                                % Note: 3 nested functions: Find array elements of C that match the expression 'BEGIN',
                                                                                % that are also NOT empty cells (apply funtion NOT 'isempty' to each cell in cell array)
    endIdx = find(~cellfun(@isempty, regexp(rawData{1}, 'END', 'match')));      % Returns an array containing the locations of all instances of 'END' in the cell C
    
    % At this point the .mdf file has been imported into a x by 1 cell and the 'BEGIN' and 'END' locations in this cell array found (and stored in start_idx and end_idx)
    extractblock = @(n)({rawData{1}{startIdx(n):endIdx(n) - 1}});               % Create handle 'extract_block' to an anonymous function, with input argument 'n', that is the blocks of text between start_idx(n) and end_idx(n)-1 (the last line of each end_idx location is 'END' and is removed)
    cellBlocks = arrayfun(extractblock, 1:numel(startIdx), 'Uniform', false);   % Apply the function 'extract_block', with 'n' between 1 and the last array element of start_idx, return the output in 1 by x cell, with each column containing a 1 by y block of data (x blocks of data in total)
    
    % Sort cellBlocks data into each data block with the following rows:
    % Name, number of data blocks in each set,
    
    %{
    --------------------------------------------------------------------------
    2   -   Create variable 'dataBlock' containing the data set name and size (number of data points)
    --------------------------------------------------------------------------
    %}
    % For loop to determine the size of each set of data
    % Compares the first (nested) cell of each column of cellBlocks (that contains 'BEGIN' then the data set) to the current data set name
    % If the two cells equal, add 1 to the data block size variable, sizeDataBlock for that data set
    dataSetNum = 1;              % The current data set
    dataSetCurrentLoc = 1;       % Beginning location of the current data set
    dataBlock{2,dataSetNum} = 0; % Create cell array with the first row recording the name of each data set
                                 % The second row = the size of the data set
    erasedText = "BEGIN ";
    dataBlock{1,dataSetNum} = formatdatablockname(cellBlocks,dataSetCurrentLoc,erasedText);
    
    for cellNum=1:numel(cellBlocks)
        if isequal(cellBlocks{1,dataSetCurrentLoc}{1,1},cellBlocks{1,cellNum}{1,1}) % Check if the current data set of the loop and the data set of the current cell element are the same
            dataBlock{2,dataSetNum} = dataBlock{2,dataSetNum} + 1;                  % Increase the size of the current data set by 1
        else
            dataSetNum = dataSetNum + 1; % Add 1 to the current data set which, when used, effectively adds another data set
            dataBlock{2,dataSetNum} = 1;
            dataSetCurrentLoc = cellNum;
            dataBlock{1,dataSetNum} = formatdatablockname(cellBlocks,dataSetCurrentLoc,erasedText);
        end
    end
    
    nLoads=numel(cellBlocks);                                       % Number of loads, maybe you can change it with number of bias points? The load could be presented at different input drive levels but is currently counted as a separate load.
    nHarm=numel(cellBlocks{1})-3;                                   % Number of harmonic frequencies, excluding 0. Each harmonic is on one line, so the # of loads = # of lines (the -3 is to remove the 'BEGIN', '%freq' and DC lines).
    nData=numel(str2num(cell2mat(cellBlocks{1}(3:end))))/(nHarm+1); % Number of data stored for each harmonic: freq a1(real) a1(imag) b1(real) b1(imag) ect
    % First converts the harmonic frequencies (lines 3:end of 'cell_blocks') from a cell array to an ordinary array
    % Then converts this character array to a numeric array (text that represents numbers is converted into numbers)
    % The number of elements in the resulting numeric array / NHARM+1 (to include the DC) = NDATI
    
    %{
    --------------------------------------------------------------------------
    3   -   Create and format the variables measured in the variable 'data' created in the next step.
            These are different from the variables listed as VARs in the mdf file so to differentiate the two, 
            variables in the 'data' block are called 'dataVars' and the VARs are called 'variables'
    --------------------------------------------------------------------------
    %}
    currentLoc = 1; % Start with first element of cellBlocks (= first data set)
    dataVars = ''; % Initialise variable
    dataTypeVars = 1;
    dataBlockSize = numel(dataBlock(2,:));
    for cellNum=1:dataBlockSize
        indexVariables = find(~cellfun(@isempty,(regexp(cellBlocks{1,currentLoc},'%')))); % Find locations in 1st cell that start with % symbol
        dataVars{1,cellNum} = [cellBlocks{1,currentLoc}{1,indexVariables}];	% Store these in a separate variable (is currently char arrays for each line)
        dataVars{1,cellNum} = erase(dataVars{1,cellNum},"%");               % Remove percentage symbols
        dataVars{1,cellNum} = strsplit(dataVars{1,cellNum});              	% Split into individual variables, seems to produce a blank element at the start
        dataVars{1,cellNum} = dataVars{1,cellNum}(~cellfun('isempty',dataVars{1,cellNum}));   % Remove blank elements from variable
        
        % Get data type (integer, real, complex) for each variable, determines if variables will be 1 or 2 cells of data
        dataVars{1,cellNum} = regexp(dataVars{1,cellNum}, '[^()]*', 'match'); % Parse each variable, split into the name and the type (integer, real, complex) in separate elements
        
        % For loop formats 'variables': row 1 = Variable name
        %                               row 2 = Data type
        %                               row 3 = Number of cells associated with data type
        % Each data set is contained in a cell (row 3)
        for cellDataTypeLoc = 1:size(dataVars{1,cellNum},2)
            dataVars{2,cellNum}{cellDataTypeLoc} = dataVars{1,cellNum}{1,cellDataTypeLoc}{1,2};
            dataVars{1,cellNum}{cellDataTypeLoc} = dataVars{1,cellNum}{1,cellDataTypeLoc}{1,1};
            
            dataTypeVars = dataVars{2,cellNum}{cellDataTypeLoc};
            % Switch-case based on data type to determine how many cells per variable?
            % Store this beforehand and access cell or read in type dynamically?
            switch dataTypeVars
                case 'integer'
                    dataTypeVars = 1; % 1 cell
                case 'real'
                    dataTypeVars = 1;
                case 'complex'
                    dataTypeVars = 2; % 2 cells
                otherwise
                    dataTypeVars = 1; % Default
                    sprintf('Error, data type incorrect');
            end
            dataVars{3,cellNum}{cellDataTypeLoc} = dataTypeVars; % Store number of cells associated with data type in new row
            
        end
        
        for x = 1:size(dataVars{1,cellNum},2)
            % If the variable name contains a period, replace all periods with underscores then extract the name after the first underscore
            if contains(dataVars{1,cellNum}{1,x},'.')
                dataVars{1,cellNum}{1,x} = replace(dataVars{1,cellNum}{1,x},'.','_');
                dataVars{1,cellNum}(1,x) = regexp(dataVars{1,cellNum}{1,x},'(?<=\_)\w*','match'); % Extract the name after the first . and replace the second . with _ (otherwise the struct field names will throw up errors)
            end
            if contains(dataVars{1,cellNum}{1,x},'[')
                dataVars{1,cellNum}{1,x} = replace(dataVars{1,cellNum}{1,x},'.','_');
                dataVars{1,cellNum}{1,x} = extractBefore(dataVars{1,cellNum}{1,x},'[');
            end
        end
        
        currentLoc = currentLoc + dataBlock{2,cellNum}; % Move to the location (for cellBlocks) for the next data set
    end
    
    for dataSetNum = 1:dataBlockSize % Current data set, limit is the number of data sets
        currentDataLocEnd = sum([dataBlock{2,1:dataSetNum}],'native');	% Calculate the end position of the current data set (cumulatively sums up to the current data set)
        % currentDataLocEnd = currentDataLocEnd(end);     % cumsum() produces an array of values, are only interested in the last element
        currentDataLocStart = currentDataLocEnd - dataBlock{2,dataSetNum} + 1;	% Calculate the start position of the current data set
             
        varValuesStart = find(~cellfun(@isempty,(regexp(cellBlocks{currentDataLocStart},'%'))),1,'last') + 1;   % Find starting point of dataVars by:
                                                                                                                % Find last location in 1st cell of data set that starts with % symbol
                                                                                                                % Add 1 to last last location, is now the first cell element with dataVars values
        varValuesEnd = find(cellfun(@isempty,(cellBlocks{currentDataLocStart})),1);
        if isempty(varValuesEnd)
            varValuesEnd = 1;
            varValuesSize = 1;
            varValuesSizePlusEmpty = 1;
        else
            varValuesSize = varValuesEnd - varValuesStart;
            varValuesSizePlusEmpty = varValuesEnd - varValuesStart + 1; % # cells containing data for each harmonic (+ 1 as there is an empty cell at the end)
        end
        
        %{
        --------------------------------------------------------------------------
        4   -   Extract the measurements for each data point of each data set and store in the variable 'data'
        --------------------------------------------------------------------------
        %}
        if isempty(cellBlocks{currentDataLocStart}{end})
            nHarm = (size(cellBlocks{currentDataLocStart},2)-(varValuesStart-1))/(varValuesStart-1); % Calculate number of harmonics measured in this dataset (if measured)
        else
            nHarm = (numel(cellBlocks{currentDataLocStart}) - varValuesStart + 1)/ varValuesSize;
        end
        % Calculate the number of elements the variables in the current data set use (sum of elements of dataVars{3,1}, row 3 of 'dataVars')
        nData = 0;
        for currentVarLoc = 1:size(dataVars{3,dataSetNum},2)
            nData = nData + dataVars{3,dataSetNum}{currentVarLoc};
        end
        
        % Parse cellBlocks to create variable 'data' which is a 1 by x cell array, where x is the number of data points
        % Each cell element is a nHarm by nData array, where nHarm is the number of harmonics and nData is the number of variables
        % (a variable can be more than one element in size, size is retrieved from 'variables' row 3)
        % EG: v1(real)      = 1 cell
        %     v2(complex)   = 2 cells
        %     v3(integer)   = 1 cell
        % Number of elements these variables use = 1 + 2 + 1 = 4 elements, so nData is 4 in this case
        % nHarm = 10
        % So, in this example, the current data location in the data set would be an nHarm x nData array
        % If there were 13 data sets then 'data' would be a 1 x 13 cell array
        for currentDataLoc = currentDataLocStart:currentDataLocEnd	% Current cell location, limit is the size of the current data set
           currentHarm = 0;
           data{currentDataLoc} = zeros(nHarm,nData); % TODO: Fix for single data point measurements, currently nHarm calculation does not work for this scenario
           for currentVarLoc = varValuesStart:varValuesSizePlusEmpty:size(cellBlocks{currentDataLocStart},2)	% Loop to move to start of each harmonic in the data set
               dataTemp = str2num(cellBlocks{currentDataLoc}{currentVarLoc});
               for varValuesLoc = 1:(varValuesSize-1)
                   dataTemp = [dataTemp str2num(cellBlocks{currentDataLoc}{currentVarLoc+varValuesLoc})];
               end
               data{currentDataLoc}((currentHarm+1),:) = [dataTemp];
               currentHarm = currentHarm + 1;
           end
        end
    end
    
    %{
    --------------------------------------------------------------------------
    5   -   Extract VARs for each data set and store in the variable 'variables'
    --------------------------------------------------------------------------
    %}
    % varIdx = find(~cellfun(@isempty, regexp(C{1}, 'VAR+', 'match')));	% Returns an array containing the locations of all instances of 'VAR' in the cell C
                                                                        % Note: 3 nested functions: Find array elements of C that match the expression 'BEGIN',
                                                                        % that are also NOT empty cells (apply funtion NOT 'isempty' to each cell in cell array)   
    currentDataPointStart = 1;   
    currentVarLoc = 0;  
    rawDataSetCurrentPos = 1;
    rawDataSetNextPos = 1;
        
   	for dataSetNum = 1:dataBlockSize    % Current data set, limit is the number of data sets
        currentDataLocEnd = sum([dataBlock{2,1:dataSetNum}],'native');      % Calculate the end position of the current data set (cumulatively sums up to the current data set)
        % currentDataLocEnd = currentDataLocEnd(end);     % cumsum() produces an array of values, are only interested in the last element
        currentDataLocStart = currentDataLocEnd - dataBlock{2,dataSetNum} + 1;	% Calculate the start position of the current data set
        
        % Calculate the number of lines for data point (in variable 'C') in the current data set
        currentDataLocEndPrev = currentDataLocStart - 1;
        if currentDataLocEndPrev == 0
            currentDataLocSize = (endIdx(currentDataLocStart) + 1);
        else
            currentDataLocSize = (endIdx(currentDataLocStart) + 1) - (endIdx(currentDataLocEndPrev) + 1);
        end

        nVarLines = (startIdx(currentDataLocStart) - 1) - (rawDataSetCurrentPos - 1); % Finds number of VARS for the current data set        
        rawDataSetNextPos = rawDataSetNextPos + (currentDataLocSize * dataBlock{2,dataSetNum}); % Calculate position of the next data set in 'C'
        
        % Store VAR names for the current data set
        for currentVarLine = 1:nVarLines
            % rawDataSetCurrentPos:(rawDataSetCurrentPos + (nVarLines - 1))
            currentVarData = strsplit(rawData{1}{rawDataSetCurrentPos+currentVarLine-1});
            variables{1,dataSetNum}{currentVarLine} = currentVarData{2};
            if contains(variables{1,dataSetNum}{currentVarLine},'.')
                variables{1,dataSetNum}(currentVarLine) = regexp(variables{1,dataSetNum}{currentVarLine},'(?<=\.)\w*(?=\()','match'); % Extract the name between the last . and first ( otherwise the struct field names will throw up errors
            end
            if contains(variables{1,dataSetNum}{currentVarLine},'(')
                variables{1,dataSetNum}(currentVarLine) = regexp(variables{1,dataSetNum}{currentVarLine},'\w*(?=\()','match');
            end
        end
        
        % Store VAR values for the current data set
        currentDataLoc = 1;
        % Loop moving to the start of each data point in the current data set
        for currentDataPointStart = rawDataSetCurrentPos:currentDataLocSize:(rawDataSetNextPos - 1)        
            % Loop moving through each VAR of the current data point
            for currentVar = 0:(nVarLines-1)
                currentVarLoc = currentDataPointStart + currentVar;     % Line of the current VAR at the current data point
                currentVarData = strsplit(rawData{1}{currentVarLoc});   % Split string into separate elements and store in variable
                
                % Mesuro measurement data and ADS simulated data either have a space separating the data type ('real', 'imag'
                % ect) or not, so this changes the cell where the VAR value is located
                if (currentVarData{3} == '=')
                    variables{2,dataSetNum}{currentVar+1}(currentDataLoc) = str2num(currentVarData{4});
                else
                    variables{2,dataSetNum}{currentVar+1}(currentDataLoc) = str2num(currentVarData{5});
                end
            end
        currentDataLoc = currentDataLoc + 1;    
        end
        rawDataSetCurrentPos = rawDataSetNextPos;
    end

    %{
    --------------------------------------------------------------------------
    6   -   Sort dataBlock, variables, dataVars and data by size (of the data sets)
    --------------------------------------------------------------------------
    %}
    dataSetMainSize = 1;
    for dataSetNum = 1:(dataBlockSize-1)
        currentDataLocEnd = sum([dataBlock{2,1:dataSetNum}],'native');	% Calculate the end position of the current data set (cumulatively sums up to the current data set)
        % currentDataLocEnd = currentDataLocEnd(end);     % cumsum() produces an array of values, are only interested in the last element
        nextDataLocEnd = currentDataLocEnd + dataBlock{2,(dataSetNum+1)};       % Calculate the end position of the current data set (cumulatively sums up to the current data set)
        currentDataLocStart = currentDataLocEnd - dataBlock{2,dataSetNum} + 1;	% Calculate the start position of the current data set
        nextDataLocStart = currentDataLocEnd + 1;       % Calculate the start position of the current data set

        if dataBlock{2,dataSetNum} ~= dataBlock{2,(dataSetNum+1)}
            % If next data set is larger than current
            if dataBlock{2,(dataSetNum+1)} > dataBlock{2,dataSetNum}
                % Swap the larger (next) set with the smaller (current) set for dataBlock, variables, datVars and data
                
                dataBlockTemp = dataBlock(:,dataSetNum);
                dataBlock(:,dataSetNum)     = dataBlock(:,(dataSetNum+1));
                dataBlock(:,(dataSetNum+1)) = dataBlockTemp;
                
                variablesTemp = variables(:,dataSetNum);
                variables(:,dataSetNum)     = variables(:,(dataSetNum+1));
                variables(:,(dataSetNum+1)) = variablesTemp;
                
                dataVarsTemp = dataVars(:,dataSetNum);
                dataVars(:,dataSetNum)      = dataVars(:,(dataSetNum+1));
                dataVars(:,(dataSetNum+1))  = dataVarsTemp;  
                
                dataTempCurrent = data(currentDataLocStart:currentDataLocEnd);  
                dataTempNext    = data(nextDataLocStart:nextDataLocEnd);
                data(currentDataLocStart:(currentDataLocStart+numel(dataTempNext)-1))	= dataTempNext;
                data((currentDataLocStart+numel(dataTempNext)):nextDataLocEnd) = dataTempCurrent;
                
                dataSetMainSize = dataSetMainSize + 1;
            end
        end
    end
           
    % Put single data set into a struct
    % Create field names from variables and dataVars for first element
    % isequal check for variables (and size from dataBlocks?)
    % setdiff check for dataVars to only add new variables
    dataSetSizes = cell2mat(dataBlock(2,:));        % Create matrix of doubles from the dataBlock sizes
    dataSetValues = unique(dataSetSizes,'stable');	% Find unique values in dataSetSizes and store in dataSetValues
    nOutputs = numel(dataSetValues);                % Number of unique values = number of output sets    
    % Find start locations of each output set
    for x = 1:nOutputs
        outputStartLocs(x) = find(dataSetSizes(:)==dataSetValues(x),1,'first'); % Find the first location that corresponds to the size of the current output set EG 4500 measurement points
    end
    for x = 1:nOutputs
        if x == nOutputs
            outputEndLocs(x) = dataBlockSize;
        else
            outputEndLocs(x) = outputStartLocs(x+1) - 1;
        end
    end
        
    for currentOutputSet = 1:nOutputs
        % Preallocate string arrays for the field names
        fieldNamesVariables = [];
        
        % Output variables, adding the output set number before the name ('d#_' where # is the output set number)
        for currentVar = 1:numel(variables{1,outputStartLocs(currentOutputSet)}) % Locations from 1 to the end of the current output set
            fieldNamesVariables{currentVar} = strcat('d',num2str(currentOutputSet),'_',variables{1,outputStartLocs(currentOutputSet)}{currentVar});
            output.(fieldNamesVariables{currentVar}) = variables{2,outputStartLocs(currentOutputSet)}{currentVar}; % Add the VARs to the output structure
        end
            
        for dataSetNum = outputStartLocs(currentOutputSet):outputEndLocs(currentOutputSet)
            fieldNamesDataVars = []; % Wipe field names to prevent previous names carrying over into the next set
                 
            % Store the variable names of the current data set
            for currentVar = 1:numel(dataVars{1,dataSetNum})
                fieldNamesDataVars{currentVar} = strcat('d',num2str(currentOutputSet),'_',dataVars{1,dataSetNum}{1,currentVar});
            end
            
            currentDataLocEnd = sum([dataBlock{2,1:dataSetNum}],'native');          % Calculate the end position of the current data set (cumulatively sums up to the current data set)
            % currentDataLocEnd = currentDataLocEnd(end);     % cumsum() produces an array of values, are only interested in the last element
            currentDataLocStart = currentDataLocEnd - dataBlock{2,dataSetNum} + 1;	% Calculate the start position of the current data set                        
            % dataVarsSize = sum([dataVars{3,dataSetNum}{1:end}],'native');
            currentDataVarLoc = 0;
            % Loop through the variables for the current data set, storing each varible in turn then outputting to the output structure
            for currentVar = 1:numel(dataVars{1,dataSetNum})   
               	currentDataVarLoc = currentDataVarLoc + dataVars{3,dataSetNum}{currentVar};
                % Check if field name already exists (to avoid outputting repeated data)
                if ~isfield(output,fieldNamesDataVars{currentVar})
                    % If the data is complex (data is 2 cells in size) then combine into a complex number (using 1 cell)
                    % Otherwise just read the data of that cell
                    % Store the first value in 'tempData'
                    if dataVars{3,dataSetNum}{currentVar} == 2
                        tempData = [transpose(data{currentDataLocStart}(:,currentDataVarLoc-1) + j*data{currentDataLocStart}(:,currentDataVarLoc))];
                    else
                        tempData = [transpose(data{currentDataLocStart}(:,currentDataVarLoc))];
                    end
                    
                    % Add the rest of the current variable to tempData
                    for currentDataLoc = (currentDataLocStart+1):currentDataLocEnd
                        if dataVars{3,dataSetNum}{currentVar} == 2
                            tempData = [tempData; transpose(data{currentDataLoc}(:,currentDataVarLoc-1) + j*data{currentDataLoc}(:,currentDataVarLoc))];
                        else
                            tempData = [tempData; transpose(data{currentDataLoc}(:,currentDataVarLoc))];
                        end
                    end
                    output.(fieldNamesDataVars{currentVar}) = tempData; % Add the variable to the output structure
                end
            end
        end
    end
    output.nDataSets = nOutputs;
    %{
    output.dataBlock = dataBlock;
    output.variables = variables;
    output.data = data;
    output.dataVars = dataVars;
    %}
end