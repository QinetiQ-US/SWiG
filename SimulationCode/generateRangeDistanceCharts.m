%> @brief generate range/bit rate plots for each modulator type

modulatorsSMAC = {
    SWIGModulator(false,false);
    SWIGImprovedModulator(false,false);
    genericDSSSModulator(false,false);
    };
modulatorsHDC = {
    BFSKModulator(false,false);
    BPSKCDMAModulator(false,false);
    QPSKModulator(false,false);
    OFDM64QAM3_4Modulator(false,false);
    };
channel = reliableAcousticPathModel(70,3,0);

%go do ROC curves
for channelType=1:2
    if channelType == 1
        modulators = modulatorsSMAC;
    else
        modulators = modulatorsHDC;
    end
    figure(channelType);
    range=logspace(0,log10(50e3),5000);
    bitrates=zeros(length(modulators),length(range));
    modulatorNames=cell(length(modulators),1);
    for i=1:length(modulators)
        modulator = modulators{i};
        Fc = modulator.centerFrequency;
        BwMax = modulator.maxBandwidth;
        maxBits = modulator.topBitrate;
        EbN0Min = modulator.EbOverN0Required;
        P = modulator.signalPowerIn_dB;
        TL = zeros(size(range));
        txlocation = [0 0 0];
        noise = channel.noiseLevel(Fc);
        for j=1:length(range)
            rxlocation = [0 0 range(j)];
            TL(j) = channel.transmissionLoss(txlocation,rxlocation,Fc);
        end
        PowerOverNoise = P - noise - TL;
        ExcessPower = PowerOverNoise - EbN0Min;
        bitRate = 10.^(0.1*ExcessPower);
        bitRate(bitRate > maxBits) = maxBits;
        %re-do for when we end up limited
        k1=find(bitRate < maxBits,1,'first');
        if ~isempty(k1)
            for m = k1:length(bitRate)
                fraction = bitRate(m-1)/maxBits;
                FcNew = (Fc - 0.5*BwMax) + (0.5*fraction*BwMax);
                noise = channel.noiseLevel(FcNew);
                rxlocation = [0 0 range(m)];
                TLx = channel.transmissionLoss(txlocation,rxlocation,FcNew);
                PowerOverNoise = P - noise - TLx;
                ExcessPowerx = PowerOverNoise - EbN0Min;
                bitRate(m) = min(10 .^(0.1*ExcessPowerx),bitRate(m-1));
            end
        end
        bitRate(bitRate < 0.01 ) = NaN;
        bitrates(i,:)=bitRate(:)';
        modulatorInfo = modulator.getModulatorType;
        modulatorNames{i} = modulatorInfo.style;
    end
    semilogy(range*1e-3,bitrates);
    xlabel('Range (Km)');
    ylabel('Bit rate (bps)');
    title('Range vs. Max Bit Rate');
    grid on
    legend(modulatorNames,'Location','northeast');
