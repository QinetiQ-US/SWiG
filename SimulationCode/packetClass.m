%> @brief the class for packets
%> @details contains all information for a packet, modulation details,
%source node, destination node, whether a routed hop is required, whether
%an ACK is required, time it started, time in flight, UID for message, UID
%for ACK (if this is an ACK), raw data
classdef packetClass < matlab.mixin.Copyable
    %packet class

    properties
        %> modulator object
        modulator;
        %> source node number
        source;
        %> node number of next hop
        hop;
        %> node number of destination
        destination;
        %> boolean indicating if an ACK is required
        responseRequired;
        %> time in seconds of start of transmission
        timeStarted;
        %> time day for transmission - a variable of convenience
        timeDelay;
        %> power at receiver - a variable of convenience
        signalLevelAtReceiver;
        %> location of transmitter at time of transmission (seconds)
        transmitterLocation;
        %> UID of this packet
        IDsend;
        %> UID of packet this is ACKing
        IDack;
        %> binary message data
        data;
    end

    methods
        %> @brief packetClass constructor
        %> @param [in] mod - modulator object for this packet
        %> @param [in] src - node number for source of this packet
        %> @param [in] dest - node number for destination of this packet
        %> @param [in] respReq - boolean: is ACK required?
        %> @param [in] IDsend - UID for this packet
        %> @param [in] IDack - UID this packet is ACKing
        %> @param [in] data - binary message data
        function obj = packetClass(mod,src,dest,respReq,IDsend,IDack,data)
            obj.modulator = copy(mod);
            obj.source = src;
            obj.hop = dest;
            obj.destination = dest;
            obj.responseRequired = respReq;
            obj.timeStarted = -1;
            obj.transmitterLocation = [nan,nan,nan];  %use this to say we don't have it
            obj.timeDelay = -1;  %use this to say we don't have it yet
            obj.IDsend = IDsend;
            obj.IDack = IDack;
            obj.data = data;
        end

        %> @brief set modulator for packet
        %> @param [in] obj - the packet object
        %> @param [in] modulator - the modulator for the packet
        %> @retval obj - the modified packet object
        function obj = setModulator(obj,modulator)
            obj.modulator = modulator;
        end
        
        %> @brief get packet data
        %> @param [in] obj - packet object
        %> @retval result - the packet data
        function result = getData(obj)
            result = obj.data;
        end

        %> @brief start packet transmission
        %> @param [in] obj - the packet object
        %> @param [in] time - time in seconds for start of packet
        %> [x,y,z] in meters
        %> @retval - modified packet object
        function obj = startPacket(obj,time)
            obj.timeStarted = time;
        end

        %> @brief set packet propagation time
        %> @param [in] obj - the packet object
        %> @param [in] delay - packet propagation time in seconds
        %> @retval - modified packet object
        function obj = setPacketDelay(obj,delay)
            obj.timeDelay = delay;
        end

        %> @brief get packet start time
        %> @param [in] obj - the packet object
        %> @retval result - start time in seconds
        function result = getPacketStart(obj)
            result = obj.timeStarted;
        end

        %> @brief get packet propagation time
        %> @param [in] obj - the packet object
        %> @retval result - propagation time in seconds
        function result = getPacketDelay(obj)
            result = obj.timeDelay;
        end

        %> @brief set packet signal level at receiver
        %> @param [in] obj - the packet object
        %> @param [in] level - power level in dB
        %> @retval obj - the object
        function obj = setSignalLevel(obj,level)
            obj.signalLevelAtReceiver = level;
        end

        %> @brief get packet signal level at receiver
        %> @param [in] obj - the packet object
        %> @retval result - signal level at the receiver in dB
        function result = getSignalLevel(obj)
            result = obj.signalLevelAtReceiver;
        end

        %> @brief get packet duration
        %> @param [in] obj - the packet object
        %> @retval result - duration in seconds
        function result = getPacketDuration(obj)
            result = obj.modulator.getPacketDuration;
        end
        
        %> @brief get packet modulator
        %> @param [in] obj - the packet object
        %> @retval result - modulator for packet (NOT a copy!)
        function result = getModulator(obj)
            result = obj.modulator;
        end

        %> @brief get packet destination node number
        %> @param [in] obj - the packet object
        %> @retval result - destination node number
        function result = getDestination(obj)
            result = obj.destination;
        end

        %> @brief get packet packet UID
        %> @param [in] obj - the packet object
        %> @retval result - packet UID
        function result = getIDsend(obj)
            result = obj.IDsend;
        end

        %> @brief get packet ACK required boolean
        %> @param [in] obj - the packet object
        %> @retval result - is ACK required?
        function result = getResponseRequired(obj)
            result = obj.responseRequired;
        end

        %> @brief get packet source node number
        %> @param [in] obj - the packet object
        %> @retval result - source node number
        function result = getSource(obj)
            result = obj.source;
        end

        %> @brief get packet UID for ACK
        %> @param [in] obj - the packet object
        %> @retval result - ACK UID
        function result = getIDack(obj)
            result = obj.IDack;
        end

        %> @brief set packet hop node number
        %> @param [in] obj - the packet object
        %> @param [in] hop - node number for the hop
        %> @retval obj - modified packet object
        function obj = setHop(obj,hop)
            obj.hop = hop;
        end

        %> @brief get packet hop node number
        %> @param [in] obj - the packet object
        %> @retval result - packet hop node number
        function result = getHop(obj)
            result = obj.hop;
        end

    end

   methods(Access = protected)
      %> @brief Override copyElement method:
      %> @param [in] obj - packet object to be copied
      %> @retval cpObj - copied object - important to NOT re-use modulator
      function cpObj = copyElement(obj)
         % Make a shallow copy of all four properties
         cpObj = copyElement@matlab.mixin.Copyable(obj);
         % Make a deep copy of the DeepCp object
         cpObj.modulator = copy(obj.modulator);
      end
   end


end