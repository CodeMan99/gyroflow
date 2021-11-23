import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC

Rectangle {
    id: rp;

    enum Direction { HandleUp, HandleDown, HandleRight, HandleLeft }

    property int direction: ResizablePanel.HandleRight;

    color: styleBackground2;

    property real lastWidth: implicitWidth;
    property real lastHeight: implicitHeight;
    property real minWidth: 100 * dpiScale;
    property real minHeight: 100 * dpiScale;
    width: (rp.direction === 2 || rp.direction === 3? Math.max(minWidth, (rpd.active? (rpd.activeTranslation.x * (rp.direction === 3? -1 : 1)) : 0) + lastWidth + additionalWidth) : lastWidth);
    height: (rp.direction === 0 || rp.direction === 1? Math.max(minHeight, (rpd.active? (rpd.activeTranslation.y * (rp.direction === 0? -1 : 1)) : 0) + lastHeight + additionalHeight) : lastHeight);
    property real additionalWidth: 0;
    property real additionalHeight: 0;

    property alias hr: rphr;

    Item {
        id: rphr;
        width:  rp.direction === 2 || rp.direction === 3? 15 * dpiScale : parent.width;
        height: rp.direction === 0 || rp.direction === 1? 15 * dpiScale : parent.height;
        anchors.top: rp.direction == 0? parent.top : undefined;
        anchors.bottom: rp.direction == 1? parent.bottom : undefined;
        anchors.right: rp.direction == 2? parent.right : undefined;
        anchors.left: rp.direction == 3? parent.left : undefined;
        anchors.topMargin: -height / 2;
        anchors.bottomMargin: -height / 2;
        anchors.rightMargin: -width / 2;
        anchors.leftMargin: -width / 2;

        Hr {
            width:  rp.direction === 2 || rp.direction === 3? 1 * dpiScale : parent.width;
            height: rp.direction === 0 || rp.direction === 1? 1 * dpiScale : parent.height;
            anchors.centerIn: parent;
        }

        DragHandler {
            id: rpd;
            target: null;
            onActiveChanged: {
                if (!active) {
                    if (rp.direction === 2 || rp.direction === 3) rp.lastWidth = rp.width - additionalWidth;
                    else rp.lastHeight = height - additionalHeight;
                }
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: rp.direction === 2 || rp.direction === 3? Qt.SplitHCursor : Qt.SplitVCursor; acceptedButtons: Qt.NoButton; }
    }
}