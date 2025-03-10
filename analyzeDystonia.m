path = '/Users/ozzy/Desktop/dystoniaData/';

% Remove 10
healthy = {'S01', 'S02', 'S03', 'S04', 'S05', 'S06', 'S07', 'S08', ...
           'S10', 'S11', 'S12', 'S13', 'S14'};
cervical = {'P01', 'P02', 'P03', 'P04', 'P05', 'P07', 'P10', 'P12', 'P15', 'P18', 'P19'};
bleph = {'P06', 'P13', 'P14', 'P16','P20'};
writers = {'P08', 'P11', 'P17'};


combined = {healthy, cervical, bleph, writers};
labels = {'healthy', 'cervical', 'bleph', 'writers'};
results = {};

for con = 1:size(combined,2)
    data = combined{con};
    for ii = 1:size(data,2)
        cbiPath = fullfile(path, data{ii}, 'analysisFolder', 'CBIresults.mat');
        icPath = fullfile(path, data{ii}, 'analysisFolder', 'ICresults.mat');
        
        if isfile(cbiPath)
            load(cbiPath)
            results{con}.cbi(ii) = CBIresults.CBI;
        else
            results{con}.cbi(ii) = NaN;
        end
    
        if isfile(icPath)
            load(icPath)
            results{con}.SICI(ii) = ICresults.SICI;
            results{con}.SICF14(ii) = ICresults.SICF14;
            results{con}.SICF22(ii) = ICresults.SICF22;
            results{con}.LICI(ii) = ICresults.LICI;
        end    
    end
end

jitter = 0;
colors = {'ro', 'bo', 'go', 'mo'};
for ii = 1:size(results,2)
    scatter(ones(size(results{ii}.cbi,2))*1+jitter, log(results{ii}.cbi), colors{ii}, 'filled')
    hold on
    scatter(ones(size(results{ii}.SICI,2))*4+jitter, log(results{ii}.SICI), colors{ii}, 'filled')
    scatter(ones(size(results{ii}.SICF14,2))*7+jitter, log(results{ii}.SICF14), colors{ii}, 'filled')
    scatter(ones(size(results{ii}.SICF22,2))*10+jitter, log(results{ii}.SICF22), colors{ii}, 'filled')
    scatter(ones(size(results{ii}.LICI,2))*13+jitter, log(results{ii}.LICI), colors{ii}, 'filled')
    jitter = jitter + 0.5;
end
xticks([1.75, 4.75, 7.75, 10.75, 13.75])
xticklabels({'CBI', 'SICI', 'SICF14', 'SICF22', 'LICI'})
h = zeros(1, length(labels));
for ii = 1:length(labels)
    h(ii) = scatter(nan, nan, 50, colors{ii}, 'filled'); % Dummy scatter for legend
end
legend(h, labels, 'Location', 'best')


% % t-test 
% p = [];
% 
% % CBI 
% 
% hold on 
% plot(ones(size(patientCBI,2))*1.5, patientCBI, 'ro')
% xlim([0,3])
% [~,p(1),~,~] = ttest2(healthyCBI,patientCBI);
% 
% % SICI 
% plot(ones(size(healthySICI,2))*3, healthySICI, 'bo')
% plot(ones(size(patientSICI,2))*3.5, patientSICI, 'ro')
% [~,p(2),~,~] = ttest2(healthySICI,patientSICI);
% 
% % SICF14
% plot(ones(size(healthySICF14,2))*5, healthySICF14, 'bo')
% plot(ones(size(patientSICF14,2))*5.5, patientSICF14, 'ro')
% [~,p(3),~,~] = ttest2(healthySICF14,patientSICF14);
% 
% % SICF22
% plot(ones(size(healthySICF22,2))*7, healthySICF22, 'bo')
% plot(ones(size(patientSICF22,2))*7.5, patientSICF22, 'ro')
% [~,p(4),~,~] = ttest2(healthySICF22,patientSICF22);
% 
% % LICI
% plot(ones(size(healthyLICI,2))*9, healthyLICI, 'bo')
% plot(ones(size(patientLICI,2))*9.5, patientLICI, 'ro')
% [~,p(5),~,~] = ttest2(healthyLICI,patientLICI);
% 
% xticks([1.25, 3.25, 5.25, 7.25, 9.25])
% xticklabels({'CBI', 'SICI', 'SICF14', 'SICF22', 'LICI'})
% xlim([0,10])
% title('Measurements')
% legend({'healthy', 'patient'})
