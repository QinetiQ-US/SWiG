%> @brief Analyze simulation results to produce statistical values
%> @param [in] sentPacketInfo N x 6 array of sent-packet info from
% simulation function
%> @param [in] receivedPacketInfo M x 3 array of received packet info from
%> simulation function
%> @param [in] startHD time in seconds for HD cutover (omit if none)
%> @param [in] durationOfHD time in seconds for HD operation (omit if none)
%> @retval results a struct with fields:<br>
%> SMACnumMessagesSent - total number of SMAC messages sent<br>
%> SMACnumMessagesLost - total number of SMAC messages that were lost<br>
%> SMACnumAckRequiredMessages - number of SMAC critical messages<br>
%> SMACnumAckRequiredMessagesLost - number of SMAC critical messages where ACK never received<br>
%> SMACmeanLatency - [mean latency for all SMAC, mean latency for critical SMAC
%> (including ACK received)] <br>
%> SMACsigmaLatency - standard deviations of latencies<br>
%> SMACmedianLatency - median latencies<br>
%> SMACmaxLatency - max latencies <br>
%> SMACThroughput - total SMAC throughput in bits/second<br>
%> HDnumMessagesSent - total number of HD messages sent<br>
%> HDnumMessagesLost - number of HD messages lost<br>
%> SMACNoHDThroughput - throughput of SMAC channel in bps when no HD is in
%> operation<br>
%> SMACDuringHDThroughput - throughput of SMAC channel in bps when HD is in
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

%handle SMAC channel first
SMACsentPacketInfo = sentPacketInfo(sentPacketInfo(:,1)<1e5,:);
%first, find number of messages sent
results.SMACnumMessagesSent = size(SMACsentPacketInfo,1);
%find number of lost messages and accumulate latency array
latencies = nan(size(SMACsentPacketInfo,1),1);
results.SMACnumMessagesLost = 0;
results.SMACnumAckRequiredMessages = sum(SMACsentPacketInfo(:,2));
results.SMACnumAckRequiredMessagesLost = 0;
SMACtotalBits = 0;
SMACduringHDBits = 0;
SMACOutsideHDBits = 0;
ackRequired = false(length(SMACsentPacketInfo),1);
for i=1:length(SMACsentPacketInfo)
    which = find(SMACsentPacketInfo(i,1)==receivedPacketInfo(:,1),1,'first');
    ackRequired(i) = SMACsentPacketInfo(i,2) ~= 0;
    if ~isempty(which)
        latencies(i) = receivedPacketInfo(which,3) - SMACsentPacketInfo(i,3);
        SMACtotalBits = SMACtotalBits + SMACsentPacketInfo(i,5);
        if HD
            if SMACsentPacketInfo(i,6)>0.95
                SMACOutsideHDBits = SMACOutsideHDBits + SMACsentPacketInfo(i,5);
            else
                SMACduringHDBits = SMACduringHDBits + SMACsentPacketInfo(i,5);
            end
        end
    else
        results.SMACnumMessagesLost = results.SMACnumMessagesLost + 1;
        if (sentPacketInfo(i,2))
            results.SMACnumAckRequiredMessagesLost = results.SMACnumAckRequiredMessagesLost + 1;
        end
    end
end
ack = latencies(isfinite(latencies) & ackRequired);
nack = latencies(isfinite(latencies)& ~ackRequired);
results.SMACmeanLatency = [mean(nack) mean(ack)];
results.SMACsigmaLatency = [std(nack) std(ack)];
results.SMACmedianLatency = [median(nack) median(ack)];
results.SMACmaxLatency = [max(nack) max(ack)];
results.SMACminLatency = [min(nack) min(ack)];
results.SMACrawLatency = sort(latencies);
results.SMACThroughput = SMACtotalBits/range(SMACsentPacketInfo(:,3));
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
    results.SMACNoHDThroughput = SMACOutsideHDBits/(range(SMACsentPacketInfo(:,3)) - (endHD - startHD));
    results.SMACDuringHDThroughput = SMACduringHDBits / (endHD - startHD);
    results.HDThroughput = HDtotalBits / (endHD - startHD);
end