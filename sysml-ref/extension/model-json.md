# Model JSON (`sysml-model`, version 1)

*SysML: Export Model as JSON*, `sysml-sim export` and the `sysml/exportModel` request write the
resolved model as one JSON document: every named element of the given files (and the anonymous
ones that matter: connections, satisfy relationships, transitions, successions, actions), with
qualified names, types, relationships and **evaluated values**. Library elements are referred
to by qualified name but not exported.

Scripts and other tools can read it without parsing SysML: generate code or reports, feed a
dashboard, or compare two versions (the semantic diff, `sysml-sim diff`, is built on it).

```json
{
  "format": "sysml-model",
  "version": 1,
  "files": ["file:///…/sensor-power.sysml"],
  "elements": [
    {
      "id": "SensorPower::node::battery::capacity",
      "name": "capacity",
      "kind": "ReferenceUsage",
      "owner": "SensorPower::node::battery",
      "redefines": ["Electronics::Battery::capacity"],
      "value": {
        "expression": "2400 [mAh]",
        "text": "2.4 Ah",
        "si": 8640,
        "dimension": { "A": 1, "s": 1 }
      },
      "uri": "file:///…/sensor-power.sysml",
      "range": { "start": { "line": 18, "character": 12 }, "end": { "line": 18, "character": 38 } }
    }
  ]
}
```

## Elements

Elements are listed in document order, owners before what they own.

| Property | Present | Meaning |
|---|---|---|
| `id` | always | Qualified name: `Package::Def::feature`. Names that are not plain identifiers are quoted (`'PWR-1'`). An anonymous element gets `#kind` and a number within its owner (`Pkg::node::#connection1`, `Pkg::#satisfyRequirement1`), so ids are stable as long as the order of anonymous siblings is. Unique within a document. |
| `name`, `shortName` | if declared | `requirement <'PWR-1'> nodeLife` has `shortName` `PWR-1`, `name` `nodeLife`. |
| `kind` | always | The metaclass: `Package`, `PartDefinition`, `PartUsage`, `AttributeUsage`, `PortUsage`, `ConnectionUsage`, `InterfaceUsage`, `RequirementDefinition`, `RequirementUsage`, `SatisfyRequirementUsage`, `ConstraintUsage`, `CalculationUsage`, `AnalysisCaseUsage`, `StateUsage`, `TransitionUsage`, `ActionUsage`, `SuccessionAsUsage`, `MetadataUsage`, … |
| `owner` | except at top level | The owning element's `id`. |
| `types` | typed features | Qualified names of the types (`: T`). A conjugated port type is `~PortDef`. |
| `specializes` | definitions | `:>` on a definition. |
| `subsets`, `redefines` | features | `:>` and `:>>` on a feature, as declared (implied ones are not listed). `:>> capacity = 2400 [mAh];` in a part body is a `ReferenceUsage` redefining the definition's attribute; it has no `types` of its own. |
| `direction` | directed features | `in`, `out` or `inout`. |
| `multiplicity` | if declared | As written: `[2]`, `[0..*]`. |
| `isAbstract` | abstract elements | `true`. |
| `value` | features with a value | See below. |
| `doc` | if documented | The `doc` comment's text, without the comment markers. |
| `ends` | connectors, successions | Feature paths of the ends, relative to the owner: `["ldo.output", "mcu.supply"]`. |
| `satisfies`, `satisfiedBy` | `satisfy` | The requirement satisfied and what satisfies it: qualified names, or a feature chain as written (`node.battery`). |
| `declaration` | transitions, successions, assign/accept/send/if/loop actions | The declaration as written, whitespace collapsed (`transition first measuring accept after 500 [ms] then transmitting;`). Their internals (parameters, payloads, guards) are not exported as elements. |
| `uri`, `range` | always | Where the element is declared (LSP positions: zero-based lines and characters). |

Not exported: memberships and other relationships (except connectors and `satisfy`), comments,
expression internals, multiplicities, connector ends, and anonymous KerML features.

## Values

| Property | Meaning |
|---|---|
| `expression` | The value expression as written: `2400 [mAh]`, `ldo.output.voltage / r1.resistance`. |
| `text` | The evaluated value with a unit suitable for reading (`2.4 Ah`, `19.09 µA`), when it evaluates. Values are evaluated **in instance context**: a feature of a part usage takes the values redefined for that usage. |
| `si` | The value in SI base units (kg, m, s, A, K, mol, cd), when it is a quantity or number. |
| `dimension` | The exponents of the SI base units: `{ "kg": 1, "m": 2, "s": -3, "A": -1 }` is a voltage; `{}` is a plain number. |
| `literal` | For strings and booleans, the value; for a reference to an element (an enumeration literal, a part), its qualified name. |

## Queries

`sysml-sim query` and the extension's query API filter the elements:

| Option | Matches |
|---|---|
| `--kind` | A metaclass (`PartUsage`) or keyword: `part`, `part def`, `attribute`, `attribute def`, `port`, `port def`, `item`, `item def`, `action`, `action def`, `state`, `state def`, `requirement`, `requirement def`, `constraint`, `calc`, `calc def`, `analysis`, `connection`, `interface`, `satisfy`, `package`. |
| `--name` | Name or short name, with `*` and `?` wildcards, ignoring case: `--name 'PWR-*'`. |
| `--within` | An element and everything under it: `--within SensorPower::node`. |
| `--type` | Typed by, or specializing, an element whose qualified name ends with this: `--type Battery`. |

```sh
sysml-sim query model/ --kind part --within SensorPower::node --format json
sysml-sim query model/ --kind requirement --name 'PWR-*'
```

## Compatibility

`format` and `version` identify the schema. New properties may be added within version 1;
a change that removes or redefines a property increments `version`.
