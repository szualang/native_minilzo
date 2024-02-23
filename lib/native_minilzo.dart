
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'dart:typed_data';

import 'native_minilzo_bindings_generated.dart';

/// A struct for compress or decompress data, which used to trans
class BitCompressData {
  final Uint8List data;
  final int len;

  BitCompressData(this.data, this.len);
}

/// A function use for compress data by using minilzo
///
/// [inData] the data which should be compress
/// [inLen] the size of data to compress
BitCompressData compressData(Uint8List inData, int inLen) {
  // 将Uint8List的数据复制到分配的内存中
  final inDataPtr = _Uint8ListToPointer(inData);
  final outDataPrr = calloc<ffi.Uint8>(inLen);

  final outLenPtr = calloc<ffi.Size>();
  outLenPtr.value = inLen;

  final result = _bindings.FMCompressData(inDataPtr.cast(), inLen, outDataPrr as ffi.Pointer<ffi.UnsignedChar>, outLenPtr);

  if (result == 0) {
    throw Exception("compress error");
  }

  //把data转换成Uint8List深度拷贝过来，否则data释放后，Uint8List就是空的了
  Uint8List bytes = _PointerToUint8List(outDataPrr, outLenPtr.value);

  print('inLen size: $inLen');
  print(bytes);
  print('outLen size: ${outLenPtr.value}');
  print(result);

  return BitCompressData(bytes, outLenPtr.value);
}


/// A function use for decompress data by using minilzo
///
/// [inData] the data which should be decompress
/// [inLen] the size of data to decompress
BitCompressData decompressData(Uint8List inData, int inLen) {
  final inDataPtr = _Uint8ListToPointer(inData);
  final outDataPrr = calloc<ffi.Uint8>(inLen);

  final outLenPtr = calloc<ffi.Size>();
  outLenPtr.value = inLen;

  final result = _bindings.FMDecompressData(inDataPtr.cast(), inLen, outDataPrr as ffi.Pointer<ffi.UnsignedChar>, outLenPtr);

  if (result == 0) {
    throw Exception("compress error");
  }

  //把data转换成Uint8List深度拷贝过来，否则data释放后，Uint8List就是空的了
  Uint8List bytes = _PointerToUint8List(outDataPrr, outLenPtr.value);

  print('inLen size: $inLen');
  print(bytes);
  print('outLen size: ${outLenPtr.value}');
  print(result);

  return BitCompressData(bytes, outLenPtr.value);
}

ffi.Pointer _Uint8ListToPointer(Uint8List list){
  Pointer<Uint8> myPointer = malloc.allocate<ffi.Uint8>(list.length);
  //用uint8list指向空间,并将数据拷贝到空间
  myPointer.asTypedList(list.length).setAll(0, list);
  return myPointer;
}

Uint8List _PointerToUint8List(Pointer<Uint8> data, int len){
  //把data转换成Uint8List深度拷贝过来，否则data释放后，Uint8List就是空的了
  Uint8List bytes = Uint8List.fromList(data.asTypedList(len));
  return bytes;
}

/// A longer lived native function, which occupies the thread calling it.
///
/// Do not call these kind of native functions in the main isolate. They will
/// block Dart execution. This will cause dropped frames in Flutter applications.
/// Instead, call these native functions on a separate isolate.
///
/// Modify this to suit your own use case. Example use cases:
///
/// 1. Reuse a single isolate for various different kinds of requests.
/// 2. Use multiple helper isolates for parallel execution.
// Future<int> sumAsync(int a, int b) async {
//   final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
//   final int requestId = _nextSumRequestId++;
//   final _SumRequest request = _SumRequest(requestId, a, b);
//   final Completer<int> completer = Completer<int>();
//   _sumRequests[requestId] = completer;
//   helperIsolateSendPort.send(request);
//   return completer.future;
// }

const String _libName = 'native_minilzo';

/// The dynamic library in which the symbols for [NativeMinilzoBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final NativeMinilzoBindings _bindings = NativeMinilzoBindings(_dylib);

