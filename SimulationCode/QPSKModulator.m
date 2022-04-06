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
            interferenceMitigation = -8;   %in dB - interference in QPSK is very bad
            nominalPreambleDuration = (127 + 32)*1.2/maxBandwidth;
            obj = obj@modulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,interferenceMitigation,nominalPreambleDuration,maxBandwidth);
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
        %> @brief default boolean for is HD modulator - true
        function result = isHDModulator
            result = true;
        end
    end



end