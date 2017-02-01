import os
import sys
from os import listdir
from os.path import dirname, join, abspath, isdir
import time
from subprocess import check_output

import convertible
import pytest
import re
import requests
import shutil
import smtplib
from email.mime.text import MIMEText
from integration.util.ssh import run_scp, ssh_command, SSH, run_ssh, set_docker_ssh_port
from requests.adapters import HTTPAdapter
import getpass, imaplib
import logging

logging.basicConfig(level=logging.DEBUG)

DIR = dirname(__file__)
LOG_DIR = join(DIR, 'log')
SYNCLOUD_INFO = 'syncloud.info'
DEVICE_USER = 'user'
DEVICE_PASSWORD = 'password'
DEFAULT_DEVICE_PASSWORD = 'syncloud'
LOGS_SSH_PASSWORD = DEFAULT_DEVICE_PASSWORD
APPS = ['owncloud', 'mail', 'nextcloud', 'diaspora', 'files', 'gogs']


@pytest.fixture(scope="session")
def module_setup(request):
    request.addfinalizer(module_teardown)


def module_teardown():
    os.mkdir(LOG_DIR)

    coopy_logs('sam', '/var/log/sam.log')
    coopy_logs('platform')
    for app in APPS:
        coopy_logs(app)

    run_ssh('netstat -l', password=DEVICE_PASSWORD)

    # print('systemd logs')
    # run_ssh('journalctl', password=DEVICE_PASSWORD)

    print('-------------------------------------------------------')
    print('syncloud docker image is running')
    print('connect using: {0}'.format(ssh_command(DEVICE_PASSWORD, SSH)))
    print('-------------------------------------------------------')


def coopy_logs(app, device_logs=None):
    if not device_logs:
        device_logs = '/opt/data/{0}/log/*'.format(app)
    log_dir = join(LOG_DIR, '{0}_log'.format(app))
    os.mkdir(log_dir)
    run_scp('root@localhost:{0} {1}'.format(device_logs, log_dir), password=LOGS_SSH_PASSWORD, throw=False)


@pytest.fixture(scope='module')
def user_domain(device_domain):
    return 'device.{0}'.format(device_domain)


@pytest.fixture(scope='module')
def device_domain(auth):
    email, password, domain, release, arch = auth
    return '{0}.{1}'.format(domain, SYNCLOUD_INFO)


@pytest.fixture(scope='function')
def syncloud_session():
    session = requests.session()
    session.post('http://localhost/rest/login', data={'name': DEVICE_USER, 'password': DEVICE_PASSWORD})

    return session


def test_start(module_setup):
    shutil.rmtree(LOG_DIR, ignore_errors=True)


def test_activate_device(auth):
    email, password, domain, release, arch = auth

    run_ssh('/opt/app/sam/bin/sam update --release {0}'.format(release), password=DEFAULT_DEVICE_PASSWORD)
    run_ssh('/opt/app/sam/bin/sam --debug upgrade platform', password=DEFAULT_DEVICE_PASSWORD)
    wait_for_platform_web()
    response = requests.post('http://localhost:81/rest/activate',
                             data={'main_domain': 'syncloud.info', 'redirect_email': email,
                                   'redirect_password': password,
                                   'user_domain': domain, 'device_username': DEVICE_USER,
                                   'device_password': DEVICE_PASSWORD})
    assert response.status_code == 200
    global LOGS_SSH_PASSWORD
    LOGS_SSH_PASSWORD = DEVICE_PASSWORD


def wait_for_platform_web():
    print(check_output('while ! nc -w 1 -z localhost 80; do sleep 1; done', shell=True))


def wait_for_sam(syncloud_session):
    sam_running = True
    while sam_running:
        try:
            response = syncloud_session.get('http://localhost/rest/settings/sam_status')
            if response.status_code == 200:
                json = convertible.from_json(response.text)
                sam_running = json.is_running
        except Exception, e:
            pass
        print('waiting for sam to finish its work')
        time.sleep(1)


def test_login(syncloud_session):
    syncloud_session.post('http://localhost/rest/login', data={'name': DEVICE_USER, 'password': DEVICE_PASSWORD})


@pytest.mark.parametrize("app", APPS)
def test_app_install(syncloud_session, app, device_domain):
    response = syncloud_session.get('http://localhost/rest/install?app_id={0}'.format(app), allow_redirects=False)

    assert response.status_code == 200
    wait_for_sam(syncloud_session)
    
    response = syncloud_session.get('http://localhost/rest/installed_apps')
    assert response.status_code == 200
    assert app in response.text


@pytest.mark.parametrize("app", APPS)
def test_app_upgrade(syncloud_session, app):
    response = syncloud_session.get('http://localhost/rest/upgrade?app_id={0}'.format(app),
                                    allow_redirects=False)
    assert response.status_code == 200


@pytest.mark.parametrize("app", APPS)
def test_app_remove(syncloud_session, app):
    response = syncloud_session.get('http://localhost/rest/remove?app_id={0}'.format(app),
                                    allow_redirects=False)
    assert response.status_code == 200
    wait_for_sam(syncloud_session)
