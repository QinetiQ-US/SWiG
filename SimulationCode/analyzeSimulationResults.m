function results = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo)
% function results = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo)
%analyze results from a simulation run
%structure with all kinds of relevant statistics

%handle FD channel first
FDsentPacketInfo = sentPacketInfo(sentPacketInfo(:,1)<1e5,:);
%first, find number of messages sent
results.FDnumMessagesSent = size(FDsentPacketInfo,1);
%find number of lost messages and accumulate latency array
latencies = nan(size(FDsentPacketInfo,1));
results.FDnumMessagesLost = 0;
results.FDnumAckRequiredMessages = sum(FDsentPacketInfo(:,2));
results.FDnumAckRequiredMessagesLost = 0;
for i=1:length(FDsentPacketInfo)
    which = find(FDsentPacketInfo(i,1)==receivedPacketInfo(:,1),1,'first');
    if ~isempty(which)
        latencies(i) = receivedPacketInfo(which,3) - FDsentPacketInfo(i,3);
    else
        results.FDnumMessagesLost = results.FDnumMessagesLost + 1;
        if (sentPacketInfo(i,2))
            results.FDnumAckRequiredMessagesLost = results.FDnumAckRequiredMessagesLost + 1;
        end
    end
end
goodLatencies = latencies(isfinite(latencies));
results.FDmeanLatency = mean(goodLatencies);
results.FDsigmaLatency = std(goodLatencies);
results.FDmedianLatency = median(goodLatencies);
results.FDmaxLatency = max(goodLatencies);
results.FDminLatency = min(goodLatencies);
results.FDrawLatency = sort(goodLatencies);

%now handle HD channel
HDsentPacketInfo = sentPacketInfo(sentPacketInfo(:,1)>=1e5,:);
%first, find number of messages sent
results.HDnumMessagesSent = size(HDsentPacketInfo,1);
%find number of lost messages
results.HDnumMessagesLost = 0;
for i=1:length(HDsentPacketInfo)
    which = find(HDsentPacketInfo(i,1)==receivedPacketInfo(:,1),1,'first');
    if isempty(which)
        results.HDnumMessagesLost = results.HDnumMessagesLost + 1;
    end
end
