/// Execution phase of the animated card deck OTP verification
enum OtpDeckPhase {
  /// User is typing digits into the separated cards
  input,

  /// Cards fan out in an arc like a deck of playing cards
  fanOut,

  /// Cards collapse inward into a single compact deck in the center
  stacked,

  /// Glowing gradient ring spins while backend verification runs
  verifying,

  /// Elastic checkmark pop when the code is verified
  success,

  /// Horizontal shake animation when the code is invalid
  error,
}

