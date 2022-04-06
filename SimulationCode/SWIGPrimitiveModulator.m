%> @brief Class for SWIG primitive modulator
%> @details Implements a modulator based on SWiG level with, with no
%>ability to demodulate and decode multiple messages simultaneously
classdef SWIGPrimitiveModulator < midBandModulatorClass
    %SWIGModulator Characterizes the SWIG physical transmission
    %   

    properties
    end

    methods
        %> @brief Constructor
        %> @param [in] fullDuplex - boolean describing if self-cancelling
        %> @param [in] CSMA - boolean indicating if must wait for no carrier
        %> before sending
        function obj = SWIGPrimitiveModulator(fullDuplex,CSMA)
            topBitrate = 110;
            packetLength = 49;
            preambleCollisionFatal = true;
            centerFrequency = 21.33e3;
            maxBandwidth = 6.76e3;
            interferenceMitigation = -60;   %in dB - all collisions fatal
            nominalPreambleDuration = 32 * 0.003846 ;
            obj = obj@midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,interferenceMitigation,nominalPreambleDuration,maxBandwidth);
        end

        %> @brief Function to describe the modulator
        %> @param [in] obj - the modulator object
        %> @retval modulatorType - a struct with the following fields:<br>
        %> style - a string with the modulator name ('SWiGPrimitive')<br>
        %> bandwidth - a double between 0 and 1 indicating fractional
        %>bandwidth
        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'SWiGPrimitive';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

end