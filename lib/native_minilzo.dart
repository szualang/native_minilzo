
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

/// A very short-lived native function.
///
/// For very short-lived functions, it is fine to call them on the main isolate.
/// They will block the Dart execution while running the native function, so
/// only do this for native functions which are guaranteed to be short-lived.
int sum(int a, int b) => _bindings.sum(a, b);

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

  print(inLen);
  print(bytes);
  print(outLenPtr.value);
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

  print(inLen);
  print(bytes);
  print(outLenPtr.value);
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

//
// /// A request to compute `sum`.
// ///
// /// Typically sent from one isolate to another.
// class _SumRequest {
//   final int id;
//   final int a;
//   final int b;
//
//   const _SumRequest(this.id, this.a, this.b);
// }
//
// /// A response with the result of `sum`.
// ///
// /// Typically sent from one isolate to another.
// class _SumResponse {
//   final int id;
//   final int result;
//
//   const _SumResponse(this.id, this.result);
// }
//
// /// Counter to identify [_SumRequest]s and [_SumResponse]s.
// int _nextSumRequestId = 0;
//
// /// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
// final Map<int, Completer<int>> _sumRequests = <int, Completer<int>>{};
//
// /// The SendPort belonging to the helper isolate.
// Future<SendPort> _helperIsolateSendPort = () async {
//   // The helper isolate is going to send us back a SendPort, which we want to
//   // wait for.
//   final Completer<SendPort> completer = Completer<SendPort>();
//
//   // Receive port on the main isolate to receive messages from the helper.
//   // We receive two types of messages:
//   // 1. A port to send messages on.
//   // 2. Responses to requests we sent.
//   final ReceivePort receivePort = ReceivePort()
//     ..listen((dynamic data) {
//       if (data is SendPort) {
//         // The helper isolate sent us the port on which we can sent it requests.
//         completer.complete(data);
//         return;
//       }
//       if (data is _SumResponse) {
//         // The helper isolate sent us a response to a request we sent.
//         final Completer<int> completer = _sumRequests[data.id]!;
//         _sumRequests.remove(data.id);
//         completer.complete(data.result);
//         return;
//       }
//       throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
//     });
//
//   // Start the helper isolate.
//   await Isolate.spawn((SendPort sendPort) async {
//     final ReceivePort helperReceivePort = ReceivePort()
//       ..listen((dynamic data) {
//         // On the helper isolate listen to requests and respond to them.
//         if (data is _SumRequest) {
//           final int result = _bindings.sum_long_running(data.a, data.b);
//           final _SumResponse response = _SumResponse(data.id, result);
//           sendPort.send(response);
//           return;
//         }
//         throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
//       });
//
//     // Send the port to the main isolate on which we can receive requests.
//     sendPort.send(helperReceivePort.sendPort);
//   }, receivePort.sendPort);
//
//   // Wait until the helper isolate has sent us back the SendPort on which we
//   // can start sending requests.
//   return completer.future;
// }();
