function gain = cn_sar_gain(repo, direction_A)
% Existing owner receive baseline, not a newly designed CST or installed SAR pattern.
    policy=jsondecode(fileread(fullfile(repo,'output/codex/emission_inputs/latest_owner_policy.json')));
    d=direction_A(:)/norm(direction_A);theta=acosd(max(-1,min(1,d(1))));
    if theta>80
        gain=policy.sar_absolute_peak_gain_dbi+policy.sar_rear_relative_peak_db;return;
    end
    % SAR transverse roll is unconfirmed: higher of owner azimuth/elevation envelopes.
    gain=policy.sar_absolute_peak_gain_dbi+max(envelope(policy.azimuth,theta),envelope(policy.elevation,theta));
end
function value=envelope(axis,angle)
    pts=axis.samples;
    pts=[pts;axis.half_power_angle_deg,-3;axis.first_null_angle_deg,axis.first_null_db;axis.maximum_sidelobe_angle_deg,axis.maximum_sidelobe_db];
    [~,order]=sort(pts(:,1));pts=pts(order,:);
    exact=find(abs(pts(:,1)-angle)<1e-10,1);
    if ~isempty(exact);value=pts(exact,2);return;end
    if angle>pts(end,1);value=axis.maximum_sidelobe_db;return;end
    if angle<=axis.first_null_angle_deg;value=interp1(pts(:,1),pts(:,2),angle,'linear');return;end
    j=find(pts(:,1)>angle,1);value=max(pts(j-1:j,2));
end
