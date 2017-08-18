# coding=utf-8

from OpenSSL import crypto

# Prepare X509 objects
root_cert = crypto.load_certificate(
    crypto.FILETYPE_PEM, open('root.crt').read()
)
intermediate_cert = crypto.load_certificate(
    crypto.FILETYPE_PEM, open('intermediate.crt').read()
)
server_cert = crypto.load_certificate(
    crypto.FILETYPE_PEM, open('server.crt').read()
)

# Prepare X509 store
store = crypto.X509Store()
store.add_cert(root_cert)
store.add_cert(intermediate_cert)

# https://pyopenssl.org/en/stable/api/crypto.html#OpenSSL.crypto.X509StoreFlags
store.set_flags(crypto.X509StoreFlags.CRL_CHECK)

# Verify
crypto.X509StoreContext(store, server_cert).verify_certificate()
