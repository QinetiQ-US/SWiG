function [sentPacketInfo,receivedPacketInfo] = runSimulation(nodes,timeToRun,...
    timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded)
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




receivedPacketInfo = [];
sentPacketInfo =[];
msgNum = 0;
lastSendTime = timeToRun - timeToFinish;
numNodes = length(nodes);
rng(0); %make sure you can repeat this
%tick off every 5 minutes
tPrint = -1;
for time = 0:timeIncrement:timeToRun
    if time >= tPrint
        fprintf(1,'Running, time = %d seconds\n',round(time));
        tPrint = time + 299.99;
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
                end
                msgNum = msgNum + 1;
                message = randi(2,nodes{i}.getModulator.getPacketLength,1) - 1;  %random bitstream
                %make every once in a while a packet requiring ack
                pRequiresAck = pAckNeeded;
                tester = rand(1,1);
                requiresAck = (tester < pRequiresAck);
                packet = packetClass(nodes{i}.getModulator,i,destination,requiresAck,msgNum,0,message);
                nodes{i}.pushPacketsToSend(packet);
                sentPacketInfo = [sentPacketInfo;[msgNum requiresAck time modulatorIndex(packet.getModulator)]];
            end
        end
    end
end
