import QtQuick

Item {
    id: keyIntercept

    property var root: null
    property var displayModel: null

    focus: true
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
        if (!root || !displayModel) return
        if (event.key === Qt.Key_Escape) {
            root.dismiss()
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            if (root.cursorPosition > 0) {
                root.filterText = root.filterText.substring(0, root.cursorPosition - 1) + root.filterText.substring(root.cursorPosition)
                root.cursorPosition--
                if (root.modeIndex !== 2) root.selectedIndex = 0
            } else if (root.modeIndex !== 0) {
                root.setMode(0)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            root.cursorPosition = Math.max(0, root.cursorPosition - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.cursorPosition = Math.min(root.filterText.length, root.cursorPosition + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (displayModel.count > 0) {
                root.selectedIndex = (root.selectedIndex - 1 + displayModel.count) % displayModel.count
                root.positionToSelected()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            if (displayModel.count > 0) {
                root.selectedIndex = (root.selectedIndex + 1) % displayModel.count
                root.positionToSelected()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
            if (displayModel.count > 0) {
                root.selectedIndex = Math.max(0, root.selectedIndex - 8)
                root.positionToSelected()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            if (displayModel.count > 0) {
                root.selectedIndex = Math.min(displayModel.count - 1, root.selectedIndex + 8)
                root.positionToSelected()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Y && (event.modifiers & Qt.ControlModifier)) {
            root.activateSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
            if (root.modeIndex === 2) root.copySelectedPath()
            event.accepted = true
        } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
            if (displayModel.count > 0) {
                root.selectedIndex = (root.selectedIndex - 1 + displayModel.count) % displayModel.count
                root.positionToSelected()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
            if (displayModel.count > 0) {
                root.selectedIndex = (root.selectedIndex + 1) % displayModel.count
                root.positionToSelected()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            root.cursorPosition = 0
            event.accepted = true
        } else if (event.key === Qt.Key_E && (event.modifiers & Qt.ControlModifier)) {
            root.cursorPosition = root.filterText.length
            event.accepted = true
        } else if (event.key === Qt.Key_B && (event.modifiers & Qt.ControlModifier)) {
            if (root.cursorPosition > 0) {
                var pos = root.cursorPosition - 1
                while (pos > 0 && root.filterText[pos] === ' ') pos--
                while (pos > 0 && root.filterText[pos - 1] !== ' ') pos--
                root.cursorPosition = pos
            }
            event.accepted = true
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            if (root.cursorPosition < root.filterText.length) {
                var pos = root.cursorPosition
                while (pos < root.filterText.length && root.filterText[pos] !== ' ') pos++
                while (pos < root.filterText.length && root.filterText[pos] === ' ') pos++
                root.cursorPosition = pos
            }
            event.accepted = true
        } else if (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
            if (root.cursorPosition === 0 && root.modeIndex !== 0) {
                root.setMode(0)
            } else if (root.cursorPosition > 0) {
                var pos = root.cursorPosition
                while (pos > 0 && root.filterText[pos - 1] === ' ') pos--
                while (pos > 0 && root.filterText[pos - 1] !== ' ') pos--
                if (pos < root.cursorPosition) {
                    root.filterText = root.filterText.substring(0, pos) + root.filterText.substring(root.cursorPosition)
                    root.cursorPosition = pos
                    if (root.modeIndex !== 2) root.selectedIndex = 0
                }
            }
            event.accepted = true
        } else if (event.text && event.text.length === 1) {
            var char = event.text
            if (root.filterText.length === 0 && root.modeIndex === 0) {
                if (char === ':') { root.setMode(1); event.accepted = true; return }
                if (char === '.') { root.setMode(2); event.accepted = true; return }
                if (char === '$') { root.setMode(3); event.accepted = true; return }
                if (char === '=') { root.setMode(4); event.accepted = true; return }
                if (char === '#') { root.setMode(5); event.accepted = true; return }
            }
            if (char.charCodeAt(0) >= 32 && char.charCodeAt(0) !== 127) {
                root.selectedIndex = 0
                root.filterText = root.filterText.substring(0, root.cursorPosition) + char + root.filterText.substring(root.cursorPosition)
                root.cursorPosition++
                event.accepted = true
            }
        }
    }
}
