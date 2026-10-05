function p = cn_load_pattern(repo, entry)
% Separate accepted dataset -> existing InstalledPattern/FreeSpacePattern classes.
    CA=rfscreen.kaa.CstLocalFrameAdapter; M=CA.localToAntenna();
    fq=entry.frequencies_ghz(:).'*1e9;az=-180:2:180;el=-90:2:90;
    G=zeros(numel(el),numel(az),numel(fq));
    for k=1:numel(fq)
        cuts=cell(1,2);planes={'XZ','YZ'};
        for j=1:2
            file=fullfile(repo,entry.directory,'registered',sprintf('f%.6f_%s.csv',fq(k)/1e9,planes{j}));
            conv=rfscreen.patterndata.SourceCoordinateConvention(struct('plane',planes{j},'angleRange','[0,360)','gainUnit','dBi'));
            meta=struct('patternId',[entry.dataset_id '_' planes{j}],'frequency_Hz',fq(k),'fidelity','SIMULATED_2D_CUT');
            cuts{j}=rfscreen.patterndata.CsvPatternImporter(file,conv,meta).importCut();
            assert(numel(cuts{j}.theta_deg)==360 && all(isfinite(cuts{j}.gain_dBi)));
        end
        % Use the EXISTING CST-local adapter, not the generic cut assembler's different roll map.
        for ie=1:numel(el)
            for ia=1:numel(az)
                dA=[cosd(el(ie))*cosd(az(ia));cosd(el(ie))*sind(az(ia));sind(el(ie))];dL=M.'*dA;
                G(ie,ia,k)=rfscreen.kaa.KaVictimResponse.cutGain(cuts{1}.gain_dBi,cuts{2}.gain_dBi,dL);
            end
        end
    end
    grid=rfscreen.antenna.PatternGrid(az,el,fq,G);opts=struct('confidence',NaN,'polarization','UNKNOWN');
    if strcmp(entry.pattern_class,'InstalledPattern')
        p=rfscreen.antenna.InstalledPattern(entry.dataset_id,'APPROX_FROM_CUTS',grid,'CST',opts);
    else
        p=rfscreen.antenna.FreeSpacePattern(entry.dataset_id,'APPROX_FROM_CUTS',grid,opts);
    end
end
