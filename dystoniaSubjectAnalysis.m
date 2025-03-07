function dystoniaSubjectAnalysis(subjectFolder, test, runCleaning)

    % Script to analyze dystonia TMS data. The files are found
    % automatically and plotted with a few diagnostic indicators. A red box
    % is drawn with -0.5 - 0.5 borders to visually inspect the background
    % muscle activity. Peaks are also detected automatically and plotted.
    % If multiple peaks appear, this is shown on the figure as a warning.
    % 3xRMS is calculated from background activity and if peak-to-peak
    % measurement is smaller than this amount, another warning is plotted.
    % Peak-to-peak activity is calculated in a window between 3-5sec which
    % is placed 0.2sec after the test pulse in both CBI and IC data. 
    %
    % The script creates an empty analysis folder in the subject directory.
    % Once the visual inspection is done, this folder is populated with a
    % few diagnostic images. Cleaned up data is also saved in here as a
    % .mat file. 
    %
    %   Inputs:
    %   subjectFolder: Path to subject folder. CBI and IC files are found
    %                  automatically.
    %   test:          Enter 'CBI' or 'IC' or 'All' to do a part of the
    %                  analysis or all of it. 
    %   runCleaning  : Enter true or false. The latter skips the cleaning
    %                  step and does the analysis on raw data.
    %

    % Create a new folder in the subject folder to save analysis files
    analysisFolder = fullfile(subjectFolder, 'analysisFolder');
    if ~isfolder(analysisFolder)
        system(['mkdir ' analysisFolder]);
    end

    % Get all files in the directory
    allFiles = dir(subjectFolder);
    allFiles = {allFiles(3:end).name};

    % Set RMS multiplier. We want MEPs to be bigger than 3 times the RMS
    RMSmult = 3;

    %% CBI analysis section

    if strcmp(test, 'CBI') || strcmp(test, 'All')
        
        % Create CBI plot folder 
        CBIplotFolder = fullfile(analysisFolder, 'CBI_plots');
        if ~isfolder(CBIplotFolder)
            system(['mkdir ' CBIplotFolder]);
        end
        
        % Find the CBI files by looking for CBI and .mat in names
        CBIindex = find(contains(allFiles, 'CBI') & contains(allFiles, '.mat'));
        CBIfile = fullfile(subjectFolder, allFiles{CBIindex});
        CBIvarName = strrep(allFiles{CBIindex}, '.mat', '');
    
        % Load the CBI file 
        CBIdata = load(CBIfile);
    
        % Loop through trials and do cleanup plots
        CBIbads = [];
        if runCleaning
            % Create a sub-folder in the folder above for diagnostics
            diagnostics = fullfile(CBIplotFolder, 'diagnostics');
            if ~isfolder(diagnostics)
                system(['mkdir ' diagnostics]);
            end

            % Start the cleaning
            for ii = 1:size(CBIdata.([CBIvarName, '_wave_data']).values, 3)
                data = CBIdata.([CBIvarName, '_wave_data']).values(:,1,ii);
                plot(data)
                hold on
                title([CBIdata.([CBIvarName, '_wave_data']).frameinfo(ii).label ' ,Trial ' num2str(ii)])
                plot(ones(length([-0.5:0.1:0.5]),1)*(0.5*1500/5) , [-0.5:0.1:0.5], 'r')
                plot([(0.5*1500/5):978], ones(length([(0.5*1500/5):978]))*0.05, 'r')
                plot([(0.5*1500/5):978], ones(length([(0.5*1500/5):978]))*-0.05, 'r')
                maxIdx = find(data(1050:end) == max(data(1050:end)));
                minIdx = find(data(1050:end) == min(data(1050:end)));
                plot((1050 + maxIdx-1), max(data(1050:end)), 'r*')
                plot((1050 + minIdx-1), min(data(1050:end)), 'r*')
                
                % Check if there are more than 2 peaks. Plot a warning. 
                if length(maxIdx) > 1 || length(minIdx) > 1
                    % Get the axis limits
                    xLimits = xlim;
                    yLimits = ylim;
                    % Add text to the top right corner
                    text(xLimits(2), yLimits(2), 'Warning: multiple peaks', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','Color', 'red');
                end
                
                % Check baseline 3*RMS and plot a warning if MEP is smaller
                % than this threshold
                if peak2peak(data(1050:end)) < rms(data((0.5*1500/5):978)) * RMSmult
                    xLimits = xlim;
                    yLimits = ylim;
                    text(xLimits(2), yLimits(2) - 0.1*(yLimits(2) - yLimits(1)), ['Warning: MEP < ' num2str(RMSmult) 'xRMS'], ...
                        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
                        'Color', 'red');
                end

                hold off             
                ask = input(['Drop trial number ' num2str(ii) '/' num2str(size(CBIdata.([CBIvarName, '_wave_data']).values,3)) ' enter: y/n: \n'], 's');
                if strcmp(ask, 'y')
                    CBIbads = [CBIbads, ii];
                    title(['DROPPED ' CBIdata.([CBIvarName, '_wave_data']).frameinfo(ii).label ' ,Trial ' num2str(ii)])
                    saveas(gcf, fullfile(diagnostics, ['DROPPED_Trial_' num2str(ii), '.png']));
                else
                    title([CBIdata.([CBIvarName, '_wave_data']).frameinfo(ii).label ' ,Trial ' num2str(ii)])
                    saveas(gcf, fullfile(diagnostics, ['Trial_' num2str(ii), '.png']));
                end
                close all
            end
        end
    
        % If there are dropped trials remove these from the variables. Save
        % a new version of the data regardless with the clean extension
        if ~isempty(CBIbads)
            CBIdata.([CBIvarName, '_wave_data']).values(:,:,CBIbads) = [];
            CBIdata.([CBIvarName, '_wave_data']).frameinfo(CBIbads,:) = [];
        end
        save(fullfile(analysisFolder, [CBIvarName '_cleaned']), 'CBIdata');
        
        % Get the indices of test (state 1) and conditioning (state 2) stim
        % and separate TS and CS. 
        TSidx = find(arrayfun(@(x) x.state == 1, CBIdata.([CBIvarName, '_wave_data']).frameinfo));
        CSidx = find(arrayfun(@(x) x.state == 2, CBIdata.([CBIvarName, '_wave_data']).frameinfo));
        TS = squeeze(CBIdata.([CBIvarName, '_wave_data']).values(:,1,TSidx));
        CS = squeeze(CBIdata.([CBIvarName, '_wave_data']).values(:,1,CSidx));

        % Save a plot showing averages
        figure('Visible','off')
        plot(mean(TS,2), 'b');
        hold on 
        plot(mean(CS,2), 'r');
        legend('TS', 'CS')
        title('Average TS compared to average CS')
        saveas(gcf, fullfile(CBIplotFolder, 'TSvsCS.png'));

        % The last stimulus artifact happen at frame 1003. We will get the
        % data after datapoint 1050 to make sure we are not getting any 
        % artifacts in the calculation.
        TS = TS(1050:1500, :);
        CS = CS(1050:1500, :);
    
        % Get the peak2peak calculations
        TSpeakToPeak = peak2peak(TS);
        CSpeakToPeak = peak2peak(CS);
    
        % Plot peak2peak values separately for each trial
        plotData = [TSpeakToPeak, CSpeakToPeak];
        group = [repmat(1, size(TSpeakToPeak,2), 1); 
                 repmat(2, size(CSpeakToPeak,2), 1)];
        figure('Visible','off')
        boxplot(plotData, group, 'Labels', {'TS', 'CS'});
        hold on
        scatter(ones(size(TSpeakToPeak,2))*0.7, TSpeakToPeak, 'ob', 'filled');
        scatter(ones(size(CSpeakToPeak,2))*1.7, CSpeakToPeak, 'or', 'filled');
        xlim([0 3])
        set(gca, 'XTick', [1, 2], 'XTickLabel', {'TS', 'CS'});
        title('Individual peak-to-peak values for all trials')
        hold off
        saveas(gcf, fullfile(CBIplotFolder, 'individualPeak2Peaks.png'));
    
        % Save the CBI results. This file will contain peak to peak
        % measurements and CBI
        CBI = mean(CSpeakToPeak) / mean(TSpeakToPeak);
        CBIresults.CBI = CBI;
        CBIresults.TS_peak2peak = TSpeakToPeak;
        CBIresults.CS_peak2peak = CSpeakToPeak;
        save(fullfile(analysisFolder, 'CBIresults.mat'), 'CBIresults');
    end

    %% IC analysis section
    
    if strcmp(test, 'IC') || strcmp(test, 'All')
        % Create IC plot folder 
        ICplotFolder = fullfile(analysisFolder, 'IC_plots');
        if ~isfolder(ICplotFolder)
            system(['mkdir ' ICplotFolder]);
        end

        % Find the IC files with a similar procedure 
        ICindex = find(contains(allFiles, 'IC') & contains(allFiles, '.mat'));
        ICfile = fullfile(subjectFolder, allFiles{ICindex});
        ICvarName = strrep(allFiles{ICindex}, '.mat', '');   
    
        % Load the IC file 
        ICdata = load(ICfile);

        % Now plot the IC trials and ask for the index of bad data
        ICbads = [];
        if runCleaning
            % Create a sub-folder in the folder above for diagnostics
            diagnostics = fullfile(ICplotFolder, 'diagnostics');
            if ~isfolder(diagnostics)
                system(['mkdir ' diagnostics]);
            end
            for ii = 1:size(ICdata.([ICvarName, '_wave_data']).values, 3)
                data = ICdata.([ICvarName, '_wave_data']).values(:,1,ii);
                figure
                plot(data)
                hold on
                plot(ones(length([-0.5:0.1:0.5]),1)*(0.5*1500/5) , [-0.5:0.1:0.5], 'r')
                if isequal(ICdata.([ICvarName, '_wave_data']).frameinfo(ii).state, 5)
                    limit = 500;
                else
                    limit = 990;
                end
                plot([(0.5*1500/5):limit], ones(length([(0.5*1500/5):limit]))*0.05, 'r')
                plot([(0.5*1500/5):limit], ones(length([(0.5*1500/5):limit]))*-0.05, 'r')
                maxIdx = find(data(1050:1500) == max(data(1050:1500)));
                minIdx = find(data(1050:1500) == min(data(1050:1500)));
                plot((1050 + maxIdx-1), max(data(1050:1500)), 'r*')
                plot((1050 + minIdx-1 ), min(data(1050:1500)), 'r*')
                
                % Check multiple occurances of max min values and plot
                % warning
                if length(maxIdx) > 1 || length(minIdx) > 1
                    % Get the axis limits
                    xLimits = xlim;
                    yLimits = ylim;
                    % Add text to the top right corner
                    text(xLimits(2), yLimits(2), 'Warning: multiple peaks', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','Color', 'red');
                end
                
                % Check baseline 3*RMS and plot a warning if MEP is smaller
                % than this threshold
                if peak2peak(data(1050:1500)) < rms(data((0.5*1500/5):limit)) * RMSmult
                    xLimits = xlim;
                    yLimits = ylim;
                    text(xLimits(2), yLimits(2) - 0.1*(yLimits(2) - yLimits(1)), ['Warning: MEP < ' num2str(RMSmult) 'xRMS'], ...
                        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
                        'Color', 'red');
                end

                hold off
                title(ICdata.([ICvarName, '_wave_data']).frameinfo(ii).label)
                ask = input(['Drop trial number ' num2str(ii) '/' num2str(size(ICdata.([ICvarName, '_wave_data']).values,3)) ' enter: y/n: \n'], 's');
                if strcmp(ask, 'y')
                    ICbads = [ICbads, ii];
                    title(['DROPPED ' ICdata.([ICvarName, '_wave_data']).frameinfo(ii).label])
                    saveas(gcf, fullfile(diagnostics, ['DROPPED_Trial_' num2str(ii), '.png']));
                else
                    title(ICdata.([ICvarName, '_wave_data']).frameinfo(ii).label)
                    saveas(gcf, fullfile(diagnostics, ['Trial_' num2str(ii), '.png']));
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

        % Do the cutting. For TS, the last pulse comes in at frame 1003,
        % so we will cut from 1040. 
        TS = TS(1050:1500, :);
        SICI = SICI(1050:1500, :);
        SICF14 = SICF14(1050:1500, :);
        SICF22 = SICF22(1050:1500, :);
        LICI = LICI(1050:1500, :);

        % Save a plot showing averages
        figure('Visible','off')
        plot(mean(TS,2));
        hold on 
        plot(mean(SICI,2));
        plot(mean(SICF14,2));
        plot(mean(SICF22,2));
        plot(mean(LICI,2));
        legend('TS', 'SICI', 'SICF14', 'SICF22', 'LICI')
        title('Average of IC measurements')
        saveas(gcf, fullfile(ICplotFolder, 'ICplots.png'));
        
        % Get the peak2peak calculations
        TSpeakToPeak = peak2peak(TS);
        SICIpeakToPeak = peak2peak(SICI);
        SICF14peakToPeak = peak2peak(SICF14);
        SICF22peakToPeak = peak2peak(SICF22);
        LICIpeakToPeak = peak2peak(LICI);
    
        % Plot peak2peak values separately for each trial
        figure('Visible','off')
        % Combine all data into a single array and create a grouping variable
        plotData = [TSpeakToPeak, SICIpeakToPeak, SICF14peakToPeak, SICF22peakToPeak, LICIpeakToPeak];
        group = [repmat(1, size(TSpeakToPeak,2), 1); 
                 repmat(2, size(SICIpeakToPeak,2), 1); 
                 repmat(3, size(SICF14peakToPeak,2), 1); 
                 repmat(4, size(SICF22peakToPeak,2), 1); 
                 repmat(5, size(LICIpeakToPeak,2), 1)];

        % Create the boxplot
        boxplot(plotData, group, 'Labels', {'TS', 'SICI', 'SICF14', 'SICF22', 'LICI'});
        hold on
        title('Boxplot of peak-to-peak values for all trials')
        ylabel('Peak-to-Peak Values')        
        scatter(ones(size(TSpeakToPeak,2))*0.6, TSpeakToPeak, 'filled');
        scatter(ones(size(SICIpeakToPeak,2))*1.6, SICIpeakToPeak, 'filled');
        scatter(ones(size(SICF14peakToPeak,2))*2.6, SICF14peakToPeak, 'filled');
        scatter(ones(size(SICF22peakToPeak,2))*3.6, SICF22peakToPeak, 'filled');
        scatter(ones(size(LICIpeakToPeak,2))*4.6, LICIpeakToPeak, 'filled');
        xlim([0 6])
        set(gca, 'XTick', [1,2,3,4,5], 'XTickLabel', {'TS', 'SICI', 'SICF14', 'SICF22', 'LICI'});
        title('Individual peak-to-peak values for all trials')
        hold off 
        saveas(gcf, fullfile(ICplotFolder, 'individualPeak2Peaks.png'));

        % Get ratios
        ICresults.TSpeakToPeak = TSpeakToPeak;
        ICresults.SICIpeakToPeak = SICIpeakToPeak;
        ICresults.SICF14peakToPeak = SICF14peakToPeak;
        ICresults.SICF22peakToPeak = SICF22peakToPeak;
        ICresults.LICIpeakToPeak = LICIpeakToPeak;
        ICresults.SICI = mean(SICIpeakToPeak) / mean(TSpeakToPeak);
        ICresults.SICF14 = mean(SICF14peakToPeak) / mean(TSpeakToPeak);
        ICresults.SICF22 = mean(SICF22peakToPeak) / mean(TSpeakToPeak);
        ICresults.LICI = mean(LICIpeakToPeak) / mean(TSpeakToPeak);
        save(fullfile(analysisFolder, 'ICresults.mat'), 'ICresults');

    end     
end