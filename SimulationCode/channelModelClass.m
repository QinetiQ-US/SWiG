%> @brief Channel model class - Abstract class
%> @details actual channel model classes derive from channelModelClass
classdef channelModelClass < matlab.mixin.Copyable

    properties(Access = public)
        %> Shipping noise level at 100 Hz in dB re 1 uPa/root-Hz
        NL100;
        %> Noise level at 1 kHz - which depends on sea state
        NL1k;
        %> pH used for absorption computation
        pH;
        %> salinity used for absorption computation
        salinity;
        %> depth used for absorption computation
        depth;
        %> temperature used for absorption computation
        temperature;
    end

    methods
        %> @brief Constructor
        %> @param [in] NL100 Noise level at 100 Hz due to shipping
        %> @param [in] seaState sea state number
        function obj = channelModelClass(NL100,seaState)
            if nargin < 1
                NL100 = 70;  %default shipping noise level
            elseif nargin < 2
                seaState = 3;
            end
            obj.NL100 = NL100;
            obj.setSeaState(seaState);
            %default parameter form Francois-Garrison absorption
            obj.depth = 100.0;
            obj.pH = 8;
            obj.salinity = 35;
            obj.temperature = 8;
        end

        %> @brief set noise level based on sea state
        function obj = setSeaState(obj,seaState)
            referenceSeaState=[0 0.5 1 2 3 4 5 6];  %from Lurton
            referenceNoise=[44.5 50 55 61.5 64.5 66.5 68.5 70];
            obj.NL1k = interp1(referenceSeaState,referenceNoise,seaState,'linear','extrap');
        end

        %> @brief compute noise PSD from Lurton
        %> @param [in] obj the object
        %> @param [in] f frequency in Hz
        %> @retval result
        function result = noiseLevel(obj,f)
            if (f < 100 )  %we don't handle this case
                error('Channel model frequency below limit');
            elseif (f < 1000)
                result = obj.NL100 - 20*log10(f/100);
            elseif (f < 100e3)
                result = obj.NL1k -17*log10(f/1e3);
            else
                result = -75 + 20*log10(f);
            end
        end

        %> @brief absorption of sound per m in dB
        %> @details compute absorption first in dB/Km as per
        %> Francois-Garrison equations, then convert to absorption in dB/m, 
        %> which is what we'll need later. Utilizes salinity, temperature,
        %> depth etc. set up previously in the object
        %> @param [in] obj - the object (used to hold ocean parameters)
        %> @param [in] fHz - frequency in Hz
        %> @retval result - transmission loss in dB/m
        function result = absorption(obj,fHz)
            %set up simple variables to make entering formulas easier
            T = obj.temperature;
            S = obj.salinity;
            f = fHz / 1e3;  %needed in kHz for the formulas
            z = obj.depth;
            PH = obj.pH;
            %calculate effective speed of sound
            c = 1412 + 3.21*T + 1.19*S + 0.0167*z;
            %boric acid paramters
            A1 = (8.86/c) * (10^(0.78*PH - 5));
            %pH modifier
            P1 = 1;
            f1 = 2.8*sqrt(S/35) * (10^(4 - (1245/(T+273))));
            %magnesium sulphate parameters
            A2 = 21.44*(S/c) * (1 + 0.025*T);
            P2 = 1 - 1.37e-4 *z + 6.2e-9*z*z;
            f2 = (8.17 * (10^(8-(1990/(T+273)))))/(1+0.0018*(S-35));
            %water viscosity parameters
            P3 = 1 -3.83e-5*z + 4.9e-10*z*z;
            if T < 20
                A3 = 4.937e-4 - 2.59e-5*T + 9.11e-7*T*T - 1.5e-8*T*T*T;
            else
                A3 = 3.964e-4 - 1.146e-5*T + 1.45e-7*T*T - 6.5e-10*T*T*T;
            end
            %put them all together
            alpha = A1*P1*(f1*f*f/(f1*f1+f*f)) + ...
                A2*P2*(f2*f*f/(f2*f2+f*f)) + ...
                A3*P3*f*f;
            %and convert back
            result = alpha * 1e-3;
        end

    end


    methods(Abstract)
        %> @brief transmission loss computation
        %> @param [in] obj - the channel model object
        %> @param [in] sendLocation - location of sender [x,y,z] in meters
        %> @param [in] receiveLocation - location of receiver [x,y,z] in
        %> meters
        %> @param [in] f - frequency - in Hz
        %> @retval loss transmission loss in dB
        %> @retval propagationTime - propagation time in seconds
        [loss, propagationTime] = transmissionLoss(obj,sendLocation, receiveLocation, f);
    end
end


