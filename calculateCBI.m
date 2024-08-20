function CBIvalues = calculateCBI(inputData)

    % Put everything in a cell so the scipt supports multiple input
    dataCell = {};
    if iscell(inputData)
        dataCell = inputData;
    else
        dataCell{1} = inputData;
    end

    % Setup some empty cells to populate with results 
    CBIvalues = []; 
    files = {};

    % Loop through the input images
    for ii = 1:size(dataCell,2)
        % Get file names and load data
        [filepath, filename, fileextension] = fileparts(inputData{ii});
        files{ii} = filename;
        dataset = load(inputData{ii});
        
        % Get the indices of test (state 1) and conditioning (state 2) stim
        TSidx = find(arrayfun(@(x) x.state == 1, dataset.data.frameinfo));
        CSidx = find(arrayfun(@(x) x.state == 2, dataset.data.frameinfo));
        
        % Separate the TS and CS data from the data values. Squeeze as we
        % have a single channel.
        TS = squeeze(dataset.data.values(:,1,TSidx));
        CS = squeeze(dataset.data.values(:,1,CSidx));

        % The last stimulus artifact happen at frame 1003. We will get the
        % data after datapoint 1010.
        TScut = TS(1010:end, :);
        CScut = CS(1010:end, :);

        % Prepare subplots for showing averages 
        subplot(1, size(dataCell,2), ii);
        plot(mean(TScut,2));
        hold on 
        plot(mean(CScut,2));
        ylim([-1 1])
        legend('TS', 'CS')
        title(strrep(filename, '_', '-'));

        % Loop through the trials and get the peak to peak and calculate
        % CBI
        TSpeakToPeak = [];
        CSpeakToPeak = [];
        for trial = 1:size(TScut,2)
            TSpeakToPeak = [TSpeakToPeak peak2peak(TScut(:,trial))];
        end
        for trial = 1:size(CScut,2)
            CSpeakToPeak = [CSpeakToPeak peak2peak(CScut(:,trial))];      
        end
        CBIvalues(ii) = mean(TSpeakToPeak) / mean(CSpeakToPeak);
    end
end
