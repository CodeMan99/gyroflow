import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC

QQC.CheckBox {
    id: cb;
    onCheckedChanged: if (checked) { cm1.width = 0; cm2.width = 0; cbanim.start(); }
    hoverEnabled: false; // FIXME: shows system checkbox when theme set to Basic
    implicitHeight: 30 * dpiScale;

    indicator: Rectangle {
        implicitWidth: 20 * dpiScale
        implicitHeight: 20 * dpiScale
        x: cb.leftPadding
        y: parent.height / 2 - height / 2
        radius: 5 * dpiScale;
        color: cb.checked? styleAccentColor : "transparent";
        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo; } }
        border.color: cb.checked? styleAccentColor : "#999999";

        opacity: cb.down? 0.8 : 1.0;
        Ease on opacity { }

        Item {
            id: cm;
            anchors.fill: parent;
            visible: opacity > 0;
            Ease on opacity { }
            opacity: checked? 1 : 0;
            Rectangle {
                id: cm1;
                width: 0;
                height: 2 * dpiScale;
                radius: height;
                color: styleTextColorOnAccent;
                x: 6.5 * dpiScale;
                y: 9 * dpiScale;
                transformOrigin: Item.Left;
                transform: Rotation { angle: 45; }
            }
            Rectangle {
                id: cm2;
                width: 0;
                height: 2 * dpiScale;
                color: styleTextColorOnAccent;
                radius: height;
                x: 7.5 * dpiScale;
                y: 13 * dpiScale;
                transformOrigin: Item.Left;
                transform: Rotation { angle: -45; }
            }
            ParallelAnimation {
                id: cbanim;
                loops: 1;
                PropertyAnimation { target: cm1; property: "width"; from: 0; to: 5 * dpiScale; easing.type: Easing.InOutCubic; duration: 200; }
                SequentialAnimation {
                    PauseAnimation { duration: 80; }
                    PropertyAnimation { target: cm2; property: "width"; from: 0; to: 10 * dpiScale; easing.type: Easing.InOutCubic; duration: 200; }
                }
            }
        }
    }
    topPadding: 0;
    bottomPadding: 0;
    leftPadding: 0;

    contentItem: Text {
        text: cb.text;
        font.pixelSize: 13 * dpiScale;
        font.family: styleFont;
        color: styleTextColor;
        opacity: enabled ? 1.0 : 0.3
        verticalAlignment: Text.AlignVCenter
        leftPadding: cb.indicator.width + cb.spacing
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.NoButton; }
}