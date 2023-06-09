%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Purpose: Run trained classifier and obtain classifier outputs
% Inputs:
% 1. model
% 2. data directory
% 3. patient id
%
% Outputs:
% 1. outcome
% 2. outcome probability
% 3. CPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [outcome_binary, outcome_probability, cpc] = team_testing_code(model,input_directory,patient_id,verbose)

features=get_features(input_directory,patient_id);

[outcome_binary, outcome_probability]=model.model_outcome.predict(features);
outcome_binary=str2double(outcome_binary);
outcome_probability=outcome_probability(2);
cpc=model.model_cpc.predict(features);

end
