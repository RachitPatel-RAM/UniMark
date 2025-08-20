// Custom exception classes for authentication
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

// Generic exceptions
class NetworkException extends AuthException {
  NetworkException() : super('Please check your internet connection.');
}

class UnknownException extends AuthException {
  UnknownException() : super('An unknown error occurred. Please try again later.');
}

// Login exceptions
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException() : super('Invalid email or password.');
}

class UserNotFoundException extends AuthException {
  UserNotFoundException() : super('No user found with this email.');
}

class UserDisabledException extends AuthException {
  UserDisabledException() : super('This user account has been disabled.');
}

class TooManyRequestsException extends AuthException {
  TooManyRequestsException() : super('Too many login attempts. Please try again later.');
}

class DeviceBindingException extends AuthException {
  DeviceBindingException() : super('This account is bound to another device.');
}

// Registration exceptions
class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException() : super('This email is already in use.');
}

class WeakPasswordException extends AuthException {
  WeakPasswordException() : super('The password is too weak.');
}

class InvalidEmailException extends AuthException {
  InvalidEmailException() : super('The email address is not valid.');
}

class EnrollmentNumberAlreadyExistsException extends AuthException {
  EnrollmentNumberAlreadyExistsException() : super('This enrollment number is already registered.');
}

// General Firebase exceptions
class FirestoreException extends AuthException {
  FirestoreException(String message) : super('A Firestore error occurred: $message');
}
