#!/bin/bash
# Python's own regression tests, run from the build tree (Lib/test), excluding network/resource-heavy ones
JT=~/dev/stdio-noob; G6=$JT/g6; G8=$JT/g8; G9=$JT/g9; G10=$JT/g10; GL=$JT/g216/glibc216
export PATH=$G6/mbbin6:$G8/only LC_ALL=C; export C_INCLUDE_PATH=$GL/include LIBRARY_PATH=$GL/lib
cd $G10/src/python/Python-3.5.9
timeout 2400 ./python -m test -x test_socket test_urllib2net test_urllibnet test_ftplib test_smtplib test_telnetlib test_nntplib test_poplib test_imaplib test_asyncio test_multiprocessing_fork test_multiprocessing_forkserver test_multiprocessing_spawn test_multiprocessing_main_handling > $G10/pytest.log 2>&1; echo "PYTEST-RC=$?" > $G10/pytest.rc
