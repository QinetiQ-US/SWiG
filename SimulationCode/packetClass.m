classdef packetClass < matlab.mixin.Copyable
    %packet class

    properties
        modulator;
        source;
        hop;
        destination;
        responseRequired;
        timeStarted;
        timeDelay;
        IDsend;
        IDack;
        data;
        hCRC;
    end

    methods
        function obj = packetClass(mod,src,dest,respReq,IDsend,IDack,data)
            obj.modulator = copy(mod);
            obj.source = src;
            obj.hop = dest;
            obj.destination = dest;
            obj.responseRequired = respReq;
            obj.timeStarted = -1;
            obj.timeDelay = -1;
            obj.IDsend = IDsend;
            obj.IDack = IDack;
            obj.data = data;
        end

        function obj = setModulator(obj,modulator)
            obj.modulator = modulator;
        end
        
        function result = getData(obj)
            result = obj.data;
        end
        function obj = startPacket(obj,time)
            obj.timeStarted = time;
        end
        function obj = setPacketDelay(obj,delay)
            obj.timeDelay = delay;
        end
        function result = getPacketStart(obj)
            result = obj.timeStarted;
        end
        function result = getPacketDelay(obj)
            result = obj.timeDelay;
        end
        function result = getPacketDuration(obj)
            result = obj.modulator.getPacketDuration;
        end
        function result = getModulator(obj)
            result = obj.modulator;
        end

        function result = getDestination(obj)
            result = obj.destination;
        end

        function result = getIDsend(obj)
            result = obj.IDsend;
        end

        function result = getResponseRequired(obj)
            result = obj.responseRequired;
        end

        function result = getSource(obj)
            result = obj.source;
        end

        function result = getIDack(obj)
            result = obj.IDack;
        end

        function obj = setHop(obj,hop)
            obj.hop = hop;
        end

        function result = getHop(obj)
            result = obj.hop;
        end

    end

   methods(Access = protected)
      % Override copyElement method:
      function cpObj = copyElement(obj)
         % Make a shallow copy of all four properties
         cpObj = copyElement@matlab.mixin.Copyable(obj);
         % Make a deep copy of the DeepCp object
         cpObj.modulator = copy(obj.modulator);
      end
   end


end