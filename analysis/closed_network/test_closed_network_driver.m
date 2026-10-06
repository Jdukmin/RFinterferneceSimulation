function test_closed_network_driver()
% Synthetic end-to-end fixture in a temporary repository; no mission RF results.
    here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
    fixture=tempname();mkdir(fixture);cleanup=onCleanup(@()rmdir(fixture,'s'));
    copyfile(fullfile(repo,'src'),fullfile(fixture,'src'));
    target=fullfile(fixture,'analysis','closed_network');mkdir(target);
    copyfile(fullfile(here,'cn_load_pattern.m'),target);copyfile(fullfile(here,'run_closed_network_rfi.m'),target);
    mkdir(fullfile(fixture,'data','closed_network_patterns'));mkdir(fullfile(fixture,'cst','closed_network'));
    ids={'TX_FEED','TX_REFLECTOR','RX_ORIGINAL','RX_INSTALLED'};gains=[10 13 20 25];entries=struct([]);
    for k=1:4
        directory=['data/closed_network_patterns/' ids{k}];mkdir(fullfile(fixture,directory,'registered'));
        for plane={'XZ','YZ'}
            fid=fopen(fullfile(fixture,directory,'registered',['f1.000000_' plane{1} '.csv']),'w');fprintf(fid,'theta,gain\n');
            for angle=0:359;fprintf(fid,'%d,%g\n',angle,gains(k));end;fclose(fid);
        end
        cls='FreeSpacePattern';if k==4;cls='InstalledPattern';end
        entries(k)=struct('dataset_id',ids{k},'directory',directory,'frequencies_ghz',1,'pattern_class',cls);
    end
    writejson(fullfile(fixture,'data/closed_network_patterns/registry.json'),entries);
    geom.installations=[struct('installation_id','TEST_TX','position_body_mm',[0 0 0],'nominal_R_BL',eye(3),'mount_type','FIXED'), ...
                       struct('installation_id','TEST_RX','position_body_mm',[0 0 3000],'nominal_R_BL',eye(3),'mount_type','FIXED')];
    writejson(fullfile(fixture,'cst/closed_network/full_spacecraft_geometry.json'),geom);
    manifest=struct([]);k=0;
    for it=1:2
        for ir=1:2
            k=k+1;tc='FEED_ONLY';if it==2;tc='FEED_WITH_REFLECTOR';end
            rc='ORIGINAL';if ir==2;rc='INSTALLED';end
            manifest(k)=struct('pair_id','TEST_ONLY','pair','SYNTHETIC','tx_installation','TEST_TX','rx_installation','TEST_RX', ...
                'tx_configuration',tc,'rx_configuration',rc,'tx_dataset',ids{it},'rx_dataset',ids{ir+2}, ...
                'f_low_ghz',1,'f_high_ghz',1,'source_psd_dbm_hz',-100,'allowable_psd_dbm_hz',-177,'source_provenance','SYNTHETIC,CSV_QUOTING_TEST');
        end
    end
    writejson(fullfile(target,'rfi_plan.json'),manifest);
    % Resolve the identical driver from the synthetic repository, then restore search path.
    previous=path;restore=onCleanup(@()path(previous));addpath(target,'-begin');clear run_closed_network_rfi cn_load_pattern;
    rows=run_closed_network_rfi(false);
    expected=-100+10+20-rfscreen.psd.PsdMath.fspl(1e9,3);
    assert(abs(rows{1,14}-expected)<1e-8);assert(abs(rows{1,16}-(-177-expected))<1e-8);
    assert(abs(rows{1,17}-max(0,expected+177))<1e-8);
    assert(abs(rows{2,14}-rows{1,14}-5)<1e-8);assert(abs(rows{3,14}-rows{1,14}-3)<1e-8);
    original=fileread(fullfile(fixture,'output/closed_network/original_installed_comparison.csv'));
    reflector=fileread(fullfile(fixture,'output/closed_network/feed_reflector_comparison.csv'));
    assert(numel(strfind(original,'TEST_ONLY'))==2);assert(numel(strfind(reflector,'TEST_ONLY'))==2);
    primary=fileread(fullfile(fixture,'output/closed_network/rfi_ten_pairs.csv'));
    assert(~isempty(strfind(primary,'"SYNTHETIC,CSV_QUOTING_TEST"')));
    fprintf('PASS: synthetic PSD/reference-plane arithmetic; required suppression; installed +5 dB; reflector +3 dB; comparison CSVs.\n');
end
function writejson(file,value)
    fid=fopen(file,'w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(value));fclose(fid);
end
