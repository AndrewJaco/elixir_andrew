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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar, { hide } from "../vendor/topbar"

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
    if (savedTheme) {
      document.documentElement.classList.remove("theme-mc", "theme-hk", "theme-lg", "theme-default")
      document.documentElement.classList.add(savedTheme)

      //push theme to the server to sync with session if needed
      if (this.el.dataset.theme !== savedTheme) {
        this.pushEvent("sync-theme", { theme: savedTheme })
      }
    }
  }
}

//add event listeners for theme handling outside the hooks
//these will work even outside the LiveView components
window.addEventListener("phx:store_theme", (e) => {
  const theme = e.detail.theme
  document.documentElement.classList.remove("theme-mc", "theme-hk", "theme-lg", "theme-default");
  if (theme) document.documentElement.classList.add(theme);
  localStorage.setItem("theme", theme)
})

//initialize on page load
document.addEventListener("DOMContentLoaded", () => {
  const savedTheme = localStorage.getItem("theme")
  if (savedTheme) {
    document.documentElement.classList.remove("theme-mc", "theme-hk", "theme-lg", "theme-default")
    document.documentElement.classList.add(savedTheme)
  }
})

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})


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

