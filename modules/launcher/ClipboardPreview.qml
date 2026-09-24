pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia
import "services"
import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Caelestia.I18n

Item {
    id: root

    property var currentItem: null
    property bool shouldShow: false

    property string imageDataUrl: ""
    property string extractedImageUrl: ""
    property bool loadingImage: false
    property bool decodingHtml: false
    property bool imageLoadError: false

    // Text preview: cliphist list only carries a flattened 100-char preview,
    // so the full text is decoded on selection, capped at textByteCap bytes.
    readonly property int textByteCap: 20000
    property string fullText: ""
    property bool loadingText: false
    property bool textTruncated: false

    readonly property bool isTextItem: {
        const data = currentItem?.modelData;
        return !!data && data.isImage !== true && data.hasImageUrl !== true;
    }

    readonly property var textLines: fullText === "" ? [] : fullText.replace(/\n+$/, "").split("\n")
    readonly property int textMaxLineLength: textLines.reduce((m, l) => Math.max(m, l.length), 0)

    // Short one-liners already read in full in the list row.
    readonly property bool hasText: isTextItem && fullText !== "" && (textLines.length > 1 || fullText.length > 80)

    // Share of visible characters that are not letters, digits or common
    // punctuation. Braille, box drawing and block art score high, logs low.
    readonly property real symbolRatio: {
        const visible = fullText.replace(/\s/g, "");
        if (visible.length === 0)
            return 0;
        const plain = visible.match(/[A-Za-z0-9.,:;'"!?()\[\]{}\-_\/\\@#$%&*+=<>|~`^]/g);
        return 1 - (plain ? plain.length : 0) / visible.length;
    }

    // Art keeps its columns and shrinks to fit, so it stays aligned.
    // Everything else wraps at a readable size.
    readonly property bool asciiLayout: textLines.length > 1 && textMaxLineLength <= 240 && symbolRatio > 0.3

    readonly property bool hasContent: hasImage || hasText

    readonly property bool hasImage: {
        if (!currentItem?.modelData || imageLoadError)
            return false;
        const data = currentItem.modelData;
        return data.isImage === true || data.hasImageUrl === true;
    }

    readonly property string imageSource: {
        if (!currentItem?.modelData)
            return "";
        const data = currentItem.modelData;

        if (data.isImage === true && imageDataUrl !== "")
            return imageDataUrl;
        if (data.hasImageUrl === true)
            return extractedImageUrl || data.imageUrl || "";

        return "";
    }

    readonly property real rounding: Config.border.rounding

    property real lastValidHeight: 0

    readonly property real targetHeight: {
        if (!shouldShow || !hasContent) {
            return 0;
        }

        if (hasText) {
            const lineHeight = 17;
            const chrome = Tokens.padding.medium * 2 + 28;
            const rows = asciiLayout ? textLines.length : textLines.reduce((n, l) => n + Math.max(1, Math.ceil(l.length / 46)), 0);
            return Math.max(140, Math.min(asciiLayout ? 520 : 420, rows * lineHeight + chrome));
        }

        if (previewImage.status === Image.Ready && previewImage.sourceSize.height > 0) {
            const aspectRatio = previewImage.sourceSize.width / previewImage.sourceSize.height;
            const maxHeight = 600;
            const minHeight = 200;
            const availableWidth = width - (Tokens.padding.medium * 2);
            const calculatedHeight = (availableWidth / aspectRatio) + (Tokens.padding.medium * 2);
            const newHeight = Math.max(minHeight, Math.min(maxHeight, calculatedHeight));
            lastValidHeight = newHeight;
            return newHeight;
        }

        return lastValidHeight;
    }

    function decodeImageToDataUrl(): void {
        if (!currentItem?.modelData?.isImage)
            return;
        decodeProcess.command = ["sh", "-c", "cliphist decode \"$1\" | base64 -w 0", "sh", String(currentItem.modelData.id)];
        decodeProcess.running = true;
    }

    function decodeText(): void {
        if (!isTextItem)
            return;
        const id = String(currentItem.modelData.id);
        decodeTextProcess.requestedId = id;
        decodeTextProcess.command = ["sh", "-c", "cliphist decode \"$1\" | head -c \"$2\"", "sh", id, String(textByteCap + 1)];
        decodeTextProcess.running = true;
    }

    function decodeHtmlForImageUrl(): void {
        if (!currentItem?.modelData?.needsDecodeForUrl)
            return;
        decodeHtmlProcess.command = ["cliphist", "decode", currentItem.modelData.id];
        decodeHtmlProcess.running = true;
    }

    width: hasText ? 480 : 400

    height: targetHeight

    enabled: shouldShow && hasContent

    visible: height > (rounding * 2)

    clip: false

    onCurrentItemChanged: {
        const wasImage = imageDataUrl !== "" || extractedImageUrl !== "";
        const isImage = currentItem?.modelData?.isImage === true || currentItem?.modelData?.hasImageUrl === true || currentItem?.modelData?.imageUrl;

        if (wasImage && !isImage)
            lastValidHeight = 0;

        imageDataUrl = "";
        loadingImage = false;
        extractedImageUrl = "";
        imageLoadError = false;
        decodingHtml = false;
        fullText = "";
        textTruncated = false;
        loadingText = false;

        if (currentItem && currentItem.modelData) {
            const data = currentItem.modelData;
            if (data.isImage === true) {
                loadingImage = true;
                decodeImageToDataUrl();
            } else if (data.needsDecodeForUrl === true) {
                decodingHtml = true;
                decodeHtmlForImageUrl();
            } else if (data.imageUrl) {
                extractedImageUrl = data.imageUrl;
            } else if (isTextItem) {
                loadingText = true;
                decodeText();
            }
        }
    }

    Process {
        id: decodeProcess

        stdout: StdioCollector {}
        onExited: { // qmllint disable signal-handler-parameters
            if (root.currentItem?.modelData?.isImage) {
                const b64 = String(stdout.text).trim(); // qmllint disable missing-property
                if (b64)
                    root.imageDataUrl = "data:image/png;base64," + b64;
            }
            root.loadingImage = false;
        }
    }

    Process {
        id: decodeTextProcess

        property string requestedId: ""

        stdout: StdioCollector {}
        onExited: { // qmllint disable signal-handler-parameters
            // Drop a result that lands after the selection moved on.
            if (String(root.currentItem?.modelData?.id) !== requestedId)
                return;
            let text = String(stdout.text); // qmllint disable missing-property
            root.textTruncated = text.length > root.textByteCap;
            if (root.textTruncated)
                text = text.substring(0, root.textByteCap);
            root.fullText = text;
            root.loadingText = false;
        }
    }

    Process {
        id: decodeHtmlProcess

        stdout: StdioCollector {}
        onExited: { // qmllint disable signal-handler-parameters
            root.decodingHtml = false;
            if (root.currentItem?.modelData?.needsDecodeForUrl) {
                const srcMatch = String(stdout.text).match(/<img[^>]+src\s*=\s*["']([^"']+)["']/i); // qmllint disable missing-property
                if (srcMatch?.[1])
                    root.extractedImageUrl = srcMatch[1];
            }
        }
    }

    Process {
        id: copyGrabbedImageProcess

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (exitCode === 0) {
                Toaster.toast("Image copied", "Copied image to clipboard", "image");
                Clipboard.refresh(); // qmllint disable missing-property
            } else {
                Toaster.toast("Copy failed", "Failed to copy image", "error");
            }
        }
    }

    Behavior on height {
        enabled: root.targetHeight === 0 || root.height === 0 || Math.abs(root.targetHeight - root.height) > 5

        Anim {
            duration: Tokens.anim.durations.expressiveDefaultSpatial
            easing: Tokens.anim.expressiveDefaultSpatial
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: 0

        Item {
            id: textContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.hasText
            clip: true

            StyledText {
                id: previewText

                anchors.fill: parent
                text: root.fullText
                font: Tokens.font.mono.small
                color: Colours.palette.m3onSurface
                verticalAlignment: Text.AlignTop
                wrapMode: root.asciiLayout ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                fontSizeMode: root.asciiLayout ? Text.Fit : Text.FixedSize
                minimumPointSize: 5
                opacity: root.shouldShow && root.hasText ? 1 : 0

                Behavior on opacity {
                    Anim {
                        duration: Tokens.anim.durations.small
                        easing: Tokens.anim.standard
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.small
            visible: root.hasText
            text: {
                const lines = root.textLines.length;
                const chars = root.fullText.length.toLocaleString(Qt.locale(), "f", 0);
                return `${lines} line${lines !== 1 ? "s" : ""} · ${chars}${root.textTruncated ? "+" : ""} chars`;
            }
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }

        Item {
            id: imageContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.hasText

            property string pendingSource: ""

            onPendingSourceChanged: {
                if (pendingSource !== "")
                    fadeOutIn.restart();
            }

            Image {
                id: previewImage

                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                visible: opacity > 0
                opacity: (root.shouldShow && root.hasImage && status === Image.Ready) ? 1 : 0

                onStatusChanged: {
                    if (status === Image.Error)
                        root.imageLoadError = true;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.anim.durations.small
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Connections {
                function onImageSourceChanged() {
                    imageContainer.pendingSource = root.imageSource;
                }

                target: root
            }

            SequentialAnimation {
                id: fadeOutIn

                NumberAnimation {
                    target: previewImage
                    property: "opacity"
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing.type: Easing.InOutQuad
                }

                ScriptAction {
                    script: {
                        previewImage.source = imageContainer.pendingSource;
                        imageContainer.pendingSource = "";
                    }
                }

                NumberAnimation {
                    target: previewImage
                    property: "opacity"
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing.type: Easing.InOutQuad
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: root.loadingImage ? "Loading..." : (root.decodingHtml ? "Loading..." : "")
                horizontalAlignment: Text.AlignHCenter
                color: Colours.palette.m3onSurfaceVariant
                opacity: text !== "" ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        duration: Tokens.anim.durations.small
                        easing: Tokens.anim.standard
                    }
                }
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.medium + Tokens.padding.extraSmall
        anchors.rightMargin: Tokens.padding.medium + Tokens.padding.extraSmall
        z: 10
        icon: "content_copy"
        type: IconButton.Filled
        visible: {
            if (!root.currentItem?.modelData)
                return false;
            const data = root.currentItem.modelData;
            return (data.hasImageUrl === true || data.needsDecodeForUrl === true) && root.extractedImageUrl !== "" && previewImage.status === Image.Ready;
        }
        onClicked: {
            previewImage.grabToImage(function (result) {
                const tempPath = "/tmp/quickshell-clipboard-grab-" + Date.now() + ".png";
                if (result.saveToFile(tempPath)) {
                    const cmd = `wl-copy < '${tempPath}' --type image/png && rm '${tempPath}'`;
                    copyGrabbedImageProcess.command = ["sh", "-c", cmd];
                    copyGrabbedImageProcess.running = true;
                }
            });
        }
    }
}
