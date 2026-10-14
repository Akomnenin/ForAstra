function cloud_matlab_test(stage)
% Two-way file exchange test; compatible with MATLAB R2023b.
% Run cloud_matlab_test('start'), upload matlab_to_cloud.json,
% then download cloud_reply.json here and run cloud_matlab_test('finish').
if nargin == 0
    stage = 'start';
end
folder = fileparts(mfilename('fullpath'));
request = jsondecode(fileread(fullfile(folder, 'cloud_request.json')));
assert(strcmp(request.protocol, 'forastra-smoke-v1'), 'Wrong protocol.');
switch stage
    case 'start'
        assert(strcmp(request.operation, 'square_and_sum'), 'Wrong operation.');
        x = double(request.values(:).');
        assert(isequal(x, [1 2 3 4 5]), 'Unexpected input data.');
        result.squares = x .^ 2;
        result.sum = sum(x);
        assert(isequal(result.squares, [1 4 9 16 25]));
        assert(result.sum == 15);
        outgoing.protocol = request.protocol;
        outgoing.test_id = request.test_id;
        outgoing.source = 'local-matlab';
        outgoing.matlab_version = version;
        outgoing.matlab_release = version('-release');
        outgoing.platform = computer;
        outgoing.matlab_result = result;
        outgoing.python_request.operation = 'matrix_multiply';
        outgoing.python_request.A = [1 2; 3 4];
        outgoing.python_request.B = [5 6; 7 8];
        output = fullfile(folder, 'matlab_to_cloud.json');
        write_json(output, outgoing);
        fprintf('PASS: cloud Python input processed in local MATLAB.\n');
        fprintf('Squares: %s; sum: %g\n', mat2str(result.squares), result.sum);
        fprintf('Upload this file to the cloud chat: %s\n', output);
    case 'finish'
        reply = jsondecode(fileread(fullfile(folder, 'cloud_reply.json')));
        outgoing = jsondecode(fileread(fullfile(folder, 'matlab_to_cloud.json')));
        assert(strcmp(reply.protocol, request.protocol), 'Wrong protocol.');
        assert(strcmp(reply.test_id, request.test_id), 'Wrong test ID.');
        assert(strcmp(outgoing.test_id, request.test_id), 'Local request ID mismatch.');
        assert(reply.matlab_result_validated, 'Cloud did not validate MATLAB result.');
        assert(strcmp(reply.python_result.operation, 'matrix_multiply'));
        expected = outgoing.python_request.A * outgoing.python_request.B;
        assert(isequal(reply.python_result.C, expected), 'Cloud matrix result is incorrect.');
        report.protocol = request.protocol;
        report.test_id = request.test_id;
        report.source = 'local-matlab';
        report.status = 'PASS';
        report.matlab_version = version;
        report.matrix_result = reply.python_result.C;
        write_json(fullfile(folder, 'local_final_report.json'), report);
        fprintf('PASS: local MATLAB request processed by cloud Python and verified locally.\n');
        disp(reply.python_result.C);
        fprintf('Two-way file exchange passed. Share local_final_report.json or this output.\n');
    otherwise
        error('Use cloud_matlab_test(''start'') or cloud_matlab_test(''finish'').');
end
end

function write_json(path, value)
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid ~= -1, 'Cannot open output file.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
count = fprintf(fid, '%s\n', jsonencode(value, 'PrettyPrint', true));
assert(count > 0, 'Could not write output.');
end
