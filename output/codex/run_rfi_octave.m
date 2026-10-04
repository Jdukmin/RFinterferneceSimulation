function run_rfi_octave(action)
% Executed in GNU Octave. No CST solve or frozen input modification.
  out=fileparts(mfilename('fullpath')); repo=fileparts(fileparts(out));
  addpath(fullfile(repo,'src')); addpath(fullfile(repo,'examples'));
  if nargin>0 && strcmp(action,'sar'); sar_response(repo,out); return; end
  diary(fullfile(out,'octave_execution.log')); diary on;
  fprintf('GNU Octave %s; repo=%s\n',version,repo);
  manifest=jsondecode(fileread(fullfile(repo,'data/antenna_port_response_cst/provenance.json')));
  cuts=manifest.cuts; if iscell(cuts); cuts=[cuts{:}]; end
  cache=containers.Map('KeyType','char','ValueType','any');
  cutcache=containers.Map('KeyType','char','ValueType','any');
  MB=rfscreen.mission.MissionCaseBuilder; RL=rfscreen.mission.RfcLevelReport;
  cases=MB.listCases(); modes={'SCREENING_ALL_TX','NOM_NADIR_KAA1','NOM_ZENITH_KAA2'};
  allbase=[]; records={}; evidence={}; samples={}; aggregates={}; excluded={};
  h={'case_id','mode_id','tx_id','rx_id','tx_installation','rx_installation','tx_band','tx_fc_hz','rx_fc_hz','distance_m','tx_az_deg','tx_el_deg','rx_az_deg','rx_el_deg','los','blocking_panels','tx_gain_dbi','rx_gain_dbi','tx_quantity','rx_quantity','coupling_validity','fspl_db','s21_db','tx_power_dbm','received_center_dbm','received_integrated_dbm','noise_dbm','allowable_dbm','required_rejection_db','spectral_factor_db','inband_interference_dbm','margin_db','analysis_status','missing_reason','spatial_samples','integration_refinement_delta_db'};
  eh={'case_id','mode_id','function_id','installation_id','role','baseline_pattern_key','baseline_source','baseline_xz','baseline_yz','sba_variant','gps_band','active_tx_ids','active_rx_ids'};
  sh={'case_id','mode_id','tx_id','rx_id','frequency_hz','tx_gain_dbi','rx_gain_dbi','fspl_db','s21_db','coupling_validity','tx_source','rx_source','tx_quantity','rx_quantity'};
  ah={'case_id','mode_id','rx_id','required_pairs','supported_pairs','aggregate_port_dbm_supported_only','aggregate_inband_dbm_supported_only','allowable_dbm','coverage_status'};
  for ci=1:numel(cases)
    for mi=1:numel(modes)
      c=MB.buildCase(cases(ci).caseId,struct('patternCache',cache,'modeId',modes{mi},'azStep_deg',10,'elStep_deg',10));
      sc=c.scenario; txids=sc.activeTxIds; if isempty(txids); txids=sc.transmitters.keys(); end
      rxids=sc.activeRxIds; if isempty(rxids); rxids=sc.receivers.keys(); end
      base=RL.build(c,RL.couplingModel()); allbase=[allbase,base];
      for fi=1:numel(c.functions)
        f=c.functions(fi); paths=f.patternSourceFiles; if isempty(paths); paths={'',''}; end
        evidence(end+1,:)={c.caseId,modes{mi},f.functionId,f.installationId,f.role,f.patternKey,f.patternSource,paths{1},paths{2},c.sbaVariant,c.gpsBand,strjoin(txids,';'),strjoin(rxids,';')};
      end
      for ri=1:numel(rxids)
        rx=sc.receivers(rxids{ri}); ra=sc.antennas(rx.antennaId); ir=sc.installations(ra.installationId);
        noise=rx.noiseModel.noisePower_dBm(rx.bw_Hz); allow=noise+rx.interferenceCriterion.thresholdValue;
        required=0; supported=0; sumport=0; suminband=0;
        for ti=1:numel(txids)
          tx=sc.transmitters(txids{ti}); ta=sc.antennas(tx.antennaId); it=sc.installations(ta.installationId);
          if strcmp(ta.installationId,ra.installationId)
            excluded(end+1,:)={c.caseId,modes{mi},tx.id,rx.id,'SAME_INSTALLATION_NO_SEPARATE_PROPAGATION_PATH'}; continue;
          end
          required=required+1;
          geo=rfscreen.geometry.AntennaToAntennaFOV.relativeGeometry(it.position_m,it.R_BA,ir.position_m,ir.R_BA);
          los=rfscreen.geometry.LineOfSight.segment(ta.installationId,ra.installationId,it.position_m,ir.position_m,sc.activeStructures());
          band=txband(tx.fc_Hz); tf=family(ta.id); rf=family(ra.id);
          [gt,ts,tq]=gainat(repo,cuts,cutcache,tf,band,tx.fc_Hz,geo.txAz_deg,geo.txEl_deg);
          [gr,rs,rq]=gainat(repo,cuts,cutcache,rf,band,tx.fc_Hz,geo.rxAz_deg,geo.rxEl_deg);
          spec=rfscreen.interference.SpectralCouplingAnalyzer.analyze(tx.spectrum,rx.filter);
          missing=''; if ~isfinite(gt); missing=[missing 'TX_PATTERN_MISSING;']; end
          if ~isfinite(gr); missing=[missing 'RX_PATTERN_MISSING;']; end
          fspl=NaN; s21=NaN; received=NaN; pint=NaN; pin=NaN; margin=NaN; rej=NaN; delta=NaN;
          valid='NOT_EVALUATED'; status='INPUT_MISSING'; ns=0;
          if isempty(missing)
            ctx=rfscreen.coupling.CouplingModel.newContext(); ctx.distance_m=geo.distance_m;
            ctx.txGain_dBi=gt; ctx.rxGain_dBi=gr; ctx.frequency_Hz=tx.fc_Hz; ctx.txPower_dBm=tx.power_dBm;
            ctx.txMaxDim_m=ta.maxDimension_m; ctx.rxMaxDim_m=ra.maxDimension_m;
            model=RL.couplingModel(); cres=model.computeCoupling(ctx); fspl=cres.metric_dB; valid=cres.validity;
            s21=gt+gr-fspl; received=tx.power_dBm+s21;
            [portW,inW,ss,bad]=integrate(repo,cuts,cutcache,tf,rf,band,tx,rx,geo,ctx,model,64,c.caseId,modes{mi});
            if ~isempty(bad); missing=bad; status='INPUT_MISSING_IN_OCCUPIED_BAND';
            else
              [portFine,inFine,unused,bad2]=integrate(repo,cuts,cutcache,tf,rf,band,tx,rx,geo,ctx,model,128,c.caseId,modes{mi});
              assert(isempty(bad2)); delta=10*log10(portFine/portW); assert(abs(delta)<0.1,'Spatial integration refinement >0.1 dB');
              pint=wattsdbm(portFine); pin=wattsdbm(inFine); margin=allow-pin; rej=max(0,pint-allow); ns=128;
              samples=[samples;ss]; supported=supported+1; sumport=sumport+portFine; suminband=suminband+inFine;
              if spec.overlapFraction==0; status='IDEAL_FILTER_NO_FUNDAMENTAL_OVERLAP'; else; status='LINEAR_MODEL_EVALUATED'; end
              if ~strcmp(tq,'RealizedGain') || ~strcmp(rq,'RealizedGain'); status=[status '_REFERENCE_GAIN_MISMATCH_UNKNOWN']; end
            end
          end
          records(end+1,:)={c.caseId,modes{mi},tx.id,rx.id,ta.installationId,ra.installationId,band,tx.fc_Hz,rx.fc_Hz,geo.distance_m,geo.txAz_deg,geo.txEl_deg,geo.rxAz_deg,geo.rxEl_deg,los.status,strjoin(los.blockingStructureIds,';'),gt,gr,tq,rq,valid,fspl,s21,tx.power_dBm,received,pint,noise,allow,rej,spec.spectralFactor_dB,pin,margin,status,missing,ns,delta};
        end
        coverage='COMPLETE_LINEAR_MODEL_ONLY'; if supported<required; coverage='INCOMPLETE_MISSING_RESPONSES'; end
        aggregates(end+1,:)={c.caseId,modes{mi},rx.id,required,supported,wattsdbm(sumport),wattsdbm(suminband),allow,coverage};
      end
      fprintf('%s / %s: legacy=%d, cumulative frequency-aware=%d\n',c.caseId,modes{mi},numel(base),size(records,1));
    end
  end
  RL.writeCsv(allbase,fullfile(out,'legacy_engine_reference.csv'));
  writecells(fullfile(out,'rfi_pairs.csv'),h,records);
  writecells(fullfile(out,'case_pattern_evidence.csv'),eh,evidence);
  writecells(fullfile(out,'frequency_direction_evidence.csv'),sh,samples);
  writecells(fullfile(out,'receiver_aggregates.csv'),ah,aggregates);
  writecells(fullfile(out,'excluded_same_installation.csv'),{'case_id','mode_id','tx_id','rx_id','reason'},excluded);
  availability={};
  for ff={'S','L','ISL','KA'}
    for bb={'S_TC','S_TM','L1','L2','L5','SAR','ISL','KA'}
      idx=strcmp({cuts.family},ff{1}) & strcmp({cuts.band},bb{1}) & strcmp({cuts.quantity},'RealizedGain');
      state='MISSING'; if any(idx); state='CST_REALIZED_GAIN_AVAILABLE'; elseif strcmp(ff{1},'KA') && strcmp(bb{1},'KA'); state='FROZEN_REFLECTOR_REFERENCE_GAIN_MISMATCH_UNKNOWN'; end
      availability(end+1,:)={ff{1},bb{1},state};
    end
  end
  writecells(fullfile(out,'band_availability.csv'),{'family','band','status'},availability);
  fid=fopen(fullfile(out,'run_metadata.json'),'w'); fprintf(fid,'%s',jsonencode(struct('runtime',['GNU Octave ' version],'cases',6,'modes',3,'scenarios',18,'pairs',size(records,1),'pattern_policy','FREE_SPACE_PRIMARY','angular_method','native 1-degree periodic cuts plus documented two-cut azimuth interpolation; no 3D claim','legacy_assembly_grid_deg',10,'frequency_integration','linear watts midpoint 64 vs 128 bins; refinement <0.1 dB','emission_model','baseline rectangular PSD; ideal receiver bandpass; no spur/nonlinear data'))); fclose(fid);
  fprintf('FINISHED: %d pair rows, %d evidence samples\n',size(records,1),size(samples,1)); diary off;
