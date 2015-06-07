#!/usr/bin/env python
import logging
from os.path import dirname

import pytest
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.sam.manager import get_sam
from syncloud.server.serverfacade import get_server

DIR = dirname(__file__)

@pytest.fixture(scope="session", autouse=True)
def activate_device(auth):

    logger.init(logging.DEBUG, True)

    print("installing latest platform")
    get_sam().update("0.9")
    get_sam().install("syncloud-platform")

    # persist upnp mock setting
    get_insider().insider_config.set_upnpc_mock(True)

    server = get_server(insider=get_insider(use_upnpc_mock=True))
    email, password = auth
    server.activate('test', 'syncloud.info', 'http://api.syncloud.info:81', email, password, 'teamcity', 'user', 'password', False)

def test_owncloud_activation():
    # logger.init(logging.DEBUG, True)

    print("installing local owncloud build")
    get_sam().install("syncloud-owncloud")
    from syncloud.owncloud.setup import Setup

    setup = Setup()
    assert not setup.is_finished()
    setup.finish('test', 'test', overwritehost='localhost')
    assert setup.is_finished()

