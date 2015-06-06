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


