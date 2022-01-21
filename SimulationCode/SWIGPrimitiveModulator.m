classdef SWIGPrimitiveModulator < midBandModulatorClass
    %SWIGModulator Characterizes the SWIG physical transmission
    %   

    properties
    end

    methods
        function obj = SWIGPrimitiveModulator(fullDuplex,CSMA)
            topBitrate = 110;
            packetLength = 49;
            preambleCollisionFatal = true;
            centerFrequency = 21.33e3;
            maxBandwidth = 6.76e3;
            maxInterference = -130;   %in dB - all collisions fatal
            nominalPreambleDuration = 32 * 0.003846 ;
            obj = obj@midBandModulatorClass(topBitrate,packetLength,preambleCollisionFatal,fullDuplex,...
                CSMA, centerFrequency,maxInterference,nominalPreambleDuration,maxBandwidth);
        end

        function modulatorType = getModulatorType(obj)
            modulatorType.style = 'SWiGPrimitive';
            modulatorType.bandwidth = obj.bandwidthFraction;
        end
    end

end