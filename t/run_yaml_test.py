import difflib
import glob
import logging
import os
import subprocess
import sys


try:
    import yaml
except ImportError:
    print('Unable to import yaml module')
    sys.exit(1)


logger = logging.getLogger(__name__)


def test_all_yaml_files():
    """
    Walk all the YAML files and run their tests.
    """
    filenames = glob.glob('t/*.yaml')
    for filename in filenames:
        logger.info('YAML: %s' % filename)
        with open(filename, 'r', encoding='UTF-8') as f:
            cases = yaml.load_all(f, yaml.FullLoader)
            for case in cases:
                case = massage_case(case)
                run_case(case)


def massage_case(case: dict):
    """
    Takes the raw case from the YAML and sets defaults.
    """
    if 'exitcode' not in case:
        case['exitcode'] = 0

    # Make an array of args arrays out of it if it's not already.
    if not isinstance(case['args'], list):
        case['args'] = [case['args']]

    if case['stdout'] is None:
        case['stdout'] = ''

    return case


def expected_lines(case):
    """
    Gets the lines expected from the case, adjusting on the settings.
    """
    lines = case['stdout'].splitlines()
    if indent := case.get('indent-stdout', 0):
        lines = [' ' * indent + x for x in lines]

    return lines


def show_diff(exp, got):
    """
    Shows the diffs between two sets of strings
    """
    diff = '\n'.join(
        difflib.unified_diff(
            exp, got, fromfile='expected', tofile='got', lineterm=''
        )
    )
    print(diff)


def run_case(case):
    """
    Runs an individual case from the YAML.
    """
    logger.info('    Case: %s' % case['name'])
    for args in case['args']:
        if os.getenv('DIRK'):
            command = ['./dirk']
        else:
            command = ['perl', '-Mblib', 'ack', '--noenv']
        command += args.split()
        logger.info('    Command: %s' % ' '.join(command))

        try:
            result = subprocess.run(
                command,
                input=case.get('stdin', None),
                capture_output=True,
                text=True,
                check=(not case['exitcode']),
            )
        except subprocess.CalledProcessError as e:
            print('STDOUT from', command)
            print(repr(e.stdout))
            print('STDERR from', command)
            print(repr(e.stderr))
            raise

        if case['exitcode']:
            assert result.returncode == case['exitcode']

        exp_lines = expected_lines(case)
        got_lines = result.stdout.splitlines()
        if not case.get('ordered', False):
            got_lines = sorted(got_lines)
            exp_lines = sorted(exp_lines)

        # show_diff(exp_lines, got_lines)
        assert got_lines == exp_lines


test_all_yaml_files()
