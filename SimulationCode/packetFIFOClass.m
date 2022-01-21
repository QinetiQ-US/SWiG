classdef packetFIFOClass < handle

    properties
        queue;
        front;
        back;
        maxNum;
    end

    methods
        function obj = packetFIFOClass(maxQueued)
            obj.maxNum = uint32(maxQueued);
            fakePacket = packetClass(SWIGModulator(false,false),0,1,false,0,0,randi(2,20,1)-1);
            obj.queue = repmat(fakePacket,maxQueued,1);
            obj.front = uint32(0);
            obj.back = uint32(0);
        end
        
        function obj = push(obj,packet)
            %see if we've overflowed
            if (obj.back - obj.front) >= obj.maxNum
                return;  %nope, we simply drop it
            else
                obj.back = obj.back + uint32(1);
                index = 1 + mod(obj.back,obj.maxNum);
                obj.queue(index) = copy(packet);
            end
        end

        function [message, obj] = pop(obj)
            if (obj.front >= obj.back)  %FIFO empty
                message=[];
            else
                index = 1 + mod(obj.front+1,obj.maxNum);
                message = copy(obj.queue(index));
                obj.front = obj.front + uint32(1);
            end
        end

        function result = head(obj)
            if obj.isEmpty
                result = [];
            else
                index = 1 + mod(obj.front+1,obj.maxNum);
                result = copy(obj.queue(index));
            end
        end

        function result = isEmpty(obj)
            result = (obj.front == obj.back);
        end
    end
end
