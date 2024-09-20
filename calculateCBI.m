function CBIvalues = calculateCBI(inputData, intensities)
    % This function calculates CBI values and plots CBI results. 
    %   inputData = input mat file converted from signal format on Signal
    %               software. To save your data as mat, use the export 
    %               option in signal. You need to pass your data as a cell.
    %               See below for usage.
    %   intensities = Enter the MSO you used for the CBI. You can enter
    %                 multiple numbers in a struct if you tried different
    %                 intensities on the same subject. The number of
    %                 entries to intensities should match number of files
    %                 you enter in inputData, so make sure you are saving 
    %                 each intensity in different files in Spike. 
    % 

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
        figure(1)
        subplot(1, size(dataCell,2), ii);
        plot(mean(TScut,2), 'b');
        hold on 
        plot(mean(CScut,2), 'r');
        ylim([-0.5 0.5])
        legend('TS', 'CS')
        title([num2str(intensities(ii)) ' MSO%']);

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
        CBIvalues(ii) = mean(CSpeakToPeak) / mean(TSpeakToPeak);

        % Plot peak2peak values separately for each intensity
        figure(2)
        subplot(1, size(dataCell,2), ii);
        scatter(ones(size(TSpeakToPeak,2)), TSpeakToPeak, 'ob', 'filled');
        hold on 
        scatter(ones(size(CSpeakToPeak,2))*2, CSpeakToPeak, 'or', 'filled');
        xlim([0 3])
        set(gca, 'XTick', [1, 2], 'XTickLabel', {'TS', 'CS'});
        title([num2str(intensities(ii)) ' MSO%']);
    end
end