end

function sar_response(repo,out)
  m=jsondecode(fileread(fullfile(repo,'data/antenna_port_response_cst/provenance.json'))); cuts=m.cuts; if iscell(cuts); cuts=[cuts{:}]; end
  cache=containers.Map('KeyType','char','ValueType','any'); pc=containers.Map('KeyType','char','ValueType','any'); rows={};
  MB=rfscreen.mission.MissionCaseBuilder; cases=MB.listCases();
  for ci=1:numel(cases)
    c=MB.buildCase(cases(ci).caseId,struct('patternCache',pc,'azStep_deg',10,'elStep_deg',10)); sc=c.scenario;
    si=sc.installations('SAR_ANT'); ids=sc.receivers.keys();
    for ri=1:numel(ids)
      rx=sc.receivers(ids{ri}); ra=sc.antennas(rx.antennaId); ir=sc.installations(ra.installationId);
      geo=rfscreen.geometry.AntennaToAntennaFOV.relativeGeometry(si.position_m,si.R_BA,ir.position_m,ir.R_BA);
      for f=[8.9 9.65 10.4]*1e9
        [gr,source,q]=gainat(repo,cuts,cache,family(ra.id),'SAR',f,geo.rxAz_deg,geo.rxEl_deg);
        fspl=20*log10(4*pi*geo.distance_m*f/299792458); threshold=rx.noiseModel.noisePower_dBm(rx.bw_Hz)+rx.interferenceCriterion.thresholdValue;
        transfer=gr-fspl; maxeirp=threshold-transfer; status='SAR_PATTERN_MISSING_NO_ABSOLUTE_RFI;RX_RESPONSE_AVAILABLE';
        if ~isfinite(gr); status='SAR_AND_RX_PATTERN_MISSING'; end
        rows(end+1,:)={c.caseId,rx.id,f,geo.distance_m,geo.rxAz_deg,geo.rxEl_deg,gr,q,source,fspl,transfer,maxeirp,rx.filter.responseLinear(f),status};
      end
    end
  end
  writecells(fullfile(out,'sar_response_sensitivity.csv'),{'case_id','rx_id','frequency_hz','distance_m','rx_az_deg','rx_el_deg','rx_gain_dbi','quantity','source','free_space_assumed_fspl_db','port_transfer_per_directional_eirp_db','directional_eirp_threshold_dbm_no_filter_rejection','ideal_rx_filter_power_ratio','status'},rows);
  fprintf('SAR response-only sensitivity: %d rows; no actual SAR absolute power assumed\n',size(rows,1));
