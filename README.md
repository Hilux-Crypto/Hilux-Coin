## Resources & community

Binaries and source code: https://github.com/Hilux-Crypto/Hilux-Master-Node/releases

Report a bug, idea or feature:https://github.com/Hilux-Crypto/Hilux-Master-Node/issues

Explorer: https://explorer.coleganet.com

Pool Minning : https://mecrypto.club

Pool Block Explorer: https://mecrypto.club/site/block?id=1486


Masternodes tabs are now automatically added upon installation.

Please Make a installation in a clean VPS or Server Ubuntu 18.04

EASY INSTALL 
=============
PLeaseuse a clean new VPS or Server UBuntu 18.04

wget https://github.com/Hilux-Crypto/Hilux-Master-Node/tree/master/scripts/Hilux-setup.sh

chmod +x Hilux-setup.sh

./Hilux-setup.sh

Please after that Follow the instructions in the github folder  docs

Other extra info you can get in this link https://github.com/Hilux-Crypto/Hilux-Master-Node/wiki

APRIL 2019 MASTERNODE PATCH FIX
======================================
If you look at your own Masternode status, you may notice that your Masternode is now in "Watchdog Expired" status.
To fix this, do the following steps.
1. Login to your VPS which runs the Hilux masternode. Type:

cd ~
wget https://github.com/Hilux-Crypto/Hilux-Coin/releases/download/1.2.0/patch1.sh
chmod +x patch1.sh
./patch1.sh

Then follow the screen instructions. 
In 6 hours, your masternode status should be ENABLED.
If not, login again to the vps and type:

python3 /root/sentinel-hilux2/bin/sentinel.py

That's it. Enjoy the patch.




Hilux Core 1.0.2
===============================


https://www.hiluxcoin.com


What is Hilux?
----------------

Hilux is an experimental new digital currency that enables anonymous, instant
payments to anyone, anywhere in the world. Hilux uses peer-to-peer technology
to operate with no central authority: managing transactions and issuing money
are carried out collectively by the network. Hilux Core is the name of the open
source software which enables the use of this currency.

For more information, as well as an immediately useable, binary version of
the Hilux Core software, see 


License
-------

Hilux Core is released under the terms of the MIT license. See [COPYING](COPYING) for more
information or see https://opensource.org/licenses/MIT.

Development Process
-------------------

The `master` branch is meant to be stable. Development is normally done in separate branches.
[Tags](https://github.com/hiluxcrypto/hilux/tags) are created to indicate new official,
stable release versions of Hilux Core.

The contribution workflow is described in [CONTRIBUTING.md](CONTRIBUTING.md).

Testing
-------

Testing and code review is the bottleneck for development; we get more pull
requests than we can review and test on short notice. Please be patient and help out by testing
other people's pull requests, and remember this is a security-critical project where any mistake might cost people
lots of money.

### Automated Testing

Developers are strongly encouraged to write [unit tests](/doc/unit-tests.md) for new code, and to
submit new unit tests for old code. Unit tests can be compiled and run
(assuming they weren't disabled in configure) with: `make check`

There are also [regression and integration tests](/qa) of the RPC interface, written
in Python, that are run automatically on the build server.
These tests can be run (if the [test dependencies](/qa) are installed) with: `qa/pull-tester/rpc-tests.py`

The Travis CI system makes sure that every pull request is built for Windows
and Linux, OS X, and that unit and sanity tests are automatically run.

### Manual Quality Assurance (QA) Testing

Changes should be tested by somebody other than the developer who wrote the
code. This is especially important for large or high-risk changes. It is useful
to add a test plan to the pull request description if testing the changes is
not straightforward.
