function model = team_training_code(input_directory,output_directory, verbose) % train_EEG_classifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Purpose: Train EEG classifiers and obtain the models
% Inputs:
% 1. input_directory
% 2. output_directory
%
% Outputs:
% 1. model: trained model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if verbose>=1
    disp('Finding challenge data...')
end

% Find the folders
patient_ids=dir(input_directory);
patient_ids=patient_ids([patient_ids.isdir]==1);
patient_ids(1:2)=[]; % Remove "./" and "../" paths 
patient_ids={patient_ids.name};
num_patients = length(patient_ids);

% Create a folder for the model if it doesn't exist
if ~isdir(output_directory)
    mkdir(output_directory)
end

fprintf('Loading data for %d patients...\n', num_patients)

% Extract fatures and labels

features=[];
outcomes=zeros(1,num_patients);
cpcs=zeros(1,num_patients);

for j=1:num_patients

    if verbose>1
        fprintf('%d/%d \n',j,num_patients)
    end

    % Extract features
    patient_id=patient_ids{j};
    current_features=get_features(input_directory,patient_id);
    features(j,:)=current_features;

    % Load data
    patient_metadata=load_challenge_data(input_directory,patient_id);

    % Extract labels
    current_outcome=get_outcome(patient_metadata);
    outcomes(j)=current_outcome;
    current_cpc=get_cpc(patient_metadata);
    cpcs(j)=current_cpc;
    
end

%% train RF

disp('Training the model...')

model_outcome = TreeBagger(100,features,outcomes);

model_cpc = TreeBagger(100,features,cpcs,'method','regression');

save_model(model_outcome,model_cpc,output_directory);

disp('Done.')

end

function save_model(model_outcome,model_cpc,output_directory) %save_model
% Save results.
filename = fullfile(output_directory,'model.mat');
save(filename,'model_outcome','model_cpc','-v7.3');

disp('Done.')
end

function outcome=get_outcome(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
outcome_tmp=patient_metadata(startsWith(patient_metadata,'Outcome:'));
outcome_tmp=strsplit(outcome_tmp{1},':');

if strncmp(strtrim(outcome_tmp{2}),'Good',4)
    outcome=0;
elseif strncmp(strtrim(outcome_tmp{2}),'Poor',4)
    outcome=1;
else
    keyboard
end

end

function cpc=get_cpc(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
cpc_tmp=patient_metadata(startsWith(patient_metadata,'CPC:'));
cpc_tmp=strsplit(cpc_tmp{1},':');
cpc=str2double(cpc_tmp{2});

end