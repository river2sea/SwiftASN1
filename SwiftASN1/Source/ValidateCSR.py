from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes

if __name__ == "__main__":
    csrDER = open( "/tmp/Signed-PKC-CSR.der", "rb" ).read()
    csr = x509.load_der_x509_csr( csrDER, default_backend() )
    print( csr )
    #isinstance( csr.signature_hash_algorithm, hashes.SHA256 )
