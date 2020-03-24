function [output] = calculatewaveform(waveData,nLoads,padding_size)
% ---- v2 and i2 waveforms ----
% CHANGE LOG:
% 10/11/2018 - Changed 'scaleFactor' for v and i to length() of frequency-domain arrays
% 13/11/2018 - Creates a cell array storing time-domain waveforms for each load at each input drive.
%              Currently only uses 'struct_35105_18_17dBm'
% 24/11/2018 - Changed to use inputs from processMat, v2data is a (n x 1) cell
%              array (v2) field from the nonscalar struct being constructed in
%              processMat.
%              Could extended to calculate waveform and min of any input i
%              or v data

% ---- v2 ----
for currentLoad  = 1:nLoads
    % FFT coefficients w/o zero padding, with negative freq values
    wave_f1 = [waveData(currentLoad,1) ...
               waveData(currentLoad,(2:end))/2 ...
               conj(waveData(currentLoad,(end:-1:2)))/2];
    % FFT coefficients, w/ zero-centered zero padding, with negative freq values
    % # of zeros is calculated to produce a power-of-two # of total values
    % by subtracting the original length of testwave_v2_f1
    % padding_size   = 2^10;
    wave_f1 = [waveData(currentLoad,1) ...
               waveData(currentLoad,(2:end))/2 ...
               zeros(1,(padding_size - length(wave_f1))) ...
               conj(waveData(currentLoad,(end:-1:2)))/2];
    
    % Perform iffts
    wave_t1 = ifft(wave_f1);
    
    % Calculate and apply scaling to zero-padded iffts w/ respect to original ifft
    % scaleFactor_v2_1  = length(testwave_v2_f1); % Old method, is actually equal to padding_size
    wave_t1 = padding_size * wave_t1;
    
    outputWave_t1{1,currentLoad} = wave_t1;
end

output = outputWave_t1; % Output calculated waveform data