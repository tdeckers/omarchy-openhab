.pragma library

var MAX_ITEMS = 10

function pluginFile(url) {
    var path = String(url || "")
    if (path.indexOf("file://") === 0)
        path = path.slice(7)
    if (path.length > 1 && path.charAt(path.length - 1) === "/")
        path = path.slice(0, -1)
    return path
}

function parseJson(text) {
    try {
        return JSON.parse(String(text || ""))
    } catch (e) {
        return null
    }
}

function formatState(item) {
    if (!item)
        return ""
    var state = String(item.state || "")
    if (state === "NULL" || state === "UNDEF")
        return "—"
    return state
}

function formatLine(item) {
    if (!item)
        return ""
    var label = String(item.label || item.name || "")
    var state = formatState(item)
    if (!label)
        return state
    if (!state)
        return label
    return label + "  " + state
}

function barLabel(items, error) {
    if (error)
        return "OH !"
    if (!items || items.length === 0)
        return "OH"
    return formatLine(items[0])
}

function matchesQuery(item, query) {
    var q = String(query || "").trim().toLowerCase()
    if (!q)
        return true
    var name = String(item.name || "").toLowerCase()
    var label = String(item.label || "").toLowerCase()
    var type = String(item.type || "").toLowerCase()
    return name.indexOf(q) !== -1 || label.indexOf(q) !== -1 || type.indexOf(q) !== -1
}

function filterItems(items, query) {
    var src = items instanceof Array ? items : []
    var out = []
    for (var i = 0; i < src.length; i++) {
        if (matchesQuery(src[i], query))
            out.push(src[i])
    }
    return out
}

function selectedSet(names) {
    var set = {}
    var src = names instanceof Array ? names : []
    for (var i = 0; i < src.length; i++)
        set[String(src[i])] = true
    return set
}

function toggleName(names, name) {
    var next = []
    var found = false
    var src = names instanceof Array ? names : []
    for (var i = 0; i < src.length; i++) {
        if (src[i] === name)
            found = true
        else
            next.push(src[i])
    }
    if (!found) {
        if (next.length >= MAX_ITEMS)
            return src
        next.push(name)
    }
    return next
}
