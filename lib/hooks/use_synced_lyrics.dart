import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotube/provider/playlist_queue_provider.dart';

int useSyncedLyrics(
  WidgetRef ref,
  Map<int, String> lyricsMap,
  int delay,
) {
  final stream = PlaylistQueueNotifier.position;

  final currentTime = useState(0);

  useEffect(() {
    return stream.listen((pos) {
      if (lyricsMap.containsKey(pos.inSeconds + delay)) {
        currentTime.value = pos.inSeconds + delay;
      }
    }).cancel;
  }, [lyricsMap, delay]);

  return (Duration(seconds: currentTime.value)).inSeconds;
}