end
%now, go do variants on SWiG modulator
figure(3);
range=logspace(0,log10(50e3),5000);
bitrates=zeros(6,length(range));
for i=1:6
    modulator = SWIGModulator(false,false);
    maxBits = modulator.topBitrate;
    EbN0Min = modulator.EbOverN0Required;
    P = modulator.signalPowerIn_dB;
    Fc = modulator.getCenterFrequency;
    BwMax = modulator.maxBandwidth;
    switch(i)
        case 1
        case 2
            P = P + 10;
        case 3
            Fc = 15e3;
        case 4
            Fc = 15e3;
            P = P + 10;
        case 5
            Fc = 12e3;
        case 6
            Fc = 12e3;
            P = P + 10;

    end
    noise = channel.noiseLevel(Fc);
    TL = zeros(size(range));
    txlocation = [0 0 0];
    for j=1:length(range)
        rxlocation = [0 0 range(j)];
        TL(j) = channel.transmissionLoss(txlocation,rxlocation,Fc);
    end
    PowerOverNoise = P - noise - TL;
    ExcessPower = PowerOverNoise - EbN0Min;
    bitRate = 10.^(0.1*ExcessPower);
    bitRate(bitRate > maxBits) = maxBits;
    %re-do for when we end up limited
    k1=find(bitRate < maxBits,1,'first');
    if ~isempty(k1)
        for m = k1:length(bitRate)
            fraction = bitRate(m-1)/maxBits;
            FcNew = (Fc - 0.5*BwMax) + (0.5*fraction*BwMax);
            noise = channel.noiseLevel(FcNew);
            rxlocation = [0 0 range(m)];
            TLx = channel.transmissionLoss(txlocation,rxlocation,FcNew);
            PowerOverNoise = P - noise - TLx;
            ExcessPowerx = PowerOverNoise - EbN0Min;
            bitRate(m) = min(10 .^(0.1*ExcessPowerx),bitRate(m-1));
        end
    end
    bitRate(bitRate < 0.01 ) = NaN;
    bitrates(i,:)=bitRate(:)';
end
semilogy(range*1e-3,bitrates);
xlabel('Range (Km)');
ylabel('Bit rate (bps)');
title('Range vs. Max Bit Rate SWiG Modulation');
grid on
legend('180 dB, 21 kHz','190 dB, 21 kHz','180 dB, 15 kHz',...
    '190 dB, 15 kHz', '180 dB, 12 kHz','190 dB, 12 kHz');
figure(4);
range=logspace(0,log10(50e3),5000);
bitrates=zeros(6,length(range));
for i=1:6
    modulator = SWIGImprovedModulator(false,false);
    maxBits = modulator.topBitrate;
    EbN0Min = modulator.EbOverN0Required;
    P = modulator.signalPowerIn_dB;
    Fc = modulator.getCenterFrequency;
    BwMax = modulator.maxBandwidth;
    switch(i)
        case 1
        case 2
            P = P + 10;
        case 3
            Fc = 17e3;
        case 4
            Fc = 17e3;
            P = P + 10;
        case 5
            Fc = 12e3;
        case 6
            Fc = 12e3;
            P = P + 10;

    end
    noise = channel.noiseLevel(Fc);
    TL = zeros(size(range));
    txlocation = [0 0 0];
    for j=1:length(range)
        rxlocation = [0 0 range(j)];
        TL(j) = channel.transmissionLoss(txlocation,rxlocation,Fc);
    end
    PowerOverNoise = P - noise - TL;
    ExcessPower = PowerOverNoise - EbN0Min;
    bitRate = 10.^(0.1*ExcessPower);
    bitRate(bitRate > maxBits) = maxBits;
    %re-do for when we end up limited
    k1=find(bitRate < maxBits,1,'first');
    if ~isempty(k1)
        for m = k1:length(bitRate)
            fraction = bitRate(m-1)/maxBits;
            FcNew = (Fc - 0.5*BwMax) + (0.5*fraction*BwMax);
            noise = channel.noiseLevel(FcNew);
            rxlocation = [0 0 range(m)];
            TLx = channel.transmissionLoss(txlocation,rxlocation,FcNew);
            PowerOverNoise = P - noise - TLx;
            ExcessPowerx = PowerOverNoise - EbN0Min;
            bitRate(m) = min(10 .^(0.1*ExcessPowerx),bitRate(m-1));
        end
    end
    bitRate(bitRate < 0.01 ) = NaN;
    bitrates(i,:)=bitRate(:)';
end
semilogy(range*1e-3,bitrates);
xlabel('Range (Km)');
ylabel('Bit rate (bps)');
title('Range vs. Max Bit Rate SWiG Improved Modulation');
grid on
legend('180 dB, 25 kHz','190 dB, 25 kHz','180 dB, 17 kHz',...
    '190 dB, 17 kHz', '180 dB, 12 kHz','190 dB, 12 kHz');
