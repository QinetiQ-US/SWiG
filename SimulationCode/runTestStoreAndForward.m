%> @brief Example script to run multiple store-and-forward network
%> simulations simultaneously
ModulatorList = {
    genericDSSSModulator(true,false)
    genericDSSSModulator(false,false)
    genericDSSSModulator(false,true)
    SWIGPrimitiveModulator(false,true)
    SWIGModulator(false,false)
    QPSKModulator(false,false)
    };
nodeRange = 6000;
numNodes = 15;
rng(0);
locations=nodeRange*rand(numNodes,3);
%make vertical range much smaller
vertRangeRatio = 0.1;
locations(:,3) = locations(:,3)*vertRangeRatio;
vertRange = vertRangeRatio * nodeRange;
numNodes = size(locations,1);
%build a very simple set of routing tables based on distance
routingTableCollection = cell(numNodes,1);
for i=1:length(routingTableCollection)
    routingTableCollection{i}=[];
end
emptyRoutingTableCollection = routingTableCollection;
repeaterNumberToTest = [0 1 2 4];
modulatorIndexList = 1:4;
% overallStats = cell(length(modulatorIndexList),1);
% stats=cell(length(repeaterNumberToTest),1);
% for modulatorIndex = 1:length(modulatorIndexList)
%     thisModulator = modulatorIndexList(modulatorIndex);
%     parfor repIndex = 1:length(repeaterNumberToTest)
nReps=length(repeaterNumberToTest);
nMods=length(modulatorIndexList);
overallStats = cell(nMods*nReps,1);
parfor combinedIndex = 1:(nReps*nMods)
    repIndex = 1+ rem(combinedIndex-1,nReps);
    modulatorIndex = 1 + floor((combinedIndex-1)/nReps);
    rng(0);  %force repeatability, since we don't know which order things run
    thisModulator = modulatorIndexList(modulatorIndex); %#ok<PFBNS> 
    numRepeaters = repeaterNumberToTest(repIndex); %#ok<PFBNS> 
    minRouteDistance = 0;
    idealPoints=[]; %#ok<NASGU>
    switch numRepeaters
        case 4
            % 4 repeaters
            idealPoints =[
                [nodeRange*(1/3) nodeRange*(1/3) 0.5*vertRange];...
                [nodeRange*(1/3) nodeRange*(2/3) 0.5*vertRange];...
                [nodeRange*(2/3) nodeRange*(1/3) 0.5*vertRange];...
                [nodeRange*(2/3) nodeRange*(2/3) 0.5*vertRange]
                ];
            %set minimum route distance
            minRouteDistance = 0.25 * nodeRange;
        case 2
            idealPoints =[
                [nodeRange*(1/3) nodeRange*(1/3) 0.5*vertRange];...
                [nodeRange*(2/3) nodeRange*(2/3) 0.5*vertRange];...
                ];
            %set minimum route distance
            minRouteDistance = 0.15 * nodeRange;
        case 1
            idealPoints=[0.5*nodeRange 0.5*nodeRange 0.5*vertRange];
            minRouteDistance = 0.15 * nodeRange;
        case 0
            idealPoints=[];
        otherwise
            error('Invalid number of repeaters')
    end
    %set up the nodes
    maxQueueDepth = 1024;
    nodes = cell(numNodes,1);
    for i = 1:numNodes
        %special for node number 10 - it's going to move from one point to
        %another over 3000 seconds in a straight line
        if i==10
            myLocations=nodeRange*rand(2,3);
            %make vertical range much smaller
            myLocations(:,3) = myLocations(:,3)*vertRangeRatio;
            trajectory=[[0 myLocations(1,:)];...
                [3000 myLocations(2,:)]];
            nodes{i}=nodeClass(trajectory,ModulatorList,i,maxQueueDepth); %#ok<*SAGROW>
        else
            nodes{i}=nodeClass(locations(i,:),ModulatorList,i,maxQueueDepth); %#ok<PFBNS,*SAGROW>
        end
        nodes{i}.setModulator(thisModulator);
    end
    %set up the store and forward tables
    %go get the nodes closest to the desired repeater points
    repeaterIDs=zeros(size(idealPoints,1),1);
    for i=1:length(repeaterIDs)
        d2 = sum((locations - repmat(idealPoints(i,:),size(locations,1),1)).^2,2);
        [~,which] = min(d2);
        repeaterIDs(i) = which;
    end
    for i = 1:length(repeaterIDs)
        tab = [];
        for j = 1:size(locations,1)
            d1 = norm(locations(j,:) - locations(repeaterIDs(i),:));
            if d1 > minRouteDistance
                tab=[tab;j]; 
            end
        end
        nodes{repeaterIDs(i)}.setStoreAndForwardTable(tab);
    end
    timeToRun = 3600;  %one hour
    timeToFinish = 60;  %how much time to stay quiet at the end to let things finish
    timeIncrement = 0.05;  %10 mSec
    poissonSendInterval = 1/0.06;  %as per SWiG requirements
    pAckNeeded = 0.1;           %on average 10% of messages require ACK

    [sentPacketInfo,receivedPacketInfo] = runSimulation(nodes,timeToRun,...
        timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded);
    thisStats = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo);
    fprintf(1,'Stats for %d relays:\n',numRepeaters);
    disp(thisStats);
    overallStats{combinedIndex} = thisStats;
end
%unwind stats
completeStats = cell(nMods,nReps);
for combinedIndex = 1:(nReps*nMods)
    repIndex = 1+ rem(combinedIndex-1,nReps);
    modulatorIndex = 1 + floor((combinedIndex-1)/nReps);
    stats = overallStats{combinedIndex};
    stats.fractionLost = [stats.SMACnumMessagesLost/stats.SMACnumMessagesSent stats.SMACnumAckRequiredMessagesLost/stats.SMACnumAckRequiredMessages];
    completeStats{modulatorIndex,repIndex} = stats;
end