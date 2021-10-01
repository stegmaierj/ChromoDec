%%
% LiveCellMiner.
% Copyright (C) 2020 D. Moreno-Andres, A. Bhattacharyya, W. Antonin, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and one
% of the following publications:
%
% TBA
%
%%

%% remember the previous selection
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;

%% find the manual synchronization feature
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
syncFeature = parameter.gui.merkmale_und_klassen.ind_zr;

%% ask for normalization mode (either based on the mean intensity of the interphase or the MA sync time point)
methodSelection = questdlg('Which reference value should be normalized to?', ...
	'Normalization Method', ...
	'Interphase Mean', 'First TP after MA', 'Interphase Mean');

normalizationMode = 1;
normalizationSuffix = 'IntMean';
if (strcmp(methodSelection, 'First TP after MA'))
    normalizationMode = 2;
    normalizationSuffix = 'TPAfterMA';
end

%% restore the old selection
set(gaitfindobj('CE_Auswahl_ZR'), 'value', oldSelection);
aktparawin;

%% get the selected features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;

%% normalize time series of all selected features
for f=generate_rowvector(selectedFeatures)

    %% initialize a new feature and add a new specifier
    d_orgs(:,:,end+1) = 0;
    
    if (var_bez(end,1) == 'y')
        var_bez = char(var_bez(1:end-1, :), [kill_lz(var_bez(f, :)) '-Normalized' normalizationSuffix]);
    else
        var_bez = char(var_bez, [kill_lz(var_bez(f, :)) '-Normalized' normalizationSuffix]);
    end

    %% process all data points and use the frame after the synchronization time point for normalization.
    for i=1:size(d_orgs,1)

        %% find normalization time point
        intPhaseFrames = find(d_orgs(i,:,syncFeature) == 1);
        anaPhaseFrames = find(d_orgs(i,:,syncFeature) == 3);

        %% skip if no valid sync point was selected
        if (isempty(anaPhaseFrames))
            continue;
        end

        %% get the reference intensity
        if (normalizationMode == 1)
            referenceFeatureValue = mean(d_orgs(i, intPhaseFrames, f));
        else
            referenceFeatureValue = d_orgs(i, anaPhaseFrames(1), f);
        end

        %% disable entries with invalid reference intensities
        normalizedFeatureValues = d_orgs(i, :, f) / referenceFeatureValue;
        if (sum(isinf(normalizedFeatureValues)) == 0)
            d_orgs(i, :, end) = normalizedFeatureValues;
        else
            disp(['Inf detected, removing cell ' num2str(i) ' from the valid cells!!']);
            d_orgs(i, :, syncFeature) = 0;
        end
    end
end

%% update the time series
aktparawin;