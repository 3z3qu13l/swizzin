#!/usr/bin/env python
#
# Deluge password generator
#
#   deluge.Userpass.py <salt> < password
#
# The password comes on stdin so other accounts cannot read it in the process list

import hashlib
import sys

password = getattr(sys.stdin, 'buffer', sys.stdin).read()
salt = sys.argv[1].encode('utf-8')

s = hashlib.sha1()
s.update(salt)
s.update(password)

print(s.hexdigest())
