from subprocess import check_output, STDOUT, CalledProcessError

import time

SSH_OPTS= '-o StrictHostKeyChecking=no'

def run_scp(command, throw=True, debug=True, password='syncloud'):
    return _run_command('scp {0} {1}'.format(SSH_OPTS, command), throw, debug, password)


def run_ssh(host, command, throw=True, debug=True, password='syncloud', retries=0, sleep=1):
    retry = 0
    while True:
        try:
            return _run_command('ssh {0} root@{1} "{2}"'.format(SSH_OPTS, host, command), throw, debug, password)
        except Exception, e:
            if retry >= retries:
                raise e
            retry = retry + 1
            time.sleep(sleep)
            print('retrying {0}'.format(retry))


def _run_command(command, throw, debug, password):
    try:
        print('ssh command: {0}'.format(command))
        output = check_output('sshpass -p {0} {1}'.format(password, command), shell=True, stderr=STDOUT).strip()
        if debug:
            print output
            print
        return output
    except CalledProcessError, e:
        print(e.output)
        if throw:
            raise e
