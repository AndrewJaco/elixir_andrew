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
    // Only sync theme once per session, not on every reconnection
    if (!this.themeSynced) {
      const savedTheme = localStorage.getItem("theme")
      const serverTheme = this.el.dataset.theme

      if (savedTheme && savedTheme !== serverTheme) {
        this.pushEvent("sync-theme", { theme: savedTheme })
      } else {
        localStorage.setItem("theme", serverTheme)
      }

      this.themeSynced = true
    }
  },

  reconnected() {
    // On reconnection, just ensure localStorage has the current server theme
    // Don't push an event that could re-trigger initialization
    const serverTheme = this.el.dataset.theme
    if (serverTheme) {
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
    this.startCell = null
    this.currentCell = null
    this.previewPath = []

    // Calculate cell size, padding, and gap once on mount
    const gridElement = this.el.querySelector('.word-search-grid')
    const firstCell = gridElement?.querySelector('.word-search-cell')
    if (firstCell && gridElement) {
      const rect = firstCell.getBoundingClientRect()
      this.cellSize = rect.width

      // Get computed styles for grid
      const gridStyles = window.getComputedStyle(gridElement)
      this.padding = parseFloat(gridStyles.paddingLeft)
      this.gap = parseFloat(gridStyles.gap)

      // Get grid's position relative to the SVG
      const svg = this.el.querySelector('svg')
      const gridRect = gridElement.getBoundingClientRect()
      const svgRect = svg.getBoundingClientRect()
      this.gridOffsetX = gridRect.left - svgRect.left
      this.gridOffsetY = gridRect.top - svgRect.top
    }

    // Set color based on current number of permanent paths
    // Randomize colors
    const colors = [
      '#FFE680', // Light Yellow
      '#E0BBE4', // Light Lavender
      '#FFD1DC', // Light Rose
      '#C7CEEA', // Light Periwinkle
      '#FFE4B5', // Light Moccasin
      '#BAE1FF', // Light Blue
      '#77DD77',  // Green
      '#FFB3BA', // Light Pink
      '#FFDFBA', // Light Peach
      '#BAFFC9', // Light Mint
    ]

    for (let i = colors.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [colors[i], colors[j]] = [colors[j], colors[i]];
    }

    this.colors = colors

    // Pointer events
    this.el.addEventListener("pointerdown", this.start.bind(this))
    this.el.addEventListener("pointermove", this.move.bind(this))
    window.addEventListener("pointerup", this.end.bind(this))

    // Server events
    this.handleEvent("keep-path", () => {
      this.renderPath(this.previewPath, true)
      this.previewPath = []
      this.clearPreview()
    })

    this.handleEvent("clear-path", () => {
      this.clearPreview()
      this.previewPath = []
    })

    // Expose to console for testing
    window.wordSearchHook = this
    // Quick test after window.wordSearchHook = this
    console.log("Testing generatePath:", this.generatePath(
      { dr: 2, dc: 0 },
      { dataset: { row: "0", col: "0" } },
      { dataset: { row: "3", col: "0" } }
    ))
  },

  start(e) {
    const cell = this.getCellFromPoint(e)
    if (!cell) return

    this.startCell = cell
    this.currentCell = cell
    // clear previous selection
    this.previewPath = [this.coords(cell)]
  },

  move(e) {
    if (!this.startCell) return

    const hoverCell = this.getCellFromPoint(e)

    if (!hoverCell || hoverCell === this.currentCell) return

    // Calculate raw vector
    const startCoords = this.coords(this.startCell)
    const hoverCoords = this.coords(hoverCell)
    const dr = hoverCoords.row - startCoords.row
    const dc = hoverCoords.col - startCoords.col

    // Check if it's a valid straight line (horizontal, vertical, or diagonal)
    const isValidLine = dr === 0 || dc === 0 || Math.abs(dr) === Math.abs(dc)

    if (!isValidLine) return // Invalid direction, don't update path

    const direction = {
      dr: Math.sign(dr),
      dc: Math.sign(dc)
    }

    this.currentCell = hoverCell
    this.previewPath = this.generatePath(direction, this.startCell, this.currentCell)
    this.renderPath(this.previewPath, false)
  },

  generatePath(direction, startCell, currentCell) {
    //valid directions must have 1, -1, or 0 for dr and dc
    const isValidDirection = [Math.abs(direction.dr), Math.abs(direction.dc)].every(
      val => val === 0 || val === 1
    )

    if (isValidDirection) {
      const path = []
      const startCoords = this.coords(startCell)
      const currentCoords = this.coords(currentCell)
      const distance = Math.max(
        Math.abs(currentCoords.row - startCoords.row),
        Math.abs(currentCoords.col - startCoords.col)
      )

      for (let i = 0; i <= distance; i++) {
        const row = startCoords.row + i * direction.dr
        const col = startCoords.col + i * direction.dc
        const cell = { row, col }
        if (this.isInbounds(cell)) {
          console.log("Adding cell to path:", cell)
          path.push(cell)
        } else {
          return []
        }
      }
      return path
    } else {
      return []
    }
  },

  isInbounds(cell) {
    const gridSize = parseInt(this.el.dataset.gridSize, 10)
    return (
      cell.row >= 0 &&
      cell.row < gridSize &&
      cell.col >= 0 &&
      cell.col < gridSize
    )
  },

  end() {
    this.pushEvent("check_word", { path: this.previewPath })
    this.startCell = null
    this.currentCell = null
    this.direction = null

    setTimeout(() => {
      if (this.previewPath.length > 0) {
        this.clearPreview()
        this.previewPath = []
      }
    }, 200)
  },

  coords(cell) {
    return {
      row: parseInt(cell.dataset.row, 10),
      col: parseInt(cell.dataset.col, 10)
    }
  },

  cellCenter({ row, col }) {
    // Get the actual cell element and its position
    const gridElement = this.el.querySelector('.word-search-grid')
    const cell = gridElement.querySelector(`[data-row="${row}"][data-col="${col}"]`)

    if (!cell) return { x: 0, y: 0 }

    // Get positions relative to viewport
    const cellRect = cell.getBoundingClientRect()
    const svg = this.el.querySelector('svg')
    const svgRect = svg.getBoundingClientRect()

    return {
      x: cellRect.left - svgRect.left + cellRect.width / 2,
      y: cellRect.top - svgRect.top + cellRect.height / 2
    }
  },

  renderPath(path, keepExisting = false) {
    const points = path.map(cell => this.cellCenter(cell))
    let pathEl
    if (keepExisting) {
      pathEl = document.createElementNS('http://www.w3.org/2000/svg', 'path')
      pathEl.classList.add('permanent-path')

      const pathIndex = this.el.querySelectorAll('.permanent-path').length
      pathEl.style.stroke = this.colors[pathIndex % this.colors.length]

    } else {
      pathEl = this.el.querySelector("#preview-path")
    }

    if (!pathEl) return

    if (points.length === 0) {
      if (!keepExisting) {
        pathEl.setAttribute("d", "")
      }
      return
    }

    const d = points.map((point, i) => {
      const command = i === 0 ? "M" : "L"
      return `${command} ${point.x} ${point.y}`
    }).join(" ")

    pathEl.setAttribute("d", d)
    if (keepExisting) {
      const svg = this.el.querySelector('svg')
      svg.appendChild(pathEl)
    }
  },

  clearPreview() {
    const pathEl = this.el.querySelector("#preview-path")
    pathEl?.setAttribute("d", "")
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

// Expose for console testing
window.Hooks = Hooks

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