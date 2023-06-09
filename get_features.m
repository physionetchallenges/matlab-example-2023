function features=get_features(input_directory,patient_id)

[patient_metadata,recording_ids]=load_challenge_data(input_directory,patient_id);
num_recordings=length(recording_ids);

% Extract patient features
age=get_age(patient_metadata);
sex=get_sex(patient_metadata);
rosc=get_rosc(patient_metadata);
ohca=get_ohca(patient_metadata);
vfib=get_vfib(patient_metadata);
ttm=get_ttm(patient_metadata);

% Use one-hot encoding for sex
if strncmp(sex,'Male',4)
    male=1;
    female=0;
    other=0;
elseif strncmp(sex,'Female',4)
    male=0;
    female=1;
    other=0;
else
    male=0;
    female=0;
    other=1;
end

patient_features=[age male female other rosc ohca vfib ttm];

%Extract EEG features
channels = {'F3', 'P3', 'F4', 'P4'};
group='EEG';

if num_recordings>0

    recording_id=recording_ids{end};
    recording_location = fullfile(input_directory,patient_id,sprintf('%s_%s',recording_id,group));

    if exist([recording_location '.hea'],'file')>0 & exist([recording_location '.mat'],'file')>0

        [signal_data,sampling_frequency,signal_channels]=load_recording(recording_location);
        utility_frequency=get_utility_frequency(recording_location);

        [signal_data, ~] = reduce_channels(signal_data, channels, signal_channels);

        [signal_data, sampling_frequency] = preprocess_data(signal_data, sampling_frequency, utility_frequency);

        % Convert to bipolar montage: F3-P3 and F4-P4
        data(1,:)=signal_data(1,:)-signal_data(2,:);
        data(2,:)=signal_data(3,:)-signal_data(4,:);

        features_eeg=get_eeg_features(data, sampling_frequency);

    else

        features_eeg=NaN(1,8);

    end

end

% Extract ECG features.
channels = {'ECG', 'ECGL', 'ECGR', 'ECG1', 'ECG2'};
group = 'ECG';

if num_recordings>0

    recording_id=recording_ids{end};
    recording_location = fullfile(input_directory,patient_id,sprintf('%s_%s',recording_id,group));

    if exist([recording_location '.hea'],'file')>0 & exist([recording_location '.mat'],'file')>0

        [signal_data,sampling_frequency,signal_channels]=load_recording(recording_location);
        utility_frequency=get_utility_frequency(recording_location);

        [signal_data, ~] = reduce_channels(signal_data, channels, signal_channels);

        [signal_data, sampling_frequency] = preprocess_data(signal_data, sampling_frequency, utility_frequency);

        features_ecg=get_ecg_features(signal_data, sampling_frequency);

    else

        features_ecg=NaN(1,10);

    end

end

% Combine the features 
features=[patient_features features_eeg features_ecg];

