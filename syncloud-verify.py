#!/usr/bin/env python
import logging
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.server.serverfacade import get_server

logger.init(logging.DEBUG, True)

server = get_server()
release = open('RELEASE', 'r').read().strip()
server.activate(release, 'localhost', 'http://api.syncloud.info:81', 'mail@example.com', 'test', 'test')

owncloud = facade.get_control(get_insider())
owncloud.finish('test', 'test', 'localhost', 'http')
owncloud.verify('localhost')