function test_ten_pair_execution()
% Full 10-family driver with SYNTHETIC constant-gain exports in a temporary repository.
    here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
    fixture=tempname();mkdir(fixture);cleanup=onCleanup(@()rmdir(fixture,'s'));
    copyfile(fullfile(repo,'src'),fullfile(fixture,'src'));target=fullfile(fixture,'analysis/closed_network');mkdir(target);
    for name={'cn_load_pattern.m','run_closed_network_rfi.m','cn_sar_gain.m'};copyfile(fullfile(here,name{1}),target);end
    copyfile(fullfile(here,'rfi_plan.json'),target);
    mkdir(fullfile(fixture,'cst/closed_network'));copyfile(fullfile(repo,'cst/closed_network/full_spacecraft_geometry.json'),fullfile(fixture,'cst/closed_network'));
    mkdir(fullfile(fixture,'output/codex/emission_inputs'));copyfile(fullfile(repo,'output/codex/emission_inputs/latest_owner_policy.json'),fullfile(fixture,'output/codex/emission_inputs'));
    plan=jsondecode(fileread(fullfile(target,'rfi_plan.json')));ids=unique([{plan.tx_dataset},{plan.rx_dataset}]);entries=struct([]);
    for k=1:numel(ids)
        id=ids{k};directory=['data/closed_network_patterns/' id];mkdir(fullfile(fixture,directory,'registered'));
        if strcmp(id,'SAR_ENGINEERING_RECEIVE_BASELINE');fq=[8.9,9.65,10.4];cls='EngineeringReceiveBaseline';
        else
            r=plan(find(strcmp({plan.tx_dataset},id)|strcmp({plan.rx_dataset},id),1));
            if strfind(id,'L1');fq=[1.563,1.57542,1.588];elseif strfind(id,'STM')||strfind(id,'SBA_TM');fq=[2.2,2.25,2.3];
            elseif strfind(id,'SAR');fq=[8.9,9.65,10.4];else;fq=[10.55,10.6,10.65];end
            cls='FreeSpacePattern';if strfind(id,'INSTALLED');cls='InstalledPattern';end
            for f=fq
                for plane={'XZ','YZ'}
                    fid=fopen(fullfile(fixture,directory,'registered',sprintf('f%.6f_%s.csv',f,plane{1})),'w');fprintf(fid,'theta,gain\n');
                    for angle=0:359;fprintf(fid,'%d,10\n',angle);end;fclose(fid);
                end
            end
        end
        entries(k)=struct('dataset_id',id,'directory',directory,'frequencies_ghz',fq,'pattern_class',cls);
    end
    fid=fopen(fullfile(fixture,'data/closed_network_patterns/registry.json'),'w');fprintf(fid,'%s\n',jsonencode(entries));fclose(fid);
    previous=path;restore=onCleanup(@()path(previous));addpath(target,'-begin');clear run_closed_network_rfi cn_load_pattern cn_sar_gain;
    warning('off','backtrace');rows=run_closed_network_rfi(false);
    assert(size(rows,1)==67 && numel(unique(rows(:,1)))==10);
    assert(all(strcmp(rows(:,9),'ANTENNA_PORT_PSD_EVALUATED')));assert(all(isfinite(cell2mat(rows(:,14)))));
    sar=strcmp(rows(:,8),'SAR_ENGINEERING_RECEIVE_BASELINE');assert(sum(sar)==7 && all(cell2mat(rows(sar,11))==2));
    assert(all(cell2mat(rows(sar,15))==-176));
    a=fileread(fullfile(fixture,'output/closed_network/original_installed_comparison.csv'));
    b=fileread(fullfile(fixture,'output/closed_network/feed_reflector_comparison.csv'));
    assert(numel(strfind(a,sprintf('\n')))==31);assert(numel(strfind(b,sprintf('\n')))==23);
    fprintf('PASS SYNTHETIC ONLY: 10/10 families; 67 finite rows; seven SAR rear +2 dBi rows / -176 criterion; 30 installed and 22 reflector comparisons.\n');
end
