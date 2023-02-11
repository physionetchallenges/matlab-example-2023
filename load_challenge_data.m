function [patient_metadata,recording_metadata,recordings]=load_challenge_data(input_directory,patient_id)

% Define file location
patient_metadata_file=fullfile(input_directory,patient_id,[patient_id '.txt']);
recording_metadata_file=fullfile(input_directory,patient_id,[patient_id '.tsv']);

% Load non-recording data
patient_metadata=fileread(patient_metadata_file);

opts=detectImportOptions(recording_metadata_file,'FileType','text','Delimiter','\t');
opts.VariableTypes{4}='char';
recording_metadata=readtable(recording_metadata_file,opts);

% Load recordings
recording_ids=recording_metadata.Record;
recordings=struct();
for j=1:length(recording_ids)

    if ~strncmp(recording_ids{j},'nan',3)
        recording_location=fullfile(input_directory,patient_id,recording_ids{j});
        [recording_data,sampling_frequency,channels]=load_recording(recording_location);
    else
        recording_data=NaN;
        sampling_frequency=NaN;
        channels=NaN;
    end

    recordings(j).recording_data=recording_data;
    recordings(j).sampling_frequency=sampling_frequency;
    recordings(j).channels=channels;

%     keyboard

end

function [rescaled_data,sampling_frequency,channels]=load_recording(recording_location)

header_file=strsplit([recording_location '.hea'],'/');
header_file=header_file{end};

header=strsplit(fileread([recording_location '.hea']),'\n');

header(cellfun(@(x) isempty(x),header))=[];

recordings_info=strsplit(header{1},' ');
record_name=recordings_info{1};
num_signals=str2double(recordings_info{2});
sampling_frequency=str2double(recordings_info{3});
num_samples=str2double(recordings_info{4});

signal_file=cell(1,length(header)-1);
gain=zeros(1,length(header)-1);
offset=zeros(1,length(header)-1);
initial_value=zeros(1,length(header)-1);
checksum=zeros(1,length(header)-1);
channels=cell(1,length(header)-1);
for j=2:length(header)

    header_tmp=strsplit(header{j},' ');

    signal_file{j-1}=header_tmp{1};
    gain(j-1)=str2double(extractBefore(header_tmp{3},'/'));
    offset(j-1)=str2double(header_tmp{5});
    initial_value(j-1)=str2double(header_tmp{6});
    checksum(j-1)=str2double(header_tmp{7});
    channels{j-1}=header_tmp{9};

end

if ~length(unique(signal_file))==1
    error('A single signal file was expected for %s',header_file)
end

% Load the signal file
load([recording_location '.mat'],'val')

num_channels=length(channels);
if num_channels~=size(val,1) || num_samples~=size(val,2)
    error('The header file %s is inconsistent with the dimensions of the signal file',header_file)
end

for j=1:num_channels
    if val(j,1)~=initial_value(j)
        error('The initial value in header file %s is inconsistent with the initial value for the channel',header_file)
    end
    
    if sum(val(j,:))~=checksum(j)
        error('The checksum in header file %s is inconsistent with the initial value for the channel',header_file)
    end
end

rescaled_data=zeros(num_channels,num_samples);
for j=1:num_channels
    rescaled_data(j,:)=(val(j,:)-offset(j))/gain(j);
end