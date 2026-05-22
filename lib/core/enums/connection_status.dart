/// LG connection state.
enum ConnectionStatus {
  connected('Connected'),
  disconnected('Disconnected'),
  connecting('Connecting...'),
  error('Connection Error');

  final String label;
  const ConnectionStatus(this.label);
}
