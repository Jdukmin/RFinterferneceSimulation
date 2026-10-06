function test_closed_network_adapter()
% Synthetic temporary fixtures only; never treated as mission antenna data.
    here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));addpath(fullfile(repo,'src'));
    rows=run_closed_network_rfi(true);assert(size(rows,1)==67);assert(all(strcmp(rows(:,9),'INPUT_MISSING')));
    temp=tempname();mkdir(temp);mkdir(fullfile(temp,'test'));mkdir(fullfile(temp,'test','registered'));
    cleanup=onCleanup(@()rmdir(temp,'s'));
    for plane={'XZ','YZ'}
        name=plane{1};fid=fopen(fullfile(temp,'test','registered',['f1.000000_' name '.csv']),'w');fprintf(fid,'theta,gain\n');
        amp=10;if strcmp(name,'YZ');amp=20;end
        for angle=0:359;fprintf(fid,'%d,%.12g\n',angle,amp*sind(angle));end;fclose(fid);
    end
    entry=struct('frequencies_ghz',1,'directory','test','dataset_id','SYNTHETIC_TEST_CUTS','pattern_class','FreeSpacePattern');
    p=cn_load_pattern(temp,entry);assert(isa(p,'rfscreen.antenna.FreeSpacePattern'));
    assert(abs(p.evaluate(1e9,0,90)-10)<1e-7);assert(abs(p.evaluate(1e9,-90,0)-20)<1e-7);assert(abs(p.evaluate(1e9,0,0))<1e-7);
    for az=[-180,-132,-40,16,80,170]
        for el=[-70,-16,0,32,86]
            dA=[cosd(el)*cosd(az);cosd(el)*sind(az);sind(el)];dL=rfscreen.kaa.CstLocalFrameAdapter.localToAntenna().'*dA;
            expected=rfscreen.kaa.KaVictimResponse.cutGain(10*sind(0:359),20*sind(0:359),dL);
            assert(abs(p.evaluate(1e9,az,el)-expected)<1e-7);
        end
    end
    entry.pattern_class='InstalledPattern';p=cn_load_pattern(temp,entry);assert(isa(p,'rfscreen.antenna.InstalledPattern') && p.isInstalled());
    assert(strcmp(p.installedSource,'CST'));
    assert(cn_sar_gain(repo,[1;0;0])==52);assert(cn_sar_gain(repo,[-1;0;0])==2);
    assert(cn_sar_gain(repo,[cosd(85);sind(85);0])==2);
    fprintf('PASS: 10 families / 67 comparisons; native CST frame; distinct installed/original types; SAR 52/+2 dBi baseline.\n');
end
