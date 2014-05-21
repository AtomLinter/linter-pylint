"""pylint option block-disable"""

__revision__ = None

class Foo(object):
    """block-disable test"""

    def __init__(self):
        pass

    def meth1(self, arg):
        """this issues a message"""
        print self

    def meth2(self, arg):
        """and this one not"""
        # pylint: disable=unused-argument
        print self\
              + "foo"

    def meth3(self):
        """test one line disabling"""
        # no error
        print self.bla # pylint: disable=no-member
        # error
        print self.blop

    def meth4(self):
        """test re-enabling"""
        # pylint: disable=no-member
        # no error
        print self.bla
        print self.blop
        # pylint: enable=no-member
        # error
        print self.blip
