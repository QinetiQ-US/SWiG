%> @brief OFDM64QAM3_4 high-speed HD modulator/demodulator
%> @details OFDM 64 subcarriers, 48 data carriers, coded 64QAM, 3/4 rate
%>FEC
classdef OFDM64QAM3_4Modulator < modulatorClass
    %

    properties
    end

    methods
        %> @brief Constructor
        %> @param [in] fullDuplex - boolean describing if self-cancelling
        %> @param [in] CSMA - boolean indicating if must wait for no carrier
        %> before sending
        function obj = OFDM64QAM3_4Modulator(fullDuplex,CSMA)
            packetLength = 1206;
            preambleCollisionFatal = true;
            centerFrequency = 25e3;
            maxBandwidth = 10e3;
            interferenceMitigation = 20;   %in dB - highly resistant
            nominalPreambleDuration = 4*80/maxBandwidth;
            topBitrate = 216*maxBandwidth/80;
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
            modulatorType.style = 'OFDM64QAM3_4';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

    methods(Static)
        %> @brief default boolean for is HD modulator - true
        function result = isHDModulator
            result = true;
        end
        %> @brief SNR required for successful decoding
        %> @retval result - value in dB Eb/N0
        function result = EbOverN0Required()
            result = 9 + 10;  %9 dB for threshold, plus 10 dB because RMS power is approximately 10 dB below peak power
        end
    end



end