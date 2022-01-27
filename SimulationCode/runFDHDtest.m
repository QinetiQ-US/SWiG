ModulatorList = {
    SWIGModulator(false,false)
    genericDSSSModulator(false,false)
    SWIGPrimitiveModulator(false,true)
    QPSKModulator(false,false)
    };
nodeRange = 2000;
numNodes = 8;
rng(0);
locations=nodeRange*rand(numNodes,3);
%make vertical range much smaller
vertRangeRatio = 0.1;
locations(:,3) = locations(:,3)*vertRangeRatio;
vertRange = vertRangeRatio * nodeRange;
numNodes = size(locations,1);
maxQueueDepth = 1024;
nodes = cell(numNodes,1);
for i = 1:numNodes
    nodes{i}=nodeClass(locations(i,:),ModulatorList,i,maxQueueDepth); %#ok<*SAGROW>
    nodes{i}.setModulator(1);  %SWiG modulator without CSMA and with multiple simultaneous decode
end
timeToRun = 1200;  
timeToFinish = 60;  %how much time to stay quiet at the end to let things finish
timeIncrement = 0.025;  %10 mSec
poissonSendInterval = 60;   %on average one message per node per minute
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
modulatorForHD = 4;  %QPSK
rng(0);
[sentPacketInfo,receivedPacketInfo] = runSimulationWithHDFDchangeover(nodes,timeToRun,...
    timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded,sendHDnodeNumber,receiveHDnodeNumber,...
    timeToDoHD, durationForHD, messagesForHD,modulatorForHD);
thisStats = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo,timeToDoHD, durationForHD);
disp(thisStats);
