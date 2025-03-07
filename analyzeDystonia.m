path = '/Users/ozzy/Desktop/dystoniaData/';

patients = {'P01', 'P02', 'P03', 'P04', 'P05', 'P06', 'P07', 'P08', ...
            'P10', 'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P17', ...
            'P18', 'P19', 'P20'};
healthy = {'S01', 'S02', 'S03', 'S04', 'S05', 'S06', 'S07', 'S08', ...
           'S10', 'S11', 'S12', 'S13', 'S14'};

healthyCBI = [];
healthySICI = [];
healthySICF14 = [];
healthySICF22 = [];
healthyLICI = [];

patientCBI = [];
patientSICI = [];
patientSICF14 = [];
patientSICF22 = [];
patientLICI = [];

for ii = 1:size(healthy,2)
    cbiPath = fullfile(path, healthy{ii}, 'analysisFolder', 'CBIresults.mat');
    icPath = fullfile(path, healthy{ii}, 'analysisFolder', 'ICresults.mat');
    
    if isfile(cbiPath)
        load(cbiPath)
        healthyCBI(ii) = CBIresults.CBI;
    end

    if isfile(icPath)
        load(icPath)
        healthySICI(ii) = ICresults.SICI;
        healthySICF14(ii) = ICresults.SICF14;
        healthySICF22(ii) = ICresults.SICF22;
        healthyLICI(ii) = ICresults.LICI;
    end    
end

for ii = 1:size(patients,2)
    cbiPath = fullfile(path, patients{ii}, 'analysisFolder', 'CBIresults.mat');
    icPath = fullfile(path, patients{ii}, 'analysisFolder', 'ICresults.mat');
    
    if isfile(cbiPath)
        load(cbiPath)
        patientCBI(ii) = CBIresults.CBI;
    end

    if isfile(icPath)
        load(icPath)
        patientSICI(ii) = ICresults.SICI;
        patientSICF14(ii) = ICresults.SICF14;
        patientSICF22(ii) = ICresults.SICF22;
        patientLICI(ii) = ICresults.LICI;
    end    
end

% t-test 
p = [];

% CBI 
plot(ones(size(healthyCBI,2))*1, healthyCBI, 'b*')
hold on 
plot(ones(size(patientCBI,2))*1.5, patientCBI, 'r*')
xlim([0,3])
[~,p(1),~,~] = ttest2(healthyCBI,patientCBI);

% SICI 
plot(ones(size(healthySICI,2))*3, healthySICI, 'b*')
plot(ones(size(patientSICI,2))*3.5, patientSICI, 'r*')
[~,p(2),~,~] = ttest2(healthySICI,patientSICI);

% SICF14
plot(ones(size(healthySICF14,2))*5, healthySICF14, 'b*')
plot(ones(size(patientSICF14,2))*5.5, patientSICF14, 'r*')
[~,p(3),~,~] = ttest2(healthySICF14,patientSICF14);

% SICF22
plot(ones(size(healthySICF22,2))*7, healthySICF22, 'b*')
plot(ones(size(patientSICF22,2))*7.5, patientSICF22, 'r*')
[~,p(4),~,~] = ttest2(healthySICF22,patientSICF22);

% LICI
plot(ones(size(healthyLICI,2))*9, healthyLICI, 'b*')
plot(ones(size(patientLICI,2))*9.5, patientLICI, 'r*')
[~,p(5),~,~] = ttest2(healthyLICI,patientLICI);

xticks([1.25, 3.25, 5.25, 7.25, 9.25])
xticklabels({'CBI', 'SICI', 'SICF14', 'SICF22', 'LICI'})
xlim([0,10])
title('Measurements')