end

function f=family(id)
  if strncmp(id,'SBA',3); f='S'; elseif strncmp(id,'GPS',3); f='L'; elseif strncmp(id,'KAA',3); f='KA'; elseif strcmp(id,'ISL'); f='ISL'; else; f='SAR'; end
end
function b=txband(f)
  if f<3e9; b='S_TM'; elseif f<11e9; b='ISL'; else; b='KA'; end
end
function [g,source,quantity]=gainat(repo,cuts,cache,family,band,f,az,el)
  g=NaN; source=''; quantity='RealizedGain';
  idx=strcmp({cuts.family},family)&strcmp({cuts.band},band)&strcmp({cuts.quantity},'RealizedGain'); list=cuts(idx);
  if strcmp(family,'KA') && strcmp(band,'KA')
    fs=[25.5 26.25 27]*1e9; vals=zeros(1,3); paths={}; tags={'25p5','26p25','27'};
    for j=1:3
      paths{end+1}=sprintf('data/Kaband_KAA_CST/KA_DLS_physical_f%s_XZ.csv',tags{j});
      paths{end+1}=sprintf('data/Kaband_KAA_CST/KA_DLS_physical_f%s_YZ.csv',tags{j});
      vals(j)=directiongain(repo,cache,paths{end-1},paths{end},az,el);
    end
    if f>=fs(1)&&f<=fs(end); g=interp1(fs,vals,f,'linear'); end
    source=strjoin(paths,';'); quantity='FROZEN_REFLECTOR_REFERENCE_GAIN_MISMATCH_UNKNOWN'; return;
  end
  if isempty(list); return; end
  fs=sort(unique([list.frequency_hz])); if f<fs(1)||f>fs(end); return; end
  vals=zeros(size(fs)); paths={};
  for j=1:numel(fs)
    x=list([list.frequency_hz]==fs(j)&strcmp({list.plane},'XZ'));
    y=list([list.frequency_hz]==fs(j)&strcmp({list.plane},'YZ'));
    assert(numel(x)==1&&numel(y)==1); vals(j)=directiongain(repo,cache,x.path,y.path,az,el);
    paths{end+1}=[x.path '|' x.source_case]; paths{end+1}=[y.path '|' y.source_case];
  end
  if numel(fs)==1; g=vals(1); else; g=interp1(fs,vals,f,'linear'); end
  source=strjoin(paths,';');
