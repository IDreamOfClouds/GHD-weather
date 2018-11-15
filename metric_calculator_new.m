clc
clear all
close all

load raw_data_full.mat   % load data

z=0.5;

% Initialise matrices needed

direction_start=[1:15:345];
direction_start(1)=direction_start(1)-1;
direction_start=[direction_start 345];
direction_end=[15:15:360];

data_full=cell(2,size(wind_direction_data,2));
table=zeros(length(direction_start),5);
mean_wind=zeros(1,size(wind_direction_data,2));
mean_metric=zeros(size(wind_direction_data,2),4);


% Do the calcs for each location

for location_index=1:size(wind_direction_data,2)
    % for location_index=1:6
    stability_class=stability_class_data(:,location_index);
    wind_speed=wind_speed_data(:,location_index);
    for i=1:numel(wind_speed)
        if wind_speed(i)<0.5
            wind_speed(i)=0.5;
        end
    end
    sigma_y=zeros(length(stability_class));     
    sigma_z=zeros(length(stability_class));
    metric=zeros(length(stability_class));
    wind_direction=wind_direction_data(:,location_index);
    for i=1:length(stability_class) %   calculate for only E and F
        if stability_class{i}=='E'
            sigma_y(i)=51.06*z^0.919;
            sigma_z(i)=21*z^0.76;
        end
        if stability_class{i}=='F'
            sigma_y(i)=33.92*z^0.919;
            sigma_z(i)=14*z^0.78;
        end
        metric(i)=10000/(wind_speed(i)*sigma_y(i)*sigma_z(i));
    end
    filter=metric>0 & ~isinf(metric);
    metric=metric(filter);
    wind_direction=wind_direction(filter);
    for direction_index=1:length(direction_start)       % calulate for each direction
        metric_sp=metric;
        for i=1:numel(metric)
            if wind_direction(i)<direction_start(direction_index) || wind_direction(i)>direction_end(direction_index)
                metric_sp(i)=0;
            end
        end
        filter=wind_direction>=direction_start(direction_index) & wind_direction<=direction_end(direction_index);
        wind_sp=wind_speed(filter);
        percentile_999=prctile(metric_sp,99.9);
        percentile_995=prctile(metric_sp,99.5);
        percentile_990=prctile(metric_sp,99);
        percentile_950=prctile(metric_sp,95);
        avg_wind=mean(wind_sp);
        %         fprintf('Metric for wind direction interval %g - %g\n', [direction_start(direction_index) direction_end(direction_index)])
        %         fprintf('99.9 Metric: %g\n', percentile_999)
        %         fprintf('99.5 Metric: %g\n', percentile_995)
        %         fprintf('99.0 Metric: %g\n', percentile_990)
        %         fprintf('90.0 Metric: %g\n', percentile_900)
        table(direction_index,:)=[percentile_999,percentile_995,percentile_990,percentile_950,avg_wind];    % entry for each location
    end
    data_full{1,location_index}=colheaders{location_index};
    data_full{2,location_index}=table;
    mean_wind(location_index)=mean(wind_speed);
    mean_metric(location_index,:)=mean(data_full{2,location_index}(:,1:4)); % place each location into a larger matrix
end

