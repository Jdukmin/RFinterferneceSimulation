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
        [A,E]=meshgrid(az,el);dL=M.'*[cosd(E(:)).'.*cosd(A(:)).';cosd(E(:)).'.*sind(A(:)).';sind(E(:)).'];
        th=acosd(max(-1,min(1,dL(3,:))));ph=mod(atan2d(dL(2,:),dL(1,:)),360);
        xz=cuts{1}.gain_dBi(:).';yz=cuts{2}.gain_dBi(:).';
        sample=@(c,t)interp1(0:360,[c,c(1)],mod(t,360),'linear');
        v=[sample(xz,th);sample(yz,th);sample(xz,360-th);sample(yz,360-th)];
        sector=floor(ph/90)+1;w=(ph-90*(sector-1))/90;n=1:numel(ph);
        q=(1-w).*v(sub2ind(size(v),sector,n))+w.*v(sub2ind(size(v),mod(sector,4)+1,n));
        G(:,:,k)=reshape(q,numel(el),numel(az));
    end
    grid=rfscreen.antenna.PatternGrid(az,el,fq,G);opts=struct('confidence',NaN,'polarization','UNKNOWN');
    if strcmp(entry.pattern_class,'InstalledPattern')
        p=rfscreen.antenna.InstalledPattern(entry.dataset_id,'APPROX_FROM_CUTS',grid,'CST',opts);
    else
        p=rfscreen.antenna.FreeSpacePattern(entry.dataset_id,'APPROX_FROM_CUTS',grid,opts);
    end
end
