%> @brief equipment noise class
%> @details provides equipment noise model
classdef equipmentNoiseClass < matlab.mixin.Copyable

    properties(Access = public)
        %> location (x,y,z) in meters
        location;  
        %> PSD for noise Nx2 [frequency PSD]
        PSD;  
    end

    methods
        %> @brief Constructor
        %> @param [in] locationIn (x,y,z) in meters
        %> @param [in] PSDin Nx2 [frequency PSD]
        function obj = equipmentNoiseClass(locationIn,PSDin)
            obj.location = locationIn;
            obj.PSD = PSDin;
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
        %> @retval result PSD at that frequency in dB re 1uPa/root-Hz
        function result = getPSD(obj,freq)
            result = interp1(obj.PSD(:,1),obj.PSD(:,2),freq,'linear','extrap');
        end

    end


end