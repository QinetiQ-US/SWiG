%> @brief equipment noise class
%> @details provides equipment noise model - based in PSD list and a list
%> of active times (to simulate intermittent noise)
classdef equipmentNoiseClass < matlab.mixin.Copyable

    properties(Access = public)
        %> location (x,y,z) in meters
        location;  
        %> PSD for noise Nx2 [frequency PSD]
        PSD;
        %> active times for this noise source
        activeTimeList
    end

    methods
        %> @brief Constructor
        %> @param [in] locationIn (x,y,z) in meters
        %> @param [in] PSDin Nx2 [frequency PSD]
        %> @param [in] activeTimes list n x 2 of [StartTime EndTime] in
        %> seconds - can be empty
        function obj = equipmentNoiseClass(locationIn,PSDin,activeTimes)
            obj.location = locationIn;
            obj.PSD = PSDin;
            if nargin < 3
                activeTimes = [];
            end
            obj.activeTimeList = activeTimes;
        end

        %> @brief get location
        %> @param [in] obj - the object
        %> @retval result location (x,y,z) in meters
        function result = getLocation(obj)
            result = obj.location;
        end

        %> @brief get PSD at modem operating frequency
        %> @param [in] obj - the object
        %> @param [in] freq - frequency in Hz for PSD
        %> @param [in] time - time in seconds (used for intermittent noise
        %> sources)
        %> @retval result PSD at that frequency in dB re 1uPa/root-Hz
        function result = getPSD(obj,freq,time)
            %see if we are actually active
            active = isempty(obj.activeTimeList);  %if empty, always active, otherwise test
            for i = 1:size(obj.activeTimeList,1)
                if (obj.activeTimeList(i,1) <= time) && (obj.activeTimeList(i,2) >= time)
                    active = true;
                    break;
                end
            end
            if active
                result = interp1(obj.PSD(:,1),obj.PSD(:,2),freq,'linear','extrap');
            else
                result = -120;  %truly, no noise to speak of
            end
        end

    end


end