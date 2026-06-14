import QtQuick

Item {
    id: preview

    property var displayModel: null
    property int selectedIndex: 0
    property bool active: false

    clip: false

    visible: active && hasImage()
    width: visible ? parent.height : 0
    height: parent.height

    function hasImage() {
        if (!displayModel || displayModel.count === 0) return false
        var item = displayModel.get(selectedIndex)
        return item && item.imagePath && item.imagePath.length > 0
    }

    function imagePath() {
        if (!displayModel || displayModel.count === 0) return ''
        var item = displayModel.get(selectedIndex)
        return item ? item.imagePath : ''
    }

    Image {
        anchors.fill: parent
        anchors.margins: 8
        source: parent.visible ? 'file://' + parent.imagePath() : ''
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }
}
