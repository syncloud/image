#!/usr/bin/env python
import logging
from syncloud.apache.facade import ApacheFacade
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade

logger.init(logging.DEBUG, True)

apache = ApacheFacade()
apache.activate('localhost')

owncloud = facade.get_control(get_insider())
owncloud.finish('test', 'test', 'localhost', 'http')
owncloud.verify('localhost')