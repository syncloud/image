#!/usr/bin/env python
import logging
from insider.facade import get_insider
from owncloud import facade
from syncloud.apache.facade import ApacheFacade
from syncloud.app import logger

logger.init(logging.DEBUG, True)

apache = ApacheFacade()
apache.activate('localhost')

owncloud = facade.get_control(get_insider())
owncloud.finish('test', 'test', 'localhost', 'http')
owncloud.verify('localhost')