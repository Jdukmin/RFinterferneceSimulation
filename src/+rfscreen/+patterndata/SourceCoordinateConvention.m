classdef SourceCoordinateConvention
    %SOURCECOORDINATECONVENTION Descriptor of an external cut's coordinate convention
    %   (DR-103, ICD pattern_data.md 2). The importer canonicalizes USING this
    %   descriptor; no universal sign convention is hard-coded (§14, §15).
    properties (SetAccess = private)
        boresightAxis           % e.g. '+Z'
        plane                   % 'XZ' | 'YZ'
        angleZeroAxis           % direction of theta=0 (boresight for these cuts)
        positiveRotationToward  % axis theta increases toward
        angleRange              % '[-180,180]' | '[0,360)'
        angleUnit               % 'deg'
        gainUnit                % 'dBi'
        polarizationComponent   % 'TOTAL'/'THETA'/'PHI'/'CO'/'CROSS'/'UNKNOWN'
    end

    methods
        function obj = SourceCoordinateConvention(opts)
            if nargin < 1 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            names = rfscreen.patterndata.SourceCoordinateConvention.axisNames();
            getopt = @(nm, dflt) rfscreen.patterndata.SourceCoordinateConvention.opt(opts, nm, dflt);

            obj.plane = V.member(getopt('plane', ''), {'XZ', 'YZ'}, 'plane');
            obj.boresightAxis = V.member(getopt('boresightAxis', '+Z'), names, 'boresightAxis');
            obj.angleZeroAxis = V.member(getopt('angleZeroAxis', '+Z'), names, 'angleZeroAxis');
            defRot = '+X'; if strcmp(obj.plane, 'YZ'); defRot = '+Y'; end
            obj.positiveRotationToward = V.member(getopt('positiveRotationToward', defRot), ...
                names, 'positiveRotationToward');
            obj.angleRange = V.member(getopt('angleRange', '[-180,180]'), ...
                {'[-180,180]', '[0,360)'}, 'angleRange');
            obj.angleUnit = V.member(getopt('angleUnit', 'deg'), {'deg'}, 'angleUnit');
            obj.gainUnit = V.member(getopt('gainUnit', 'dBi'), {'dBi'}, 'gainUnit');
            obj.polarizationComponent = V.member(getopt('polarizationComponent', 'UNKNOWN'), ...
                {'TOTAL', 'THETA', 'PHI', 'CO', 'CROSS', 'UNKNOWN'}, 'polarizationComponent');

            % zero-axis and rotation axis must be orthogonal, and neither may be the plane normal.
            z0 = rfscreen.patterndata.SourceCoordinateConvention.axisVec(obj.angleZeroAxis);
            t0 = rfscreen.patterndata.SourceCoordinateConvention.axisVec(obj.positiveRotationToward);
            if abs(dot(z0, t0)) > 1e-9
                error('rfscreen:patterndata:badConvention', ...
                    'angleZeroAxis and positiveRotationToward must be orthogonal.');
            end
            n = rfscreen.patterndata.SourceCoordinateConvention.planeNormal(obj.plane);
            if abs(dot(z0, n)) > 1e-9 || abs(dot(t0, n)) > 1e-9
                error('rfscreen:patterndata:badConvention', ...
                    'zero/rotation axes must lie in the %s plane.', obj.plane);
            end
        end

        function d = directionForTheta(obj, theta_deg)
            %DIRECTIONFORTHETA Source-frame unit vector for a cut angle (§1.1).
            z0 = rfscreen.patterndata.SourceCoordinateConvention.axisVec(obj.angleZeroAxis);
            t0 = rfscreen.patterndata.SourceCoordinateConvention.axisVec(obj.positiveRotationToward);
            d = cosd(theta_deg) .* z0 + sind(theta_deg) .* t0;
        end

        function s = toStruct(obj)
            p = properties(obj); s = struct();
            for i = 1:numel(p); s.(p{i}) = obj.(p{i}); end
        end
    end

    methods (Static)
        function v = axisNames()
            v = {'+X', '-X', '+Y', '-Y', '+Z', '-Z'};
        end
        function u = axisVec(name)
            switch name
                case '+X'; u = [1;0;0];
                case '-X'; u = [-1;0;0];
                case '+Y'; u = [0;1;0];
                case '-Y'; u = [0;-1;0];
                case '+Z'; u = [0;0;1];
                case '-Z'; u = [0;0;-1];
                otherwise
                    error('rfscreen:patterndata:badAxis', 'unknown axis ''%s''.', name);
            end
        end
        function n = planeNormal(plane)
            switch plane
                case 'XZ'; n = [0;1;0];   % XZ plane normal = Y
                case 'YZ'; n = [1;0;0];   % YZ plane normal = X
                otherwise
                    error('rfscreen:patterndata:badPlane', 'unknown plane ''%s''.', plane);
            end
        end
        function c = canonicalFor(plane)
            %CANONICALFOR Fixed canonical convention for a plane (boresight +Z, [0,360)).
            defRot = '+X'; if strcmp(plane, 'YZ'); defRot = '+Y'; end
            c = rfscreen.patterndata.SourceCoordinateConvention(struct( ...
                'plane', plane, 'boresightAxis', '+Z', 'angleZeroAxis', '+Z', ...
                'positiveRotationToward', defRot, 'angleRange', '[0,360)', ...
                'angleUnit', 'deg', 'gainUnit', 'dBi'));
        end
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
                v = s.(name);
            else
                v = default;
            end
        end
    end
end
