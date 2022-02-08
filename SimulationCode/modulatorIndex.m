%> @brief unique number for each modulator type
%> @param [in] modulator - a modulator object
%> @retval result - an index based on the modulator type:<br>
%> 1 for SWIGModulator<br>
%> 2 for genericDSSSModulator<br>
%> 3 for SWIGPrimitiveModulator<br>
%> 4 for QPSKModulator
function result = modulatorIndex(modulator)

persistent modulatorTable;

if isempty(modulatorTable)
    modulatorTable = cell(4,1);
    m = SWIGModulator(false,true);
    modulatorTable{1} = m.getModulatorType;
    m = genericDSSSModulator(false,false);
    modulatorTable{2} = m.getModulatorType;
    m = SWIGPrimitiveModulator(false,true);
    modulatorTable{3} = m.getModulatorType;
    m = QPSKModulator(false,false);
    modulatorTable{4} = m.getModulatorType;
end

type = modulator.getModulatorType;
result = -1;
for i =1:length(modulatorTable)
    if strcmp(type, modulatorTable{i})
        result = i;
        break;
    end
end
end
