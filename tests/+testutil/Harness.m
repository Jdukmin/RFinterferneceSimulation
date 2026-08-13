classdef Harness < handle
    %HARNESS Minimal portable (MATLAB+Octave) assertion/reporting harness.
    %   Assertions record pass/fail and DO NOT throw, so a whole test file runs
    %   to completion. Deterministic; no randomness.
    properties
        nPass = 0
        nFail = 0
        failures = {}     % cellstr of "group :: name : message"
        group = ''
    end

    methods
        function setGroup(obj, g)
            obj.group = g;
        end

        function ok(obj, name, cond)
            if logical(cond)
                obj.pass(name);
            else
                obj.fail(name, 'expected true');
            end
        end

        function pass(obj, name) %#ok<INUSD>
            obj.nPass = obj.nPass + 1;
        end

        function fail(obj, name, msg)
            obj.nFail = obj.nFail + 1;
            obj.failures{end+1} = sprintf('[%s] %s : %s', obj.group, name, msg);
        end

        function eqTol(obj, name, actual, expected, tol)
            if nargin < 5 || isempty(tol); tol = 1e-9; end
            a = double(actual(:)); e = double(expected(:));
            if numel(a) ~= numel(e)
                obj.fail(name, sprintf('size mismatch (%d vs %d)', numel(a), numel(e)));
                return;
            end
            d = max(abs(a - e));
            if isempty(d); d = 0; end
            if d <= tol
                obj.pass(name);
            else
                obj.fail(name, sprintf('max abs diff %.3g > tol %.3g', d, tol));
            end
        end

        function eqStr(obj, name, actual, expected)
            if ischar(actual) && ischar(expected) && strcmp(actual, expected)
                obj.pass(name);
            else
                obj.fail(name, sprintf('''%s'' ~= ''%s''', ...
                    rfscreen.util.Validate.asStr(actual), ...
                    rfscreen.util.Validate.asStr(expected)));
            end
        end

        function isTrue(obj, name, cond)
            obj.ok(name, cond);
        end

        function isFalse(obj, name, cond)
            obj.ok(name, ~logical(cond));
        end

        function isNaNval(obj, name, v)
            obj.ok(name, isscalar(v) && isnan(v));
        end

        function throws(obj, name, fn, expectedId)
            %THROWS Assert fn() errors; optionally with a specific identifier.
            if nargin < 4; expectedId = ''; end
            threw = false; gotId = '';
            try
                fn();
            catch err
                threw = true; gotId = err.identifier;
            end
            if ~threw
                obj.fail(name, 'expected an error, none thrown');
            elseif ~isempty(expectedId) && ~strcmp(gotId, expectedId)
                obj.fail(name, sprintf('error id ''%s'' ~= expected ''%s''', gotId, expectedId));
            else
                obj.pass(name);
            end
        end

        function noThrow(obj, name, fn)
            try
                fn();
                obj.pass(name);
            catch err
                obj.fail(name, sprintf('unexpected error: %s (%s)', err.message, err.identifier));
            end
        end

        function tf = report(obj)
            %REPORT Print summary; return true if all passed.
            fprintf('\n================ TEST SUMMARY ================\n');
            fprintf('Passed: %d   Failed: %d   Total: %d\n', ...
                obj.nPass, obj.nFail, obj.nPass + obj.nFail);
            if obj.nFail > 0
                fprintf('\nFailures:\n');
                for i = 1:numel(obj.failures)
                    fprintf('  - %s\n', obj.failures{i});
                end
            end
            fprintf('=============================================\n');
            tf = (obj.nFail == 0);
        end
    end
end
