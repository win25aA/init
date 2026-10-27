# noctalia с доступом к NVML (статистика NVIDIA): добавляем драйверные либы в LD_LIBRARY_PATH.
{ symlinkJoin, makeWrapper, stdenv, inputs }:

symlinkJoin {
  name = "noctalia-nvml";
  paths = [ inputs.noctalia.packages.${stdenv.hostPlatform.system}.default ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    for bin in $out/bin/*; do
      wrapProgram "$bin" --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
    done
  '';
}
