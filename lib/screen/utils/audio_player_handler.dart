import 'package:audio_service/audio_service.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  @override
  Future<void> play() async {
    // Пользователь нажал 'Play' на наушниках
    print('>>> ПОЙМАЛ СОБЫТИЕ: PLAY');
    // TODO: Здесь вы бы вызвали _player.play()
  }

  @override
  Future<void> pause() async {
    // Пользователь нажал 'Pause' на наушниках
    print('>>> ПОЙМАЛ СОБЫТИЕ: PAUSE');
    // TODO: Здесь вы бы вызвали _player.pause()
  }

  @override
  Future<void> skipToNext() async {
    // Пользователь нажал 'Next' на наушниках
    print('>>> ПОЙМАЛ СОБЫТИЕ: NEXT');
    // TODO: Здесь вы бы вызвали _player.seekToNext()
  }

  @override
  Future<void> skipToPrevious() async {
    // Пользователь нажал 'Previous' на наушниках
    print('>>> ПОЙМАЛ СОБЫТИЕ: PREVIOUS');
    // TODO: Здесь вы бы вызвали _player.seekToPrevious()
  }
}
