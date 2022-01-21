classdef SWIGModulator < midBandModulatorClass
    %SWIGModulator Characterizes the SWIG physical transmission
    %   

    properties
    end

    methods
        function obj = SWIGModulator(fullDuplex,CSMA)
            topBitrate = 110;
            packetLength = 49;
            preambleCollisionFatal = true;
            centerFrequency = 21.33e3;
            maxBandwidth = 6.76e3;
            maxInterference = 30;   %in dB
            nominalPreambleDuration = 32 * 0.003846 ;
            obj = obj@midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,maxInterference,nominalPreambleDuration,maxBandwidth);
        end

        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'SWiG';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

end