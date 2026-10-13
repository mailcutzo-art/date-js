enum ReportReason {
  fakeProfile('Fake profile or spam'),
  inappropriate('Inappropriate photos or messages'),
  harassment('Harassment or hate'),
  underage('Looks under 18'),
  scam('Scam or asking for money'),
  other('Something else');

  const ReportReason(this.label);
  final String label;
}
