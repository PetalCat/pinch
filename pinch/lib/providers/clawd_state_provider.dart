import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/clawd/clawd_state.dart';

final clawdStateProvider = StateProvider<ClawdState>((ref) => ClawdState.idle);
