function [sentPacketInfo,receivedPacketInfo] = runSimulationWithHDFDchangeover(nodes,timeToRun,...
    timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded,sendHDnodeNumber,receiveHDnodeNumber,...
    timeToDoHD, durationForHD, messagesForHD,modulatorForHD)
% function [sentPacketInfo,receivedPacketInfo] = runSimulation(nodes,timeToRun,...
%     timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded)
%run a simulation of a network
%nodes is an array of nodeClass, pre-set with modulators and routing table
%timeToRun          how long in simulated seconds to run the network
%timeToFinish       how long before the end to turn off queueing new messages
%                       to allow ACKs to settle out
%timeIncrement      how many seconds to increment clock for simulation
%poissonSendInterval    lambda for Poisson decision process on queueing new
%                           messages (per node) in seconds
%pAckNeeded             fraction of messages that will require ACK (again
%                           Poisson, but on queued messages


%figure out if FD modulator is SWiG or DSSS
baseModulator = nodes{1}.getModulator;
type = baseModulator.getModulatorType;
style = type.style;
if ~contains(style,'SW')
    %DSSS
    FcenterSlow = 14e3;
    BWSlow = 0.9;
else
    %SWiG either primitive or other
    FcenterSlow = 18795;
    BWSlow = 0.25;
end


receivedPacketInfo = [];
sentPacketInfo =[];
msgNum = 0;
lastSendTime = timeToRun - timeToFinish;
numNodes = length(nodes);
rng(0); %make sure you can repeat this

%schedule the changeover
%begin by making the list for packets
HDMessageList = cell(length(messagesForHD),1);
HDID = 100000;  %start high so we can go from there
for i=1:length(HDMessageList)
    msgData = messagesForHD{i};
    HDMessageList{i} = packetClass(nodes{sendHDnodeNumber}.getModulator,sendHDnodeNumber,receiveHDnodeNumber,0,HDID,-1,msgData);
    %add to sentPacketInfo
    sentPacketInfo = [sentPacketInfo;[HDID 0 timeToDoHD modulatorForHD length(msgData) 1.0]];
    HDID = HDID + 1;
end
holdoffInterval = [timeToDoHD-10 timeToDoHD+durationForHD+10];  %don't do any messaging in FD on HD tx/rx channels during this time

HDchannelTriggered = false;

%tick off every 5 minutes
tPrint = -1;
for time = 0:timeIncrement:timeToRun
    if time >= tPrint
        fprintf(1,'Running, time = %d seconds\n',round(time));
        tPrint = time + 299.99;
    end
    %trigger off the node that will be doing HD
    if ~HDchannelTriggered && time > timeToDoHD - 120  %send early to allow for all ACKs to finish
        nodes{sendHDnodeNumber}.scheduleHDChannelEvent(timeToDoHD,durationForHD,1:length(nodes),FcenterSlow,...
            BWSlow,receiveHDnodeNumber,25000,1.0,modulatorForHD,HDMessageList);
        HDchannelTriggered = true;
    end

    sendingPackets = [];
    sendingLocations = [];
    for i=1:length(nodes)
        %run the node to get received packets and sending packet
        [rxthese,txthis] = nodes{i}.run(time);
        %if we've got a packet addressed to this node, chalk up the success
        for j=1:length(rxthese)
            if rxthese(j).getDestination == i
                IDsend = rxthese(j).getIDsend;
                IDack = rxthese(j).getIDack;
                receivedPacketInfo = [receivedPacketInfo;[IDsend IDack time]]; %#ok<*AGROW>
            end
        end
        %if we started a transmission, we'll need to let everybody know
        if ~isempty(txthis)
            sendingPackets = [sendingPackets;txthis];
            sendingLocations = [sendingLocations;nodes{i}];
        end
    end
    %handle the newly sending packets
    for i=1:length(nodes)
        nodes{i}.addTransmittedPackets(sendingPackets,sendingLocations);
    end
    %now, see about some random transmissions
    if time < lastSendTime
        for i = 1:length(nodes)
            %don't queue any messages for HD channel participants while
            %they're busy
            if time >= holdoffInterval(1) && time <= holdoffInterval(2) && ...
                    (i == sendHDnodeNumber || i == receiveHDnodeNumber)
                continue;
            end
            %see if we want to queue a message
            pSend = timeIncrement/poissonSendInterval;
            check = rand(1);
            if check < pSend
                %destination is a random node that is not us
                running = true;
                while running
                    destination = randi(numNodes);
                    if destination ~= i
                        running = false;
                    end
                    %but don't send to HD transmitter during operation,
                    %either
                    if time >= holdoffInterval(1) && time <= holdoffInterval(2) && ...
                            (destination == sendHDnodeNumber)
                        running = true;
                    end
                end
                msgNum = msgNum + 1;
                message = randi(2,nodes{i}.getModulator.getPacketLength,1) - 1;  %random bitstream
                %make every once in a while a packet requiring ack
                pRequiresAck = pAckNeeded;
                tester = rand(1,1);
                requiresAck = (tester < pRequiresAck);
                packet = packetClass(nodes{i}.getModulator,i,destination,requiresAck,msgNum,0,message);
                nodes{i}.pushPacketsToSend(packet);
                sentPacketInfo = [sentPacketInfo;[msgNum requiresAck time modulatorIndex(packet.getModulator) length(message) packet.getModulator.bandwidthFraction]];
            end
        end
    end
end
