# 2. Packages, names and comments

Before modeling anything, you need to know how a SysML model is organized and how its elements
refer to each other. This chapter covers packages, names, imports and comments: the
"housekeeping" every other construct relies on.

## Packages

A **package** is a named container of model elements, like a folder or a C++ namespace. It owns
its members: definitions, usages, other packages. A model is usually a few top-level packages,
each in its own file, each holding one concern (parts, requirements, behaviour…).

<!-- check: standalone -->
```sysml
package PowerSupplies {
    part def Ldo;
    part def BuckConverter;

    package Magnetics {
        part def Inductor;
    }
}
```

A package is not a part of the system: it doesn't exist physically. It is only a way to organize
the model.

## Names

Every element can have a **name**. A name is an identifier (`Ldo`, `buck_converter`,
`mcu2`) or, if it needs other characters, a quoted name: `'3V3 rail'`, `'R&D notes'`.

An element can also have a **short name**, written in angle brackets before its name. Short names
are the identifiers that engineers actually use: requirement IDs, reference designators, part
numbers.

<!-- check: standalone -->
```sysml
package Names {
    part def <'TPS7A02'> 'Low-Iq LDO';
    requirement def <'PWR-1'> NodeLifetime;
}
```

You can refer to either name. Tools show the short name as an ID: the verification matrix of
chapter 9 lists `PWR-1 NodeLifetime`.

### Qualified names

Inside a package you refer to its members by their names. From outside, you use a **qualified
name**, the names of the containers joined with `::`. The inductor above is
`PowerSupplies::Magnetics::Inductor`.

<!-- check: standalone -->
```sysml
package Board {
    part def PowerStage {
        part inductor : PowerSupplies::Magnetics::Inductor;
    }
}

package PowerSupplies {
    package Magnetics {
        part def Inductor;
    }
}
```

The order of declarations does not matter: `Board` can use `PowerSupplies` even though it comes
later, and even if it is in another file of the workspace.

## Imports

Writing qualified names everywhere is tedious. An **import** makes the members of another
namespace visible by their simple names:

| Import | Makes visible |
|---|---|
| `import PowerSupplies::Ldo;` | one element: `Ldo` |
| `import PowerSupplies::*;` | all the members of `PowerSupplies` (but not the members of `Magnetics`) |
| `import PowerSupplies::**;` | all the members, recursively: `Ldo`, `Magnetics`, `Inductor`… |

Imports are usually **private**: `private import ISQ::*;` makes the ISQ names visible inside this
package without re-exporting them to whoever imports this package. A **public** import (the default
when you write no visibility) re-exports them. Prefer private imports; they keep packages
independent.

You will see the same block of imports at the top of nearly every package in this guide:

<!-- check: standalone -->
```sysml
package Imports {
    private import ScalarValues::*;      // Real, Integer, Boolean, String
    private import ISQ::*;               // quantity types: ElectricPotentialValue, DurationValue...
    private import SI::*;                // units: V, A, s, Ω (written 'Ω'), m, kg...
    private import EngineeringUnits::*;  // more units: mA, µA, mAh, kΩ, ms, KiB... (this extension)

    attribute supply : ElectricPotentialValue = 3.3 [V];
    attribute sleep : ElectricCurrentValue = 1.5 ['µA'];
}
```

`ScalarValues`, `ISQ` and `SI` are packages of the SysML v2 standard library, which every model can
use. `EngineeringUnits` is one of this extension's libraries. Press **F12** on a library name to open
its source: the libraries are SysML text too.

An **alias** gives an element a second name:

<!-- check: standalone -->
```sysml
package Aliases {
    alias Volt for SI::V;
    attribute rail : ISQ::ElectricPotentialValue = 3.3 [Volt];
}
```

## Comments and documentation

There are three ways to write text in a model, and the difference matters:

<!-- check: standalone -->
```sysml
package Comments {
    // A note: ignored by the model, like a C comment. For the person editing the file.

    part def Ldo {
        doc /* A low-dropout linear regulator. */
    }

    /* A comment: part of the model. It annotates the package it is in. */

    comment about Ldo /* Pick a part with less than 1 µA of quiescent current. */
}
```

- **`// note`** is for the reader of the file. Tools ignore it.
- **`doc /* … */`** is the element's **documentation**. It is shown on hover, in the model tree
  and in generated documents: the requirements specification is built from the `doc` of each
  requirement. Write one for every definition that matters.
- **`/* … */`** and **`comment about X /* … */`** are comments that belong to the model: they
  annotate an element and travel with it.

## In the tool

1. Hover over `Ldo` anywhere it is used: the tooltip shows its `doc` text.
2. Put the cursor on `PowerSupplies::Magnetics::Inductor` and press **F12**: you land on the
   inductor. F12 on `PowerSupplies` lands on the package.
3. Write `private import ISQ::*;` and type `attribute x : Elec` then **Ctrl+Space**: completion
   lists the ISQ types that start with `Elec`.
4. Remove the import, and `ElectricPotentialValue` becomes an unresolved name. Diagnostics tell
   you when an import is missing.

## The EnviroNode

Open `model/node-parts.sysml` and start the first package of the project. It holds the kinds of
parts the node is built from. Give it a `doc` and the imports it needs:

<!-- check: project -->
```sysml
package NodeParts {
    doc
    /*
     * The kinds of parts the EnviroNode is built from: each definition is like a datasheet. It
     * specializes a part of the extension's Electronics library and fills in the values of one
     * real (or realistic) component.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    ...
}
```

The `...` stands for what you add in the next chapters. `Electronics` is the extension's library of
electronic parts: batteries, regulators, microcontrollers, resistors. You meet it in chapter 4.

## Check yourself

1. A package `Firmware` contains a package `Drivers` that contains `part def SpiDriver`. Write a
   part usage, in another package, that uses it (a) with a qualified name and (b) with an import.
2. Which of these appear on hover: `// note`, `doc /* … */`, `/* … */`?

<details><summary>Answers</summary>

1. With a qualified name:

   <!-- check: standalone -->
   ```sysml
   package Board1 {
       part driver : Firmware::Drivers::SpiDriver;
   }
   package Firmware {
       package Drivers { part def SpiDriver; }
   }
   ```

   With an import:

   <!-- check: standalone -->
   ```sysml
   package Board2 {
       private import Firmware2::Drivers::*;
       part driver : SpiDriver;
   }
   package Firmware2 {
       package Drivers { part def SpiDriver; }
   }
   ```

2. Only `doc /* … */`. A note is not part of the model, and a plain comment annotates its
   container rather than documenting a definition.

</details>

Next: [3. Parts: definitions and usages](03-parts.md)
