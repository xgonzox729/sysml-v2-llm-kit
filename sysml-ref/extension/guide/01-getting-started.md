# 1. Getting started

In this chapter you install the extension, write a first model, and meet the editor features you
will use all the time: diagnostics, the outline, the model tree, hover, go to definition and
diagrams. At the end you set up the EnviroNode project.

## Installing

You need **VS Code 1.95 or later**. Nothing else: the extension bundles the SysML v2 standard
library, its own libraries, and a SPICE simulator (ngspice compiled to WebAssembly).

1. Get the extension file, `sysml-vscode-<version>.vsix`.
2. In VS Code, open the Command Palette (**⇧⌘P** on macOS, **Ctrl+Shift+P** on Windows and Linux)
   and run **Extensions: Install from VSIX…**.
3. Pick the file. VS Code installs the extension and activates it when you open a `.sysml` file.

> **Tip.** Throughout the guide, "run *X*" means: open the Command Palette and type *X*. Every
> command of this extension starts with **SysML:**, so typing `SysML` lists them all. Appendix
> [D](D-commands.md) has the full list.

## A first model

Create a folder (say `sysml-playground`), open it in VS Code (**File › Open Folder…**), and create a
file `hello.sysml` in it. Type:

<!-- check: standalone -->
```sysml
package Hello {
    part def Board {
        part mcu : Mcu;
        part sensor : Sensor;
    }
    part def Mcu;
    part def Sensor;
}
```

As you type, a few things happen:

- **Syntax highlighting** colors keywords (`package`, `part`, `def`), names and types.
- **Completion** (**Ctrl+Space**) offers keywords and the names you can refer to at the cursor:
  after `part mcu : ` it lists `Board`, `Mcu` and `Sensor`, among others.
- The **Outline** view (in the Explorer side bar) shows `Hello › Board › mcu, sensor`, `Mcu`,
  `Sensor`. So do the breadcrumbs above the editor.

### Diagnostics

Change `part def Sensor;` to `part def TempSensor;`. A red squiggle appears under `Sensor` in
`part sensor : Sensor;`. Hover over it to read *Could not resolve reference to Type named
'Sensor'*. The **Problems** panel (**⇧⌘M** / **Ctrl+Shift+M**) lists it too. Change the name back
and the error disappears.

Diagnostics come in three kinds:
- **syntax errors**: a missing `;`, or a keyword in the wrong place;
- **unresolved names**: a reference to something that doesn't exist or isn't visible;
- **model checks**: unit errors, failed requirements, overloaded supply rails, wiring problems and
  more. They are introduced chapter by chapter.

### Hover and go to definition

Hover over `Mcu` in `part mcu : Mcu;`. The tooltip shows what it is (`part def Mcu`) and, once you
add one, its documentation comment.

Press **F12** (*Go to Definition*) on `Mcu` and the cursor jumps to `part def Mcu;`. This works into
the standard library too. Add `private import ISQ::*;` inside the package, write
`attribute mass : MassValue;` in `Board`, and press F12 on `MassValue`: VS Code opens the
standard library file where `MassValue` is defined. Reading library definitions this way is the
best way to learn what they offer.

**Shift+F12** (*Go to References*) lists every place an element is used, and **F2** (*Rename*)
renames it everywhere, across files.

### The SysML Model tree

The Explorer side bar has a **SysML Model** view. It shows the models of all the `.sysml` files in
the workspace as a tree: packages, definitions, usages, their features. Click an entry to reveal it
in the text. The diagram icon next to an entry opens a diagram of that element.

### A first diagram

Press **⌥⌘D** (**Ctrl+Alt+D**), or click the **Open Diagram** icon in the editor title bar. A
diagram opens beside the text: the **General view** of the package. `Board` is a box with a *parts*
compartment listing `mcu : Mcu` and `sensor : Sensor`, and `Mcu` and `Sensor` are boxes of their
own.

The diagram follows the text. Add `part radio : Mcu;` to `Board` and watch it appear. Click a box
and the editor jumps to its declaration; put the cursor on a declaration and its box is
highlighted. Chapter 3 explains what you see, and chapter 6 shows how to edit from the diagram.

### Formatting

**Format Document** (**⇧⌥F** / **Shift+Alt+F**) re-indents the file and normalizes spacing. It never
changes the model itself, only whitespace.

## Setting up the EnviroNode project

Now create the project you will build through the guide:

1. Create a folder `sensor-node`, with a folder `model` inside it.
2. Open `sensor-node` in VS Code (**File › Open Folder…**). Open the folder, not just one file:
   the model is split into several files that refer to each other, and the extension resolves
   names across all the files in the open folder.
3. Create `model/node-parts.sysml`. You fill it in chapter 3.

Every chapter tells you which file to edit and what to add. If you get lost, the finished project
is in [example/sensor-node](example/sensor-node). Copy its `model` folder and continue from there.

## Check yourself

1. In `hello.sysml`, rename `Mcu` to `Microcontroller` with **F2**. What happens to
   `part mcu : Mcu;`?
2. Delete the `;` after `part def Sensor`. What does the Problems panel say?

<details><summary>Answers</summary>

1. It becomes `part mcu : Microcontroller;`. Rename updates every reference.
2. A syntax error at the closing brace: *Unexpected '}'. Expected ';', '{'.* A declaration ends
   either with `;` or with a body in braces.

</details>

Next: [2. Packages, names and comments](02-packages-and-names.md)
