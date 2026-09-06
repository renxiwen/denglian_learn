#!/usr/bin/env python3
"""用 RSA / ECC 私钥对 "web3" + nonce 签名，再用公钥验签。"""

from __future__ import annotations

import random

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa
from cryptography.hazmat.primitives.asymmetric.ec import EllipticCurvePrivateKey
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPrivateKey

PREFIX = "web3"


def pem_public_key(private_key: RSAPrivateKey | EllipticCurvePrivateKey) -> str:
    return private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    ).decode("utf-8")


def rsa_sign(private_key: RSAPrivateKey, message: bytes) -> bytes:
    return private_key.sign(
        message,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH,
        ),
        hashes.SHA256(),
    )


def rsa_verify(private_key: RSAPrivateKey, message: bytes, signature: bytes) -> bool:
    try:
        private_key.public_key().verify(
            signature,
            message,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH,
            ),
            hashes.SHA256(),
        )
        return True
    except InvalidSignature:
        return False


def ecc_sign(private_key: EllipticCurvePrivateKey, message: bytes) -> bytes:
    return private_key.sign(message, ec.ECDSA(hashes.SHA256()))


def ecc_verify(
    private_key: EllipticCurvePrivateKey, message: bytes, signature: bytes
) -> bool:
    try:
        private_key.public_key().verify(signature, message, ec.ECDSA(hashes.SHA256()))
        return True
    except InvalidSignature:
        return False


def main() -> None:
    nonce = random.randint(0, 2**32 - 1)
    message = f"{PREFIX}{nonce}".encode("utf-8")

    print(f"明文: {PREFIX!r} + nonce {nonce}")
    print(f"待签消息: {message.decode('utf-8')!r}")
    print()

    rsa_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    rsa_sig = rsa_sign(rsa_key, message)
    print("=== RSA-2048 + PSS/SHA256 ===")
    print("公钥 PEM:")
    print(pem_public_key(rsa_key), end="")
    print(f"签名 (hex): {rsa_sig.hex()}")
    print(f"公钥验签: {rsa_verify(rsa_key, message, rsa_sig)}")
    print(f"篡改后验签: {rsa_verify(rsa_key, message + b'x', rsa_sig)}")
    print()

    ecc_key = ec.generate_private_key(ec.SECP256R1())
    ecc_sig = ecc_sign(ecc_key, message)
    print("=== ECC secp256r1 + ECDSA/SHA256 ===")
    print("公钥 PEM:")
    print(pem_public_key(ecc_key), end="")
    print(f"签名 (hex): {ecc_sig.hex()}")
    print(f"公钥验签: {ecc_verify(ecc_key, message, ecc_sig)}")
    print(f"篡改后验签: {ecc_verify(ecc_key, message + b'x', ecc_sig)}")


if __name__ == "__main__":
    main()
