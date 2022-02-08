%> @brief deque class for packets
%> also holds information whether packet is valid
classdef packetDequeClass < handle

    properties
        %> array of packets - can grow as needed
        queue;
        %> boolean array indicating if a packet as at a location
        occupied;
        %> boolean array indicating if packet is valid
        valid;
    end

    methods
        %> @brief constructor for packet deque
        %> @param [in] maxQueued - initital size of deque, can grow if
        %> needed
        function obj = packetDequeClass(maxQueued)

            obj.occupied = false(maxQueued,1);
            obj.valid = obj.occupied;
            fakePacket = packetClass(SWIGModulator(false,false),0,1,false,0,0,randi(2,10,1)-1);
            obj.queue = repmat(fakePacket,maxQueued,1);
        end

        %> @brief add a packet to the deque - packet marked as valid
        %> @param [in] obj - the deque object
        %> @param [in] packet - the packet to add
        %> @retval index - the index in the deque where the packet was
        %>added
        %> @retval obj - the modified deque
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

        %> @brief mark a packet as invalid
        %> @param [in] obj - the deque object
        %> @param [in] index - the index into the deque for the packet
        %> @retval obj - the modified deque object
        function obj = invalidate(obj,index)
            if obj.occupied(index)
                obj.valid(index) = false;
            end
        end

        %> @brief remove a packet from the deque
        %> @param [in] obj - the deque object
        %> @param [in] index - location of packet in deque
        %> @retval obj - the modified deque object
        function obj = remove(obj, index)
            if (index <= length(obj.occupied))
                obj.occupied(index) = false;
            end
        end

        %> @brief the full list of packets in the deque
        %> @param [in] obj - the deque object
        %> @retval packets - array of packets in the object
        %> @retval validies - array of booleans for validity of packets
        %> retval indices - indices within the deque where packets reside
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
