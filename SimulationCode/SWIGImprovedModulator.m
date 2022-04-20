%> @brief Class for SWIG modulator
%> @details Implements a modulator based on SWiG level with, but with the
%>ability to demodulate and decode multiple messages simultaneously
classdef SWIGImprovedModulator < midBandModulatorClass
    %SWIGImprovedModulator Characterizes the SWIG physical transmission
    %   

    properties
    end

    methods
        %> @brief Constructor
        %> @param [in] fullDuplex - boolean describing if self-cancelling
        %> @param [in] CSMA - boolean indicating if must wait for no carrier
        %> before sending
        function obj = SWIGImprovedModulator(fullDuplex,CSMA)
            topBitrate = 220;
            packetLength = 49;
            preambleCollisionFatal = true;
            maxBandwidth = 6.76e3 * 2;
            centerFrequency = 21.33e3 - 0.25*maxBandwidth + 0.5*maxBandwidth;
            interferenceMitigation = 60;   %in dB
            nominalPreambleDuration = 32 * 0.003846 ;
            obj = obj@midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,interferenceMitigation,nominalPreambleDuration,maxBandwidth);
        end
        
        %> @brief Function to describe the modulator
        %> @param [in] obj - the modulator object
        %> @retval modulatorType - a struct with the following fields:<br>
        %> style - a string with the modulator name ('SWiG')<br>
        %> bandwidth - a double between 0 and 1 indicating fractional
        %>bandwidth
        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'SWiG improved';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

end