class InsufficientCreditsException implements Exception {
  final String message;
  InsufficientCreditsException(this.message);
  
  @override
  String toString() => message;
}

class ProcessingException implements Exception {
  final String message;
  ProcessingException(this.message);
  
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
