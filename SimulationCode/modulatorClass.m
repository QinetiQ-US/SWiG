classdef modulatorClass < matlab.mixin.Copyable
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        bandwidthFraction;  %bandwidth fraction
        topBitrate;  %top bit rate - assuming to scale with bandwidth (scaled to deal with error correction)
        packetLength;  %nominal packet length (prior to error correction)
        preambleCollisionFatal;  %is collision with preamble fatal?
        fullDuplex;     %am I full-duplex-capable?
        CSMA;           %do I use CSMA to decide when to transmit
        centerFrequency;    %center frequency
        nominalCenterFrequency; %nominal center frequency
        maxInterferenceIn_dB;   %maximum permissible interference in dB
        selfCancellationIn_dB;  %self-cancellation in dB
        nominalPreambleDuration;  %preamble duration when bandwidth full - scales inverse to bandwidth
        maxBandwidth;       %full bandwidth
    end

    methods
        function obj = modulatorClass(topBitrate,packetLength,preambleCollisionFatal,...
                fullDuplex,CSMA,centerFrequency,maxInterferenceIn_dB,nominalPreambleDuration,maxBandwidth)
            obj.bandwidthFraction = 1.0;  %initialize to max
            obj.topBitrate = topBitrate;
            obj.packetLength = packetLength;
            obj.preambleCollisionFatal = preambleCollisionFatal;
            obj.fullDuplex = fullDuplex;
            obj.CSMA = CSMA;
            obj.centerFrequency = centerFrequency;
            obj.nominalCenterFrequency = centerFrequency;
            obj.maxInterferenceIn_dB = maxInterferenceIn_dB;
            obj.selfCancellationIn_dB = 50;  %based on experimental values near bottom or top
            obj.nominalPreambleDuration = nominalPreambleDuration;
            obj.maxBandwidth = maxBandwidth;
        end

        function obj = resetModulator(obj)
            obj.centerFrequency = obj.nominalCenterFrequency;
            obj.bandwidthFraction = 1.0;
        end

        function result = getDuplex(obj)
            result = obj.fullDuplex;
        end

        function result = getCSMA(obj)
            result = obj.CSMA;
        end

        function result = getBandwidthFraction(obj)
            result = obj.bandwidthFraction;
        end

        function result = getPacketLength(obj)
            result = obj.packetLength;
        end

        function result = getPacketDuration(obj)
            result = (1.2*obj.packetLength/(obj.topBitrate * obj.bandwidthFraction)) + ...
                (obj.nominalPreambleDuration / obj.bandwidthFraction);
        end

        function result = isPreambleCollisionFatal(obj)
            result = obj.preambleCollisionFatal;
        end

        function result = getMaxInterferenceIn_dB(obj)
            result = obj.maxInterferenceIn_dB;
        end

        function result = getPreambleDuration(obj)
            result = obj.nominalPreambleDuration / obj.bandwidthFraction;
        end

        function result = getBandwidth(obj)
            result = obj.maxBandwidth * obj.bandwidthFraction;
        end

        function obj = setBandwidthFraction(obj,bandwidthFaction)
            obj.bandwidthFraction = bandwidthFaction;
        end

        function obj = setCenterFrequency(obj,centerFrequency)
            obj.centerFrequency = centerFrequency;
        end

        function result = getCenterFrequency(obj)
            result = obj.centerFrequency;
        end

        function [low, high] = getBandEdges(obj)
            low = obj.centerFrequency - 0.5*obj.bandwidthFraction*obj.maxBandwidth;
            high = obj.centerFrequency + 0.5*obj.bandwidthFraction*obj.maxBandwidth;
        end

        function result = getBandOverlapFraction(obj, otherModulator)
            [thisLow, thisHigh] = obj.getBandEdges;
            [otherLow,otherHigh] = otherModulator.getBandEdges;
            midlow = max(thisLow,otherLow);
            midhigh = min(thisHigh,otherHigh);
            if midhigh <= midlow
                result = 0;
            else
                result = (midhigh - midlow)/(thisHigh - thisLow);
            end
        end

    end

    methods(Static)
        function result = isHDModulator()
            result = false;
        end
    end

    methods(Abstract,Static)
        packetValid(delay)
        attenuation(delay)
    end

    methods(Abstract)
        getModulatorType(obj)
    end


end