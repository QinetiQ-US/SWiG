%> @brief Class for generic DSSSmodulator
%> @details Implements a modulator based on SWiG level expected behavior of
% > generic DSSS modulator/demodulator, including interference,
%> parallel/serial cancellation and 
%>ability to demodulate and decode multiple messages simultaneously
classdef genericDSSSModulator < modulatorClass
    %SWIGModulator Characterizes the SWIG physical transmission
    %

    properties
    end

    methods
        %> @brief Constructor
        %> @param [in] fullDuplex - boolean describing if self-cancelling
        %> @param [in] CSMA - boolean indicating if must wait for no carrier
        %> before sending
        function obj = genericDSSSModulator(fullDuplex,CSMA)
            topBitrate = 1024;
            packetLength = 511;
            preambleCollisionFatal = false;
            centerFrequency = 15e3;
            maxBandwidth = 10e3;
            interferenceMitigation = 30;  %typical interference mitigation level in dB
            nominalPreambleDuration = 255 * 1.2 / 1e4;
            obj = obj@modulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,interferenceMitigation,nominalPreambleDuration,maxBandwidth);
        end

        %> @brief Function to describe the modulator
        %> @param [in] obj - the modulator object
        %> @retval modulatorType - a struct with the following fields:<br>
        %> style - a string with the modulator name ('DSSS')<br>
        %> bandwidth - a double between 0 and 1 indicating fractional
        %>bandwidth
        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'DSSS';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end



end