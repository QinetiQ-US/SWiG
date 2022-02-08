%> @brief FIFO class for nodes
classdef packetFIFOClass < handle

    properties
        %> circular array of packets
        queue;
        %> index for front of circular buffer
        front;
        %> index for back of circular buffer
        back;
        %> length of circular buffer
        maxNum;
    end

    methods
        %> @brief packetFIFOClass constructor
        %> @param [in] maxQueued length of circular buffer
        function obj = packetFIFOClass(maxQueued)
            obj.maxNum = uint32(maxQueued);
            fakePacket = packetClass(SWIGModulator(false,false),0,1,false,0,0,randi(2,20,1)-1);
            obj.queue = repmat(fakePacket,maxQueued,1);
            obj.front = uint32(0);
            obj.back = uint32(0);
        end
        
        %> @brief push function for FIFO
        %> @param [in] obj - the FIFO object
        %> @param [in] packet - the packet to be pushed
        %> @retval obj - the modified FIFO object
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

        %> @brief pop a packet off the FIFO
        %> @param [in] obj - the FIFO object
        %> @retval message - the first out message ([] if FIFO empty)
        %> @retval obj - the modified FIFO object
        function [message, obj] = pop(obj)
            if (obj.front >= obj.back)  %FIFO empty
                message=[];
            else
                index = 1 + mod(obj.front+1,obj.maxNum);
                message = copy(obj.queue(index));
                obj.front = obj.front + uint32(1);
            end
        end

        %> @brief oldest packet in FIFO
        %> @param [in] obj - the FIFO object
        %> @retval result - the oldest packet ([] if FIFO empty)
        function result = head(obj)
            if obj.isEmpty
                result = [];
            else
                index = 1 + mod(obj.front+1,obj.maxNum);
                result = copy(obj.queue(index));
            end
        end

        %> @brief is the FIFO empty?
        %> @param [in] obj - the FIFO object
        %> @retval result - true if the FIFO empty, otherwise false
        function result = isEmpty(obj)
            result = (obj.front == obj.back);
        end
    end
end
