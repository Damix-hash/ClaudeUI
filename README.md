# 🏗️ ClaudeUI // Industrial Minimalist SDK
> **Lead Architects:** Claude (Anthropic) × Gemini Collaboration  
> **Idea Inspiration:** [vib-OS](https://github.com/viralcode/vib-OS)

ClaudeUI is a high-performance, state-driven UI framework for Roblox. While the aesthetic is industrial, the **core idea and philosophy** were inspired by the minimalist, functional approach of **vib-OS**. 

This library isn't just a menu; it's a modular ecosystem featuring a **Plugin-First** architecture, a built-in **State Manager**, and a persistent **Notification Engine**.

---

## 🚀 Installation
To use ClaudeUI in your script, use the following loadstring:

```lua
local ClaudeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Damix-hash/ClaudeUI/main/src/Main.lua"))()
```

---

## 🎨 Industrial Design Specs
ClaudeUI follows a strict professional palette to ensure high visibility and a "Technical Tool" feel:
* **Background:** #1C1C1C (Charcoal)
* **Sidebar/Rail:** #262624 (Steel)
* **Action Color:** #E85D00 (Safety Orange)
* **Typography:** Gotham SSm Medium (UI) & Roboto Mono (Data)

---

## 🧩 Plugin Architecture
Inspired by the modularity of vib-OS, ClaudeUI allows you to keep your main script "clean" by registering features as plugins. This allows for dynamic loading and better organization.

```lua
ClaudeUI.Plugins.register({
    name = "CombatModule",
    version = "1.0.4",
    onLoad = function(lib)
        local tab = lib:AddTab("Combat", "crosshair")
        lib:AddSection(tab.frame, "Main Settings", {
            { 
                type = "toggle", 
                label = "Silent Aim", 
                featureId = "silent_aim",
                onChange = function(v) print("Silent Aim:", v) end 
            }
        })
    end,
})
```

---

## 🛠️ API Overview

### Library.new(config)
Initializes the environment. 
- title: (String) Header text.
- blur: (Boolean) Applies a Gaussian blur to the game background.
- debug: (Boolean) Enables internal logs and state tracing.

### Library:AddTab(name, icon)
Creates a sidebar entry. Returns a table containing the .frame Instance. 
*Note: You must pass tab.frame as the parent for sections.*

### Library:AddSection(parent, title, items)
The core builder. Takes a table of items (toggles, sliders, keybinds) and renders them into the specified parent frame.

### Library.Pill.setTicker(list, speed)
Sets the text for the small "Pill" widget that remains visible when the menu is closed. Ideal for status monitoring.

---

## ⌨️ Shortcuts & Controls
* **Left Control + Z / Y:** Undo or Redo any setting change (State History).
* **Right Click:** (Debug Mode) View the featureId of any UI element.
* **Minimized Pill:** Click to quickly toggle the main menu visibility.

---

## 📜 Credits & Acknowledgments
* **Concept & Idea Inspiration:** [vib-OS](https://github.com/viralcode/vib-OS)
* **Logic & Architectural Design:** Claude (Anthropic)
* **Refinement & Implementation:** Gemini (Google)
* **Maintainer:** [Damix-hash](https://github.com/Damix-hash)

---
*Developed as a collaborative AI experiment in modern Roblox UI design. Licensed under MIT.*
