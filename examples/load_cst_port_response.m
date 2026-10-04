function result = load_cst_port_response(family, band, quantity)
%LOAD_CST_PORT_RESPONSE Import a completed fixed-surrogate response band.
%   r = load_cst_port_response('S','L1','RealizedGain');
%   g = r.evaluate(1.57542e9, 0, 0);
%   Source cuts are 1 degree. The 3D grid is APPROX_FROM_CUTS, not measured
%   or installed. The bounded evaluator prevents reuse across gaps or outside
%   a single-frequency case. Use r.evaluate rather than unbounded grid access.
    if nargin < 3; quantity = 'Gain'; end
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(repoRoot, 'src'));
    manifest = jsondecode(fileread(fullfile(repoRoot, 'data', ...
        'antenna_port_response_cst', 'provenance.json')));
    cuts = manifest.cuts;
    selected = strcmp({cuts.family}, family) & strcmp({cuts.band}, band) & ...
        strcmp({cuts.quantity}, quantity);
    cuts = cuts(selected);
    if isempty(cuts)
        error('rfscreen:cst:noResponse', ...
            'No completed reliable %s response for %s/%s.', quantity, family, band);
    end
    frequencies = sort(unique([cuts.frequency_hz]));
    assembler = rfscreen.patterndata.CutPatternAssembler;
    for fi = 1:numel(frequencies)
        imported = cell(1,2);
        planes = {'XZ','YZ'};
        for pi = 1:2
            matching = [cuts.frequency_hz] == frequencies(fi) & ...
                strcmp({cuts.plane}, planes{pi});
            if sum(matching) ~= 1
                error('rfscreen:cst:missingCut', 'Expected one %s cut.', planes{pi});
            end
            item = cuts(matching);
            convention = rfscreen.patterndata.SourceCoordinateConvention(struct( ...
                'plane', planes{pi}, 'angleRange', '[0,360)', ...
                'polarizationComponent', 'TOTAL'));
            if strcmp(quantity, 'IntendedCPGain')
                convention = rfscreen.patterndata.SourceCoordinateConvention(struct( ...
                    'plane', planes{pi}, 'angleRange', '[0,360)', ...
                    'polarizationComponent', 'CO'));
            end
            meta = struct('patternId', [family '_' band '_' planes{pi}], ...
                'fidelity', 'SIMULATED_2D_CUT', 'frequency_Hz', frequencies(fi));
            importer = rfscreen.patterndata.CsvPatternImporter( ...
                fullfile(repoRoot, item.path), convention, meta);
            imported{pi} = importer.importCut();
        end
        planePattern = assembler.assembleFreeSpacePattern([family '_' band], ...
            imported{1}, imported{2}, struct('frequency_Hz', frequencies(fi)));
        if fi == 1
            az = planePattern.grid.az_deg;
            el = planePattern.grid.el_deg;
            gain = zeros(numel(el), numel(az), numel(frequencies));
        end
        gain(:,:,fi) = planePattern.grid.gain_dBi;
    end
    grid = rfscreen.antenna.PatternGrid(az, el, frequencies, gain);
    pattern = rfscreen.antenna.FreeSpacePattern([family '_' band '_' quantity], ...
        'APPROX_FROM_CUTS', grid, struct('confidence',0.5,'polarization','UNKNOWN'));
    policy = rfscreen.config.PatternInterpolationPolicy(struct( ...
        'freqMethod','linear','outOfBandFreq','error'));
    interval = [frequencies(1) frequencies(end)];
    result = struct('pattern',pattern,'policy',policy, ...
        'frequencyInterval_Hz',interval,'quantity',quantity, ...
        'provenance','CST_FIXED_GEOMETRY_PORT_RESPONSE', ...
        'limitations',manifest.source_limitations);
    result.evaluate = @(f,azimuth,elevation) bounded(pattern,policy,interval,f,azimuth,elevation);
end

function g = bounded(pattern,policy,interval,f,azimuth,elevation)
    if any(f < interval(1) | f > interval(2))
        error('rfscreen:cst:outOfBand','Requested frequency is outside the computed response band.');
    end
    g = pattern.evaluate(f,azimuth,elevation,policy);
end
