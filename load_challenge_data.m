function [patient_metadata,record_names]=load_challenge_data(input_directory,patient_id)

% Find patient metadata
patient_metadata_file=fullfile(input_directory,patient_id,[patient_id '.txt']);
patient_metadata=fileread(patient_metadata_file);

% Find recording files
header_files=dir(fullfile(input_directory,patient_id,'*.hea'));
record_names=cellfun(@(x) extractBefore(x,find(x=='_',1,'last')),extractBefore({header_files.name},'.'),'UniformOutput',false);
record_names=sort(record_names);