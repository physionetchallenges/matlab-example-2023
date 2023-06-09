function run_model(model_directory,input_directory, output_directory, allow_failures, verbose)

% Do *not* edit this script. Changes will be discarded so that we can process the models consistently.

% This file contains functions for running models for the 2023 Challenge. You can run it as follows:
%
%   run_model(model, data, outputs)
%
% where 'model' is a folder containing the your trained model, 'data' is a folder containing the Challenge data, and 'outputs' is a
% folder for saving your model's outputs.

if nargin==3
    allow_failures=1;
    verbose=2;
end

% Load the model
loaded_model=load_model(model_directory); % Teams: Implement this function!!

% Find challenge data
if verbose>=1
    fprintf('Finding Challenge data... \n')
end
patient_ids=dir(input_directory);
patient_ids=patient_ids([patient_ids.isdir]==1);
patient_ids(1:2)=[]; % Remove "./" and "../" paths 
patient_ids={patient_ids.name};
num_patients = length(patient_ids);

if verbose>=1
    fprintf('Loading data for %d patients...\n', num_patients)
end

% Create the output directory if it doesn't exist
if ~exist(output_directory, 'dir')
    mkdir(output_directory)
end

% Run the model
if verbose>=1
    disp('Running the model on the Challenge data...')
end

for j=1:num_patients

    if verbose>=2
        fprintf('%d/%d \n',j,num_patients);
    end

    patient_id=patient_ids{j};

    % Make the prediction

    try
        [outcome_binary, outcome_probability, cpc] = team_testing_code(loaded_model,input_directory,patient_id,verbose); % Teams: Implement this function!
    catch
        if allow_failures==1
            outcome_binary=NaN;
            outcome_probability=NaN;
            cpc=NaN;
            fprintf('%s failed \n',patient_id)
        else
            error('%s failed \n',patient_id)
        end
    end


    % Save the predictions
    
    % Create a folder for the Challenge outputs if it does not already
    % exist
    if ~exist(fullfile(output_directory,patient_id), 'dir')
        mkdir(fullfile(output_directory,patient_id))
    end
    output_file=[fullfile(output_directory,patient_id,patient_id) '.txt'];

    save_challenge_predictions(output_file,patient_id,outcome_binary,outcome_probability,cpc);

end

disp('Done.')
end

% Save predictions
function save_challenge_predictions(output_file,patient_id,outcome_binary,outcome_probability,cpc)

C{1,1}=sprintf('Patient: %s',patient_id);
if outcome_binary==0
    C{2,1}='Outcome: Good';
elseif outcome_binary==1
    C{2,1}='Outcome: Poor';
else
    C{2,1}='Outcome: ';
end

C{3,1}=sprintf('Outcome Probability: %.3f',outcome_probability);
C{4,1}=sprintf('CPC: %.3f',cpc);


%write data to end of file
writecell(C,output_file);

end
