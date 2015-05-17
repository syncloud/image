#!/usr/bin/env python
import logging
import pytest

from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.sam.manager import get_sam
from syncloud.server.serverfacade import get_server


@pytest.fixture(scope="session", autouse=True)
def activate_device(auth):

    logger.init(logging.DEBUG, True)
    # persist upnp mock setting
    get_insider().insider_config.set_upnpc_mock(True)
    server = get_server(insider=get_insider())
    release = open('RELEASE', 'r').read().strip()
    email, password = auth
    server.activate(release, 'syncloud.info', 'http://api.syncloud.info:81', email, password, 'teamcity')

    # request.addfinalizer(finalizer_function)


def test_owncloud():
    sam = get_sam()
    sam.install('syncloud-owncloud')
    from syncloud.owncloud import facade
    owncloud = facade.get_control(get_insider())
    owncloud.finish('test', 'test', 'localhost', 'http')
    assert owncloud.verify('localhost')


# def test_imageci():
    # sam = get_sam()
    # sam.install('syncloud-image-ci')
    # from syncloud.ci.facade import ImageCI
    # image_ci = ImageCI(insider)
    # image_ci.activate()
    # assert image_ci.verify()


def test_gitbucket():
    sam = get_sam()
    sam.install('syncloud-gitbucket')
    from syncloud.gitbucketctl.facade import GitBucketControl
    gitbucket = GitBucketControl(get_insider())
    gitbucket.enable('travis', 'password')
    assert gitbucket.verify()