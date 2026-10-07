function result = main(varargin)
%MAIN Repository entry point.
%   main('--cal')                     CAL path: data/cal CST ASCII full-sphere patterns -> validation ->
%                                     pattern catalog/binding -> figures -> CAL RFI (existing engine) ->
%                                     output/cal (see docs/icd/cal_cst_3d.md).
%   main('--cal', name, value, ...)   options: 'calDir', 'outDir', 'configDir', 'plots' (true/false),
%                                     'clean' (true/false), 'verbose' (true/false).
%   main()                            prints this usage (no analysis is started).
%   Octave CLI:  octave-cli --no-gui --eval "main('--cal')"
%   Existing workflows (examples/, tests/run_all_tests.m, analysis/closed_network) are unchanged.
    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, 'src'));
    result = [];
    if nargin == 0 || ~ischar(varargin{1})
        help('main');
        return;
    end
    switch lower(varargin{1})
        case '--cal'
            opts = struct('repoRoot', here);
            rest = varargin(2:end);
            if mod(numel(rest), 2) ~= 0
                error('main:badArgs', 'options must be name/value pairs.');
            end
            for k = 1:2:numel(rest)
                opts.(rest{k}) = rest{k + 1};
            end
            result = rfscreen.cal.CalRunner.run(opts);
        otherwise
            error('main:unknownMode', 'unknown mode "%s" (supported: --cal).', varargin{1});
    end
    if nargout == 0
        clear result;
    end
end
