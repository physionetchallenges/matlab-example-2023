function train_model(input_directory, output_directory, verbose)

% Do *not* edit this script. Changes will be discarded so that we can process the models consistently.

% This file contains functions for training models for the 2023 Challenge. You can run it as follows:
%
%   train_model(data, model)
%
% where 'data' is a folder containing the Challenge data and 'model' is a folder for saving your model.

% if ~(nargin==3 || nargin==2)
%     error('Include the data and model folders as arguments')
% end

if ~exist(output_directory, 'dir')
    mkdir(output_directory)
end

if nargin~=3
    verbose=1;
end

team_training_code(input_directory,output_directory, verbose); % Teams: Implement this function!!!

end
