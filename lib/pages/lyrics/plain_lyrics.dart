import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/lyrics/zoom_controls.dart';
import 'package:spotube/components/shared/shimmers/shimmer_lyrics.dart';
import 'package:spotube/hooks/use_breakpoints.dart';
import 'package:spotube/provider/playlist_queue_provider.dart';

import 'package:spotube/services/queries/queries.dart';
import 'package:spotube/utils/type_conversion_utils.dart';

class PlainLyrics extends HookConsumerWidget {
  final PaletteColor palette;
  final bool? isModal;
  const PlainLyrics({
    required this.palette,
    this.isModal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final playlist = ref.watch(PlaylistQueueNotifier.provider);
    final lyricsQuery = useQueries.lyrics.spotifySynced(
      ref,
      playlist?.activeTrack,
    );
    final breakpoint = useBreakpoints();
    final textTheme = Theme.of(context).textTheme;

    final textZoomLevel = useState<int>(100);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isModal != true) ...[
              Center(
                child: Text(
                  playlist?.activeTrack.name ?? "",
                  style: breakpoint >= Breakpoints.md
                      ? textTheme.displaySmall
                      : textTheme.headlineMedium?.copyWith(
                          fontSize: 25,
                          color: palette.titleTextColor,
                        ),
                ),
              ),
              Center(
                child: Text(
                  TypeConversionUtils.artists_X_String<Artist>(
                      playlist?.activeTrack.artists ?? []),
                  style: (breakpoint >= Breakpoints.md
                          ? textTheme.headlineSmall
                          : textTheme.titleLarge)
                      ?.copyWith(color: palette.bodyTextColor),
                ),
              )
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Builder(
                      builder: (context) {
                        if (lyricsQuery.isLoading || lyricsQuery.isRefreshing) {
                          return const ShimmerLyrics();
                        } else if (lyricsQuery.hasError) {
                          return Text(
                            "Sorry, no Lyrics were found for `${playlist?.activeTrack.name}` :'(\n${lyricsQuery.error.toString()}",
                            style: textTheme.bodyLarge?.copyWith(
                              color: palette.bodyTextColor,
                            ),
                          );
                        }

                        final lyrics =
                            lyricsQuery.data?.lyrics.mapIndexed((i, e) {
                          final next =
                              lyricsQuery.data?.lyrics.elementAtOrNull(i + 1);
                          if (next != null &&
                              e.time - next.time >
                                  const Duration(milliseconds: 700)) {
                            return "${e.text}\n";
                          }

                          return e.text;
                        }).join("\n");

                        return AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: palette.bodyTextColor,
                            fontSize: 24 * textZoomLevel.value / 100,
                            height: textZoomLevel.value < 70
                                ? 1.5
                                : textZoomLevel.value > 150
                                    ? 1.7
                                    : 2,
                          ),
                          child: Text(
                            lyrics == null && playlist?.activeTrack == null
                                ? "No Track being played currently"
                                : lyrics ?? "",
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: ZoomControls(
            value: textZoomLevel.value,
            onChanged: (value) => textZoomLevel.value = value,
            min: 50,
            max: 200,
          ),
        ),
      ],
    );
  }
}
