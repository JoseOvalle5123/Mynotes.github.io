import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';


class EncryptionService {


  final String _secretKey = "mi_clave_super_segura_12345";

  encrypt.Key get _key {
    final keyBytes = sha256.convert(utf8.encode(_secretKey)).bytes;
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  final encrypt.IV _iv = encrypt.IV.fromLength(16);

  String encryptText(String text) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}
