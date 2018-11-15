% If data loading could be automated that would be better but loading
% pre-processed Excel files is the current option

clc
clear all

 load fullset.mat
% load fullset_specific.mat

% Initialise matrices

filter_zero=1;  % Switch to filter zeros or not

metric_2=zeros(size(MeandischargeWDOcumecs,2),1);
metric_3=zeros(size(MeandischargeWDOcumecs,2),1);
metric_1_rory_strict=zeros(size(MeandischargeWDOcumecs,2),3);
metric_1_rory_relaxed=zeros(size(MeandischargeWDOcumecs,2),3);
best_lag=zeros(size(MeandischargeWDOcumecs,2),3);
no_events=zeros(size(MeandischargeWDOcumecs,2),3);
flood_events=zeros(size(MeandischargeWDOcumecs,2),3);

% Initialise parameters

lag=3;
met_temp=zeros(2*lag+1,1);

% Code

% for location_index=1
for location_index=1:size(MeandischargeWDOcumecs,2)
    
    model_runoff_temp=model_runoff(:,location_index);
    MeandischargeWDOcumecs_temp=MeandischargeWDOcumecs(:,location_index);
    Watercourselevelm_temp=Watercourselevelm(:,location_index);
    
    % percent_diff(location_index)=((MeandischargeWDOcumecs_temp./catchment_area(location_index)-model_runoff)/(((MeandischargeWDOcumecs_temp./catchment_area(location_index))+model_runoff)/2);
    
    
    % Metric 3
    
    if filter_zero==0
        filter=~isnan(Watercourselevelm_temp)&~isnan(model_runoff_temp)&Watercourselevelm_temp>ARI_height_minor(location_index);
    else
        filter=~isnan(Watercourselevelm_temp)&~isnan(model_runoff_temp)&Watercourselevelm_temp~=0&Watercourselevelm_temp>ARI_height_minor(location_index);
    end
    if sum(filter)==0
        metric_3(location_index)=NaN;
    else
        Watercourselevelm_filtered=Watercourselevelm_temp(filter);
        model_runoff_filtered=model_runoff_temp(filter);
        if lag~=0
            if sum(filter)<lag
                metric_3(location_index)=NaN;
            else
                for i=1:lag
                    mdl = fitlm(model_runoff_filtered(1+i:end),Watercourselevelm_filtered(1:end-i));
                    met_temp(lag-i+1)=mdl.Rsquared.Ordinary;
                end
                mdl = fitlm(model_runoff_filtered,Watercourselevelm_filtered);
                met_temp(lag+1)=mdl.Rsquared.Ordinary;
                for i=1:lag
                    mdl = fitlm(model_runoff_filtered(1:end-i),Watercourselevelm_filtered(i+1:end));
                    met_temp(lag+i+1)=mdl.Rsquared.Ordinary;
                end
                
                [best_met_i,best_lag_i]=max(met_temp);
                metric_3(location_index)=best_met_i;
                best_lag(location_index,3)=best_lag_i-(lag+1);
            end
        else
            if sum(filter)<2
                metric_3(location_index)=NaN;
            else
                mdl = fitlm(model_runoff_filtered,Watercourselevelm_filtered);
                metric_3(location_index)=mdl.Rsquared.Ordinary;
            end
        end
    end
    
    
    % Metric 2
    
    if filter_zero==0
        filter=~isnan(MeandischargeWDOcumecs_temp)&~isnan(model_runoff_temp)&Watercourselevelm_temp>ARI_height_minor(location_index);
    else
        filter=~isnan(MeandischargeWDOcumecs_temp)&~isnan(model_runoff_temp)&MeandischargeWDOcumecs_temp~=0&Watercourselevelm_temp>ARI_height_minor(location_index);
    end
    if sum(filter)==0
        metric_2(location_index)=NaN;
    else
        model_runoff_filtered=model_runoff_temp(filter);
        MeandischargeWDOcumecs_filtered=MeandischargeWDOcumecs_temp(filter);
        time_filtered=time(filter);
        time_filtered=datenum(time_filtered);
        obs_runoff=MeandischargeWDOcumecs_filtered./(catchment_area(location_index)*1000^2)*86400*1000;
        
        % Check lags. Observed data occurs after modelled.
        
        if lag~=0
            if sum(filter)<lag
                metric_2(location_index)=NaN;
            else
                
                for i=1:lag
                    met_temp(lag-i+1)=nashsutcliffe([time_filtered(1:end-i) obs_runoff(1:end-i)],[time_filtered(1+i:end) model_runoff_filtered(1+i:end)]);
                end
                met_temp(lag+1)=nashsutcliffe([time_filtered obs_runoff],[time_filtered model_runoff_filtered]);
                for i=1:lag
                    met_temp(lag+i+1)=nashsutcliffe([time_filtered(i+1:end) obs_runoff(i+1:end)],[time_filtered(1:end-i) model_runoff_filtered(1:end-i)]);
                end
                
                [best_met_i,best_lag_i]=max(met_temp);
                b=best_lag(location_index,3)+(lag+1);
                best_met_i=met_temp(b);
                metric_2(location_index)=best_met_i;
                best_lag(location_index,2)=best_lag(location_index,3);
            end
            
        else
            if sum(filter)<2
                metric_3(location_index)=NaN;
            else
                metric_2(location_index)=nashsutcliffe([time_filtered obs_runoff],[time_filtered model_runoff_filtered]);
            end
        end
    end
    
    % Metric 1 (Rory's version). Need six columns that have the return
    % intervals for water height and for run off. Compare to see if
    % catergories match up. 0,1,2 is minor, moderate, major match up respectively. 3,4,5
    % if they do not..
    
    if filter_zero==0
        filter=~isnan(Watercourselevelm_temp)&~isnan(model_runoff_temp)&model_runoff_temp>ARI_runoff_minor(location_index);
    else
        filter=~isnan(Watercourselevelm_temp)&~isnan(model_runoff_temp)&model_runoff_temp~=0&model_runoff_temp>ARI_runoff_minor(location_index);
    end
    
    Watercourselevelm_filtered=Watercourselevelm_temp(filter);
    model_runoff_filtered=model_runoff_temp(filter);
    
    met_temp2=zeros(2*lag+1,3);
    
    met_r_temp2=zeros(2*lag+1,3);
    
    day_temp2=zeros(2*lag+1,3);
    
    if isnan(ARI_height_minor(location_index))==1||isnan(ARI_height_moderate(location_index))==1||isnan(ARI_height_major(location_index))==1
        metric_1_rory_strict(location_index,:)=[NaN,NaN,NaN];
        metric_1_rory_relaxed(location_index,:)=[NaN,NaN,NaN];
    else
        
        %                     no_flooddays=0;
        %             noflood_succ=0;
        %             minor_flooddays=0;
        %             minor_succ_r=0;
        %             minor_succ=0;
        %             mod_flooddays=0;
        %             mod_succ=0;
        %             mod_succ_r=0;
        %             major_flooddays=0;
        %             major_succ=0;
        %             major_succ_r=0;
        
        if lag==0
            
            no_flooddays=0;
            noflood_succ=0;
            minor_flooddays=0;
            minor_succ_r=0;
            minor_succ=0;
            mod_flooddays=0;
            mod_succ=0;
            mod_succ_r=0;
            major_flooddays=0;
            major_succ=0;
            major_succ_r=0;
            
            for i=1:numel(Watercourselevelm_filtered)
                if model_runoff_filtered(i)<ARI_runoff_minor(location_index);
                    no_flooddays=no_flooddays+1;
                    if Watercourselevelm_filtered(i)<ARI_height_minor(location_index)
                        noflood_succ=noflood_succ+1;
                    end
                end
                if model_runoff_filtered(i)>=ARI_runoff_minor(location_index)&&model_runoff_filtered(i)<ARI_runoff_moderate(location_index);
                    minor_flooddays=minor_flooddays+1;
                    if Watercourselevelm_filtered(i)>ARI_height_minor(location_index)
                        minor_succ_r=minor_succ_r+1;
                    end
                    if Watercourselevelm_filtered(i)>ARI_height_minor(location_index)&&Watercourselevelm_filtered(i)<ARI_height_moderate(location_index)
                        minor_succ=minor_succ+1;
                    end
                end
                if model_runoff_filtered(i)>=ARI_runoff_moderate(location_index)&&model_runoff_filtered(i)<ARI_runoff_major(location_index);
                    mod_flooddays=mod_flooddays+1;
                    if Watercourselevelm_filtered(i)>ARI_height_moderate(location_index)
                        mod_succ_r=mod_succ_r+1;
                    end
                    if Watercourselevelm_filtered(i)>ARI_height_moderate(location_index)&&Watercourselevelm_filtered(i)<ARI_height_major(location_index)
                        mod_succ=mod_succ+1;
                    end
                end
                if model_runoff_filtered(i)>=ARI_runoff_major(location_index);
                    major_flooddays=major_flooddays+1;
                    if Watercourselevelm_filtered(i)>ARI_height_major(location_index)
                        major_succ=major_succ+1;
                    end
                end
            end
            
            
            minor_density=minor_succ/minor_flooddays*100;     % Converted into %.
            minor_density_r=minor_succ_r/minor_flooddays*100;
            
            moderate_density=mod_succ/mod_flooddays*100;    % Converted into %.
            moderate_density_r=mod_succ_r/mod_flooddays*100;
            
            major_density=major_succ/major_flooddays*100;     % Converted into %. Same as major_density_r
            
            noflood_density=noflood_succ/no_flooddays*100;
            
            %             met_temp2(lag+1,:)=[noflood_density,minor_density,moderate_density,major_density];
            %             met_r_temp2(lag+1,:)=[noflood_density,minor_density_r,moderate_density_r,major_density];
            %             day_temp2(lag+1,:)=[no_flooddays,minor_flooddays,mod_flooddays,major_flooddays];
            
            
            
        end
        
        
        
        if lag~=0
            
            
            no_flooddays=0;
            noflood_succ=0;
            minor_flooddays=0;
            minor_succ_r=0;
            minor_succ=0;
            mod_flooddays=0;
            mod_succ=0;
            mod_succ_r=0;
            major_flooddays=0;
            major_succ=0;
            major_succ_r=0;
            
            for i=1:numel(Watercourselevelm_filtered)
                if model_runoff_filtered(i)<ARI_runoff_minor(location_index);
                    no_flooddays=no_flooddays+1;
                    if Watercourselevelm_filtered(i)<ARI_height_minor(location_index)
                        noflood_succ=noflood_succ+1;
                    end
                end
                if model_runoff_filtered(i)>=ARI_runoff_minor(location_index)&&model_runoff_filtered(i)<ARI_runoff_moderate(location_index);
                    minor_flooddays=minor_flooddays+1;
                    if Watercourselevelm_filtered(i)>ARI_height_minor(location_index)
                        minor_succ_r=minor_succ_r+1;
                    end
                    if Watercourselevelm_filtered(i)>ARI_height_minor(location_index)&&Watercourselevelm_filtered(i)<ARI_height_moderate(location_index)
                        minor_succ=minor_succ+1;
                    end
                end
                if model_runoff_filtered(i)>=ARI_runoff_moderate(location_index)&&model_runoff_filtered(i)<ARI_runoff_major(location_index);
                    mod_flooddays=mod_flooddays+1;
                    if Watercourselevelm_filtered(i)>ARI_height_moderate(location_index)
                        mod_succ_r=mod_succ_r+1;
                    end
                    if Watercourselevelm_filtered(i)>ARI_height_moderate(location_index)&&Watercourselevelm_filtered(i)<ARI_height_major(location_index)
                        mod_succ=mod_succ+1;
                    end
                end
                if model_runoff_filtered(i)>=ARI_runoff_major(location_index);
                    major_flooddays=major_flooddays+1;
                    if Watercourselevelm_filtered(i)>ARI_height_major(location_index)
                        major_succ=major_succ+1;
                    end
                end
            end
            
            
            minor_density=minor_succ/minor_flooddays*100;     % Converted into %.
            minor_density_r=minor_succ_r/minor_flooddays*100;
            
            moderate_density=mod_succ/mod_flooddays*100;    % Converted into %.
            moderate_density_r=mod_succ_r/mod_flooddays*100;
            
            major_density=major_succ/major_flooddays*100;     % Converted into %. Same as major_density_r
            
            noflood_density=noflood_succ/no_flooddays*100;
            
            met_temp2(lag+1,:)=[minor_density,moderate_density,major_density];
            met_r_temp2(lag+1,:)=[minor_density_r,moderate_density_r,major_density];
            day_temp2(lag+1,:)=[minor_flooddays,mod_flooddays,major_flooddays];
            
            
            
            for j=1:lag
                
                no_flooddays=0;
                noflood_succ=0;
                minor_flooddays=0;
                minor_succ_r=0;
                minor_succ=0;
                mod_flooddays=0;
                mod_succ=0;
                mod_succ_r=0;
                major_flooddays=0;
                major_succ=0;
                major_succ_r=0;
                
                runoff_trim=model_runoff_filtered(1+j:end);
                height_trim=Watercourselevelm_filtered(1:end-j);
                
                
                for i=1:numel(height_trim)
                    if runoff_trim(i)<ARI_runoff_minor(location_index);
                        no_flooddays=no_flooddays+1;
                        if height_trim(i)<ARI_height_minor(location_index)
                            noflood_succ=noflood_succ+1;
                        end
                    end
                    if runoff_trim(i)>ARI_runoff_minor(location_index)&&runoff_trim(i)<ARI_runoff_moderate(location_index);
                        minor_flooddays=minor_flooddays+1;
                        if height_trim(i)>ARI_height_minor(location_index)
                            minor_succ_r=minor_succ_r+1;
                        end
                        if height_trim(i)>ARI_height_minor(location_index)&&height_trim(i)<ARI_height_moderate(location_index)
                            minor_succ=minor_succ+1;
                        end
                    end
                    if runoff_trim(i)>ARI_runoff_moderate(location_index)&&runoff_trim(i)<ARI_runoff_major(location_index);
                        mod_flooddays=mod_flooddays+1;
                        if height_trim(i)>ARI_height_moderate(location_index)
                            mod_succ_r=mod_succ_r+1;
                        end
                        if height_trim(i)>ARI_height_moderate(location_index)&&height_trim(i)<ARI_height_major(location_index)
                            mod_succ=mod_succ+1;
                        end
                    end
                    if runoff_trim(i)>ARI_runoff_major(location_index);
                        major_flooddays=major_flooddays+1;
                        if height_trim(i)>ARI_height_major(location_index)
                            major_succ=major_succ+1;
                        end
                    end
                end
                
                
                
                minor_density=minor_succ/minor_flooddays*100;     % Converted into %.
                minor_density_r=minor_succ_r/minor_flooddays*100;
                
                moderate_density=mod_succ/mod_flooddays*100;    % Converted into %.
                moderate_density_r=mod_succ_r/mod_flooddays*100;
                
                major_density=major_succ/major_flooddays*100;     % Converted into %. Same as major_density_r
                
                noflood_density=noflood_succ/no_flooddays*100;
                
                met_temp2(lag-j+1,:)=[minor_density,moderate_density,major_density];
                met_r_temp2(lag-j+1,:)=[minor_density_r,moderate_density_r,major_density];
                day_temp2(lag-j+1,:)=[minor_flooddays,mod_flooddays,major_flooddays];
            end
            
            
            
            
            for j=1:lag
                
                no_flooddays=0;
                noflood_succ=0;
                minor_flooddays=0;
                minor_succ_r=0;
                minor_succ=0;
                mod_flooddays=0;
                mod_succ=0;
                mod_succ_r=0;
                major_flooddays=0;
                major_succ=0;
                major_succ_r=0;
                
                runoff_trim=model_runoff_filtered(1:end-j);
                height_trim=Watercourselevelm_filtered(1+j:end);
                
                
                
                
                for i=1:numel(height_trim)
                    if runoff_trim(i)<ARI_runoff_minor(location_index);
                        no_flooddays=no_flooddays+1;
                        if height_trim(i)<ARI_height_minor(location_index)
                            noflood_succ=noflood_succ+1;
                        end
                    end
                    if runoff_trim(i)>ARI_runoff_minor(location_index)&&runoff_trim(i)<ARI_runoff_moderate(location_index);
                        minor_flooddays=minor_flooddays+1;
                        if height_trim(i)>ARI_height_minor(location_index)
                            minor_succ_r=minor_succ_r+1;
                        end
                        if height_trim(i)>ARI_height_minor(location_index)&&height_trim(i)<ARI_height_moderate(location_index)
                            minor_succ=minor_succ+1;
                        end
                    end
                    if runoff_trim(i)>ARI_runoff_moderate(location_index)&&runoff_trim(i)<ARI_runoff_major(location_index);
                        mod_flooddays=mod_flooddays+1;
                        if height_trim(i)>ARI_height_moderate(location_index)
                            mod_succ_r=mod_succ_r+1;
                        end
                        if height_trim(i)>ARI_height_moderate(location_index)&&height_trim(i)<ARI_height_major(location_index)
                            mod_succ=mod_succ+1;
                        end
                    end
                    if runoff_trim(i)>ARI_runoff_major(location_index);
                        major_flooddays=major_flooddays+1;
                        if height_trim(i)>ARI_height_major(location_index)
                            major_succ=major_succ+1;
                        end
                    end
                end
                
                minor_density=minor_succ/minor_flooddays*100;     % Converted into %.
                minor_density_r=minor_succ_r/minor_flooddays*100;
                
                moderate_density=mod_succ/mod_flooddays*100;    % Converted into %.
                moderate_density_r=mod_succ_r/mod_flooddays*100;
                
                major_density=major_succ/major_flooddays*100;     % Converted into %. Same as major_density_r
                
                noflood_density=noflood_succ/no_flooddays*100;
                
                met_temp2(lag+j+1,:)=[minor_density,moderate_density,major_density];
                met_r_temp2(lag+j+1,:)=[minor_density_r,moderate_density_r,major_density];
                day_temp2(lag+j+1,:)=[minor_flooddays,mod_flooddays,major_flooddays];
            end
        end
        
        if lag~=0
            
            [a,b]=max(sum(met_r_temp2,2));
            b=best_lag(location_index,3)+(lag+1);    % Turn on to base off R2 best lag
            
            
            metric_1_rory_strict(location_index,:)=met_temp2(b,:);
            metric_1_rory_relaxed(location_index,:)=met_r_temp2(b,:);
            no_events(location_index,:)=day_temp2(b,:);
            best_lag(location_index,1)=b-(lag+1);
        end
        if lag==0
            metric_1_rory_strict(location_index,:)=[minor_density,moderate_density,major_density];
            metric_1_rory_relaxed(location_index,:)=[minor_density_r,moderate_density_r,major_density];
        end
        
        
    end
    
end

%% Extra stuff that is now obsolete

% filter=~isnan(fcst)&~isnan(obs);
% fcst_f=fcst(filter);
% obs_f=obs(filter);

%% Tom's metrics

%% R

% R=corrcoef(fcst_f,obs_f);

%% CRPS from http://au.mathworks.com/matlabcentral/fileexchange/47807-continuous-rank-probability-score

% CRPS=crps(fcst_f,obs_f);
% disp(['CRPS: ',num2str(CRPS)])

%% Nash-Sutcliffe efficiency

% NSE= nashsutcliffe(obs_f,fcst_f)
% disp(['NSE: ',num2str(NSE)])

%% Histograms

%  figure('Forecasted')
%  histogram(fcst)
%  figure('Observed')
%  histogram(obs)

%% RMSE

% RMSE = sqrt(mean((fcst_f-obs_f).^2))
% disp(['RMSE: ',num2str(RMSE)])

%% Bias. Forecast - Observed

% bias=sum(fcst_f-obs_f)/numel(fcst_f);
% disp(['Bias: ',num2str(bias)])

%% Correlation co-efficient

% R = corrcoef(fcst_f,obs_f);
% disp(['R: ',num2str(R)])
