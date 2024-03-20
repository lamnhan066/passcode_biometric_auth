import 'package:equatable/equatable.dart';

class CheckPasscodeState extends Equatable {
  final bool isAuthenticated;
  final bool isUseBiometric;

  const CheckPasscodeState({
    required this.isAuthenticated,
    required this.isUseBiometric,
  });

  @override
  List<Object?> get props => [isAuthenticated, isUseBiometric];
}
