import QtQuick

Item {
    id: keyIntercept

    property var root: null
    property var displayModel: null

    function itemPrevious() {
        if (displayModel.count > 0) {
            root.selectedIndex = (root.selectedIndex - 1 + displayModel.count) % displayModel.count;
            root.positionToSelected();
        }
    }

    function itemNext() {
        if (displayModel.count > 0) {
            root.selectedIndex = (root.selectedIndex + 1) % displayModel.count;
            root.positionToSelected();
        }
    }

    function cursorUnshift() {
        root.cursorPosition = Math.max(0, root.cursorPosition - 1);
    }

    function cursorShift() {
        root.cursorPosition = Math.min(root.filterText.length, root.cursorPosition + 1);
    }

    function cursorHead() {
        root.cursorPosition = 0;
    }

    function cursorTail() {
        root.cursorPosition = root.filterText.length;
    }

    function cursorUnshiftWord() {
        if (root.cursorPosition > 0) {
            var pos = root.cursorPosition - 1;
            while (pos > 0 && root.filterText[pos] === ' ')pos--
            while (pos > 0 && root.filterText[pos - 1] !== ' ')pos--
            root.cursorPosition = pos;
        }
    }

    function cursorShiftWord() {
        if (root.cursorPosition < root.filterText.length) {
            var pos = root.cursorPosition;
            while (pos < root.filterText.length && root.filterText[pos] !== ' ')pos++
            while (pos < root.filterText.length && root.filterText[pos] === ' ')pos++
            root.cursorPosition = pos;
        }
    }

    function deleteCharBeforeCursor() {
        root.filterText = root.filterText.substring(0, root.cursorPosition - 1) + root.filterText.substring(root.cursorPosition);
        root.cursorPosition--;
        if (root.mode !== "files")
            root.selectedIndex = 0;

    }

    function insertTextChar(c) {
        root.selectedIndex = 0;
        root.filterText = root.filterText.substring(0, root.cursorPosition) + c + root.filterText.substring(root.cursorPosition);
        root.cursorPosition++;
    }

    function trySetModeFromPrefix(c) {
        switch (c) {
        case ':':
            root.setSearchMode("emojis");
            return true;
        case '.':
            root.setSearchMode("files");
            return true;
        case '$':
            root.setSearchMode("clipboard");
            return true;
        case '=':
            root.setSearchMode("calc");
            return true;
        case '#':
            root.setSearchMode("chart");
            return true;
        }
        return false;
    }

    function copySelectedContent() {
        root.copySelectedContent();
    }

    function handleBackspace() {
        if (root.cursorPosition > 0)
            deleteCharBeforeCursor();
        else if (root.mode !== "apps")
            root.setSearchMode("apps");
    }

    function handleCtrlW() {
        if (root.cursorPosition === 0 && root.mode !== "apps") {
            root.setSearchMode("apps");
        } else {
            var pos = root.cursorPosition;
            while (pos > 0 && root.filterText[pos - 1] === ' ')pos--
            while (pos > 0 && root.filterText[pos - 1] !== ' ')pos--
            if (pos < root.cursorPosition) {
                root.filterText = root.filterText.substring(0, pos) + root.filterText.substring(root.cursorPosition);
                root.cursorPosition = pos;
                if (root.mode !== "files")
                    root.selectedIndex = 0;

            }
        }
    }

    focus: true
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
        if (!root || !displayModel)
            return ;

        if (event.modifiers & Qt.ControlModifier) {
            if (event.key == Qt.Key_Y)
                return root.activateSelected();

            if (event.key == Qt.Key_C)
                return copySelectedContent();

            if (event.key == Qt.Key_P)
                return itemPrevious();

            if (event.key == Qt.Key_N)
                return itemNext();

            if (event.key == Qt.Key_A)
                return cursorHead();

            if (event.key == Qt.Key_E)
                return cursorTail();

            if (event.key == Qt.Key_B)
                return cursorUnshiftWord();

            if (event.key == Qt.Key_F)
                return cursorShiftWord();

            if (event.key == Qt.Key_W)
                return handleCtrlW();

            event.accepted = false;
            return ;
        }
        if (event.key == Qt.Key_Escape)
            return root.dismiss();

        if (event.key == Qt.Key_Backspace)
            return handleBackspace();

        if (event.key == Qt.Key_Left)
            return cursorUnshift();

        if (event.key == Qt.Key_Right)
            return cursorShift();

        if (event.key == Qt.Key_Up)
            return itemPrevious();

        if (event.key == Qt.Key_Down)
            return itemNext();

        if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return)
            return root.activateSelected();

        if (event.text && event.text.length === 1) {
            var c = event.text;
            if (c.charCodeAt(0) >= 32 && c.charCodeAt(0) !== 127) {
                if (trySetModeFromPrefix(c))
                    return ;

                insertTextChar(c);
            }
        } else {
            event.accepted = false;
            return ;
        }
    }
}
