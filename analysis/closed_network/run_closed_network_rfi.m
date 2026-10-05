function rows = run_closed_network_rfi(validateOnly)
% Exact ten victim-band pair families; no solver; missing inputs never get substituted.
    if nargin<1;validateOnly=false;end
    here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));addpath(fullfile(repo,'src'));
    manifest=jsondecode(fileread(fullfile(here,'rfi_plan.json')));
    regfile=fullfile(repo,'data/closed_network_patterns/registry.json');
    registry=containers.Map('KeyType','char','ValueType','any');
    if exist(regfile,'file')==2
        entries=jsondecode(fileread(regfile));if iscell(entries);entries=[entries{:}];end
        for k=1:numel(entries);registry(entries(k).dataset_id)=entries(k);end
    end
    geom=jsondecode(fileread(fullfile(repo,'cst/closed_network/full_spacecraft_geometry.json')));
    installs=geom.installations;if iscell(installs);installs=[installs{:}];end
    cache=containers.Map('KeyType','char','ValueType','any');rows={};
    policy=rfscreen.config.PatternInterpolationPolicy(struct('freqMethod','linear','outOfBandFreq','error'));
    for k=1:numel(manifest)
        r=manifest(k);status='INPUT_MISSING';vals=NaN(1,8);
        if registry.isKey(r.tx_dataset) && registry.isKey(r.rx_dataset)
            status='INPUTS_AVAILABLE';
            if ~validateOnly
                tx=load(r.tx_dataset);rx=load(r.rx_dataset);it=inst(r.tx_installation);ir=inst(r.rx_installation);
                u=ir.position_body_mm(:)-it.position_body_mm(:);distance=norm(u)/1000;u=u/norm(u);
                dT=rfscreen.kaa.CstLocalFrameAdapter.localToAntenna()*(it.nominal_R_BL.'*u);
                dR=rfscreen.kaa.CstLocalFrameAdapter.localToAntenna()*(ir.nominal_R_BL.'*(-u));
                f=linspace(r.f_low_ghz*1e9,r.f_high_ghz*1e9,161);result=zeros(numel(f),8);
                for j=1:numel(f)
                    gt=tx.evaluate(f(j),atan2d(dT(2),dT(1)),asind(dT(3)),policy);
                    gr=rx.evaluate(f(j),atan2d(dR(2),dR(1)),asind(dR(3)),policy);
                    loss=rfscreen.psd.PsdMath.fspl(f(j),distance);coupling=gt+gr-loss;
                    port=rfscreen.psd.PsdMath.victimPortPsd(r.source_psd_dbm_hz,0,coupling);
                    margin=rfscreen.psd.PsdMath.margin(r.allowable_psd_dbm_hz,port);
                    need=max(0,rfscreen.psd.PsdMath.requiredSuppression(port,r.allowable_psd_dbm_hz));
                    result(j,:)=[gt,gr,loss,coupling,port,margin,need,f(j)];
                end
                [~,j]=max(result(:,5));vals=result(j,:);status='ANTENNA_PORT_PSD_EVALUATED';
            end
        end
        rows(end+1,:)={r.pair_id,r.pair,r.tx_installation,r.rx_installation,r.tx_configuration,r.rx_configuration,r.tx_dataset,r.rx_dataset,status,vals(1),vals(2),vals(3),vals(4),vals(5),r.allowable_psd_dbm_hz,vals(6),vals(7),vals(8),'RX_CHAIN_INPUT_MISSING','PRIOR_WORKER_SOURCE_BASELINE; DOMAIN_APPLICABILITY_REQUIRES_REVIEW','APPROX_FROM_CUTS; FAR_FIELD_FSPL_MODEL'};
    end
    if ~validateOnly
        out=fullfile(repo,'output/closed_network');if exist(out,'dir')~=7;mkdir(out);end
        writecsv(fullfile(out,'rfi_ten_pairs.csv'),{'pair_id','pair','tx_installation','rx_installation','tx_configuration','rx_configuration','tx_dataset','rx_dataset','status','gtx_dbi','grx_dbi','fspl_db','coupling_db','victim_psd_dbm_hz','allowable_psd_dbm_hz','margin_db','required_suppression_db','worst_frequency_hz','rx_chain_status','source_provenance','coupling_fidelity'},rows);
        comparisons={};
        for k=1:size(rows,1)
            if ~strcmp(rows{k,6},'INSTALLED');continue;end
            match=find(cellfun(@(a,b,c,d) strcmp(a,rows{k,1})&&strcmp(b,rows{k,3})&&strcmp(c,rows{k,4})&&strcmp(d,rows{k,5}),rows(:,1),rows(:,3),rows(:,4),rows(:,5)) & cellfun(@(x)strcmp(x,'ORIGINAL'),rows(:,6)));
            if isempty(match);continue;end
            j=match(1);delta=rows{k,14}-rows{j,14};comparisons(end+1,:)={rows{k,1},rows{k,3},rows{k,4},rows{k,5},rows{j,14},rows{k,14},delta};
        end
        writecsv(fullfile(out,'original_installed_comparison.csv'),{'pair_id','tx_installation','rx_installation','tx_configuration','original_psd_dbm_hz','installed_psd_dbm_hz','delta_installed_db'},comparisons);
        reflector={};
        for k=1:size(rows,1)
            if ~strcmp(rows{k,5},'FEED_WITH_REFLECTOR');continue;end
            match=find(cellfun(@(a,b,c,d)strcmp(a,rows{k,1})&&strcmp(b,rows{k,3})&&strcmp(c,rows{k,4})&&strcmp(d,rows{k,6}),rows(:,1),rows(:,3),rows(:,4),rows(:,6)) & cellfun(@(x)strcmp(x,'FEED_ONLY'),rows(:,5)));
            if isempty(match);continue;end
            j=match(1);reflector(end+1,:)={rows{k,1},rows{k,3},rows{k,4},rows{k,6},rows{j,14},rows{k,14},rows{k,14}-rows{j,14}};
        end
        writecsv(fullfile(out,'feed_reflector_comparison.csv'),{'pair_id','tx_installation','rx_installation','rx_configuration','feed_psd_dbm_hz','reflector_psd_dbm_hz','delta_reflector_db'},reflector);
    end
    ready=sum(strcmp(rows(:,9),'INPUTS_AVAILABLE') | strcmp(rows(:,9),'ANTENNA_PORT_PSD_EVALUATED'));
    fprintf('Pair families: %d; comparison rows: %d; input-ready rows: %d\n',numel(unique(rows(:,1))),size(rows,1),ready);
    function i=inst(id)
        i=installs(find(strcmp({installs.installation_id},id),1));assert(~isempty(i),'Installation not found');
        if strcmp(i.mount_type,'GIMBAL');warning('KAA nominal gimbal reference orientation; not a commanded tracking case');end
    end
    function p=load(id)
        if ~cache.isKey(id);cache(id)=cn_load_pattern(repo,registry(id));end;p=cache(id);
    end
end
function writecsv(path,headers,rows)
    fid=fopen(path,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',strjoin(headers,','));
    for k=1:size(rows,1)
        values=rows(k,:);for j=1:numel(values);if isnumeric(values{j});values{j}=sprintf('%.12g',values{j});end;end
        fprintf(fid,'%s\n',strjoin(values,','));
    end
end
