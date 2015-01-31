#!/usr/bin/env python
import logging
import os
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.server.serverfacade import get_server
import sys

if __name__ == '__main__':

    logger.init(logging.DEBUG, True)

    # redirect_email = os.environ['REDIRECT_EMAIL']
    # redirect_password = os.environ['REDIRECT_PASSWORD']

    # print("login: ".format(redirect_email[:3]))
    # print("password: ".format(redirect_password[:3]))

    server = get_server()
    release = open('RELEASE', 'r').read().strip()
    server.activate(release, 'syncloud.info', 'http://api.syncloud.info:81', 'build@syncloud.it', 'travispassword123', 'travis')

    owncloud = facade.get_control(get_insider())
    owncloud.finish('test', 'test', 'localhost', 'http')
    owncloud.verify('localhost')