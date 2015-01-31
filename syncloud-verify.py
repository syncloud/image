#!/usr/bin/env python
import os
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.server.serverfacade import get_server
import logging


def test_install(email, password):

    logger.init(logging.DEBUG, True)
    # logging.basicConfig(level=logging.DEBUG)

    # redirect_email = os.environ['REDIRECT_EMAIL']
    # redirect_password = os.environ['REDIRECT_PASSWORD']

    # print("login: ".format(redirect_email[:3]))
    # print("password: ".format(redirect_password[:3]))

    #test
    # responses.add(responses.POST,
    #                   "http://example.com",
    #                   status=200,
    #                   body='{"user_domain": "travis", "update_token": "some_update_token"}',
    #                   content_type="application/json")

    # get_insider().acquire_domain('build@syncloud.it', 'travispassword123', 'travis')

    insider = get_insider(use_upnpc_mock=True)

    server = get_server(insider=insider)
    release = open('RELEASE', 'r').read().strip()
    server.activate(release, 'syncloud.info', 'http://api.syncloud.info:81', email, password, 'travis')

    owncloud = facade.get_control(insider)
    owncloud.finish('test', 'test', 'localhost', 'http')
    owncloud.verify('localhost')