end
function g=directiongain(repo,cache,xpath,ypath,az,el)
  x=getcut(repo,cache,xpath,'XZ'); y=getcut(repo,cache,ypath,'YZ');
  d=rfscreen.patterndata.CutPatternAssembler.canonicalToAntenna().' * rfscreen.geometry.DirectionCalculator.azElToDirection(az,el);
  theta=acosd(max(-1,min(1,d(3)))); phi=mod(atan2d(d(2),d(1)),360);
  g=rfscreen.patterndata.CutPatternAssembler.reconstructGain(x,y,theta,phi);
end
function c=getcut(repo,cache,path,plane)
  if cache.isKey(path); c=cache(path); return; end
  a=dlmread(fullfile(repo,path),',',1,0);
  c=rfscreen.patterndata.CanonicalPatternCut(struct('patternId',strrep(strrep(path,'/','_'),'.','_'),'plane',plane,'theta_deg',a(:,1),'gain_dBi',a(:,2),'samplingType','UNIFORM','fidelity','SIMULATED_2D_CUT'));
  cache(path)=c;
end
function [portW,inW,ss,bad]=integrate(repo,cuts,cache,tf,rf,band,tx,rx,geo,ctx,model,n,caseid,mode)
  domain=tx.spectrum.supportBand_Hz(); nodes=unique([linspace(domain(1),domain(2),n+1),rx.filter.nativeGrid_Hz(),rx.filter.relevantBand_Hz()]); nodes=nodes(nodes>=domain(1)&nodes<=domain(2));
  portW=0; inW=0; ss={}; bad='';
  for i=1:numel(nodes)-1
    f=(nodes(i)+nodes(i+1))/2; df=nodes(i+1)-nodes(i);
    [gt,ts,tq]=gainat(repo,cuts,cache,tf,band,f,geo.txAz_deg,geo.txEl_deg);
    [gr,rs,rq]=gainat(repo,cuts,cache,rf,band,f,geo.rxAz_deg,geo.rxEl_deg);
    if ~isfinite(gt)||~isfinite(gr); bad='PATTERN_UNAVAILABLE_WITHIN_TX_SUPPORT'; return; end
    ctx.frequency_Hz=f; ctx.txGain_dBi=gt; ctx.rxGain_dBi=gr; cres=model.computeCoupling(ctx);
    s21=gt+gr-cres.metric_dB;
    spatial=10^(s21/10); w=tx.spectrum.psd_WPerHz(f)*spatial*df; portW=portW+w; inW=inW+w*rx.filter.responseLinear(f);
    ss(end+1,:)={caseid,mode,tx.id,rx.id,f,gt,gr,cres.metric_dB,s21,cres.validity,ts,rs,tq,rq};
  end
end
function d=wattsdbm(w)
  if w==0; d=-Inf; else; d=10*log10(w)+30; end
end
function writecells(path,headers,rows)
  fid=fopen(path,'w'); fprintf(fid,'%s\n',strjoin(headers,','));
  for i=1:size(rows,1)
    vals=cell(1,numel(headers));
    for j=1:numel(headers)
      v=rows{i,j}; if isnumeric(v)||islogical(v); v=sprintf('%.12g',v); end
      vals{j}=['"' strrep(v,'"','""') '"'];
    end
    fprintf(fid,'%s\n',strjoin(vals,','));
  end
  fclose(fid);
end
