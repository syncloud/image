#!/usr/bin/env python
from os.path import dirname
import requests

DIR = dirname(__file__)

def test_activate_device(auth):
    email, password, domain, release = auth
    response = requests.post('http://localhost:81/server/rest/activate',
                             data={'redirect-email': email, 'redirect-password': password,
                                   'redirect-domain': domain, 'name': 'user', 'password': 'password',
                                   'api-url': 'http://api.syncloud.info:81', 'domain': 'syncloud.info',
                                   'release': release})
    assert response.status_code == 200

def test_owncloud_install():
    session = requests.session()
    session.post('http://localhost/server/rest/login', data={'name': 'user', 'password': 'password'})
    response = session.get('http://localhost/server/rest/install?app_id=syncloud-owncloud', allow_redirects=False)
    assert response.status_code == 200