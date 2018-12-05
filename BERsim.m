%% ECE 300
clear all;
close all;
clc;
% For the final version of this project, you must use these 3
% parameter. You will likely want to set numIter to 1 while you debug your
% link, and then increase it to get an average BER.
numIter = 40;  % The number of iterations of the simulation
nSym = 1000;    % The number of symbols per packet
SNR_Vec = 0:2:16;
lenSNR = length(SNR_Vec);
symbolTrain = 120;
 
M = 2;        % The M-ary number, 2 corresponds to binary modulation
k = log2(M);
%SNR_Vec = SNR_Vec + 10*log10(k);
 
%chan = 1;          % No channel
chan = [1 .2 .4]; % Somewhat invertible channel impulse response, Moderate ISI
%chan = [0.227 0.460 0.688 0.460 0.227]';   % Not so invertible, severe ISI
 
 
% Time-varying Rayleigh multipath channel, try it if you dare. Or take
% wireless comms.
% ts = 1/1000;
% chan = rayleighchan(ts,1);
% chan.pathDelays = [0 ts 2*ts];
% chan.AvgPathGaindB = [0 5 10];
% chan.StoreHistory = 1; % Uncomment if you want to be able to do plot(chan)
%
 
% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, lenSNR);
berVecQAM = zeros(numIter, lenSNR);
 
