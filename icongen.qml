#!/bin/env qml

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

import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.1

ApplicationWindow {
    id: window
    width: 908; height: 720
    visible: true

    property string savePath: "."
    property int glyphStyle: styleModel.get(styleCombo.currentIndex).value // Text.Normal
    property int glpyhCodepoint: 0xF000
    onGlpyhCodepointChanged: glyphCodpointField.text = "0x" + glpyhCodepoint.toString(16)
    property string glyph: fromCodePoint(glpyhCodepoint)

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

    function saveDone(filePath) {
        console.log("saved " + filePath)
    }

    function exportImages() {
        for (var i = 0; i < archetypeRow.children.length; ++i) {
            var rect = archetypeRow.children[i]
            if (rect.children.length > 0) {
                var path = savePath + "/" + getFileName(i)
                console.log(i + " trying to save " + path)
                // how to capture path for the function passed to grabToImage:
                // http://stackoverflow.com/questions/30476721/passing-parameter-onclick-in-a-loop/
                rect.grabToImage(function(path) {
                    return function(result) {
                        result.saveToFile(path)
                        saveDone(path)
                    }}(path));
            }
        }
    }

    FileDialog {
        id: fileDialog
        selectFolder: true
        onAccepted: savePath = fileUrl
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
        property var setColorOn: null
        function openFor(sth) { setColorOn = sth; open() }
        onAccepted: setColorOn.color = colorDialog.color
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
            text: "0xF000"
            onEditingFinished: glpyhCodepoint = parseInt(text, 16)
        }


        Label { text: "Save to" }
        Button { id: dirChooseButton; text: "Choose…"; onClicked: fileDialog.open() }

        Label { text: "Naming" }
        TextField { id: namingPatternField; text: "u$x_$s.png" }

        Label {
            Layout.columnSpan: 2
            Layout.fillWidth: true
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

        Row {
            Layout.columnSpan: 4
            Layout.fillWidth: true
            spacing: 4
            Button { text: "Primary Color"; onClicked: colorDialog.openFor(primaryColorSwatch) }
            Rectangle {
                id: primaryColorSwatch
                width: 40
                height: width
                color: "black"
                border.color: "lightgrey"
            }

            Button { text: "Secondary Color"; onClicked: colorDialog.openFor(secondaryColorSwatch) }
            Rectangle {
                id: secondaryColorSwatch
                width: 40
                height: width
                color: "grey"
                border.color: "lightgrey"
            }

            Button { text: "Background"; onClicked: colorDialog.openFor(backgroundColorSwatch) }
            Rectangle {
                id: backgroundColorSwatch
                width: 40
                height: width
                color: "white"
                border.color: "lightgrey"
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
                        Rectangle {
                            width: modelData
                            height: modelData
                            anchors.bottom: parent.bottom
                            anchors.margins: 1
                            color: backgroundColorSwatch.color
                            Text {
                                id: glpyhArchetype
                                objectName: "glpyhArchetype"
                                anchors.centerIn: parent
                                font.pixelSize: modelData
                                font.family: fontFamilyLabel.text
                                text: glyph
                                color: primaryColorSwatch.color
                                style: glyphStyle
                                styleColor: secondaryColorSwatch.color
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
