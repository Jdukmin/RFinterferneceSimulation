classdef Validate
    %VALIDATE Input validation helpers (portable MATLAB/Octave subset).
    %   These replace `arguments`/property-validation blocks (unsupported in
    %   Octave) so the same code runs under MATLAB and Octave. Errors use
    %   stable identifiers under the `rfscreen:` namespace.
    methods (Static)
        function s = id(value, fieldName)
            %ID Validate a non-empty char identifier; returns it unchanged.
            if ~ischar(value) || isempty(value)
                error('rfscreen:validate:id', ...
                    '%s must be a non-empty char identifier.', fieldName);
            end
            s = value;
        end

        function v = finiteScalar(value, fieldName)
            %FINITESCALAR Validate a finite real scalar.
            if ~(isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value))
                error('rfscreen:validate:finiteScalar', ...
                    '%s must be a finite real scalar.', fieldName);
            end
            v = double(value);
        end

        function v = positiveScalar(value, fieldName)
            %POSITIVESCALAR Validate a finite positive real scalar.
            v = rfscreen.util.Validate.finiteScalar(value, fieldName);
            if v <= 0
                error('rfscreen:validate:positiveScalar', ...
                    '%s must be > 0 (got %g).', fieldName, v);
            end
        end

        function v = nonnegativeScalar(value, fieldName)
            %NONNEGATIVESCALAR Validate a finite non-negative real scalar.
            v = rfscreen.util.Validate.finiteScalar(value, fieldName);
            if v < 0
                error('rfscreen:validate:nonnegativeScalar', ...
                    '%s must be >= 0 (got %g).', fieldName, v);
            end
        end

        function v = vector3(value, fieldName)
            %VECTOR3 Validate a finite 3x1 (or 1x3) vector; returns 3x1.
            if ~(isnumeric(value) && numel(value) == 3 && isreal(value) && all(isfinite(value(:))))
                error('rfscreen:validate:vector3', ...
                    '%s must be a finite 3-element real vector.', fieldName);
            end
            v = double(value(:));
        end

        function v = member(value, allowed, fieldName)
            %MEMBER Validate that a char value is in an allowed set.
            if ~ischar(value) || ~any(strcmp(value, allowed))
                error('rfscreen:validate:member', ...
                    '%s must be one of {%s} (got ''%s'').', ...
                    fieldName, strjoin(allowed, ', '), rfscreen.util.Validate.asStr(value));
            end
            v = value;
        end

        function v = monotonicVector(value, fieldName)
            %MONOTONICVECTOR Validate a strictly increasing finite row vector.
            if ~(isnumeric(value) && isvector(value) && ~isempty(value) && all(isfinite(value(:))))
                error('rfscreen:validate:monotonicVector', ...
                    '%s must be a finite non-empty numeric vector.', fieldName);
            end
            v = double(value(:)).';
            if numel(v) > 1 && any(diff(v) <= 0)
                error('rfscreen:validate:monotonicVector', ...
                    '%s must be strictly increasing.', fieldName);
            end
        end

        function s = asStr(value)
            %ASSTR Best-effort string for error messages.
            if ischar(value)
                s = value;
            elseif isnumeric(value) && isscalar(value)
                s = num2str(value);
            else
                s = class(value);
            end
        end
    end
end
