%> @brief Analyze simulation results to produce statistical values
%> @param [in] sentPacketInfo N x 6 array of sent-packet info from
% simulation function
%> @param [in] receivedPacketInfo M x 3 array of received packet info from
%> simulation function
%> @param [in] startHD time in seconds for HD cutover (omit if none)
%> @param [in] durationOfHD time in seconds for HD operation (omit if none)
%> @retval results a struct with fields:<br>
%> FDnumMessagesSent - total number of FD messages sent<br>
%> FDnumMessagesLost - total number of FD messages that were lost<br>
%> FDnumAckRequiredMessages - number of FD critical messages<br>
%> FDnumAckRequiredMessagesLost - number of FD critical messages where ACK never received<br>
%> FDmeanLatency - [mean latency for all FD, mean latency for critical FD
%> (including ACK received)] <br>
%> FDsigmaLatency - standard deviations of latencies<br>
%> FDmedianLatency - median latencies<br>
%> FDmaxLatency - max latencies <br>
%> FDThroughput - total FD throughput in bits/second<br>
%> HDnumMessagesSent - total number of HD messages sent<br>
%> HDnumMessagesLost - number of HD messages lost<br>
%> FDNoHDThroughput - throughput of FD channel in bps when no HD is in
%> operation<br>
%> FDDuringHDThroughput - throughput of FD channel in bps when HD is in
%> %operation<br>
%> HDThroughput - throughput of HD channel in bps

function results = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo,startHD, durationOfHD)
% function results = analyzeSimulationResults(sentPacketInfo,receivedPacketInfo)
%analyze results from a simulation run
%structure with all kinds of relevant statistics

%determine if any HD usage
if nargin > 3
    HD = true;
    endHD = startHD + durationOfHD;
else
    HD = false;
end

%handle FD channel first
FDsentPacketInfo = sentPacketInfo(sentPacketInfo(:,1)<1e5,:);
%first, find number of messages sent
results.FDnumMessagesSent = size(FDsentPacketInfo,1);
%find number of lost messages and accumulate latency array
latencies = nan(size(FDsentPacketInfo,1),1);
results.FDnumMessagesLost = 0;
results.FDnumAckRequiredMessages = sum(FDsentPacketInfo(:,2));
results.FDnumAckRequiredMessagesLost = 0;
FDtotalBits = 0;
FDduringHDBits = 0;
FDOutsideHDBits = 0;
ackRequired = false(length(FDsentPacketInfo),1);
for i=1:length(FDsentPacketInfo)
    which = find(FDsentPacketInfo(i,1)==receivedPacketInfo(:,1),1,'first');
    ackRequired(i) = FDsentPacketInfo(i,2) ~= 0;
    if ~isempty(which)
        latencies(i) = receivedPacketInfo(which,3) - FDsentPacketInfo(i,3);
        FDtotalBits = FDtotalBits + FDsentPacketInfo(i,5);
        if HD
            if FDsentPacketInfo(i,6)>0.95
                FDOutsideHDBits = FDOutsideHDBits + FDsentPacketInfo(i,5);
            else
                FDduringHDBits = FDduringHDBits + FDsentPacketInfo(i,5);
            end
        end
    else
        results.FDnumMessagesLost = results.FDnumMessagesLost + 1;
        if (sentPacketInfo(i,2))
            results.FDnumAckRequiredMessagesLost = results.FDnumAckRequiredMessagesLost + 1;
        end
    end
end
ack = latencies(isfinite(latencies) & ackRequired);
nack = latencies(isfinite(latencies)& ~ackRequired);
results.FDmeanLatency = [mean(nack) mean(ack)];
results.FDsigmaLatency = [std(nack) std(ack)];
results.FDmedianLatency = [median(nack) median(ack)];
results.FDmaxLatency = [max(nack) max(ack)];
results.FDminLatency = [min(nack) min(ack)];
results.FDrawLatency = sort(latencies);
results.FDThroughput = FDtotalBits/range(FDsentPacketInfo(:,3));
if HD
    %now handle HD channel
    HDsentPacketInfo = sentPacketInfo(sentPacketInfo(:,1)>=1e5,:);
    %first, find number of messages sent
    results.HDnumMessagesSent = size(HDsentPacketInfo,1);
    %find number of lost messages
    results.HDnumMessagesLost = 0;
    HDtotalBits = 0;
    for i=1:length(HDsentPacketInfo)
        which = find(HDsentPacketInfo(i,1)==receivedPacketInfo(:,1),1,'first');
        if isempty(which)
            results.HDnumMessagesLost = results.HDnumMessagesLost + 1;
        else
            HDtotalBits = HDtotalBits + HDsentPacketInfo(i,5);
        end
    end
    results.FDNoHDThroughput = FDOutsideHDBits/(range(FDsentPacketInfo(:,3)) - (endHD - startHD));
    results.FDDuringHDThroughput = FDduringHDBits / (endHD - startHD);
    results.HDThroughput = HDtotalBits / (endHD - startHD);
end