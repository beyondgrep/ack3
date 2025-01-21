import glob
import subprocess
import yaml


def test_via_yaml_data():
    filenames = glob.glob("t/*.yaml")
    for filename in filenames:
        with open(filename, "r") as f:
            tests = yaml.load_all(f, yaml.FullLoader)
            for test in tests:
                test = massage_test(test)
                run_test(test)


def massage_test(test: dict):
    if "exitcode" not in test:
        test["exitcode"] = 0

    # Make an array of args arrays out of it if it"s not already.
    if not isinstance(test["args"], list):
        test["args"] = [test["args"]]

    return test


def sorted_output(block: str):
    return sorted([x.rstrip() for x in block.split("\n")]) if block else None


def run_test(test):
    for args in test["args"]:
        command = ["perl", "-Mblib", "ack", "--noenv"] + args.split()
        result = subprocess.run(
            command, capture_output=True, text=True, check=(not test["exitcode"])
        )

        if test["exitcode"]:
            assert result.returncode == test["exitcode"]

        if "ordered" in test and test["ordered"]:
            assert result.stdout == test["stdout"]
        else:
            assert sorted_output(result.stdout) == sorted_output(test["stdout"])


test_via_yaml_data()
