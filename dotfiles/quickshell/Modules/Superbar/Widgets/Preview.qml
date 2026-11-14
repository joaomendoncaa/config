import QtQuick
import QtMultimedia

Item {
    id: preview

    property var displayModel: null
    property int selectedIndex: 0
    property bool active: false
    property string videoSource: ""
    property bool videoPlaying: false

    clip: true
    visible: active && hasMedia()
    width: visible ? parent.height : 0
    height: parent.height

    onSelectedIndexChanged: scheduleVideo()
    onActiveChanged: scheduleVideo()
    onVisibleChanged: scheduleVideo()
    onDisplayModelChanged: scheduleVideo()
    onVideoSourceChanged: videoPlaying = false
    Component.onCompleted: scheduleVideo()

    function scheduleVideo() {
        videoTimer.stop()
        if (!visible || !isVideo()) {
            videoSource = ""
            return
        }
        videoTimer.restart()
    }

    function currentItem() {
        if (!displayModel || displayModel.count === 0)
            return null

        if (selectedIndex < 0 || selectedIndex >= displayModel.count)
            return null

        var item = displayModel.get(selectedIndex)
        return item || null
    }

    function hasMedia() {
        var item = currentItem()
        return !!item && ((item.imagePath && item.imagePath.length > 0) || (item.previewPath && item.previewPath.length > 0))
    }

    function isVideo() {
        var item = currentItem()
        return !!item && item.mediaType === 'video'
    }

    function isMeme() {
        var item = currentItem()
        return !!item && item.type === 'meme'
    }

    function mediaPath() {
        var item = currentItem()
        if (!item)
            return ''

        return item.previewPath && item.previewPath.length > 0 ? item.previewPath : item.imagePath
    }

    function thumbPath() {
        var item = currentItem()
        return item && item.imagePath ? item.imagePath : ''
    }

    Image {
        anchors.fill: parent
        anchors.margins: 8
        visible: !preview.isVideo()
        source: preview.visible && !preview.isVideo() && preview.mediaPath().length > 0 ? 'file://' + preview.mediaPath() : ''
        fillMode: preview.isMeme() ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    // Poster frame shown until the video starts (and if playback fails).
    Image {
        anchors.fill: parent
        anchors.margins: 8
        visible: preview.isVideo() && !preview.videoPlaying
        source: preview.visible && preview.isVideo() && preview.thumbPath().length > 0 ? 'file://' + preview.thumbPath() : ''
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }

    Video {
        anchors.fill: parent
        anchors.margins: 8
        visible: preview.isVideo()
        opacity: preview.videoPlaying ? 1 : 0
        source: preview.videoSource
        fillMode: VideoOutput.PreserveAspectFit
        autoPlay: true
        muted: true
        loops: MediaPlayer.Infinite
        onSourceChanged: if (source.toString().length > 0) play()
        onPlaying: preview.videoPlaying = true
        onErrorOccurred: preview.videoPlaying = false
    }

    Timer {
        id: videoTimer

        interval: 120
        onTriggered: {
            preview.videoSource = preview.visible && preview.isVideo() ? 'file://' + preview.mediaPath() : ''
        }
    }
}
