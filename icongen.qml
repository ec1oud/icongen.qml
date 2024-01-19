#!/usr/bin/env qml

/*
  Copyright (c) 2017 Shawn Rutledge <s@ecloud.org>
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 908; height: 720
    visible: true
    title: "Icon Generator: " + fontFamilyLabel.text + " " + glyphCodpointField.text

    property string savePath: "."
    property int glyphStyle: styleModel.get(styleCombo.currentIndex).value // Text.Normal
    property int glpyhCodepoint: 0xF000
    onGlpyhCodepointChanged: glyphCodpointField.text = "0x" + glpyhCodepoint.toString(16)
    property string glyph: fromCodePoint(glpyhCodepoint)
    property url checkerboardImage

    /*! http://mths.be/fromcodepoint v0.1.0 by @mathias */
    function fromCodePoint() {
        var MAX_SIZE = 0x4000;
        var codeUnits = [];
        var highSurrogate;
        var lowSurrogate;
        var index = -1;
        var length = arguments.length;
        if (!length) {
          return '';
        }
        var result = '';
        while (++index < length) {
          var codePoint = Number(arguments[index]);
          if (
            !isFinite(codePoint) ||       // `NaN`, `+Infinity`, or `-Infinity`
            codePoint < 0 ||              // not a valid Unicode code point
            codePoint > 0x10FFFF ||       // not a valid Unicode code point
            Math.floor(codePoint) != codePoint // not an integer
          ) {
            throw RangeError('Invalid code point: ' + codePoint);
          }
          if (codePoint <= 0xFFFF) { // BMP code point
            codeUnits.push(codePoint);
          } else { // Astral code point; split in surrogate halves
            // http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
            codePoint -= 0x10000;
            highSurrogate = (codePoint >> 10) + 0xD800;
            lowSurrogate = (codePoint % 0x400) + 0xDC00;
            codeUnits.push(highSurrogate, lowSurrogate);
          }
          if (index + 1 == length || codeUnits.length > MAX_SIZE) {
            result += String.fromCharCode.apply(null, codeUnits);
            codeUnits.length = 0;
          }
        }
        return result;
    }

    function getFileName(i) {
        var ret = namingPatternField.text
        ret = ret.replace("$x", glpyhCodepoint.toString(16))
        ret = ret.replace("$s", glyphsRepeater.model[i].toString())
        return ret
    }

    function saveDone(i, filePath) {
        progressBar.value = i
        if (progressBar.value == progressBar.to)
            progressCloseTimer.start()
    }

    function exportImages() {
        progressBar.to = archetypeRow.children.length - 2
        progressLabel.text = "Saving…"
        progressPopup.visible = true
        for (var i = 0; i < archetypeRow.children.length; ++i) {
            var img = archetypeRow.children[i]
            if (img.children.length > 0) {
                var rect = img.children[0]
                var path = savePath + "/" + getFileName(i)
                console.log(i + " trying to save " + path)
                // how to capture path for the function passed to grabToImage:
                // http://stackoverflow.com/questions/30476721/passing-parameter-onclick-in-a-loop/
                rect.grabToImage(function(i, path) {
                    return function(result) {
                        progressLabel.text += "\n" + path
                        result.saveToFile(path)
                        saveDone(i, path)
                    }}(i, path));
            }
        }
    }

    Canvas {
        id: checkerSquare
        width: 10
        height: 10
        property color background: "white"
        property color color: "lightgrey"
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = background;
            ctx.fillRect(0, 0, width, height);

            var boxSize = width / 2;
            ctx.fillStyle = color;
            ctx.rect(0, 0, boxSize, boxSize);
            ctx.rect(boxSize, boxSize, boxSize, boxSize);
            ctx.fill();
        }
        onPainted: checkerSquare.grabToImage(function(result) {
                checkerboardImage = result.url;
                checkerSquare.visible = false;
            });
    }
    FolderDialog {
        id: folderDialog
        onAccepted: savePath = selectedFolder
    }
    FontDialog {
        id: fontDialog
        currentFont: Qt.font({ family: "FontAwesome", pointSize: 24, weight: Font.Normal })
        onAccepted: {
            fontFamilyLabel.text = fontDialog.font.family
        }
    }
    ColorDialog {
        id: colorDialog
        options: ColorDialog.ShowAlphaChannel
        property var setColorOn: null
        function openFor(sth) { setColorOn = sth; open() }
        onAccepted: setColorOn.color = colorDialog.selectedColor
    }
    Popup {
        id: progressPopup
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        ColumnLayout {
            anchors.fill: parent
            Label {
                id: progressLabel
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
            ProgressBar {
                id: progressBar
                Layout.fillWidth: true
                value: 0.5
            }
        }
        Timer {
            id: progressCloseTimer
            onTriggered: progressPopup.visible = false
        }
    }

    Shortcut { sequence: StandardKey.Quit; onActivated: Qt.quit() }

    Component {
        id: colorPicker
        Row {
            spacing: 4
            property alias color: swatch.color
            property alias colorName: button.text
            Button { id: button; text: "Color"; onClicked: colorDialog.openFor(swatch) }
            Image {
                width: 32
                height: width
                fillMode: Image.Tile
                source: checkerboardImage
                anchors.verticalCenter: button.verticalCenter
                Rectangle {
                    id: swatch
                    anchors.fill: parent
                    color: "black"
                    border.color: "lightgrey"
                }
            }
        }
    }

    GridLayout {
        id: grid
        columns: 6
        anchors.fill: parent
        anchors.margins: 4

        Label { id: fontFamilyLabel; text: "FontAwesome" }
        Button { text: "Choose…"; onClicked: fontDialog.open() }

        Label { text: "Sizes" }
        TextField {
            Layout.minimumWidth: parent.width / 4
            text: "16 22 24 36"
            onTextChanged: {
                var tok = text.split(" ");
                var biggest = 0
                var sizes = tok.map(function(s) {
                    var size = parseInt(s)
                    if (size > biggest)
                        biggest = size
                    return size
                })
                glyphsRepeater.model = sizes
                archetypeFrame.height = biggest + 8
            }
        }

        Label { text: "Unicode" }
        TextField {
            id: glyphCodpointField
            Layout.fillWidth: true
            text: "0xF000"
            onEditingFinished: glpyhCodepoint = parseInt(text, 16)
        }


        Label { text: "Save to" }
        Button { id: dirChooseButton; text: "Choose…"; onClicked: folderDialog.open() }

        Label { text: "Naming" }
        TextField { id: namingPatternField; Layout.minimumWidth: parent.width / 4; text: "u$x_$s.png" }

        Label {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.minimumWidth: parent.width / 3
            text: "Example: " + getFileName(0)
        }

        Label { text: "Style" }
        ComboBox {
            id: styleCombo
            textRole: "key"
            model: ListModel {
                id: styleModel
                ListElement { key: "Plain"; value: Text.Normal }
                ListElement { key: "Outline"; value: Text.Outline }
                ListElement { key: "Raised"; value: Text.Raised }
                ListElement { key: "Sunken"; value: Text.Sunken }
            }
        }
        SpinBox {
            id: styleOffsetSB
            from: 1
            to: 4
            value: 1
            property real multiplier: value * (glyphStyle == Text.Sunken ? -1 : 1)
            visible: styleCombo.currentIndex > 1
        }

        Row {
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.minimumHeight: dirChooseButton.height
            spacing: 6

            Item {
                id: primaryColorPicker
                property color color: children.length > 0 ? children[0].color : "black"
                implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
                height: 32
                Component.onCompleted: colorPicker.createObject(this, {"colorName": "Primary", "color": "black"})
            }

            Item {
                id: highlightColorPicker
                property color color: children.length > 0 ? children[0].color : "white"
                implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
                height: 32
                Component.onCompleted: colorPicker.createObject(this, {"colorName": "Highlight", "color": "white"})
                visible: styleCombo.currentIndex > 0
            }

            Item {
                id: shadowColorPicker
                property color color: children.length > 0 ? children[0].color : "white"
                implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
                height: 32
                Component.onCompleted: colorPicker.createObject(this, {"colorName": "Shadow", "color": "darkgray"})
                visible: styleCombo.currentIndex > 1
            }

            Item {
                id: backgroundColorPicker
                property color color: children.length > 0 ? children[0].color : "transparent"
                implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
                height: 32
                Component.onCompleted: colorPicker.createObject(this, {"colorName": "Background", "color": "transparent"})
            }
        }


        Row {
            Layout.columnSpan: 6
            Layout.minimumHeight: Math.max(archetypeFrame.height, goButton.height)
            Layout.fillWidth: true
            height: archetypeFrame.height
            spacing: 4

            Rectangle {
                id: archetypeFrame
                radius: 3
                color: "#444"
                height: 42
                width: parent.width - goButton.width - 4

                Row {
                    id: archetypeRow
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        id: glyphsRepeater
                        model: [16, 22, 24, 36]
                        Image {
                            width: modelData
                            height: modelData
                            anchors.bottom: parent.bottom
                            anchors.margins: 1
                            fillMode: Image.Tile
                            source: checkerboardImage
                            Rectangle {
                                color: backgroundColorPicker.color
                                anchors.fill: parent
                                Text {
                                    id: shadow
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: styleOffsetSB.multiplier
                                    anchors.horizontalCenterOffset: styleOffsetSB.multiplier
                                    font.pixelSize: glpyhArchetype.font.pixelSize
                                    font.family: glpyhArchetype.font.family
                                    text: glyph
                                    color: shadowColorPicker.color
                                    visible: glyphStyle > Text.Outline
                                }
                                Text {
                                    id: highlight
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -styleOffsetSB.multiplier
                                    anchors.horizontalCenterOffset: -styleOffsetSB.multiplier
                                    font.pixelSize: glpyhArchetype.font.pixelSize
                                    font.family: glpyhArchetype.font.family
                                    text: glyph
                                    color: highlightColorPicker.color
                                    visible: glyphStyle > Text.Outline
                                }
                                Text {
                                    id: glpyhArchetype
                                    objectName: "glpyhArchetype"
                                    anchors.centerIn: parent
                                    font.pixelSize: modelData - styleOffsetSB.value * 2
                                    font.family: fontFamilyLabel.text
                                    text: glyph
                                    color: primaryColorPicker.color
                                    style: glyphStyle == Text.Outline ? Text.Outline : Text.Normal
                                    styleColor: highlightColorPicker.color
                                }
                            }
                        }
                    }
                }
            }

            Button {
                id: goButton
                text: "Go!"
                anchors.verticalCenter: archetypeFrame.verticalCenter
                onClicked: exportImages()
            }
        }

        GridView {
            model: 1024
            Layout.columnSpan: 6
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellHeight: 36
            cellWidth: 36
            clip: true

            delegate: Rectangle {
                width: 34
                height: 34
                border.color: "grey"
                radius: 3
                Text {
                    text: fromCodePoint(modelData + 0xF000)
                    anchors.centerIn: parent
                    font.pointSize: 18
                    font.family: fontFamilyLabel.text
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: glpyhCodepoint = modelData + 0xF000
                }
            }
        }
    }
}
