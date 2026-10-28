# NVIDIA 580 поддерживает NVENC API до 13.0, а GSR с FFmpeg 9 требует 13.1.
# Меняем FFmpeg только у рекордера: системные FFmpeg, mpv и прочие не затрагиваем.
# FFmpeg 7 из того же nixpkgs совместим с этой веткой драйвера.
{ gpu-screen-recorder, ffmpeg_7 }:

gpu-screen-recorder.override {
  ffmpeg = ffmpeg_7;
}
