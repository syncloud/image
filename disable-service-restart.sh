#!/bin/bash

cat <<NOSTART > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
NOSTART
chmod +x /usr/sbin/policy-rc.d