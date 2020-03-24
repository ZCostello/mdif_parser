function [output] = formatstruct(inputDrive,vgs,vds,v1,v2,i1,i2,varargin)
% ---- Format the structure generated by parsemdf() into a nonlinear struct, sorted by a user-specified variable ----
z0 = 50;

[fileNum,filePath,fileName,inputFile] = importfile(varargin); % Import files into function

for currentFile = 1:fileNum
    inputFile = load(inputFile{currentFile});
    fieldNames = fieldnames(inputFile.(fileName{1})); % Find the field names of the current input struct
    % inputFile.(fileName{1}).d1_f0_drive;
    
    % Get name of inputDrive after the d1_ and locate the inputDrive field for each data set
    inputDriveShort = extractAfter(inputDrive,'_');
    locSortFields = contains(fieldNames,inputDriveShort);
    sortFields = fieldNames(locSortFields);
    
    for nCurrentDataSet = 1:inputFile.(fileName{1}).nDataSets
        startDrive = inputFile.(fileName{1}).(sortFields{nCurrentDataSet})(1);	% Get start drive
        locStartDrive = inputFile.(fileName{1}).(sortFields{nCurrentDataSet}) == startDrive;	% Create logical index of locations of startDrive
        if nnz(locStartDrive(1,:)) == 1
            nDrives = size(locStartDrive,2);
        else
            nDrives = size(inputFile.(fileName{1}).(sortFields{nCurrentDataSet}),2)/nnz(locStartDrive);  % Divide number of measurements by number of occurance of startDrive == number of input drives    
        end
        nLoadsDiv = size(inputFile.(fileName{1}).(sortFields{nCurrentDataSet}),2)/nnz(locStartDrive);
        nLoads = size(inputFile.(fileName{1}).(sortFields{nCurrentDataSet}),2)/nLoadsDiv;	% Number of loads
        nMeas = size(inputFile.(fileName{1}).(sortFields{nCurrentDataSet}),2);	% Number of measurements (different from nLoads if multiple measurements at one Z load, such as power sweep)   
        
        % For each input drive add each field to the output structure (SORTED BY INPUT DRIVE)
        for nCurrentDrive = 1:nDrives
            currentDrive = inputFile.(fileName{1}).(sortFields{nCurrentDataSet})(nCurrentDrive);
            locCurrentDrive = inputFile.(fileName{1}).(sortFields{nCurrentDataSet}) == currentDrive;
            % Populate inputDrive field based on the first data set
            if nCurrentDataSet == 1
                output(nCurrentDrive).f0_drive = inputFile.(fileName{1}).(sortFields{nCurrentDataSet})(locCurrentDrive);
                output(nCurrentDrive).inputDrive = output(nCurrentDrive).f0_drive(1);
            end
            
            % Add fields of the current data set to the output structure
            for nCurrentName = 1:size(fieldNames,1)
                if isequal(nMeas,size(inputFile.(fileName{1}).(fieldNames{nCurrentName}),1))
                    output(nCurrentDrive).(fieldNames{nCurrentName}) = inputFile.(fileName{1}).(fieldNames{nCurrentName})(locCurrentDrive,:);
                elseif isequal(nMeas,size(inputFile.(fileName{1}).(fieldNames{nCurrentName}),2))
                    output(nCurrentDrive).(fieldNames{nCurrentName}) = inputFile.(fileName{1}).(fieldNames{nCurrentName})(locCurrentDrive);
                end
            end
            
            % Calculate variables (assuming first data set contains v1, v2, i1 and i2 otherwise you will have to change this (or modify the script)            
            if nCurrentDataSet == 1             
                output(nCurrentDrive).Vgs = inputFile.(fileName{1}).(vgs)(locCurrentDrive);
                output(nCurrentDrive).Vds = inputFile.(fileName{1}).(vds)(locCurrentDrive);
                % Calculate input/output reflection coefficients, based on v and i given (so will be at device plane
                % or package plane depending on given v and i)
                
                % NOTE: If your gammaL is not being calculated correctly, it could be because of the current:
                %       For measurements from the Mesuro load pull system, the calculation for the output reflection coefficient
                %       is inversed - If this is not correct then uncomment the block below and it should fix this.
                % Simulated (fundamental) drain current can be inverted so *-1 to get actual gammaL
                
                if inputFile.(fileName{1}).(i2)(1,2) < 0
                    inputFile.(fileName{1}).(i2) = inputFile.(fileName{1}).(i2) * -1;
                    output(nCurrentDrive).(i2) = output(nCurrentDrive).(i2) * -1;
                end
                
                % Impedances NOTE: zL and zS
                zL = inputFile.(fileName{1}).(v2)(locCurrentDrive,2) ./ inputFile.(fileName{1}).(i2)(locCurrentDrive,2);    % Load impedance
                zS = inputFile.(fileName{1}).(v1)(locCurrentDrive,2) ./ inputFile.(fileName{1}).(i1)(locCurrentDrive,2);    % Source impedance
                output(nCurrentDrive).realZLoad = real(zL); % CHECK IF CORRECT
                output(nCurrentDrive).imagZLoad = imag(zL); % CHECK IF CORRECT
                
                % Reflection coefficients
                output(nCurrentDrive).gammaL = 1./((zL-z0)./(zL+z0));   % Load reflection coefficient NOTE: gammaL eqn is inverted
                output(nCurrentDrive).gammaIn = ((zS-z0)./(zS+z0));     % Source reflection coefficient **CHECK IF CORRECT FOR SIMULATED DATA**
                                
                output(nCurrentDrive).PDC = abs(output(nCurrentDrive).(v2)(:,1) .* output(nCurrentDrive).(i2)(:,1));	% DC power
                output(nCurrentDrive).Pout1      = abs(0.5 * real(output(nCurrentDrive).(v2)(:,2) .* conj(output(nCurrentDrive).(i2)(:,2))));	% Pout (W)
                output(nCurrentDrive).Pin1       = 0.5 * real(output(nCurrentDrive).(v1)(:,2) .* conj(output(nCurrentDrive).(i1)(:,2)));        % Pin (W)
                output(nCurrentDrive).Pout_dBm1  = real(30 + 10 * log10(output(nCurrentDrive).Pout1));	% Pout (dBm)
                output(nCurrentDrive).Pin_dBm1   = real(30 + 10 * log10(output(nCurrentDrive).Pin1));	% Pin (dBm)
                output(nCurrentDrive).Gp         = output(nCurrentDrive).Pout_dBm1 - output(nCurrentDrive).Pin_dBm1;	% Power gain (dB)
                output(nCurrentDrive).ZL         = -output(nCurrentDrive).(v2) ./ output(nCurrentDrive).(i2);           % Zload
                
                output(nCurrentDrive).eta        = output(nCurrentDrive).Pout1 ./ output(nCurrentDrive).PDC * 100;      % Efficiency
                % Some i2 DC components are 0, causing some PDC values to also be 0. This causes a /0 error when calculating efficiency.
                % To fix this the script finds inf values and replaces with NaN
                infCheck = isinf(output(nCurrentDrive).eta);
                output(nCurrentDrive).eta(infCheck) = NaN;
                
                output(nCurrentDrive).IRL         = 10 * log10((1 - abs(output(nCurrentDrive).gammaIn) .^ 2));	% Input mismatch loss (dB)
                output(nCurrentDrive).Pav_dBm     = output(nCurrentDrive).Pin_dBm1 - output(nCurrentDrive).IRL;
                output(nCurrentDrive).PoutMax    = max(max(output(nCurrentDrive).Pout_dBm1));	% Maximum power
                output(nCurrentDrive).PoutMin    = min(min(output(nCurrentDrive).Pout_dBm1));	% Minimum power
                output(nCurrentDrive).etaMax     = max(max(output(nCurrentDrive).eta));         % Maximum efficiency
                output(nCurrentDrive).etaMin     = min(min(output(nCurrentDrive).eta));         % Minimum efficiency
            
                % Calculate waveforms at each load at the current input drive
                output(nCurrentDrive).v2_waveforms = calculatewaveform(output(nCurrentDrive).(v2),nLoads,2^10);
                output(nCurrentDrive).i2_waveforms = calculatewaveform(output(nCurrentDrive).(i2),nLoads,2^10);
                % output(nCurrentDrive).v1_waveforms = calculatewaveform(output(nCurrentDrive).(v1),nLoads,2^10);
                % output(nCurrentDrive).i1_waveforms = calculatewaveform(output(nCurrentDrive).(i1),nLoads,2^10);
                
                % Calculate Vmin, Vmax, Imin and Imax at each load at the current input drive
                for nCurrentLoad = 1:nLoads
                    % To calculate i1 and v1 max/min, just replace v2_waveforms with v1_waveforms ect
                    output(nCurrentDrive).Vmin(nCurrentLoad,1) = min(output(nCurrentDrive).v2_waveforms{1,nCurrentLoad}); % Calculate Vmin at each load for the current input drive and store in 
                    % output(nCurrentDrive).Imin(nCurrentLoad,1) = min(output(nCurrentDrive).i2_waveforms{1,nCurrentLoad}); % Calculate Imin at each load for the current input drive and store in 
                    % output(nCurrentDrive).Vmax(nCurrentLoad,1) = max(output(nCurrentDrive).v2_waveforms{1,nCurrentLoad}); % Calculate Vmax at each load for the current input drive and store in 
                    output(nCurrentDrive).Imax(nCurrentLoad,1) = max(output(nCurrentDrive).i2_waveforms{1,nCurrentLoad}); % Calculate Imax at each load for the current input drive and store in  
                end
            end
        end
    end
end