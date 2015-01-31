#!/usr/bin/env python
import logging
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.server.serverfacade import get_server
import sys

logger.init(logging.DEBUG, True)

redirect_email = sys.argv[6]
redirect_password = sys.argv[1]

server = get_server()
release = open('RELEASE', 'r').read().strip()
server.activate(release, 'syncloud.info', 'http://api.syncloud.info:81', redirect_email, redirect_password, 'travis')

owncloud = facade.get_control(get_insider())
owncloud.finish('test', 'test', 'localhost', 'http')
owncloud.verify('localhost')