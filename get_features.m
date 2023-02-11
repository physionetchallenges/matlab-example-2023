function features=get_features(patient_metadata, recording_metadata, recording_data)

% Extract features from the data
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

%Extract features from the recording data and metadata.
channels = {'Fp1-F7', 'F7-T3', 'T3-T5', 'T5-O1', 'Fp2-F8', 'F8-T4', 'T4-T6', 'T6-O2', 'Fp1-F3', ...
                'F3-C3', 'C3-P3', 'P3-O1', 'Fp2-F4', 'F4-C4', 'C4-P4', 'P4-O2', 'Fz-Cz', 'Cz-Pz'};
num_channels=length(channels);
num_recordings=length(recording_data);

% Compute mean and standard deviation for each channel for each recording.
available_signal_data=[];
for j=1:num_recordings

    signal_data=recording_data(j).recording_data;
    sampling_frequency=recording_data(j).sampling_frequency;
    signal_channels=recording_data(j).channels;

    if ~isnan(signal_data)

        signal_data=reorder_recording_channels(signal_data, signal_channels, channels);
        available_signal_data=[available_signal_data signal_data];

    end

end

signal_mean=nanmean(available_signal_data');
signal_std=nanstd(available_signal_data');

% Compute the power spectral density for the delta, theta, alpha, and beta frequency bands for each channel of the most
% recent recording.
index=find(~isnan([recording_data.sampling_frequency]),1,'last');

if ~isnan(index)

    signal_data=recording_data(index).recording_data;
    sampling_frequency=recording_data(index).sampling_frequency;
    signal_channels=recording_data(index).channels;

    reordered_signal_data=reorder_recording_channels(signal_data, signal_channels, channels);

    [psd,f]=pwelch(reordered_signal_data',256,128,1024,sampling_frequency);
    delta_psd_mean=mean(psd(f>0.5 & f<8,:));
    theta_psd_mean=mean(psd(f>4 & f<8,:));
    alpha_psd_mean=mean(psd(f>8 & f<12,:));
    beta_psd_mean=mean(psd(f>12 & f<30,:));

    quality_score=recording_metadata.Quality(index);

else

    delta_psd_mean=zeros(1,num_channels);
    theta_psd_mean=zeros(1,num_channels);
    alpha_psd_mean=zeros(1,num_channels);
    beta_psd_mean=zeros(1,num_channels);

    quality_score=NaN;

end
recording_features=[signal_mean signal_std delta_psd_mean theta_psd_mean ...
    alpha_psd_mean beta_psd_mean quality_score];

% Combine the features from the patient metadata and the recording data and metadata.
features=[patient_features recording_features];

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
vfib_tmp=patient_metadata(startsWith(patient_metadata,'VFib:'));
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

function reordered_signal_data=reorder_recording_channels(signal_data, current_channels, reordered_channels)

if length(current_channels)<length(reordered_channels)
    current_channels{end+1:length(reordered_channels)}='';
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