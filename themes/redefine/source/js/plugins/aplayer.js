(function() {
  const audioList = [];
  const isFixed = theme.plugins.aplayer.type === "fixed";
  const isMini = theme.plugins.aplayer.type === "mini";
  let hasLrc = false;

  for (const audio of theme.plugins.aplayer.audios) {
    const audioObj = {
      name: audio.name,
      artist: audio.artist,
      url: audio.url,
      cover: audio.cover,
      theme: audio.theme,
    };

    if (audio.lrc) {
      audioObj.lrc = audio.lrc;
      hasLrc = true;
    }

    audioList.push(audioObj);
  }

  if (isMini) {
    new APlayer({
      container: document.getElementById("aplayer"),
      mini: true,
      audio: audioList,
    });
  } else if (isFixed) {
    const player = new APlayer({
      container: document.getElementById("aplayer"),
      fixed: true,
      ...(hasLrc ? { lrcType: 3 } : {}),
      audio: audioList,
    });
    if (hasLrc) {
      document.querySelector(".aplayer-icon-lrc").click();
    }
  }
})();
