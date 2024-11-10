function dystoniaSubjectAnalysis(subjectFolder, test, runCleaning)

    % Create a new folder in the subject folder to save analysis files
    analysisFolder = fullfile(subjectFolder, 'analysisFolder');
    if ~isfolder(analysisFolder)
        system(['mkdir ' analysisFolder])
    end

    % Get all files in the directory
    allFiles = dir(subjectFolder);
    allFiles = {allFiles(3:end).name};

    %% CBI analysis section

    if strcmp(test, 'CBI')
        % Find the CBI files by looking for CBI and .mat in names
        CBIindex = find(contains(allFiles, 'CBI') & contains(allFiles, '.mat'));
        CBIfile = fullfile(subjectFolder, allFiles{CBIindex});
        CBIvarName = strrep(allFiles{CBIindex}, '.mat', '');
    
        % Load the CBI file 
        CBIdata = load(CBIfile);
    
        % Now plot the CBI trials and ask for the index of bad data
        CBIbads = [];
        if runCleaning
            for ii = 1:size(CBIdata.([CBIvarName, '_wave_data']).values, 3)
                plot([0:5/1500:5-5/1500], CBIdata.([CBIvarName, '_wave_data']).values(:,1,ii))
                hold on
                plot(ones(length([-0.5:0.1:0.5]),1)/2, [-0.5:0.1:0.5], 'r')
                plot([0.5:5/1500:3.25], ones(length([0.5:5/1500:3.25]))*0.05, 'r')
                plot([0.5:5/1500:3.25], ones(length([0.5:5/1500:3.25]))*-0.05, 'r')
                hold off
                title(CBIdata.([CBIvarName, '_wave_data']).frameinfo(ii).label)
                ask = input(['Drop trial number ' num2str(ii) '/' num2str(size(CBIdata.([CBIvarName, '_wave_data']).values,3)) ' enter: y/n: \n'], 's');
                if strcmp(ask, 'y')
                    CBIbads = [CBIbads, ii];
                end
                close all
            end
        end
    
        % If there are dropped trials remove these from the variables and save
        % a new file for modified data in the analysis folder
        if ~isempty(CBIbads)
            CBIdata.([CBIvarName, '_wave_data']).values(:,:,CBIbads) = [];
            CBIdata.([CBIvarName, '_wave_data']).frameinfo(CBIbads,:) = [];
        end
        save(fullfile(analysisFolder, [CBIvarName '_cleaned']), 'CBIdata')
        
        % Get the indices of test (state 1) and conditioning (state 2) stim
        TSidx = find(arrayfun(@(x) x.state == 1, CBIdata.([CBIvarName, '_wave_data']).frameinfo));
        CSidx = find(arrayfun(@(x) x.state == 2, CBIdata.([CBIvarName, '_wave_data']).frameinfo));
        
        % Separate the TS and CS data from the data values. Squeeze as we
        % have a single channel.
        TS = squeeze(CBIdata.([CBIvarName, '_wave_data']).values(:,1,TSidx));
        CS = squeeze(CBIdata.([CBIvarName, '_wave_data']).values(:,1,CSidx));
    
        % The last stimulus artifact happen at frame 1003. We will get the
        % data after datapoint 1010 to make sure we are not getting any 
        % artifacts in the calculation.
        TScut = TS(1010:end, :);
        CScut = CS(1010:end, :);
    
        % Prepare subplots for showing averages 
        figure('Visible','off')
        plot(mean(TScut,2), 'b');
        hold on 
        plot(mean(CScut,2), 'r');
        legend('TS', 'CS')
        title('Average TS compared to average CS')
        saveas(gcf, fullfile(analysisFolder, 'TSvsCS.png'));
    
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
        CBI = mean(CSpeakToPeak) / mean(TSpeakToPeak);
    
        % Plot peak2peak values separately for each intensity
        figure('Visible','off')
        scatter(ones(size(TSpeakToPeak,2)), TSpeakToPeak, 'ob', 'filled');
        hold on 
        scatter(ones(size(CSpeakToPeak,2))*2, CSpeakToPeak, 'or', 'filled');
        xlim([0 3])
        set(gca, 'XTick', [1, 2], 'XTickLabel', {'TS', 'CS'});
        title('Individual peak-to-peak values for all trials')
        saveas(gcf, fullfile(analysisFolder, 'individualPeak2Peaks.png'));
    
        % Save the CBI results. This file will contain peak to peak
        % measurements and CBI
        CBIresults.CBI = CBI;
        CBIresults.TS_peak2peak = TSpeakToPeak;
        CBIresults.CS_peak2peak = CSpeakToPeak;
        save(fullfile(analysisFolder, 'CBIresults.mat'), 'CBIresults');
    end

    %% IC analysis section
    
    if strcmp(test, 'IC')
        % Find the IC files with a similar procedure 
        ICindex = find(contains(allFiles, 'IC') & contains(allFiles, '.mat'));
        ICfile = fullfile(subjectFolder, allFiles{ICindex});
        ICvarName = strrep(allFiles{ICindex}, '.mat', '');   
    
        % Load the IC file 
        ICdata = load(ICfile);

        % Now plot the IC trials and ask for the index of bad data
        ICbads = [];
        if runCleaning
            for ii = 1:size(ICdata.([ICvarName, '_wave_data']).values, 3)
                figure
                plot([0:5/2500:5-5/2500], ICdata.([ICvarName, '_wave_data']).values(:,1,ii))
                hold on
                if ~isequal(ICdata.([ICvarName, '_wave_data']).frameinfo(ii).state, 5)
                    plot(ones(length([-0.5:0.1:0.5]),1)/2, [-0.5:0.1:0.5], 'r')
                end
                if isequal(ICdata.([ICvarName, '_wave_data']).frameinfo(ii).state, 5)
                    plot([0:5/2500:1], ones(length([0:5/2500:1]))*0.05, 'r')
                    plot([0:5/2500:1], ones(length([0:5/2500:1]))*-0.05, 'r') 
                else
                    plot([0.5:5/2500:1.98], ones(length([0.5:5/2500:1.98]))*0.05, 'r')
                    plot([0.5:5/2500:1.98], ones(length([0.5:5/2500:1.98]))*-0.05, 'r')
                end
                hold off
                title(ICdata.([ICvarName, '_wave_data']).frameinfo(ii).label)
                ask = input(['Drop trial number ' num2str(ii) '/' num2str(size(ICdata.([ICvarName, '_wave_data']).values,3)) ' enter: y/n: \n'], 's');
                if strcmp(ask, 'y')
                    ICbads = [ICbads, ii];
                end
                close all
            end
        end
        
        % If there are dropped trials remove these from the variables and save
        % a new file for modified data in the analysis folder
        if ~isempty(ICbads)
            ICdata.([ICvarName, '_wave_data']).values(:,:,ICbads) = [];
            ICdata.([ICvarName, '_wave_data']).frameinfo(ICbads,:) = [];
        end
        save(fullfile(analysisFolder, [ICvarName '_cleaned']), 'ICdata')

        % Get the indices of states TS (state 1), SICI (state 2), 
        % SICF14 (state 3), SICF22 (state 4), LICI (state 5)
        TSidx = find(arrayfun(@(x) x.state == 1, ICdata.([ICvarName, '_wave_data']).frameinfo));
        SICIidx = find(arrayfun(@(x) x.state == 2, ICdata.([ICvarName, '_wave_data']).frameinfo));
        SICF14idx = find(arrayfun(@(x) x.state == 3, ICdata.([ICvarName, '_wave_data']).frameinfo));
        SICF22idx = find(arrayfun(@(x) x.state == 4, ICdata.([ICvarName, '_wave_data']).frameinfo));
        LICIidx = find(arrayfun(@(x) x.state == 5, ICdata.([ICvarName, '_wave_data']).frameinfo));

        % Separate data based on states and squeeze
        TS = squeeze(ICdata.([ICvarName, '_wave_data']).values(:,1,TSidx));
        SICI = squeeze(ICdata.([ICvarName, '_wave_data']).values(:,1,SICIidx));
        SICF14 = squeeze(ICdata.([ICvarName, '_wave_data']).values(:,1,SICF14idx));
        SICF22 = squeeze(ICdata.([ICvarName, '_wave_data']).values(:,1,SICF22idx));
        LICI = squeeze(ICdata.([ICvarName, '_wave_data']).values(:,1,LICIidx));
    end     
end





