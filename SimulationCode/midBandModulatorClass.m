%> @brief base class for SWiG type modulators
classdef midBandModulatorClass < modulatorClass

    properties
    end

    methods
        %> @brief constructor for miBandModulatorClass
        %> @param [in] topBitrate in bits per second (bps)
        %> @param [in] packetLength in bits
        %> @param [in] preambleCollisionFatal - boolean indicating if
        %> simultaneous reception of preambles results in failure
        %> @param [in] fullDuplex - boolean indicating self-cancellation
        %> @param [in] CSMA - boolean indicating if must wait for no
        %> carrier prior to transmitting
        %> @param [in] centerFrequency - center frequency of modulator in
        %> Hz
        %> @param [in] interferenceMitigation - interference mitigation in
        %> dB
        %> @param [in] nominalPreambleDuration - in seconds at full
        %> bandwidth
        %> @param [in] maxBandwidth - in Hz
        function obj = midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,...
                fullDuplex,CSMA,centerFrequency,interferenceMitigation,nominalPreambleDuration,maxBandwidth)
            obj = obj@modulatorClass(topBitrate,packetLength,preambleCollisionFatal,...
                fullDuplex,CSMA,centerFrequency,interferenceMitigation,nominalPreambleDuration,maxBandwidth);
        end

    end


end