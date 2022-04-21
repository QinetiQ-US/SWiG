%> @brief Example script to run multiple store-and-forward network with
%> equipment interference
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
% overallStats = cell(length(modulatorIndexList),1);
% stats=cell(length(repeaterNumberToTest),1);
% for modulatorIndex = 1:length(modulatorIndexList)
%     thisModulator = modulatorIndexList(modulatorIndex);
%     parfor repIndex = 1:length(repeaterNumberToTest)
nReps=4;  %no interference, relatively quiet interference, LOUD interference, intermittent LOUD interference
overallStats = cell(nReps,1);
%go read in a sample equipment noise PSD function
interferenceData= readtable('InterferenceData.xls');
equipmentPSD = [interferenceData.Frequency interferenceData.Case4];
loudFieldPSD = [interferenceData.Frequency interferenceData.Case1];
runtimes = [1000 1500];
parfor testIndex = 1:nReps
    noisyEquipment = [];
    rng(0);  %force repeatability, since we don't know which order things run
    thisModulator = genericDSSSModulator(false,false);
    numRepeaters = 2;
    %fixed at 2 repeaters
    idealPoints =[
        [nodeRange*(1/3) nodeRange*(1/3) 0.5*vertRange];...
        [nodeRange*(2/3) nodeRange*(2/3) 0.5*vertRange];...
        ];
    %set minimum route distance
    minRouteDistance = 0.15 * nodeRange;
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
            nodes{i}=nodeClass(trajectory,{thisModulator},i,maxQueueDepth); %#ok<*SAGROW>
        else
            nodes{i}=nodeClass(locations(i,:),{thisModulator},i,maxQueueDepth); %#ok<*SAGROW>
        end
        nodes{i}.setModulator(1);
        if i==6
            %special for node 6 - we're going to put it right near some noisy
            %equipment
            switch (testIndex)
                case 1 %no noise
                    noisyEquipment = [];
                case 2  %just some reasonable stuff, always running
                    noisyEquipment = equipmentNoiseClass(locations(i,:),equipmentPSD);
                case 3  %really LOUD, always running
                    noisyEquipment = equipmentNoiseClass(locations(i,:),loudFieldPSD);
                case 4 %loud, but intermittent
                    noisyEquipment = equipmentNoiseClass(locations(i,:),loudFieldPSD,runtimes);
            end
        end
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
                tab=[tab;j]; %#ok<AGROW>
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
        timeToFinish,timeIncrement,poissonSendInterval,pAckNeeded,noisyEquipment);
    thisStats = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo);
    fprintf(1,'Stats for %d relays:\n',numRepeaters);
    disp(thisStats);
    overallStats{testIndex} = thisStats;
end
%unwind stats
completeStats = cell(nReps,1);
for repIndex = 1:nReps
    stats = overallStats{repIndex};
    stats.fractionLost = [stats.SMACnumMessagesLost/stats.SMACnumMessagesSent stats.SMACnumAckRequiredMessagesLost/stats.SMACnumAckRequiredMessages];
    completeStats{repIndex} = stats;
end