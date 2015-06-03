#!/usr/bin/env python
import logging
import convertible
import pytest
import requests

from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.sam.manager import get_sam
from syncloud.sam.pip import Pip
from syncloud.server.serverfacade import get_server


def test_owncloud():
    sam = get_sam()
    sam.install('syncloud-owncloud')
    from syncloud.owncloud import facade
    owncloud = facade.get_control(get_insider(use_upnpc_mock=True))
    owncloud.finish('test', 'test', 'localhost', 'http')
    assert owncloud.verify('localhost')