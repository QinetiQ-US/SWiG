classdef packetDequeClass < handle

    properties
        queue;
        occupied;
        valid;
    end

    methods
        function obj = packetDequeClass(maxQueued)

            obj.occupied = false(maxQueued,1);
            obj.valid = obj.occupied;
            fakePacket = packetClass(SWIGModulator(false,false),0,1,false,0,0,randi(2,10,1)-1);
            obj.queue = repmat(fakePacket,maxQueued,1);
        end
        function [index, obj] = add(obj,packet)
            cpacket = copy(packet);  %make a copy, do not use by reference
            %see if any room
            if (all(obj.occupied))
                %if not, extend the object
                obj.occupied = [obj.occupied;true];
                obj.queue = [obj.queue;cpacket];
                obj.valid = [obj.valid; true];
                index = length(obj.occupied);
            else
                index = find(~obj.occupied,1,'first');
                obj.queue(index) = cpacket;
                obj.occupied(index) = true;
                obj.valid(index) = true;
            end
        end
        function obj = invalidate(obj,index)
            if obj.occupied(index)
                obj.valid(index) = false;
            end
        end
        function obj = remove(obj, index)
            if (index <= length(obj.occupied))
                obj.occupied(index) = false;
            end
        end
        function [packets, validities, indices] = packets(obj)
            packets = [];
            validities = [];
            indices = find(obj.occupied);
            if ~isempty(indices)
                packets = copy(obj.queue(obj.occupied));
                validities = obj.valid(obj.occupied);
            end
        end
    end
end
