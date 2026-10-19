# Assembly-Programs
# COAL Assembly Assignments

A collection of 16-bit x86 Assembly Language programs written for the COAL (Computer Organization & Assembly Language) course, assembled with NASM and run on DOSBox.

## Description

This repository contains solutions to various COAL course assignments, covering topics such as:

- Video memory manipulation and text-mode display output
- Subroutines, stack frames, and calling conventions
- String primitives (`MOVSB`, `CMPSB`, `SCASB`, `STOSB`)
- Bounded viewport rendering, windowed scrolling, and keyword highlighting
- Numeric output and status bar formatting

Each assignment lives in its own folder (e.g. `Assignment3/`) with its `.asm` source file.

## Featured Program — Text Viewer Window

A text-mode viewer written for an 8088-compatible 16-bit real-mode environment. It draws a bordered window, streams a paragraph into it with line wrapping, scrolls the contents, highlights every whole-word keyword match, and reports the match count in a status bar.

### What it does

1. **Clears the screen** by filling the 80×25 text buffer with blank cells (`0x0720`).
2. **Draws a double-line frame** (`╔ ╗ ╚ ╝ ═ ║`) around a window spanning rows 3–21 and columns 8–72.
3. **Streams the paragraph** into the window, wrapping every 61 characters.
4. **Scrolls the window contents** upward by `scrollLines` rows, clearing the vacated last row.
5. **Searches for the keyword** (`"he"`) and highlights each **whole-word** match only, so `he` inside `the` or `hear` is ignored. Matches are painted with a blinking yellow-on-red attribute (`0xCE`).
6. **Draws a centered title banner** on the top border (yellow on blue, `0x1E`).
7. **Prints a status bar** on row 23: `Total Matches Found: N | Viewport Status: ACTIVE`.
8. **Waits for a keypress** (`int 16h`) so the output stays visible, then exits to DOS (`int 21h`, `AX = 4C00h`).

### Subroutines

| Routine | Purpose | Stack args cleaned with |
|---------|---------|-------------------------|
| `clear_screen` | Fills video memory with blank cells using `rep stosw` | `ret` |
| `corners` | Converts window row/column bounds into video-memory offsets for the four corners | `ret 8` |
| `draw_frame` | Draws the corners, side walls, and top/bottom edges | `ret 8` |
| `draw_title` | Centers and writes the banner text on the top border | `ret 4` |
| `stream_text` | Writes the body text into the window with fixed-width wrapping | `ret 4` |
| `scroll_window_up` | Shifts window rows up with `rep movsw` and blanks the last row | `ret 10` |
| `find_and_highlight` | Whole-word search using `repe cmpsb`, then recolors matches by writing attribute bytes | `ret 6` |
| `printNum` | Prints the status label, the match count (decimal conversion via `div`), and the trailing text | `ret 10` |

### Customizing it

All tunable values are `equ` constants or data items at the top of the file:

| Item | Meaning |
|------|---------|
| `WIN_TOP`, `WIN_BOTTOM`, `WIN_LEFT`, `WIN_RIGHT` | Window boundaries |
| `TEXT_ROW`, `TEXT_COL` | Where the text starts inside the window |
| `LINE_W` | Characters per wrapped line |
| `bannerText`, `bodyText` | Title and paragraph to display |
| `needle` | Keyword to search for (change this to highlight a different word) |
| `scrollLines` | Number of rows to scroll the window contents |

The highlight attribute is the `0xCE` pushed in `main`. Attribute layout is `B BBB FFFF` (blink, background, foreground), so `0xCE` = blink + red background + yellow foreground.

## Tools Used

- **NASM** — assembler
- **DOSBox** — 16-bit x86 emulator for running the code
- **Notepad++** — editor with the COAL package plugin for assembling, rendering, and debugging

## Setup — Assembly Programming Package

The easiest way to assemble, run, and debug these programs is using the preconfigured **Assembly Programming Package**, which bundles NASM, DOSBox, and a Notepad++ setup with hotkeys.

**Package:** https://github.com/ASD0x41/Assembly-Programming-Package

### 1. Download

- Go to the link above.
- Download the latest release as a **ZIP** (or clone the repo).
- Extract it anywhere on your machine (e.g. `C:\AssemblyProgrammingPackage`).

### 2. Open Notepad++

- Launch `code` (notepad++) from the extracted folder.
- The package ships with the required plugins already configured.

### 3. Load a program

- Open any `.asm` file from this repository in Notepad++.

### 4. Assemble and run

Inside Notepad++, use the built-in hotkeys:

| Hotkey | Action |
|--------|--------|
| **Alt + R** | Assemble and **run** the program (renders output in DOSBox) |
| **Alt + D** | Assemble and launch the **debugger** (step through execution) |

The plugin assembles the `.asm` with NASM, launches DOSBox automatically, and executes the resulting binary — no manual `nasm` or `mount` commands needed.

![image alt](https://github.com/fayzan-khalid10/Coal-Assignment-3/blob/f9e53b4da7f4800f801fd9cb15ee8f9ddf4a3651/Screenshot%202026-10-19%20230029.png)


### 5. Editing and re-running

- Edit the `.asm` file.
- Save.
- Hit **Alt + R** again to reassemble and rerun.

### Manual build (optional)

If you prefer the command line:

```
nasm -f bin textviewer.asm -o textviewer.com
```

Then mount the folder in DOSBox and run `textviewer.com`.

## Folder Structure

```
.
├── README.md
├── Assignment1/
│   └── assignment1.asm
├── Assignment2/
│   └── assignment2.asm
├── Assignment3/
│   └── org 100h.asm
└── ...
```

## Notes

- All programs are written for **16-bit real mode** (`org 0x100`), producing `.com` files.
- Display memory is accessed at segment `0xB800` in text mode.
- Stack cleanup is done with `ret n`; all subroutines use `bp`-relative addressing and preserve caller registers.
- To make NASM reject any instruction the 8088 cannot execute, add `cpu 8086` at the top of the source file.
