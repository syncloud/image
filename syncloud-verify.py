#!/usr/bin/env python
from syncloud.app import logger
from syncloud.insider.facade import get_insider
from syncloud.owncloud import facade
from syncloud.server.serverfacade import get_server
import logging

# @responses.activate
def test_install():

    logger.init(logging.DEBUG, True)
    logging.basicConfig(level=logging.DEBUG)

    # redirect_email = os.environ['REDIRECT_EMAIL']
    # redirect_password = os.environ['REDIRECT_PASSWORD']

    # print("login: ".format(redirect_email[:3]))
    # print("password: ".format(redirect_password[:3]))

    #test
    # responses.add(responses.POST,
    #                   "http://example.com",
    #                   status=200,
    #                   body='{"user_domain": "travis", "update_token": "some_update_token"}',
    #                   content_type="application/json")

    # get_insider().acquire_domain('build@syncloud.it', 'travispassword123', 'travis')

    server = get_server()
    release = open('RELEASE', 'r').read().strip()
    server.activate(release, 'syncloud.info', 'http://syncloud.info:81', 'build@syncloud.it', 'travispassword123', 'travis')

    owncloud = facade.get_control(get_insider())
    owncloud.finish('test', 'test', 'localhost', 'http')
    owncloud.verify('localhost')