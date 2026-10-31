import 'dart:io';

bool isNativeTransportError(Object error) =>
    error is SocketException || error is TlsException;
bool isTlsTransportError(Object error) => error is TlsException;
