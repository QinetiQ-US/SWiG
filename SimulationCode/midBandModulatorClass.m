classdef midBandModulatorClass < modulatorClass

    properties
    end

    methods
        function obj = midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,...
                fullDuplex,CSMA,centerFrequency,maxInterferenceIn_dB,nominalPreambleDuration,maxBandwidth)
            obj = obj@modulatorClass(topBitrate,packetLength,preambleCollisionFatal,...
                fullDuplex,CSMA,centerFrequency,maxInterferenceIn_dB,nominalPreambleDuration,maxBandwidth);
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
            fatalDistance = 4000;
            pOkay = sigmoid(distance,fatalDistance,-11);
            check = rand(1);
            result = check < pOkay;
        end
        function result = attenuation(delay)
            %r^2 attenuation
            distance = delay*1500;  %meters
            atten1 = 10*log10(distance^2);
            %frequency-dependent absorption
            atten2 = 3.5*0.001*distance;  %3.5 dB/km @ 21 kHz midband
            result = atten1 + atten2;
        end
    end



end