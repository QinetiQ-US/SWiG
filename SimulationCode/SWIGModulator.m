%> @brief Class for SWIG modulator
%> @details Implements a modulator based on SWiG level with, but with the
%>ability to demodulate and decode multiple messages simultaneously
classdef SWIGModulator < midBandModulatorClass
    %SWIGModulator Characterizes the SWIG physical transmission
    %   

    properties
    end

    methods
        %> @brief Constructor
        %> @param [in] fullDuplex - boolean describing if self-cancelling
        %> @param [in] CSMA - boolean indicating if must wait for no carrier
        %> before sending
        function obj = SWIGModulator(fullDuplex,CSMA)
            topBitrate = 110;
            packetLength = 49;
            preambleCollisionFatal = true;
            centerFrequency = 21.33e3;
            maxBandwidth = 6.76e3;
            maxInterference = 60;   %in dB
            nominalPreambleDuration = 32 * 0.003846 ;
            obj = obj@midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,maxInterference,nominalPreambleDuration,maxBandwidth);
        end
        
        %> @brief Function to describe the modulator
        %> @param [in] obj - the modulator object
        %> @retval modulatorType - a struct with the following fields:<br>
        %> style - a string with the modulator name ('SWiG')<br>
        %> bandwidth - a double between 0 and 1 indicating fractional
        %>bandwidth
        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'SWiG';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

end