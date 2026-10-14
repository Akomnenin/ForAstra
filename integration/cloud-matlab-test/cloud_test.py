"""File-based Python/MATLAB handshake. Run with Python 3.11+."""
import argparse
import json
from pathlib import Path
import platform
import uuid


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def make_request():
    return {
        "protocol": "forastra-smoke-v1",
        "test_id": str(uuid.uuid4()),
        "source": "cloud-python",
        "python_version": platform.python_version(),
        "operation": "square_and_sum",
        "values": [1, 2, 3, 4, 5],
    }


def make_reply(original, incoming):
    if incoming.get("protocol") != original["protocol"]:
        raise ValueError("Protocol mismatch")
    if incoming.get("test_id") != original["test_id"]:
        raise ValueError("Test ID mismatch: use files from the same test run")
    result = incoming["matlab_result"]
    if result["squares"] != [x * x for x in original["values"]]:
        raise ValueError("MATLAB square results are incorrect")
    if result["sum"] != sum(original["values"]):
        raise ValueError("MATLAB sum is incorrect")
    request = incoming["python_request"]
    if request["operation"] != "matrix_multiply":
        raise ValueError("Unsupported operation")
    a, b = request["A"], request["B"]
    if a != [[1, 2], [3, 4]] or b != [[5, 6], [7, 8]]:
        raise ValueError("Unexpected smoke-test matrices")
    c = [[sum(a[i][k] * b[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
    return {
        "protocol": original["protocol"],
        "test_id": original["test_id"],
        "source": "cloud-python",
        "python_version": platform.python_version(),
        "matlab_result_validated": True,
        "python_result": {"operation": "matrix_multiply", "C": c},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    start = sub.add_parser("start")
    start.add_argument("output")
    reply = sub.add_parser("reply")
    reply.add_argument("original")
    reply.add_argument("incoming")
    reply.add_argument("output")
    args = parser.parse_args()
    if args.command == "start":
        if Path(args.output).exists():
            parser.error("Refusing to overwrite an existing test request")
        value = make_request()
        write_json(args.output, value)
        print(f"Cloud request created: {value['test_id']}")
        print("Waiting for actual local MATLAB execution; integration is not yet verified.")
    else:
        value = make_reply(read_json(args.original), read_json(args.incoming))
        write_json(args.output, value)
        print("PASS: returned MATLAB values match the original Python request.")
        print(f"Cloud matrix result: {value['python_result']['C']}")
        print("Run cloud_matlab_test('finish') locally to validate the return to MATLAB.")


if __name__ == "__main__":
    main()
