classdef SyntheticPatternFactory
    %SYNTHETICPATTERNFACTORY Test-only synthetic patterns (SR-054, DR-040, Task 32).
    %   EVERY product has provenance = SYNTHETIC_TEST and a name containing
    %   'SYNTHETIC_TEST', so synthetic data can never be mistaken for reference/
    %   mission data (VR-085). NO real/mission gain values are produced.
    %
    %   These return FreeSpacePattern objects on a default 5-degree az/el grid.
    methods (Static)
        function p = isotropic(gain_dBi, frequency_Hz)
            %ISOTROPIC Constant-gain pattern over all directions.
            if nargin < 2 || isempty(frequency_Hz); frequency_Hz = 1e9; end
            gain_dBi = rfscreen.util.Validate.finiteScalar(gain_dBi, 'gain_dBi');
            [az, el] = rfscreen.antenna.SyntheticPatternFactory.defaultGrid();
            G = gain_dBi * ones(numel(el), numel(az), 1);
            grid = rfscreen.antenna.PatternGrid(az, el, frequency_Hz, G);
            p = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_isotropic', ...
                rfscreen.antenna.PatternProvenance.SYNTHETIC_TEST, grid);
        end

        function p = cosineDirectional(peak_dBi, frequency_Hz, exponent)
            %COSINEDIRECTIONAL Boresight beam ~ peak + 20*log10(cos(theta)^n).
            %   theta = off-boresight angle; back hemisphere floored very low.
            if nargin < 2 || isempty(frequency_Hz); frequency_Hz = 1e9; end
            if nargin < 3 || isempty(exponent); exponent = 2; end
            peak_dBi = rfscreen.util.Validate.finiteScalar(peak_dBi, 'peak_dBi');
            [az, el] = rfscreen.antenna.SyntheticPatternFactory.defaultGrid();
            [AZ, EL] = meshgrid(az, el);           % size [nE x nA]
            cosTheta = cosd(EL) .* cosd(AZ);        % dot(dir, boresight +X)
            cosTheta = max(cosTheta, 1e-6);         % floor for back hemisphere
            G = peak_dBi + 20 * log10(cosTheta .^ exponent);
            grid = rfscreen.antenna.PatternGrid(az, el, frequency_Hz, G);
            p = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_cosine', ...
                rfscreen.antenna.PatternProvenance.SYNTHETIC_TEST, grid);
        end

        function p = mainSideBack(peak_dBi, side_dBi, back_dBi, frequency_Hz, mainAngle_deg)
            %MAINSIDEBACK Discrete main/side/back synthetic lobes for lobe-class tests.
            %   main: off-boresight <= mainAngle_deg; back: > 90 deg; else side.
            if nargin < 4 || isempty(frequency_Hz); frequency_Hz = 1e9; end
            if nargin < 5 || isempty(mainAngle_deg); mainAngle_deg = 10; end
            V = rfscreen.util.Validate;
            peak_dBi = V.finiteScalar(peak_dBi, 'peak_dBi');
            side_dBi = V.finiteScalar(side_dBi, 'side_dBi');
            back_dBi = V.finiteScalar(back_dBi, 'back_dBi');
            [az, el] = rfscreen.antenna.SyntheticPatternFactory.defaultGrid();
            [AZ, EL] = meshgrid(az, el);
            cosTheta = max(min(cosd(EL) .* cosd(AZ), 1), -1);
            theta = acosd(cosTheta);
            G = side_dBi * ones(size(theta));
            G(theta <= mainAngle_deg) = peak_dBi;
            G(theta > 90) = back_dBi;
            grid = rfscreen.antenna.PatternGrid(az, el, frequency_Hz, G);
            p = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_mainSideBack', ...
                rfscreen.antenna.PatternProvenance.SYNTHETIC_TEST, grid);
        end

        function [az, el] = defaultGrid()
            %DEFAULTGRID Default 5-degree az/el grids.
            az = -180:5:180;
            el = -90:5:90;
        end
    end
end
