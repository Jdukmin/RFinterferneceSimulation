function setup_paths()
%SETUP_PATHS Add the rfscreen source tree to the MATLAB/Octave path.
%   Run once per session before using the rfscreen.* packages.
    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, 'src'));
end
