import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "tdeckers.openhab"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string page: "status"
  property string search: ""
  property string draftUrl: ""
  property string draftToken: ""
  property var catalog: []
  property var selectedStates: []
  property var selectedNames: []
  property bool hasToken: false
  property string lastError: ""
  property bool loadingCatalog: false
  property bool loadingStates: false
  property bool saving: false

  readonly property string pluginDir: Model.pluginFile(Qt.resolvedUrl("."))
  readonly property string apiPath: pluginDir + "/bin/openhab-api"
  readonly property var filteredCatalog: Model.filterItems(catalog, search)
  readonly property var picked: selectedSet()
  readonly property string barText: Model.barLabel(selectedStates, lastError)
  readonly property color fg: root.barForeground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function selectedSet() {
    return Model.selectedSet(selectedNames)
  }

  function open() {
    root.page = "status"
    root.controller.show()
    refreshAll()
  }

  function openSettings() {
    root.page = "settings"
    root.controller.show()
    refreshConfig()
    refreshCatalog()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function refreshAll() {
    refreshConfig()
    refreshStates()
  }

  function refreshConfig() {
    runApi(configProc, ["config-get"], "")
  }

  function refreshStates() {
    loadingStates = true
    runApi(statesProc, ["states"], "")
  }

  function refreshCatalog() {
    loadingCatalog = true
    lastError = ""
    runApi(catalogProc, ["items"], "")
  }

  function saveSettings() {
    saving = true
    lastError = ""
    if (urlField)
      draftUrl = urlField.text
    if (tokenField)
      draftToken = tokenField.text
    var payload = {
      url: draftUrl,
      items: selectedNames
    }
    if (String(draftToken || "").trim() !== "")
      payload.token = String(draftToken).trim()
    runApi(saveProc, ["config-set"], JSON.stringify(payload))
  }

  function togglePicked(name) {
    selectedNames = Model.toggleName(selectedNames, name)
    saveSettings()
  }

  function runApi(proc, args, stdinText) {
    proc.stdinText = stdinText || ""
    proc.stdinEnabled = proc.stdinText !== ""
    proc.exec(["python3", apiPath].concat(args))
  }

  function applyConfig(data) {
    draftUrl = data.url || ""
    selectedNames = data.items instanceof Array ? data.items.slice() : []
    hasToken = data.hasToken === true
    if (draftToken !== "" && data.hasToken)
      draftToken = ""
  }

  function applyPayload(text, kind) {
    var data = Model.parseJson(text)
    if (!data || data.ok !== true) {
      lastError = data && data.error ? data.error : "OpenHAB request failed"
      return
    }
    lastError = ""
    if (kind === "config")
      applyConfig(data)
    else if (kind === "items")
      catalog = data.items instanceof Array ? data.items : []
    else if (kind === "states")
      selectedStates = data.items instanceof Array ? data.items : []
  }

  Timer {
    interval: Math.max(5, Number(root.setting("refreshIntervalSec", 15))) * 1000
    running: true
    repeat: true
    onTriggered: root.refreshStates()
  }

  Component.onCompleted: refreshAll()

  Process {
    id: configProc
    property string stdinText: ""
    stdout: StdioCollector {
      onStreamFinished: root.applyPayload(this.text, "config")
    }
    onStarted: {
      if (stdinText !== "") {
        write(stdinText)
        stdinEnabled = false
      }
    }
  }

  Process {
    id: statesProc
    property string stdinText: ""
    stdout: StdioCollector {
      onStreamFinished: {
        root.loadingStates = false
        root.applyPayload(this.text, "states")
      }
    }
    onExited: root.loadingStates = false
  }

  Process {
    id: catalogProc
    property string stdinText: ""
    stdout: StdioCollector {
      onStreamFinished: {
        root.loadingCatalog = false
        root.applyPayload(this.text, "items")
      }
    }
    onExited: root.loadingCatalog = false
  }

  Process {
    id: saveProc
    property string stdinText: ""
    stdout: StdioCollector {
      onStreamFinished: {
        root.saving = false
        root.applyPayload(this.text, "config")
        root.refreshStates()
        if (root.page === "settings")
          root.refreshCatalog()
      }
    }
    onStarted: {
      if (stdinText !== "") {
        write(stdinText)
        stdinEnabled = false
      }
    }
    onExited: root.saving = false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) {
        root.switchPanel(direction)
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(8)

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width - gear.implicitWidth - parent.spacing
            text: root.page === "settings" ? "OpenHAB settings" : "OpenHAB"
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            textFormat: Text.PlainText
            elide: Text.ElideRight
          }

          Button {
            id: gear
            text: root.page === "settings" ? "Back" : "Setup"
            foreground: root.fg
            onClicked: {
              if (root.page === "settings") {
                root.page = "status"
                root.refreshStates()
              } else {
                root.openSettings()
              }
            }
          }
        }

        Text {
          width: parent.width
          visible: root.lastError !== ""
          text: root.lastError
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.page === "status"

          Text {
            width: parent.width
            visible: root.selectedNames.length === 0
            text: "No items selected. Open Setup to pick OpenHAB items."
            color: Qt.darker(root.fg, 1.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
          }

          Repeater {
            model: root.selectedStates
            delegate: Row {
              required property var modelData
              width: content.width
              spacing: Style.space(8)

              Text {
                width: parent.width * 0.58
                text: String(modelData.label || modelData.name || "")
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
                textFormat: Text.PlainText
              }

              Text {
                width: parent.width * 0.42
                text: Model.formatState(modelData)
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                textFormat: Text.PlainText
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)
          visible: root.page === "settings"

          PanelSectionHeader {
            text: "Connection"
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          TextField {
            id: urlField
            width: parent.width
            foreground: root.fg
            placeholderText: "http://openhab.local:8080"
            text: root.draftUrl
            onEditingFinished: root.draftUrl = text
          }

          TextField {
            id: tokenField
            width: parent.width
            foreground: root.fg
            password: true
            placeholderText: root.hasToken ? "Token saved — paste to replace" : "OpenHAB API token"
            text: root.draftToken
            onEditingFinished: root.draftToken = text
          }

          Row {
            spacing: Style.space(8)

            Button {
              text: root.saving ? "Saving…" : "Save"
              foreground: root.fg
              onClicked: {
                root.draftUrl = root.draftUrl
                root.saveSettings()
              }
            }

            Button {
              text: root.loadingCatalog ? "Loading…" : "Reload items"
              foreground: root.fg
              onClicked: {
                root.saveSettings()
              }
            }
          }

          PanelSectionHeader {
            text: "Items  (" + root.selectedNames.length + "/" + Model.MAX_ITEMS + ")"
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          TextField {
            width: parent.width
            foreground: root.fg
            placeholderText: "Search items"
            text: root.search
            onTextChanged: root.search = text
          }

          ListView {
            id: catalogList
            width: parent.width
            implicitHeight: Style.space(240)
            clip: true
            spacing: Style.space(2)
            model: root.filteredCatalog
            boundsBehavior: Flickable.StopAtBounds

            delegate: Button {
              required property var modelData
              width: catalogList.width
              text: (root.picked[modelData.name] ? "●  " : "○  ") + (modelData.label || modelData.name) + "  ·  " + modelData.name
              foreground: root.fg
              selected: root.picked[modelData.name] === true
              onClicked: root.togglePicked(modelData.name)
            }
          }

          Text {
            width: parent.width
            visible: root.filteredCatalog.length === 0 && !root.loadingCatalog
            text: root.catalog.length === 0 ? "Save a URL and token, then reload items." : "No items match that search."
            color: Qt.darker(root.fg, 1.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
          }
        }
      }
    }
  }
}
