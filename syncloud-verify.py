#!/usr/bin/env python
import logging

from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.sam.manager import get_sam
from syncloud.server.serverfacade import get_server


def test_install(auth):

    logger.init(logging.DEBUG, True)
    get_insider().insider_config.set_upnpc_mock(True)
    insider = get_insider()

    # End-user device activation (secret keys generation ...)
    server = get_server(insider=insider)
    release = open('RELEASE', 'r').read().strip()
    email, password = auth
    server.activate(release, 'syncloud.info', 'http://api.syncloud.info:81', email, password, 'travis')

    # ownCloud
    owncloud = facade.get_control(insider)
    owncloud.finish('test', 'test', 'localhost', 'http')
    owncloud.verify('localhost')

    # image-ci
    get_sam().install('syncloud-image-ci')
    from syncloud.ci.facade import ImageCI
    image_ci = ImageCI()
    image_ci.activate()
    assert image_ci.verify()