% Run the simulation numIter amount of times
for i = 1:numIter
   
    % bits = randi(1, nSym*M, [0 1]);     % Generate random bits
    bits = randi(2,[nSym*k, 1])-1;
    bits4 = randi(2,[nSym*2, 1])-1;
    bits16 = randi(2,[nSym*4, 1])-1;
    % New bits must be generated at every
    % iteration
   
    % If you increase the M-ary number, as you most likely will, you'll need to
    % convert the bits to integers. See the BIN2DE function
    % For binary, our MSG signal is simply the bits
    msg = bi2de(reshape(bits, [nSym k]));
    msg4 = bi2de(reshape(bits4, [nSym 2]));
    msg16 = bi2de(reshape(bits16, [nSym 4]));
    %msg(1:50) = mod(1:50, 16);
 
    for j = 1:lenSNR % one iteration of the simulation at each SNR Value
               
        tx = qammod(msg,M);  % BPSK modulate the signal
        tx4 = qammod(msg4, 4);
        tx16 = qammod(msg16, 16);
       
        if isequal(chan,1)
            txChan = tx;
        elseif isa(chan,'channel.rayleigh')
            reset(chan) % Draw a different channel each iteration
            txChan = filter(chan,tx);
        else
            txChan = filter(chan,1,tx);  % Apply the channel.
        end
       
        % Convert from EbNo to SNR.
        % Note: Because No = 2*noiseVariance^2, we must add ~3 dB
        % to get SNR (because 10*log10(2) ~= 3).
        if (M == 2)
            txNoisy = awgn(txChan,3+SNR_Vec(j),'measured'); % Add AWGN
        else 
            txNoisy = awgn(txChan,10*log10(k)+SNR_Vec(j),'measured'); % Add AWGN
        end
        
        txNoisy4 = awgn(tx4, 10*log10(log2(4))+SNR_Vec(j),'measured'); % Add AWGN
        txNoisy16 = awgn(tx16, 10*log10(log2(16))+SNR_Vec(j),'measured'); % Add AWGN
        
        rx4 = qamdemod(txNoisy4, 4);
        rx4 = de2bi(rx4);
        rxMSG4 = reshape(rx4, [nSym*2, 1]);
        [~, berVecQAM(i,j,1)] = biterr(bits4, rxMSG4);
        
        rx16 = qamdemod(txNoisy16, 16);
        rx16 = de2bi(rx16);
        rxMSG16 = reshape(rx16, [nSym*4, 1]);
        [~, berVecQAM(i,j,2)] = biterr(bits16, rxMSG16);
        
        berQAM(:,1) = mean(berVecQAM(:,:,1));
        berQAM(:,2) = mean(berVecQAM(:,:,2));
        
        eq11 = dfe(5, 3, lms(0.01));
        eq11.SigConst = qammod((0:M-1)',M)';
        eql1.ResetBeforeFiltering = 0;
        [symbolest1, y(:,1)] = equalize(eq11, txNoisy, tx(1:symbolTrain));
        rx(:,1) = qamdemod(y(:,1),M);
        rxMSG = rx;
        [~, berVec(i,j,1)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 1));
        ber(:,1) = mean(berVec(:,:,1));
        
        eq12 = dfe(5, 3, lms(0.05));
        eq12.SigConst = qammod((0:M-1)',M)';
        eql2.ResetBeforeFiltering = 0;
        [symbolest2, y(:,2)] = equalize(eq12, txNoisy, tx(1:symbolTrain));
        rx(:,2) = qamdemod(y(:,2),M);
        rxMSG = rx;
        [~, berVec(i,j,2)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 2));
        ber(:,2) = mean(berVec(:,:,2));
        
        eq13 = dfe(5, 3, lms(0.1));
        eq13.SigConst = qammod((0:M-1)',M)';
        eql3.ResetBeforeFiltering = 0;
        [symbolest3, y(:,3)] = equalize(eq13, txNoisy, tx(1:symbolTrain));
        rx(:,3) = qamdemod(y(:,3),M);
        rxMSG = rx;
        [~, berVec(i,j,3)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 3));
        ber(:,3) = mean(berVec(:,:,3));
        
        eq14 = dfe(5, 3, lms(0.5));
        eq14.SigConst = qammod((0:M-1)',M)';
        eql4.ResetBeforeFiltering = 0;
        [symbolest4, y(:,4)] = equalize(eq14, txNoisy, tx(1:symbolTrain));
        rx(:,4) = qamdemod(y(:,4),M);
        rxMSG = rx;
        [~, berVec(i,j,4)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 4));
        ber(:,4) = mean(berVec(:,:,4));
       
        
        eq15 = lineareq(8, lms(0.01));
        eq15.SigConst = qammod((0:M-1)',M)';
        eql5.ResetBeforeFiltering = 0;
        [symbolest5, y(:,5)] = equalize(eq15, txNoisy, tx(1:symbolTrain));
        rx(:,5) = qamdemod(y(:,5),M);
        rxMSG = rx;
        [~, berVec(i,j,5)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 5));
        ber(:,5) = mean(berVec(:,:,5));
        
        eq16 = lineareq(8, lms(0.05));
        eq16.SigConst = qammod((0:M-1)',M)';
        eql6.ResetBeforeFiltering = 0;
        [symbolest6, y(:,6)] = equalize(eq16, txNoisy, tx(1:symbolTrain));
        rx(:,6) = qamdemod(y(:,6),M);
        rxMSG = rx;
        [~, berVec(i,j,6)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 6));
        ber(:,6) = mean(berVec(:,:,6));
        
        eq17 = lineareq(8, rls(1));
        eq17.SigConst = qammod((0:M-1)',M)';
        eql7.ResetBeforeFiltering = 0;
        [symbolest7, y(:,7)] = equalize(eq17, txNoisy, tx(1:symbolTrain));
        rx(:,7) = qamdemod(y(:,7),M);
        rxMSG = rx;
        [~, berVec(i,j,7)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 7));
        ber(:,7) = mean(berVec(:,:,7));
        
        eq18 = lineareq(8, rls(0.7));
        eq18.SigConst = qammod((0:M-1)',M)';
        eql8.ResetBeforeFiltering = 0;
        [symbolest8, y(:,8)] = equalize(eq18, txNoisy, tx(1:symbolTrain));
        rx(:,8) = qamdemod(y(:,8),M);
        rxMSG = rx;
        [~, berVec(i,j,8)] = biterr(msg(symbolTrain+1:end), rxMSG(symbolTrain+1:end, 8));
        ber(:,8) = mean(berVec(:,:,8));
        
       
        % Demodulate
        %rx = de2bi(rx);
        %rxMSG = reshape(rx, [nSym*k, 1]);
        
        % Again, if M was a larger number, I'd need to convert my symbols
        % back to bits here.
        % rxMSG = rx;
       
        % Compute and store the BER for this iteration
       
        
        %[~, berVec(i,j)] = biterr(bits(symbolTrain+1:end), rxMSG(symbolTrain+1:end));  % We're interested in the BER, which is the 2nd output of BITERR
       
    end  % End SNR iteration
end      % End numIter iteration
 
 
% Compute and plot the mean BER


semilogy(SNR_Vec, ber(:,1:4));
 
% Compute the theoretical BER for this scenario
% THIS IS ONLY VALID FOR BPSK!
% YOU NEED TO CHANGE THE CALL TO BERAWGN FOR DIFF MOD TYPES
% Also note - there is no theoretical BER when you have a multipath channel
berTheory = berawgn(SNR_Vec,'pam',M);
hold on
semilogy(SNR_Vec,berTheory,'r')
title('BER of Different Step Sizes Using lms and a Decision-Feedback Equalizer on a BPSK signal');
xlabel('SNR');
ylabel('BER');
legend('BER step size = 0.01', 'BER step size = 0.05', 'BER step size = 0.1','BER step size = 0.5','Theoretical BER')

figure;
semilogy(SNR_Vec, ber(:,5:8));
hold on
semilogy(SNR_Vec,berTheory,'r')
title('BER of Linear Equalizers with DFE and LMS on a BPSK signal');
xlabel('SNR');
ylabel('BER');
legend('BER LMS step size = 0.01', 'BER LMS step size = 0.05', 'BER RSL forgetting factor = 1','BER RSL forgetting factor = 0.7','Theoretical BER')

figure;
semilogy(SNR_Vec, berQAM(:,1));
berTheory4QAM = berawgn(SNR_Vec,'qam',4);
hold on
semilogy(SNR_Vec,berTheory4QAM,'r')
title('BER 4 QAM');
xlabel('SNR');
ylabel('BER');
legend('4 QAM','Theoretical BER')

figure;
semilogy(SNR_Vec, berQAM(:,2));
berTheory4QAM = berawgn(SNR_Vec,'qam',16);
hold on
semilogy(SNR_Vec,berTheory4QAM,'r')
title('BER 16 QAM');
xlabel('SNR');
ylabel('BER');
legend('16 QAM','Theoretical BER')
