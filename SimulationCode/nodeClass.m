classdef nodeClass < handle

    %constants used to define state machine for FD <-> HD
    properties(Constant)
        FDHDidle = 0;
        FDHDwaitingAsHDnode = 1;
        FDHDwaitingAsFDnode = 2;
        FDHDactiveAsHDnode = 3;
        FDHDactiveAsFDnode = 4;
        FDHDchannelConfigMsgID = -3;  %special, special, special
    end

    properties
        modulators;
        activeModulator;
        ID;
        packetFIFOtoSend;
        packetDequeReceiving;
        storeAndForwardTable;
        meshRouteTable;
        sendingPacket;
        access;
        location;
        timeToCheckCSMA;
        waitingCSMA;
        packetDequeAwaitingAck;
        packetDequeRelayed;
        packetDequeAcked;
        ACKremovalAge;
        ACKrebroadcastTime;
        HSMessageList;
        completeListOfNodes;
        FDeventStructure;
    end

    methods
        function obj = nodeClass(location,modulators,ID,sendQueueDepth)
            obj.location = location;
            obj.storeAndForwardTable = [];
            obj.meshRouteTable = [];
            obj.ID = ID;
            obj.modulators = cell(size(modulators));
            for i = 1:length(modulators)
                obj.modulators{i}=copy(modulators{i});
            end
            obj.packetFIFOtoSend = packetFIFOClass(sendQueueDepth);
            obj.packetDequeReceiving = packetDequeClass(1024);
            obj.packetDequeAwaitingAck = packetDequeClass(1024);
            obj.packetDequeRelayed = packetDequeClass(1024);
            obj.packetDequeAcked = packetDequeClass(1024);
            obj.activeModulator = copy(obj.modulators{1});
            obj.sendingPacket = packetClass(obj.activeModulator,ID,ID,false,0,0,randi(2,10,1)-1);
            obj.timeToCheckCSMA = -1;
            obj.waitingCSMA = false;
            obj.ACKrebroadcastTime = 30;  %how long to wait to retry if no ACK
            obj.ACKremovalAge = 0.8 * obj.ACKrebroadcastTime;  %how long to wait after routed repeat to remove ACK request
            obj.FDeventStructure.state = obj.FDHDidle;  %nothing happening here
        end

        function result = getLocation(obj)
            result = obj.location;
        end

        function obj = setMeshRouteTable(obj,table)
            obj.meshRouteTable = table;
        end

        function obj = setStoreAndForwardTable(obj,storeAndForwardTable)
            obj.storeAndForwardTable = storeAndForwardTable;
        end

        function result = getDelay(obj,node)
            delta = obj.location - node.getLocation;
            result = norm(delta)/1500;
        end

        function obj = setBandwidthFraction(obj,fraction)
            obj.activeModulator.setBandwidthFraction(fraction);
        end

        function obj = setCenterFrequency(obj,centerFrequency)
            obj.activeModulator.setCenterFrequency(centerFrequency);
        end

        function result =getUnacknowledgeMessages(obj)
            result = obj.packetDequeAwaitingAck.packets;
        end

        function obj = handleReceivedFDConfigurationMessages(obj,packets)
            for i = 1:length(packets)
                packet = packets(i);
                if packet.getIDsend == obj.FDHDchannelConfigMsgID
                    %configure ourselves to reconfigure
                    msg = packet.getData;
                    obj.FDeventStructure.rememberedBandwidthFraction = obj.activeModulator.getBandwidthFraction;
                    obj.FDeventStructure.rememberedCenterFrequency = obj.activeModulator.getCenterFrequency;
                    obj.FDeventStructure.timeToStart = msg.timeToStart;
                    obj.FDeventStructure.timeToEnd = msg.timeToEnd;
                    obj.FDeventStructure.newFDcenterFrequency = msg.newFDcenterFrequency;
                    obj.FDeventStructure.newFDbandwidthFraction = msg.newFDbandwidthFraction;
                    obj.FDeventStructure.state = obj.FDHDwaitingAsFDnode;
                end
            end
        end

        function obj = handleFDConfigurationChanges(obj,time)
            switch obj.FDeventStructure.state
                case obj.FDHDwaitingAsFDnode  %FD node waiting, if it's time -> active, reconfigure new FD
                    if time >= obj.FDeventStructure.timeToStart
                        obj.activeModulator.setCenterFrequency(obj.FDeventStructure.newFDcenterFrequency);
                        obj.activeModulator.setBandwidthFraction(obj.FDeventStructure.newFDbandwidthFraction);
                        obj.FDeventStructure.state = obj.FDHDactiveAsFDnode;
                    end
                case obj.FDHDactiveAsFDnode  %FD node active, if done, recover
                    if time >= obj.FDeventStructure.timeToEnd
                        obj.activeModulator.setCenterFrequency(obj.FDeventStructure.rememberedCenterFrequency);
                        obj.activeModulator.setBandwidthFraction(obj.FDeventStructure.rememberedBandwidthFraction);
                        obj.FDeventStructure.state = obj.FDHDidle;
                    end
                case obj.FDHDwaitingAsHDnode  %HD node waiting, if its's time -> active, reconfigure, push messages
                    if time >= obj.FDeventStructure.timeToStart
                        obj.FDeventStructure.rememberedModulator = copy(obj.activeModulator);
                        obj.setModulator(obj.FDeventStructure.HDmodulatorIndex);
                        obj.setCenterFrequency(obj.FDeventStructure.HDCenterFrequency);
                        obj.setBandwidthFraction(obj.FDeventStructure.HDBandwidthFraction);
                        obj.FDeventStructure.state = obj.FDHDactiveAsHDnode;
                        for i = 1:length(obj.FDeventStructure.HDMessageList)
                            obj.pushPacketsToSend(obj.FDeventStructure.HDMessageList{i});
                        end
                    end
                case obj.FDHDactiveAsHDnode  %HD node active, if done, recover
                    if time >= obj.FDeventStructure.timeToEnd
                        obj.activeModulator = copy(obj.FDeventStructure.rememberedModulator);
                        obj.FDeventStructure.state = obj.FDHDidle;
                    end
            end
        end

        function result = isSending(obj,time)
            if obj.sendingPacket.getPacketStart < 0  %nope, not even trying
                result = false;
            else %we might!
                startTime = obj.sendingPacket.getPacketStart;
                endTime = startTime + obj.sendingPacket.getPacketDuration;
                if time >= startTime
                    %see if still sending or is past
                    if time <= endTime
                        result = true;
                    else
                        result = false;  %finished!
                        obj.sendingPacket.startPacket(-1);  %say we're not sending
                    end
                end
            end
        end

        function obj = addTransmittedPackets(obj,transmittedPackets,nodes)
            if ~isempty(transmittedPackets)
                for i = 1:length(transmittedPackets)
                    thePacket = transmittedPackets(i);
                    delay = obj.getDelay(nodes(i));
                    if (delay>1e-3)  %don't queue your own messages here
                        thePacket.setPacketDelay(delay);
                        obj.packetDequeReceiving.add(thePacket);
                    end
                end
            end
        end

        function obj = pushPacketsToSend(obj,packets)
            for i = 1:length(packets)
                packet=packets(i);
                packet.startPacket(-1);  %not ready to send yet
                obj.packetFIFOtoSend.push(packet);
            end
        end

        function obj = scheduleHDChannelEvent(obj,time,duration,fullNodeList,newFDcenterFrequency,...
                newFDbandwidthFraction,HDDestination,HDCenterFrequency,HDBandwidthFraction,HDmodulatorIndex,HDMessageList)
            obj.FDeventStructure.state = obj.FDHDwaitingAsHDnode;  %waiting to grab the channel
            obj.FDeventStructure.timeToStart = time + 2*obj.ACKrebroadcastTime +5;  %wait a long time before starting
            obj.FDeventStructure.timeToEnd = obj.FDeventStructure.timeToStart + duration;
            obj.FDeventStructure.fullNodeList = fullNodeList;
            obj.FDeventStructure.newFDcenterFrequency = newFDcenterFrequency;
            obj.FDeventStructure.newFDbandwidthFraction = newFDbandwidthFraction;
            obj.FDeventStructure.HDDestination = HDDestination;
            obj.FDeventStructure.HDCenterFrequency = HDCenterFrequency;
            obj.FDeventStructure.HDBandwidthFraction = HDBandwidthFraction;
            obj.FDeventStructure.HDmodulatorIndex = HDmodulatorIndex;
            obj.FDeventStructure.HDMessageList = HDMessageList;
            obj.FDeventStructure.messagesSent = false(size(HDMessageList));
            obj.FDeventStructure.ACKSreceived = false(size(fullNodeList));
            %create and queue the messages to change modes
            msg.source = obj.ID;
            msg.timeToStart = obj.FDeventStructure.timeToStart;
            msg.timeToEnd = obj.FDeventStructure.timeToEnd;
            msg.newFDcenterFrequency = obj.FDeventStructure.newFDcenterFrequency;
            msg.newFDbandwidthFraction = obj.FDeventStructure.newFDbandwidthFraction;
            for i=1:length(fullNodeList)
                %create packet (unless it's us)
                if (fullNodeList(i) ~= obj.ID)
                    pkt = packetClass(obj.activeModulator,obj.ID,fullNodeList(i),true,obj.FDHDchannelConfigMsgID,-1,msg);
                    obj.pushPacketsToSend(pkt);
                else
                    %we don't need an ACK, we're in charge
                    obj.FDeventStructure.ACKSreceived(i) = true;
                end
            end
        end

        function obj = forwardStoredAsNeeded(obj,receivedPackets,time)
            %first see if any of the previously relayed packets was long
            %enough ago that we can forget it
            [relayed,~,indices] = obj.packetDequeRelayed.packets;
            for i=1:length(relayed)
                delta = time - relayed(i).getPacketStart;
                %remove if more than 30 minutes stale
                if delta > obj.ACKremovalAge  %we will relay again if rebroadcast
                    obj.packetDequeRelayed.remove(indices(i));
                end
            end
            %now, see if we need to relay anything
            for i=1:length(receivedPackets)
                pkt=copy(receivedPackets(i));
                %only consider it if it is in the FD channel
                if pkt.getModulator.isHDModulator
                    continue;
                end
                %ignore if we already relayed
                relayed = obj.packetDequeRelayed.packets;
                alreadyRelayed = false;
                for j=1:length(relayed)
                    if pkt.getIDsend == relayed(j).getIDsend
                        alreadyRelayed = true;
                        break;
                    end
                end
                if ~alreadyRelayed
                    %if not to me, and not from me, but to someone on my routing list
                    to = pkt.getDestination;
                    from = pkt.getSource;
                    if (to ~= obj.ID) && (from ~= obj.ID)  %not me
                        %see if on my relay list
                        if any(to == obj.storeAndForwardTable)
                            %then queue this up for me to send as potential
                            %relay
                            pkt.startPacket(-1);
                            pkt.setPacketDelay(-1);
                            obj.pushPacketsToSend(pkt);
                            %and put into the queue to remember we relayed it
                            pkt.startPacket(time);
                            obj.packetDequeRelayed.add(pkt);
                        end
                    end
                end
            end
        end

        function obj = forwardMeshAsNeeded(obj,receivedPackets,time)
            %do nothing if we're not an infrastructure node
            if isempty(obj.meshRouteTable)
                return;
            end
            %first see if any of the previously relayed packets was long
            %enough ago that we can forget it
            [relayed,~,indices] = obj.packetDequeRelayed.packets;
            for i=1:length(relayed)
                delta = time - relayed(i).getPacketStart;
                %remove if  stale
                if delta > obj.ACKremovalAge  %we will relay again if rebroadcast
                    obj.packetDequeRelayed.remove(indices(i));
                end
            end
            %now, see if we need to relay anything
            for i=1:length(receivedPackets)
                pkt=copy(receivedPackets(i));
                %only consider it if it is in the FD channel
                if pkt.getModulator.isHDModulator
                    continue;
                end
                %ignore if we already relayed
                relayed = obj.packetDequeRelayed.packets;
                alreadyRelayed = false;
                for j=1:length(relayed)
                    if pkt.getIDsend == relayed(j).getIDsend
                        alreadyRelayed = true;
                        break;
                    end
                end
                if ~alreadyRelayed
                    %if it's a hop to me, or if it's from or two one of my
                    %clients, then relay
                    to = pkt.getDestination;
                    from = pkt.getSource;
                    if (to ~= obj.ID) && (from ~= obj.ID)  %not me so I can check to see about forwarding
                        %see if on my client list or is a hop to me, in
                        %which case we must forward appropriately
                        if any(from == obj.meshRouteTable.clientList)...
                                || pkt.getHop == obj.ID
                            %see if it's to another client
                            if any(to == obj.meshRouteTable.clientList)
                                %then send direct
                                pkt.setHop(to);
                            else
                                %hop it along
                                pkt.setHop(obj.meshRouteTable.nextHop);
                            end
                            pkt.startPacket(-1);
                            pkt.setPacketDelay(-1);
                            obj.pushPacketsToSend(pkt);
                            %and put into the queue to remember we relayed it
                            pkt.startPacket(time);
                            obj.packetDequeRelayed.add(pkt);
                        end
                    end
                end
            end
        end



        function obj = ACKasNeeded(obj, receivedPackets,time)
            %first see if any of the previously relayed packets was long
            %enough ago that we can forget it
            [acked,~,indices] = obj.packetDequeAcked.packets;
            for i=1:length(acked)
                delta = time - acked(i).getPacketStart;
                %remove if more stale
                if delta > obj.ACKremovalAge  %we will relay again if rebroadcast
                    obj.packetDequeAcked.remove(indices(i));
                end
            end
            %if any packet is sent to us and needs an ACK, cue up the ACK
            %IF we havent seen it in the last 50 seconds
            acked = obj.packetDequeAcked.packets;
            for i=1:length(receivedPackets)
                pack = copy(receivedPackets(i));
                if (pack.getDestination == obj.ID) && (pack.getResponseRequired)
                    packToGo = packetClass(obj.getModulator,obj.ID,pack.getSource,...
                        false,-1,pack.getIDsend,randi(2,10,1)-1);
                    %see if it's in our list
                    needToAck = true;
                    for j=1:length(acked)
                        if packToGo.getIDack == acked(j).getIDack
                            needToAck = false;
                            break;
                        end
                    end
                    if needToAck
                        obj.pushPacketsToSend(packToGo);
                        packToRemember = copy(packToGo);
                        packToRemember.startPacket(time);
                        obj.packetDequeAcked.add(packToRemember);
                    end
                end
            end
        end

        function [localSendingPacket, obj] = sendAsNeeded(obj, time, amReceiving)
            %now, see if we have something to send
            if obj.packetFIFOtoSend.isEmpty || obj.isSending(time)
                localSendingPacket = [];
                obj.waitingCSMA = false;
                obj.timeToCheckCSMA = -1;
                return;
            end
            %okay, we've got something to say. Let's see if we're able
            allowedToSend = true;  %default for non-full-duplex, non-CSMA
            %if full duplex, go right ahead as long as you're not already
            %sending
            if obj.activeModulator.getDuplex
                if obj.isSending(time)
                    allowedToSend = false;
                else
                    allowedToSend = true;
                end
            else
                if obj.activeModulator.getCSMA
                    if amReceiving
                        allowedToSend = false;
                        if obj.waitingCSMA
                            if time > obj.timeToCheckCSMA
                                obj.timeToCheckCSMA = time +rand(1)*5;
                            end
                        else
                            obj.waitingCSMA = true;
                            obj.timeToCheckCSMA = time + rand(1)*5;  %wait a random time to check
                        end
                    else
                        if obj.waitingCSMA
                            if time > obj.timeToCheckCSMA
                                obj.waitingCSMA = false;
                                obj.timeToCheckCSMA = -1;
                                allowedToSend = true;
                            else
                                allowedToSend = false;
                            end
                        else
                            allowedToSend = true;
                        end
                    end
                end
            end
            if allowedToSend
                obj.sendingPacket = obj.packetFIFOtoSend.pop;
                %and change its modulator to current one
                obj.sendingPacket.setModulator(copy(obj.activeModulator));
                obj.sendingPacket.startPacket(time);
                localSendingPacket = copy(obj.sendingPacket);
                %if this requires response, queue it for potential
                %retransmission IF WE ARE NOT RELAYING IT
                if (obj.sendingPacket.getResponseRequired && obj.sendingPacket.getSource == obj.ID)
                    obj.packetDequeAwaitingAck.add(localSendingPacket);
                end
            else
                localSendingPacket = [];
            end
        end

        function obj = handleTimedOutACKS(obj,time)
            [packetsNeedingAck, ~, indices] = obj.packetDequeAwaitingAck.packets;
            %now, see if there are any ancient packets awaiting ack
            %if so, re-send them and reset their times to now so we don't
            %keep resending
            tooLong = obj.ACKrebroadcastTime;  %If it's been this long, we need to request new ACK
            for i=1:length(packetsNeedingAck)
                pack = copy(packetsNeedingAck(i));
                index = indices(i);
                if time > (pack.getPacketStart + tooLong)
                    %queue packet for re-transmission
                    packToSend = copy(pack);
                    packToSend = packToSend.startPacket(-1);
                    obj.pushPacketsToSend(packToSend);
                    %remove the message awaiting ACK - it will be re-queued
                    %on sending
                    obj.packetDequeAwaitingAck.remove(index);
                end
            end
        end

        function obj = handleReceivedACKS(obj,receivedPackets)
            %first, see if we can pull any ACK required packets from the
            %deque
            [packetsNeedingAck, ~, indices] = obj.packetDequeAwaitingAck.packets;
            if ~isempty(packetsNeedingAck)
                for i = 1:length(receivedPackets)
                    pack = receivedPackets(i);
                    ackID = pack.getIDack;
                    if (pack.getDestination == obj.ID) && (ackID ~= -1)
                        %it's for us and it's an ACK
                        %see if we find the original in our deque
                        for j=1:length(packetsNeedingAck)
                            if ackID == packetsNeedingAck(j).getIDsend
                                %yay - it's been acked. remove it
                                obj.packetDequeAwaitingAck.remove(indices(j));
                            end
                        end
                    end
                end
            end
        end

        function [receivedPackets,localSendingPacket,obj] = run(obj,time)
            %first, do the easy thing and go handle receiving
            [receivedPackets, amReceiving] = obj.receivingPackets(time);
            obj.handleTimedOutACKS(time);
            obj.handleReceivedACKS(receivedPackets);
            obj.ACKasNeeded(receivedPackets,time);
            obj.forwardStoredAsNeeded(receivedPackets,time);
            obj.forwardMeshAsNeeded(receivedPackets,time);
            obj.handleReceivedFDConfigurationMessages(receivedPackets);
            obj.handleFDConfigurationChanges(time);
            localSendingPacket = obj.sendAsNeeded(time,amReceiving);
        end

        function [goodPackets, receiving, obj] = receivingPackets(obj,time)
            %assume not receiving
            receiving = false;
            [packets, validities, indices] = obj.packetDequeReceiving.packets;
            finished = validities;
            if isempty(packets)
                goodPackets = [];
                receiving = false;
                return;
            end
            %go through the list and see which ones are in process
            %also note those that are complete, and dequeue them
            inProcess = false(length(validities),1);
            for i = 1:length(inProcess)
                startTime = packets(i).getPacketStart + ...
                    packets(i).getPacketDelay;
                endTime = startTime + packets(i).getPacketDuration;
                finished(i) = false;
                if time >= startTime
                    %see if still sending or is past
                    if time <= endTime
                        inProcess(i) = true;
                    else
                        inProcess(i) = false;  %finished!
                        finished(i) = true;  % packet completed
                        %and dequeue
                        obj.packetDequeReceiving.remove(indices(i));
                    end
                end
            end
            packetsOfInterest = inProcess | finished;
            if ~isempty(packetsOfInterest)
                receiving = true;
            end
            packets = packets(packetsOfInterest);
            validities = validities(packetsOfInterest);
            finished = finished(packetsOfInterest);
            indices=indices(packetsOfInterest);
            validities = obj.validatePackets(packets,validities,finished,time);
            %invalidate all bad packets that are incomplete
            whichIndices = indices(~validities & ~finished);
            for i = 1:length(whichIndices)
                obj.packetDequeReceiving.invalidate(whichIndices(i));
            end
            goodPackets = packets(finished & validities);
            %finally, see if the physical layer failed us
            successes = false(length(goodPackets),1);
            for i=1:length(goodPackets)
                successes(i) = goodPackets(i).getModulator.packetValid(goodPackets(i).getPacketDelay);
            end
            %finally, only return the successful packets
            goodPackets = goodPackets(successes);
        end

        function result = getModulator(obj)
            result = obj.activeModulator;
        end

        function obj = setModulator(obj,index)
            obj.activeModulator = copy(obj.modulators{index});
        end

        function validities = validatePackets(obj,packets, validities, finished, time)
            if isempty(packets)
                return;
            end
            %we do not invalidate packets that are finished, since we're
            %looking for in-process
            %first - see if we have too much interference
            if obj.activeModulator.getDuplex && obj.isSending(time)  %full duplex and sending
                baseInterference = 10^(-0.1*obj.activeModulator.selfCancellationIn_dB);  %power
            else
                baseInterference = 0;
            end
            %now, for each unfinished packet, go compute the interference
            unfinishedPackets = find(~finished);
            for i = 1:length(unfinishedPackets)
                thisPacket=packets(unfinishedPackets(i));
                signal = 10^(-0.1*thisPacket.getModulator.attenuation(...
                    thisPacket.getPacketDelay));
                interference = baseInterference;
                for j = 1:length(unfinishedPackets)
                    if (i ~= j) %packet can't interfere with itself
                        thatPacket = packets(unfinishedPackets(j));
                        interferenceFraction = thisPacket.getModulator.getBandOverlapFraction(thatPacket.getModulator);
                        interference = interference + 10^(-0.1*thatPacket.getModulator.attenuation(...
                            thatPacket.getPacketDelay))*interferenceFraction;
                    end
                end
                if interference > 0 %don't invalidate for interference if there is none
                    interferenceFraction = 10*log10(interference/signal);
                    if interferenceFraction >= packets(unfinishedPackets(i)).getModulator.getMaxInterferenceIn_dB
                        validities(unfinishedPackets(i)) = false;
                    end
                end
            end

            %second, see if we are transmitting anything while receiving
            %(unless full-duplex)
            if ~obj.activeModulator.getDuplex
                if obj.isSending(time)
                    validities(~finished) = false;
                end
            end

            %finally, see if there is a collision of preambles
            for i=1:length(packets)
                pmodulator = packets(i).getModulator;
                if pmodulator.isPreambleCollisionFatal
                    for j=i:length(packets)
                        if (i ~= j)
                            startOfPreamble1 = packets(i).getPacketStart + ...
                                packets(i).getPacketDelay;
                            endOfPreamble1 = startOfPreamble1 + ...
                                pmodulator.getPreambleDuration;
                            startOfPreamble2 = packets(j).getPacketStart + ...
                                packets(j).getPacketDelay;
                            endOfPreamble2 = startOfPreamble2 + ...
                                pmodulator.getPreambleDuration;
                            maxStart = max(startOfPreamble1,startOfPreamble2);
                            minEnd = min(endOfPreamble1,endOfPreamble2);
                            if maxStart <= minEnd  %we have some overlap
                                validities(i) = false;
                            end
                        end
                    end
                end
            end
        end

    end
end