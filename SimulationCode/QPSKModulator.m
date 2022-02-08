%> @brief QPSK high-speed HD modulator/demodulator
classdef QPSKModulator < modulatorClass
    %

    properties
    end

    methods
        %> @brief Constructor
        %> @param [in] fullDuplex - boolean describing if self-cancelling
        %> @param [in] CSMA - boolean indicating if must wait for no carrier
        %> before sending
        function obj = QPSKModulator(fullDuplex,CSMA)
            packetLength = 1206;
            topBitrate = (10e3*2*packetLength/(2047*1.2))*1.2;
            preambleCollisionFatal = false;
            centerFrequency = 25e3;
            maxBandwidth = 10e3;
            maxInterference = -8;   %in dB
            nominalPreambleDuration = (127 + 32)*1.2/maxBandwidth;
            obj = obj@modulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,maxInterference,nominalPreambleDuration,maxBandwidth);
        end

        %> @brief access packet duration
        %> @param [in] obj - the modulator object
        %> @retval result - duration in seconds
        function result = getPacketDuration(obj)
            result = (obj.packetLength/(obj.topBitrate * obj.bandwidthFraction)) + ...
                (obj.nominalPreambleDuration / obj.bandwidthFraction);
        end


        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'QPSK';
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
            atten2 = 4.9*0.001*distance;  %4.9 dB/km @ 24 kHz midband
            result = atten1 + atten2;
        end

        %> @brief default boolean for is HD modulator - true
        function result = isHDModulator
            result = true;
        end
    end



end