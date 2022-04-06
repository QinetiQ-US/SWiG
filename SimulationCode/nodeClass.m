%> @brief node class
%> @details class characterizing a modulator/demodulator with logic for
%> transmitting, receiving, routing, scheduling transitions between FD/HD,
%> validating packets, etc.
classdef nodeClass < handle

    %constants used to define state machine for FD <-> HD
    properties(Constant)
        %> constant used to define state machine for FD <-> HD - idle
        FDHDidle = 0;
        %> constant used to define state machine for FD <-> HD - waiting as
        %> HD node
        FDHDwaitingAsHDnode = 1;
        %> constant used to define state machine for FD <-> HD - waiting as
        %> HD node
        FDHDwaitingAsFDnode = 2;
        %> constant used to define state machine for FD <-> HD - actively
        %> running as HD
        FDHDactiveAsHDnode = 3;
        %> constant used to define state machine for FD <-> HD - actively
        %> running ad FD node
        FDHDactiveAsFDnode = 4;
        %> constant used to define state machine for FD <-> HD - handling
        %> configuration message
        FDHDchannelConfigMsgID = -3;  %special, special, special
    end

    properties
        %> array of modulators for the node
        modulators;
        %> index of selected modulator
        activeModulator;
        %> channel model for use in decoding
        channelModel;
        %> ID number for this node
        ID;
        %> FIFO of packets to send
        packetFIFOtoSend;
        %> Deque of packets we are actively receiving
        packetDequeReceiving;
        %> Array with a store and forward table
        storeAndForwardTable;
        %> Array with a mesh routing table
        meshRouteTable;
        %> packet object we are currently sending
        sendingPacket;
        %>  3 x 1 (x,y,z) location of node in meters
        location;
        %> time to next check to see if carrier present for CSMA
        timeToCheckCSMA;
        %> bool indicating we are in wait for free carrier for CSMA
        waitingCSMA;
        %> deque of packets that are awaiting an ACK (so as not to
        %> rebroadcast)
        packetDequeAwaitingAck;
        %> deque of packets that have been relayed (so as not to
        %> rebroadcast)
        packetDequeRelayed;
        %> deque of packets that have been ACKED (so as not to rebroadcast)
        packetDequeAcked;
        %> array of times when we remove ACK information
        ACKremovalAge;
        %> array of times when we will rebroadcast if no ACK received
        ACKrebroadcastTime;
        %> full list of node numbers we have discovered
        completeListOfNodes;
        %> structure containing configuration information for FD/HD
        %>events.  Elements:<br>
        %>rememberedBandwidthFraction <br>
        %> rememberedCenterFrequency<br>
        %> timeToStar<br>
        %> timeToEnd<br>
        %> newFDcenterFrequency<br>
        %> newFDbandwidthFraction<br>
        %> state<br>
        FDeventStructure;
    end

    methods
        %> @brief nodeClass constructor
        %> @param [in] location - 3x1 (x,y,z) location of node in meters OR
        %> 4xn (t,x,y,z) trajectory, with t in seconds
        %> @param [in] modulators - cell array of modulator objects
        %> supported by this node
        %> @param [in] ID - integer ID number for this node
        %> @param [in] sendQueueDepth - number of elements for sending FIFO
        %> @param [in] ourChannelModel - the channel model-derived object
        %> for our propagation and noise model
        function obj = nodeClass(location,modulators,ID,sendQueueDepth,ourChannelModel)
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
            if nargin < 5
                ourChannelModel = reliableAcousticPathModel;
            end
            obj.channelModel = copy(ourChannelModel);
        end

        %> @brief get location of node
        %> @param [in] obj - node object
        %> @param [in] time - time to determine location
        %> @retval result - 3 x1 location of node
        function result = getLocation(obj, time)
            if nargin < 2
                time = 0;
            end
            if size(obj.location) < 4
                result = obj.location;
            else
                times = obj.location(:,1);
                xyzs = obj.location(:,2:4);
                myxyz = interp1(times,xyzs,time,"linear","extrap");
                result=myxyz;
            end
        end

        %> @brief set mesh routing table for node
        %> @param [in] obj - the node object
        %> @param [in] table - a routing table array
        %> @retval obj - modified node object
        function obj = setMeshRouteTable(obj,table)
            obj.meshRouteTable = table;
        end

        %> @brief set store and forward table for node
        %> @param [in] obj - the node object
        %> @param [in] storeAndForwardTable - a store and forward table array
        %> @retval obj - modified node object
        function obj = setStoreAndForwardTable(obj,storeAndForwardTable)
            obj.storeAndForwardTable = storeAndForwardTable;
        end

        %> @brief set bandwidth fraction of active modulator
        %> @param [in] obj - the node object
        %> @param [in] fraction - the bandwidth fraction to set
        %> @retval obj - modified node object
        function obj = setBandwidthFraction(obj,fraction)
            obj.activeModulator.setBandwidthFraction(fraction);
        end

        %> @brief set center frequency for active modulator
        %> @param [in] obj - the node object
        %> @param [in] centerFrequency - the new center frequency in Hz
        %> @retval obj - modifie node object
        function obj = setCenterFrequency(obj,centerFrequency)
            obj.activeModulator.setCenterFrequency(centerFrequency);
        end

        %> @brief get list of messages still awaiting ACK
        %> @param [in] obj - the node object
        %> @retval result - array of packets still awaiting ACK
        function result =getUnacknowledgeMessages(obj)
            result = obj.packetDequeAwaitingAck.packets;
        end

        %> @brief handle received FD/HD configuration messages
        %> @details If configuration message, and it's for us, set the
        %> event structure
        %> @param [in] obj - the node object
        %> @param [in] packets - array of packets containging config
        %> messages
        %> @retval obj - modified node object with updated event structure
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

        %> @brief handle FD/HD configuration changes
        %> @details - state machine for changing modulators, bandwidths,
        %> center frequencies, HD/FD channel mode based on configuration
        %> structure and present time
        %> @param [in] obj - node object
        %> @param [in] time - present time in seconds
        %> @retval modified node object
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

        %> @brief Am I sending right now?
        %> @param [in] obj - the node object
        %> @param [in] time - present time in seconds
        %> @retval result - boolean: am I sending?
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

        %> @brief add packets transmitted from other nodes to our receiving
        %>Deque
        %> @param [in] obj - this node object
        %> @param [in] transmittedPackets - array of packets transmitted by
        %> other nodes (ALL nodes, so we can compute interference)
        %> @param [in] nodes - array of nodes transmitting those packets,
        %> used to compute delay, attenuation and probability of success
        %> @param [in] time - time of added packet
        function obj = addTransmittedPackets(obj,transmittedPackets,nodes,time)
            if ~isempty(transmittedPackets)
                rxLocation = obj.getLocation(time);
                for i = 1:length(transmittedPackets)
                    thePacket = copy(transmittedPackets(i));
                    txLocation = nodes(i).getLocation(time);
                    if thePacket.getSource() ~= obj.ID  %don't queue your own messages here
                        %go run the channel model to get transmission loss,
                        %delay
                        f = thePacket.getModulator.getCenterFrequency();
                        [tl, delay] = obj.channelModel.transmissionLoss(txLocation,rxLocation,f);
                        thePacket.setPacketDelay(delay);
                        signalLevel = thePacket.getModulator.getSignalPower() - tl;
                        thePacket.setSignalLevel(signalLevel);
                        obj.packetDequeReceiving.add(thePacket);
                    end
                end
            end
        end

        %> @brief Add packets to our outbound packet FIFO
        %> @param [in] obj - the node object
        %> @param [in] packets - array of packet objects to send
        %> @retval obj - modified node object
        function obj = pushPacketsToSend(obj,packets)
            for i = 1:length(packets)
                packet=packets(i);
                packet.startPacket(-1);  %not ready to send yet
                obj.packetFIFOtoSend.push(packet);
            end
        end

        %> @brief schedule an HD channel event
        %> @details Call this for the node that will be the HD transmitter.
        %> This will send messages to all nodes - telling them time to
        %> reconfigure for use of HD channel, duration of time for use of
        %> HD channel, new center frequency for FD channel, new bandwidth
        %> fraction for FD channel, center frequency for HD channel,
        %> bandwidth fraction for HD channel, index into the modulator
        %> array for the HD modulator, and an array of packets that will be
        %> sent by the HD transmitting node. Directly sets the event
        %> structure for the HD transmitting node, pushes messages to
        %> reconfigure to all other nodes, with ACK required for all nodes
        %> @param [in] obj - the node object for scheduling
        %> @param [in] time - time in seconds for the HD event to begin
        %> @param [in] duration - duration in seconds for use of HD
        %> @param [in] fullNodeList - list of integer node IDs for whole
        %> network requiring configuration
        %> @param [in] newFDcenterFrequency - new center frequency for FD
        %> operation during HDin Hz
        %> @param[in] newFDbandwidthFraction - new fractional bandwidth for
        %> FD operation during HD
        %> @param [in] HDDestination - destination node number for HD
        %> @param [in] HDCenterFrequency - center frequency in Hz for HD
        %> modulator
        %> @param [in] HDBandwidthFraction - fractional bandwidth for HD
        %> modulator
        %> @param [in] HDmodulatorIndex - integer index in array of
        %> modulators for HD operation
        %> @param [in] HDMessageList - array of packets to be transmitted
        %> @retval obj - modified node object
        function obj = scheduleHDChannelEvent(obj,time,duration,fullNodeList,newFDcenterFrequency,...
                newFDbandwidthFraction,HDDestination,HDCenterFrequency,HDBandwidthFraction,HDmodulatorIndex,HDMessageList)
            obj.FDeventStructure.state = obj.FDHDwaitingAsHDnode;  %waiting to grab the channel
            obj.FDeventStructure.timeToStart = time; %
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

        %> @brief forward any packets if we are a forwarding node
        %> @param [in] obj - the node object
        %> @param [in] receivedPackets - array of all received packets
        %> @param [in] time - present time in seconds
        %> @retval obj - modified node object
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

        %> @brief forward any packets we need to if we are a mesh server
        %> @param [in] obj - the node object
        %> @param [in] receivedPackets - array of all received packets
        %> @param [in] time - present time in seconds
        %> @retval obj - modified node object
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


        %> @brief queue ACK messages for any critical received messages
        %> @param [in] obj - node object
        %> @param [in] receivedPackets - array of all received packets
        %> @param [in] time - present time in seconds
        %> @retval obj - modified node object
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

        %> @brief send any packets as needed
        %> @details Looks into FIFO of packets needing to be sent. Looks to
        %> see if allowed to send (i.e. the CSMA state machine, or if we
        %> are already sending), then proceeds to send earliest packet
        %> queued - if permitted
        %> @param [in] obj - the node object
        %> @param [in] time - present time in seconds
        %> @param [in] amReceiving - boolean indicating if carrier sensed
        %> @retval localSendingPacket - a packet object for present packet,
        %> if sending, empty otherwise
        %> @retval obj - modified node object
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

        %> @brief handle timed-out critical messages
        %> @details Looks to see if we sent any messages requiring ACK, for
        %> which we have still not received an ACK. If too long, re-send
        %> the message in an attempt to force an ACK from destination
        %> @param [in] obj - the node object
        %> @param [in] time - present time in seconds
        %> @retval obj - modified node object
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

        %> @brief oprate a node
        %> @details Checks for any packets being received, looks tor any
        %> critical messages we sent that still haven't been ACKed, handles
        %> any received ACKs, forwards any packets queued if we are a
        %> store-and-forward node, forwards any packets if we are a mesh
        %> server node, handles any received configuration messages, runs
        %> the configuration state machine, works on sending packets
        %> @param [in] obj - the node object
        %> @param [in] time - present time in seconds
        %> @retval receivedPackets - array of any completed received
        %> packets (valid only)
        %> @retval localSendingPacket - packet we're sending now (empty
        %> otherwise)
        %> @retval obj - modified node object
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

        %> @brief receive packets - check to see if valid
        %> @param [in] obj - the node object
        %> @param [in] time - present time in seconds
        %> @retval goodPackets - array of packets that have been validated
        %> @retval receiving - boolean if message arriving now
        %> @retval obj - the node object
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
        end

        %> @brief get active modulator (object NOT a copy)
        %> @param [in] obj - the node object
        %> @retval result - the active modulator object
        function result = getModulator(obj)
            result = obj.activeModulator;
        end

        %> @brief set the active modulator
        %> @param [in] obj - the node object
        %> @param [in] index - the index of the modulator to make active
        %> @retval obj - modifie node object
        function obj = setModulator(obj,index)
            obj.activeModulator = copy(obj.modulators{index});
        end

        %> @brief validate packets
        %> @details Compute base interference (0 if not transmitting, or
        %> residual un-self-cancelled if transmitting), then external
        %> interference from other sources based on distance, spectral
        %> overlap and temporal overlap. Finally, ask the modulator of
        %> origin about invalidation due to standard probability of failure
        %> @param [in] obj - the node object
        %> @param [in] packets - array of packets in receive process
        %> @param [in,out] validities - boolean array of packets, false
        %> elements indicate packet previously invalidated
        %> @param [in] finished - boolean array indicating whether packet
        %> has finished arriving
        %> @param [in] time - present time in seconds
        %> @retval validities - boolian array indicating which packets have
        %> been invalidated so far (marked with fals)
        function validities = validatePackets(obj,packets, validities, finished, time)
            if isempty(packets)
                return;
            end
            %we do not invalidate packets that are finished, since we're
            %looking for in-process
            %first - see if we have too much interference
            if obj.activeModulator.getDuplex && obj.isSending(time)  %full duplex and sending
                baseInterference = 10^(0.1*(obj.activeModulator.getSignalPower - obj.activeModulator.selfCancellationIn_dB));  %power
            else
                baseInterference = 0;
            end
            %now, for each unfinished packet, go compute the interference
            unfinishedPackets = find(~finished);
            for i = 1:length(unfinishedPackets)
                thisPacket=packets(unfinishedPackets(i));
                signalin_dB = thisPacket.getSignalLevel;
                interference = baseInterference;
                startTime = thisPacket.getPacketStart + ...
                    thisPacket.getPacketDelay;
                endTime = startTime + thisPacket.getPacketDuration;
                for j = 1:length(unfinishedPackets)
                    if (i ~= j) %packet can't interfere with itself
                        thatPacket = packets(unfinishedPackets(j));
                        startThat = thatPacket.getPacketStart + thatPacket.getPacketDelay;
                        endThat = startThat + thatPacket.getPacketDuration;
                        overlapFraction = (min(endThat,endTime)-max(startThat,startTime))/thisPacket.getPacketDuration;
                        if overlapFraction<0
                            overlapFraction = 0;
                        end
                        interferenceFraction = thisPacket.getModulator.getBandOverlapFraction(thatPacket.getModulator);
                        interference = interference + (10^(0.1*thatPacket.getSignalLevel))*interferenceFraction*overlapFraction;
                    end
                end
                %now, reduce interference by the interference rejection for
                %this modulator
                interference = interference * 10^(-0.1*packets(unfinishedPackets(i)).getModulator.getInterferenceMitigation);
                %convert interference to PSD
                BW = packets(unfinishedPackets(i)).getModulator.getBandwidth;
                interferencePSD = interference/BW;
                %go get noise level
                f = packets(unfinishedPackets(i)).getModulator.getCenterFrequency;
                noiseLevel = 10^(0.1*obj.channelModel.noiseLevel(f));
                noisePlusInterference = noiseLevel + interferencePSD;
                N0 =10*log10(noisePlusInterference);
                bitrate = packets(unfinishedPackets(i)).getModulator.getBandwidthFraction*...
                    packets(unfinishedPackets(i)).getModulator.topBitrate;
                bitTime = 1/bitrate;
                EbOverN0 = 10*log10(bitTime)+signalin_dB-N0;
                if EbOverN0 < packets(unfinishedPackets(i)).getModulator.EbOverN0Required
                        validities(unfinishedPackets(i)) = false;
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