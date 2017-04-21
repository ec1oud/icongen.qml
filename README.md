# icongen.qml
A tool for browsing icon fonts and generating pixmaps

You only need the icongen.qml file.  Assuming the "qml" runtime is in your path,
you can run it directly (it's a QML script with a shebang line, like any shell, perl or python script).
Should work fine with Qt 5.8 or newer.

So far it works best with FontAwesome, because it assumes the glyphs of interest
are those with Unicode codepoints over 0xF000.  The font which you would
like to use needs to be installed as a system font.

<img src="screenshot.png" width="914">

