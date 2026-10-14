ForAstra: cloud Python / local MATLAB two-way file exchange

This is a file-based handshake, not a remote-control connection.
No server, firewall change, cloud MATLAB license, or third-party package is needed.
Python runs in the cloud; MATLAB must run on your Windows computer.

1. Extract this folder on Windows and open it as MATLAB's Current Folder.
2. In MATLAB run: cloud_matlab_test('start')
3. Upload the generated matlab_to_cloud.json to the cloud chat.
4. The cloud assistant runs cloud_test.py reply with the original request
   and the uploaded JSON, validates MATLAB's response, and returns cloud_reply.json.
5. Save cloud_reply.json in this same Windows folder.
6. In MATLAB run: cloud_matlab_test('finish')
7. Share local_final_report.json or the printed result to confirm completion.

Expected results:
Cloud -> MATLAB: squares [1 4 9 16 25], sum 15.
MATLAB -> Cloud -> MATLAB: matrix product [19 22; 43 50].

The test ID ties files to one run. Do not mix files from different runs.
Python unit checks use synthetic fixtures and do not establish MATLAB execution.
