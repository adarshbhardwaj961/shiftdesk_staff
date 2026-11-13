class ClaimCheck {
  const ClaimCheck.allowed() : canClaim = true, reason = null;
  const ClaimCheck.denied(this.reason) : canClaim = false;
  final bool canClaim;
  final String? reason;
}
