// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
import "../css/app.css"
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar, { hide } from "../vendor/topbar"
import Sortable from "sortablejs"

console.log("app.js is loading...")

let Hooks = {}

Hooks.AutoClearFlash = {
  mounted() {
    let ignoredIDs = ["client-error", "server-error"]
    if (ignoredIDs.includes(this.el.id)) return;

    let hideElementAfter = 2000;
    let clearFlashAfter = hideElementAfter + 500;

    //first hide the element
    setTimeout(() => {
      this.el.style.opacity = 0;
    }, hideElementAfter)

    //the clear the flash
    setTimeout(() => {
      this.pushEvent("lv:clear-flash")
    }, clearFlashAfter)
  }
}

Hooks.ThemeHandler = {
  mounted() {
    const savedTheme = localStorage.getItem("theme")
    const serverTheme = this.el.dataset.theme

    if (savedTheme && savedTheme !== serverTheme) {
      this.pushEvent("sync-theme", { theme: savedTheme })
    } else {
      localStorage.setItem("theme", serverTheme)
    }
  }
}

Hooks.DatePicker = {
  mounted() {
    const inputId = this.el.querySelector("input[type=date]").id
    const input = document.getElementById(inputId)
    const overlay = this.el.querySelector("[id^=date-overlay]")

    overlay.addEventListener("click", () => {
      input.showPicker ? input.showPicker() : input.click()
    })
  }
}

Hooks.Sortable = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 150,
      handle: ".letter-block",
      dragClass: "grabbed",

      //Touch based options
      delay: 200,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,

      forceFallback: true, //for mobile safari support

      ghostClass: "opacity-50",
      onEnd: (evt) => {
        const orderedIds = Array.from(
          this.el.children
        ).map(el => el.dataset.id)

        this.pushEvent("reorder", { ids: orderedIds })
      }
    })
  },

  destroyed() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
}

Hooks.WordSearch = {
  mounted() {
    this.selected = []
    this.direction = null
    this.active = false

    this.el.addEventListener("pointerdown", this.start.bind(this))
    this.el.addEventListener("pointermove", this.move.bind(this))
    window.addEventListener("pointerup", this.end.bind(this))
  },

  start(e) {
    const cell = this.getCellFromPoint(e)
    if (!cell) return

    this.reset()
    this.active = true
    this.select(cell)
  },

  move(e) {
    if (!this.active) return

    const cell = this.getCellFromPoint(e)
    if (!cell || this.isSelected(cell)) return

    if (this.canSelect(cell)) {
      this.select(cell)
    }
  },

  end(e) {
    if (!this.active) return
    this.active = false

    const path = this.selected.map(cell => ({
      row: parseInt(cell.dataset.row, 10),
      col: parseInt(cell.dataset.col, 10)
    }))

    this.pushEvent("check_word", { path })
  },

  reset() {
    this.selected.forEach(c => c.classList.remove("selected"))
    this.selected = []
    this.direction = null
  },

  select(cell) {
    cell.classList.add("selected")
    this.selected.push(cell)

    if (this.selected.length === 2) {
      const first = this.coords(this.selected[0])
      const second = this.coords(this.selected[1])
      this.direction = {
        dr: second.row - first.row,
        dc: second.col - first.col
      }
    }

    if (navigator.vibrate) navigator.vibrate(10)
  },

  coords(cell) {
    return {
      row: parseInt(cell.dataset.row, 10),
      col: parseInt(cell.dataset.col, 10)
    }
  },

  isSelected(cell) {
    return this.selected.includes(cell)
  },

  canSelect(cell) {
    const next = this.coords(cell)
    const prev = this.coords(this.selected.at(-1))

    if (!this.isAdjacent(prev, next)) return false

    if (this.selected.length < 2) return true

    return (
      next.row === prev.row + this.direction.dr &&
      next.col === prev.col + this.direction.dc
    )
  },

  isAdjacent(a, b) {
    const dr = Math.abs(a.row - b.row)
    const dc = Math.abs(a.col - b.col)
    return (dr <= 1 && dc <= 1) && !(dr === 0 && dc === 0)
  },

  getCellFromPoint(e) {
    const x = e.clientX
    const y = e.clientY
    return document.elementFromPoint(x, y)?.closest(".word-search-cell")
  },
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

console.log("livesocket created with hooks:", liveSocket)

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}