#!/usr/bin/env python
import logging

from syncloud.ci import setup
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.server.serverfacade import get_server


def test_install(auth):

    logger.init(logging.DEBUG, True)
    # logging.basicConfig(level=logging.DEBUG)
    insider = get_insider(use_upnpc_mock=True)

    # End-user device activation (secret keys generation ...)
    server = get_server(insider=insider)
    release = open('RELEASE', 'r').read().strip()
    email, password = auth
    server.activate(release, 'syncloud.info', 'http://api.syncloud.info:81', email, password, 'travis')

    # ownCloud tests
    owncloud = facade.get_control(insider)
    owncloud.finish('test', 'test', 'localhost', 'http')
    owncloud.verify('localhost')

    assert setup.verify()