function age=get_age(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
age_tmp=patient_metadata(startsWith(patient_metadata,'Age:'));
age_tmp=strsplit(age_tmp{1},':');
age=str2double(age_tmp{2});

function sex=get_sex(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
sex_tmp=patient_metadata(startsWith(patient_metadata,'Sex:'));
sex_tmp=strsplit(sex_tmp{1},':');
sex=strtrim(sex_tmp{2});

function rosc=get_rosc(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
rosc_tmp=patient_metadata(startsWith(patient_metadata,'ROSC:'));
rosc_tmp=strsplit(rosc_tmp{1},':');
rosc=str2double(rosc_tmp{2});

function ohca=get_ohca(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
ohca_tmp=patient_metadata(startsWith(patient_metadata,'OHCA:'));
ohca_tmp=strsplit(ohca_tmp{1},':');

if strncmp(strtrim(ohca_tmp{2}),'True',4)
    ohca=1;
elseif strncmp(strtrim(ohca_tmp{2}),'False',4)
    ohca=0;
else
    ohca=nan;
end

function vfib=get_vfib(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
vfib_tmp=patient_metadata(startsWith(patient_metadata,'Shockable '));
vfib_tmp=strsplit(vfib_tmp{1},':');

if strncmp(strtrim(vfib_tmp{2}),'True',4)
    vfib=1;
elseif strncmp(strtrim(vfib_tmp{2}),'False',4)
    vfib=0;
else
    vfib=nan;
end

function ttm=get_ttm(patient_metadata)

patient_metadata=strsplit(patient_metadata,'\n');
ttm_tmp=patient_metadata(startsWith(patient_metadata,'TTM:'));
ttm_tmp=strsplit(ttm_tmp{1},':');
ttm=str2double(ttm_tmp{2});

function utility_frequency=get_utility_frequency(recording_info)

header_file=strsplit([recording_info '.hea'],'/');
header_file=header_file{end};
header=strsplit(fileread([recording_info '.hea']),'\n');

utility_tmp=header(startsWith(header,'#Utility'));
utility_tmp=strsplit(utility_tmp{1},':');
utility_frequency=str2double(utility_tmp{2});

function [data, channels] = reduce_channels(data, channels, signal_channels)

channel_order=signal_channels(ismember(signal_channels, channels));
data=data(ismember(signal_channels, channels),:);
data=reorder_recording_channels(data, channel_order, channels);

function reordered_signal_data=reorder_recording_channels(signal_data, current_channels, reordered_channels)

if length(current_channels)<length(reordered_channels)
    for i=length(current_channels)+1:length(reordered_channels)
        current_channels{i}='';
    end
end

if sum(cellfun(@strcmp, reordered_channels, current_channels))~=length(current_channels)
    indices=[];
    for j=1:length(reordered_channels)
        if sum(strcmp(reordered_channels{j},current_channels))>0
            indices=[indices find(strcmp(reordered_channels{j},current_channels))];
        else
            indices=[indices nan];
        end
    end
    num_channels=length(reordered_channels);
    num_samples=size(signal_data,2);
    reordered_signal_data=zeros(num_channels,num_samples);
    for j=1:num_channels
        if ~isnan(indices(j))
            reordered_signal_data(j,:)=signal_data(indices(j),:);
        end
    end
else
    reordered_signal_data=signal_data;
end

function [rescaled_data,sampling_frequency,channels]=load_recording(recording_location)

header_file=strsplit([recording_location '.hea'],'/');
header_file=header_file{end};

header=strsplit(fileread([recording_location '.hea']),'\n');

header(cellfun(@(x) isempty(x),header))=[];
header(startsWith(header,'#'))=[];

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
    gain(j-1)=str2double(header_tmp{3});
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

function [data, resampling_frequency]=preprocess_data(data, sampling_frequency, utility_frequency)
% Define the bandpass frequencies.
passband = [0.1, 30.0];

% If the utility frequency is between bandpass frequencies, then apply a notch filter.
if utility_frequency>min(passband) & utility_frequency<max(passband)
    wo = utility_frequency/(sampling_frequency/2);
    bw = wo/35;
    [b,a] = iirnotch(wo,bw);
    data = filtfilt(b,a,data')';
end

% Apply a bandpass filter.

[b,a]=butter(4,passband/(sampling_frequency/2));
data = filtfilt(b,a,data')';

%     % Resample the data.
if mod(sampling_frequency,2) == 0
    resampling_frequency = 128;
else
    resampling_frequency = 125;
end
lcm_tmp = lcm(round(sampling_frequency), round(resampling_frequency));
up = round(lcm_tmp / sampling_frequency);
down = round(lcm_tmp / resampling_frequency);
resampling_frequency = sampling_frequency * up / down;
data=resample(data',up,down)';

% Scale the data to the interval [-1, 1].
min_value = min(data(:));
max_value = max(data(:));
if min_value ~= max_value
    data = 2.0 / (max_value - min_value) * (data - 0.5 * (min_value + max_value));
else
    data = 0 * data;
end

function features=get_eeg_features(data, sampling_frequency)

try
    [psd,f]=pwelch(data',256,128,1024,sampling_frequency);
    delta_psd_mean=mean(psd(f>0.5 & f<8,:));
    theta_psd_mean=mean(psd(f>4 & f<8,:));
    alpha_psd_mean=mean(psd(f>8 & f<12,:));
    beta_psd_mean=mean(psd(f>12 & f<30,:));

    features=[delta_psd_mean theta_psd_mean alpha_psd_mean beta_psd_mean];
catch
    features=NaN(1,8);
end

function features_ecg=get_ecg_features(data, sampling_frequency)

features_ecg=[mean(data') std(data')];