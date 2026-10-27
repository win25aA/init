# noctalia с доступом к NVML (статистика NVIDIA): добавляем драйверные либы в LD_LIBRARY_PATH.
{ symlinkJoin, makeWrapper, noctalia }:

symlinkJoin {
  name = "noctalia-nvml";
  paths = [ noctalia ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    for bin in $out/bin/*; do
      wrapProgram "$bin" --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
    done
  '';
}
