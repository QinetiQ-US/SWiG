classdef genericDSSSModulator < modulatorClass
    %SWIGModulator Characterizes the SWIG physical transmission
    %

    properties
    end

    methods
        function obj = genericDSSSModulator(fullDuplex,CSMA)
            topBitrate = 110;
            packetLength = 49;
            preambleCollisionFatal = false;
            centerFrequency = 15e3;
            maxBandwidth = 10e3;
            maxInterference = 20;   %in dB
            nominalPreambleDuration = 1023 * 1.2 / 1e4;
            obj = obj@modulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,maxInterference,nominalPreambleDuration,maxBandwidth);
        end

        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'DSSS';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

    methods(Static)
        function result = packetValid(delay)
            distance = delay * 1500;
            pOops = 0.05;  %5% chance of drop no matter what
            %fixed chance of oops
            check = rand(1);
            if check < pOops
                result = false;
                return;
            end
            %probability grows fast with distance
            fatalDistance = 5000;
            pOkay = sigmoid(distance,fatalDistance,-11);
            check = rand(1);
            result = check < pOkay;
        end
        function result = attenuation(delay)
            %r^2 attenuation
            distance = delay*1500;  %meters
            atten1 = 10*log10(distance^2);
            %frequency-dependent absorption
            atten2 = 2.0*0.001*distance;  %2.0 dB/km @ 15 kHz midband
            result = atten1 + atten2;
        end
    end



end