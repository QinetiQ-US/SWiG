%> @brief Modulator class - Abstract class
%> @details actual modulator classes derive from modulator
classdef modulatorClass < matlab.mixin.Copyable

    properties(Access = public)
        %> bandwidth fraction: (0 to 1)
        bandwidthFraction;  
        %> top bit rate - assuming to scale with bandwidth (scaled to deal with error correction)
        topBitrate;  
        %> nominal packet length (prior to error correction)
        packetLength;  
        %> is collision with preamble fatal?
        preambleCollisionFatal;  
        %> am I full-duplex-capable?
        fullDuplex;     
        %> do I use CSMA to decide when to transmit
        CSMA;           
        %> center frequency in Hz
        centerFrequency;    
        %> nominal center frequency
        nominalCenterFrequency; 
        %> interference mitigation - conversion factor for interference ->
        %> effective N0
        interferenceMitigationIn_dB;   
        %> self-cancellation in dB
        selfCancellationIn_dB;  
        %> preamble duration when bandwidth full - scales inverse to bandwidth
        nominalPreambleDuration;  
        %> full bandwidth in Hz
        maxBandwidth;
        %> power into the water
        signalPowerIn_dB;
    end

    methods
        %> @brief Constructor
        %> @param [in] topBitrate in bits per second (bps)
        %> @param [in] packetLength in bits
        %> @param [in] preambleCollisionFatal - boolean indicating if
        %> simultaneous reception of preambles results in failure
        %> @param [in] fullDuplex - boolean indicating self-cancellation
        %> @param [in] CSMA - boolean indicating if must wait for no
        %> carrier prior to transmitting
        %> @param [in] centerFrequency - center frequency of modulator in
        %> Hz
        %> @param [in] maxInterferenceIn_dB - survivable interference
        %> @param [in] nominalPreambleDuration - in seconds at full
        %> bandwidth
        %> @param [in] maxBandwidth - in Hz
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
            obj.interferenceMitigationIn_dB = maxInterferenceIn_dB;
            obj.selfCancellationIn_dB = 50;  %based on experimental values near bottom or top
            obj.nominalPreambleDuration = nominalPreambleDuration;
            obj.maxBandwidth = maxBandwidth;
            obj.signalPowerIn_dB = 180;  %default signal level
        end

        %> @brief reset modulator to default carrier and bandwidth
        function obj = resetModulator(obj)
            obj.centerFrequency = obj.nominalCenterFrequency;
            obj.bandwidthFraction = 1.0;
        end

        %> @brief set the signal power to other than default
        %> @param [in] obj - the object
        %> @param [out] power - power level in dB
        %> @retval out
        function obj = setSignalPower(obj,power)
            obj.signalPowerIn_dB = power;
        end

        %> @brief get the signal power
        %> @param [in] obj - the object
        %> @retval result power output in dB
        function result = getSignalPower(obj)
            result = obj.signalPowerIn_dB;
        end

        %> @brief access duplex boolean
        function result = getDuplex(obj)
            result = obj.fullDuplex;
        end

        %> @brief access CSMA boolean
        function result = getCSMA(obj)
            result = obj.CSMA;
        end
        
        %> @brief access bandwidth fraction
        function result = getBandwidthFraction(obj)
            result = obj.bandwidthFraction;
        end

        %> @brief access packet length
        function result = getPacketLength(obj)
            result = obj.packetLength;
        end
    
        %> @brief access packet duration
        function result = getPacketDuration(obj)
            result = (1.2*obj.packetLength/(obj.topBitrate * obj.bandwidthFraction)) + ...
                (obj.nominalPreambleDuration / obj.bandwidthFraction);
        end

        %> @brief acces whether preamble collisions are fatal
        function result = isPreambleCollisionFatal(obj)
            result = obj.preambleCollisionFatal;
        end

        %> @brief access interference mitigation
        function result = getInterferenceMitigation(obj)
            result = obj.interferenceMitigationIn_dB;
        end

        %> @brief access preamble duration
        function result = getPreambleDuration(obj)
            result = obj.nominalPreambleDuration / obj.bandwidthFraction;
        end

        %> @brief access bandwidth in Hz
        function result = getBandwidth(obj)
            result = obj.maxBandwidth * obj.bandwidthFraction;
        end

        %> @brief set bandwidth fraction
        %> @param [in] obj modulator object
        %> @param [in] bandwidthFraction
        %> @retval obj - the object
        function obj = setBandwidthFraction(obj,bandwidthFraction)
            obj.bandwidthFraction = bandwidthFraction;
        end

        %> @brief set center frequency
        %> @param [in] obj modulator object
        %> @param [in] centerFrequency
        %> @retval obj - the object
        function obj = setCenterFrequency(obj,centerFrequency)
            obj.centerFrequency = centerFrequency;
        end

        %> @brief access center frequency
        function result = getCenterFrequency(obj)
            result = obj.centerFrequency;
        end

        %> @brief get the band edges
        %> @param [in] obj the modulator object
        %> @retval low - low frequency of band
        %> @retval high - high frequency of band
        function [low, high] = getBandEdges(obj)
            low = obj.centerFrequency - 0.5*obj.bandwidthFraction*obj.maxBandwidth;
            high = obj.centerFrequency + 0.5*obj.bandwidthFraction*obj.maxBandwidth;
        end

        %> @brief compute band overlap between two modulators (fraction)
        %> @param [in] obj - this modulator
        %> @param [in] otherModulator - other modulator object
        %> @retval result - fraction of overlap with this modulator
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
        %> @brief default boolean for is HD modulator - no
        function result = isHDModulator()
            result = false;
        end
        %> @brief SNR required for successful decoding
        %> @retval result - value in dB Eb/N0
        function result = EbOverN0Required()
            result = 8;
        end
    end

    methods(Abstract)
        %> @brief Function to describe the modulator
        %> @param [in] obj - the modulator object
        %> @retval modulatorType - a struct with the following fields:<br>
        %> style - a string with the modulator name <br>
        %> bandwidth - a double between 0 and 1 indicating fractional
        %>bandwidth
        getModulatorType(obj)
    end


end