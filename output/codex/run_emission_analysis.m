function run_emission_analysis()
% Independent worker driver around the unchanged freeze-point PSD engine.
  out=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(out)); addpath(fullfile(repo,'src'));
  diary(fullfile(out,'emission_execution.log')); diary on; fprintf('GNU Octave %s\n',version);
  M=jsondecode(fileread(fullfile(repo,'data/antenna_port_response_cst/provenance.json')));cuts=M.cuts;if iscell(cuts);cuts=[cuts{:}];end
  pc=containers.Map('KeyType','char','ValueType','any'); cc=containers.Map('KeyType','char','ValueType','any');
  [S,E]=rfscreen.psd.EmissionMaskTable.read(fullfile(out,'emission_inputs/tx_emission_masks.csv'));
  B=rfscreen.psd.ReceiverBaseline.read(fullfile(out,'emission_inputs/receiver_baseline.csv'));
  FS=rfscreen.psd.FilterScenario.read(fullfile(out,'emission_inputs/filter_scenarios.csv'));
  MB=rfscreen.mission.MissionCaseBuilder;cases=MB.listCases(); V=rfscreen.psd.VictimBandPsdPath;
  summary={}; details={}; spur={}; excluded={};
  sets={'PRIMARY','GENERIC_ITU','GAIN_CAP_0','GAIN_CAP_20','GAIN_CAP_40'};
  sh={'case_id','tx_id','rx_id','tx_system','victim_band','source_set','filter_db','distance_m','worst_frequency_hz','source_psd_dbm_hz','coupling_db','victim_psd_dbm_hz','allowable_dbm_hz','margin_db','minimum_required_additional_suppression_db','status','missing_reason','sweep_refinement_delta_db','reference_plane'};
  dh={'case_id','tx_id','rx_id','victim_band','frequency_hz','distance_m','tx_gain_dbi','rx_gain_dbi','fspl_db','conducted_coupling_db','radiated_transfer_db','tx_source','rx_source'};
  for ci=1:numel(cases)
    c=MB.buildCase(cases(ci).caseId,struct('patternCache',pc,'modeId','SCREENING_ALL_TX','azStep_deg',10,'elStep_deg',10));sc=c.scenario;
    txids=sc.transmitters.keys();rxids=sc.receivers.keys();
    for ti=1:numel(txids)
      tx=sc.transmitters(txids{ti});ta=sc.antennas(tx.antennaId);it=sc.installations(ta.installationId);
      tt=strsplit(tx.id,'@');template=tt{1};
      if strncmp(template,'SAR',3);continue;end
      for ri=1:numel(rxids)
        rx=sc.receivers(rxids{ri});ra=sc.antennas(rx.antennaId);ir=sc.installations(ra.installationId);rr=strsplit(rx.id,'@');b=rfscreen.psd.ReceiverBaseline.lookup(B,rr{1});
        if strcmp(ta.installationId,ra.installationId)
          excluded(end+1,:)={c.caseId,tx.id,rx.id,'SAME_PORT_ISOLATION_MISSING; not a propagating unwanted-emission path'};continue;
        end
        geo=rfscreen.geometry.AntennaToAntennaFOV.relativeGeometry(it.position_m,it.R_BA,ir.position_m,ir.R_BA);
        f=rfscreen.psd.ReceiverBaseline.tuningSweep(b,161);
        mon=[cuts(strcmp({cuts.band},b.victim_band)).frequency_hz];mon=mon(mon>=f(1)&mon<=f(end));f=unique([f mon]);
        fc=rfscreen.psd.ReceiverBaseline.tuningSweep(b,81);fc=unique([fc mon]);
        gt=NaN(size(f));gr=gt;fspl=gt;cd=gt;er=gt;
        for j=1:numel(f)
          [gt(j),ts,tq]=gainat(repo,cuts,cc,family(ta.id),b.victim_band,f(j),geo.txAz_deg,geo.txEl_deg);
          [gr(j),rs,rq]=gainat(repo,cuts,cc,family(ra.id),b.victim_band,f(j),geo.rxAz_deg,geo.rxEl_deg);
          fspl(j)=rfscreen.psd.PsdMath.fspl(f(j),geo.distance_m);cd(j)=gt(j)+gr(j)-fspl(j);er(j)=gr(j)-fspl(j);
          details(end+1,:)={c.caseId,tx.id,rx.id,b.victim_band,f(j),geo.distance_m,gt(j),gr(j),fspl(j),cd(j),er(j),ts,rs};
        end
        [~,ic]=ismember(fc,f);assert(all(ic>0));
        for ss=1:numel(sets)
          hit=cellfun(@(s) strcmp(s.txSystem,template)&&strcmp(s.victimBand,b.victim_band)&&strcmp(s.emissionType,'BROADBAND_PSD'),S);
          extra=cellfun(@(e) strcmp(e.source_set,sets{ss}),E);specs=S(hit&extra);
          if isempty(specs);continue;end
          for fi=1:numel(FS)
            R=V.evaluate(f,cd,er,b.allowable_psd_dBmHz,specs,tx.power_dBm,FS{fi},0,strncmp(template,'KA',2));
            reason='';status='UNKNOWN';peak=NaN;k=1;delta=NaN;port=NaN;margin=NaN;req=NaN;
            if all(isfinite(R.port_psd_dBmHz))
              [peak,k]=max(R.port_psd_dBmHz);margin=b.allowable_psd_dBmHz-peak;req=max(0,peak+FS{fi}.atten_dB-b.allowable_psd_dBmHz);port=peak;
              status='FAIL';if margin>=0;status='PASS';end
              delta=max(R.port_psd_dBmHz)-max(R.port_psd_dBmHz(ic));assert(abs(delta)<0.01,'frequency sweep peak not converged');
            else
              reason=strjoin(unique(R.status),';');if strcmp(ts,'NORMALIZATION_UNRELIABLE')||strcmp(rs,'NORMALIZATION_UNRELIABLE');reason=[reason ';NORMALIZATION_UNRELIABLE'];end
            end
            summary(end+1,:)={c.caseId,tx.id,rx.id,template,b.victim_band,sets{ss},FS{fi}.atten_dB,geo.distance_m,f(k),R.source_psd_dBmHz(k),R.coupling_dB(k),port,b.allowable_psd_dBmHz,margin,req,status,reason,delta,R.plane};
          end
          if strcmp(sets{ss},'PRIMARY')
            tone=S(cellfun(@(s) strcmp(s.txSystem,template)&&strcmp(s.victimBand,b.victim_band)&&strcmp(s.emissionType,'DISCRETE_SPUR'),S)&extra);
            if ~isempty(tone)
              for fi=1:numel(FS)
                pp=V.spurPortPower(tone{1},tx.power_dBm,FS{fi}.atten_dB,cd);
                if all(isfinite(pp));peak=max(pp);else;peak=NaN;end
                spur(end+1,:)={c.caseId,tx.id,rx.id,b.victim_band,FS{fi}.atten_dB,tone{1}.powerDbm(tx.power_dBm),peak,'UNKNOWN_TONE_CRITERION; discrete power is never a broadband PSD'};
              end
            end
          end
        end
      end
    end
    fprintf('%s complete; scenario rows=%d\n',c.caseId,size(summary,1));
  end
  writecells(fullfile(out,'victim_band_scenarios.csv'),sh,summary);writecells(fullfile(out,'victim_band_coupling.csv'),dh,details);
  writecells(fullfile(out,'discrete_spur_results.csv'),{'case_id','tx_id','rx_id','victim_band','filter_db','source_tone_dbm','worst_victim_tone_dbm','status'},spur);
  writecells(fullfile(out,'emission_exclusions.csv'),{'case_id','tx_id','rx_id','reason'},excluded);
  h=testutil.Harness();test_rfi_psd(h);assert(h.report());
  fprintf('Reference -120 -> -180 dBm/Hz; +2 dB verified in unchanged-engine tests.\n');diary off;
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
  if any(~[list.normalization_reliable]); source='NORMALIZATION_UNRELIABLE'; return; end
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
