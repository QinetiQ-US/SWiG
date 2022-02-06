ModulatorList = {
    SWIGPrimitiveModulator(false,true)
    SWIGModulator(false,true)
    genericDSSSModulator(false,false)
    genericDSSSModulator(true,false)
    QPSKModulator(false,false)
    };
nodeRange = 2000;
numNodes = 8;
results=cell(3,1);
parfor modulatorIndex = 1:4
    rng(0);
    locations=nodeRange*rand(numNodes,3);
    %make vertical range much smaller
    vertRangeRatio = 0.1;
    locations(:,3) = locations(:,3)*vertRangeRatio;
    vertRange = vertRangeRatio * nodeRange;
    maxQueueDepth = 1024;
    nodes = cell(numNodes,1);
    for i = 1:numNodes
        nodes{i}=nodeClass(locations(i,:),ModulatorList,i,maxQueueDepth); %#ok<*SAGROW>
        nodes{i}.setModulator(modulatorIndex);  %SWiG modulator without CSMA and with multiple simultaneous decode
    end
    timeToRun = 1200;
    timeToFinish = 60;  %how much time to stay quiet at the end to let things finish
    timeIncrement = 0.0125;  %10 mSec
    poissonSendInterval = 1/0.06;   %on average one message per node per minute
    pAckNeeded = 0.1;           %on average 10% of messages require ACK

    %configure transition
    sendHDnodeNumber = 1;  %arbitrary here
    receiveHDnodeNumber = 2;
    timeToDoHD = 725;
    myMod = QPSKModulator(false,false);
    messageLength = myMod.getPacketLength;
    messagesForHD = cell(400,1);
    for i = 1:length(messagesForHD)
        messagesForHD{i}=randn(messageLength,1);  %roughly a packet
    end
    durationForHD = length(messagesForHD)*myMod.getPacketDuration;
    durationForHD = durationForHD + 5.0;  %buffer time
    modulatorForHD = 5;  %QPSK
    rng(0);
    [sentPacketInfo,receivedPacketInfo] = runSimulationWithHDFDchangeover(nodes,timeToRun,...
        timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded,sendHDnodeNumber,receiveHDnodeNumber,...
        timeToDoHD, durationForHD, messagesForHD,modulatorForHD);
    thisStats = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo,timeToDoHD, durationForHD);
    thisStats.fractionLost = [thisStats.FDnumMessagesLost/thisStats.FDnumMessagesSent thisStats.FDnumAckRequiredMessagesLost/thisStats.FDnumAckRequiredMessages];
    thisStats.HDFractionLost = thisStats.HDnumMessagesLost/thisStats.HDnumMessagesSent;
    disp(thisStats);
    results{modulatorIndex} = thisStats;
end