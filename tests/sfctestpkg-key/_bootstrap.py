# The test's encryption key, also in .github/workflows/test.yml. Not a
# secret: a real bootstrap gets the key from the end user's license.
KEY = "23270f4a153aee54c70b6bfb0571b91d699a46ec3a8cb9c65c5ef669c460fbbc"


def unlock(*, build_date):
    return bytes.fromhex(KEY)
