function ok = run_all_tests()
%RUN_ALL_TESTS Portable (MATLAB+Octave) deterministic test runner for rfscreen.
%   Returns true if all tests passed. Does NOT call exit(); a CLI wrapper may.
    thisDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(thisDir);
    addpath(fullfile(repoRoot, 'src'));
    addpath(thisDir);

    tests = { ...
        @test_coordinate, ...
        @test_geometry, ...
        @test_pattern, ...
        @test_pairwise, ...
        @test_multisystem, ...
        @test_invalid_inputs, ...
        @test_invariants, ...
        @test_architecture_boundary };

    h = testutil.Harness();
    fprintf('Running %d test files...\n', numel(tests));
    for i = 1:numel(tests)
        fn = tests{i};
        name = func2str(fn);
        try
            fn(h);
            fprintf('  ran %s\n', name);
        catch err
            h.fail(['<file:' name '>'], sprintf('hard error: %s (%s)', err.message, err.identifier));
            fprintf('  ERROR in %s: %s\n', name, err.message);
        end
    end

    ok = h.report();
end
