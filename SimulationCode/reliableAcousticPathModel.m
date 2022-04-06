%> @brief reliable acoustic path channel model
%> details - assumes that communications are in the so-called RAP-bowl, in
%which a shallow node communicates with a deeper node. In general, the
%lateral displacement between the two nodes will be < 6 times the depth
%difference between them. This is also not a terrible model for
%deep-to-deep communications less than 10-15 km distant
%no handling of top reflection or bottom bounce
%no modeling of refractive recurve
classdef reliableAcousticPathModel < channelModelClass

    %no properties on this one
    properties
        %> probability of failure - shallow to deep nodes tend to fail at
        %some rate unrelated to information-theoretic bit error rates -
        %most likely related to rapidly time-varying surface reflections
        %this variable will cause a random dropout to occur at a particular
        %rate
        pFail;
    end

    methods

        %> @brief Constructor
        %> @param [in] NL100 Noise level at 100 Hz due to shipping (defaults to 70 dB)
        %> @param [in] seaState sea state number (defaults to 3)
        %> @param [in] pFailIn probability of random failure (defaults to 0.1)
        function obj = reliableAcousticPathModel(NL100,seaState,pFailIn)
            if nargin < 1
                NL100 = 70;  %default shipping noise level
            end
            if nargin < 2
                seaState = 3;
            end
            if nargin < 3
                pFailIn = 0.1;
            end
            obj = obj@channelModelClass(NL100,seaState);
            obj.pFail = pFailIn;
        end

        %> @brief transmission loss computation
        %> @param [in] obj - the channel model object
        %> @param [in] sendLocation - location of sender (x,y,z) in meters
        %> @param [in] receiveLocation - location of receiver (x,y,z) in meters
        %> @param [in] f - frequency - in Hz
        %> @retval loss transmission loss in dB
        %> @retval propagationTime propagation time in seconds
        function [loss, propagationTime] = transmissionLoss(obj,sendLocation, receiveLocation, f)
            %compute distance in meters
            d = norm(sendLocation - receiveLocation);
            %transmission loss 1/r^2
            TL = 20 * log10(d);
            %compute absorption loss
            absorption = obj.absorption(f);
            TL = TL + absorption * d;
            %make a random failure happen
            thisRealization = rand(1,1);
            if thisRealization < obj.pFail
                TL = TL + 200;  %so much loss we'll never recover
            end
            loss = TL;
            %and prop time
            c=1500;  %approximate speed of sound in seawater
            propagationTime = d/c;
        end

    end

end