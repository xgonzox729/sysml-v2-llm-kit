# B. A tour of the standard library

The SysML v2 standard library comes bundled with the extension. Its packages are SysML (and KerML)
text: press **F12** on any library name in your model to open its source, and **Shift+F12** to see
where your model uses it. This appendix lists what you are most likely to use.

## Values and quantities

| Package | What it has | You use it for |
|---|---|---|
| `ScalarValues` | `Boolean`, `String`, `Integer`, `Natural`, `Positive`, `Real`, `Rational`, `Complex` | plain values |
| `ISQ` | every quantity type of ISO 80000, re-exported from `ISQBase`, `ISQSpaceTime`, `ISQMechanics`, `ISQThermodynamics`, `ISQElectromagnetism`, `ISQLight`, `ISQInformation`… | typing attributes: `ElectricPotentialValue`, `ElectricCurrentValue`, `PowerValue`, `EnergyValue`, `DurationValue`, `FrequencyValue`, `ResistanceValue`, `CapacitanceValue`, `InductanceValue`, `ElectricChargeValue`, `ThermodynamicTemperatureValue`, `MassValue`, `LengthValue`, `StorageCapacityValue`… |
| `SI` | the SI units and their prefixed forms: `V`, `A`, `W`, `J`, `s`, `Hz`, `'Ω'`, `F`, `H`, `C`, `K`, `kg`, `m`, `mm`, `km`, `kW`… | writing values: `3.3 [V]` |
| `SIPrefixes` | `kilo`, `milli`, `micro`… | defining units of your own |
| `USCustomaryUnits` | `in`, `ft`, `lb`, `°F`… | values in imperial units |
| `Quantities` | `ScalarQuantityValue`, `TensorQuantityValue` | the general types quantity types specialize |
| `MeasurementReferences` | `MeasurementUnit`, `ConversionByPrefix`, `ConversionByConvention` | defining units (see `EngineeringUnits` for examples) |
| `Time` | `Clock`, `TimeInstantValue`, `Iso8601DateTime` | time stamps and clocks |

The extension evaluates quantities in any of these units, converts between them, and checks
dimensions (chapter 5). Its `EngineeringUnits` library adds the units engineers use daily (`mA`, `µA`,
`mAh`, `kΩ`, `ms`, `KiB`…): see [Appendix C](C-extension-libraries.md).

## Functions

The kernel function libraries are imported implicitly where needed. They're evaluated natively by the
extension:

| Package | Functions |
|---|---|
| `NumericalFunctions`, `RealFunctions`, `IntegerFunctions` | `abs`, `sqrt`, `floor`, `round`, `ceiling`, `max`, `min`, `sum`, `product` |
| `TrigFunctions` | `sin`, `cos`, `tan` (radians) |
| `BaseFunctions`, `DataFunctions` | `==`, `!=`, `??`, `isEmpty`, `notEmpty` |
| `SequenceFunctions`, `CollectionFunctions`, `ControlFunctions` | `size`, `includes`, `collect`, `select`, `reject`, `forAll`, `exists` |
| `StringFunctions` | `+` (concatenation), `ToString` |

## The systems library

The `Systems Library` defines what every SysML construct *is*: every `part` is implicitly a
`Parts::Part`, every `action` an `Actions::Action`, and so on. You rarely refer to these packages by
name, but reading them explains features you see in completion and in the Values view:

| Package | Defines |
|---|---|
| `Items`, `Parts` | items and parts: `Item`, `Part`, and features like `subparts`, `ownedPorts` |
| `Ports`, `Connections`, `Interfaces`, `Flows`, `Allocations` | ports and the relationships between parts |
| `Attributes` | `AttributeValue` |
| `Actions`, `States` | `Action` (with `start`, `done`), `StateAction`, `TransitionAction` |
| `Calculations`, `Constraints` | `Calculation`, `ConstraintCheck` |
| `Requirements` | `RequirementCheck`, and the subject, assumption and requirement features |
| `Cases`, `AnalysisCases`, `VerificationCases`, `UseCases` | the case kinds |
| `Views`, `StandardViewDefinitions` | views, viewpoints and the standard view kinds |
| `Metadata` | `MetadataItem`, the base of every metadata definition |

## Domain libraries

| Package | What it has |
|---|---|
| `TradeStudies` | `TradeStudy`, `MaximizeObjective`, `MinimizeObjective`, `evaluationFunction` (chapter 11) |
| `AnalysisTooling`, `SampledFunctions`, `StateSpaceRepresentation` | annotations and types for analysis tools |
| `RequirementDerivation` | `#derivation` metadata and derivation connections between requirements |
| `CauseAndEffect` | `#cause`, `#effect` for failure-mode and hazard models |
| `Geometry` (`ShapeItems`, `SpatialItems`) | shapes and coordinate frames for mechanical models |
| `ModelingMetadata`, `RiskMetadata`, `ParametersOfInterestMetadata`, `ImageMetadata` | `#refinement`, `@StatusInfo`, `@Rationale`, `@Issue`, risk levels, measures of effectiveness and performance, images |

## Finding things

- **Completion** (**Ctrl+Space**) after an import lists what the package has.
- **Hover** shows a library element's declaration and `doc`.
- **Go to Definition** (**F12**) opens its source.

Next: [C. The extension's libraries](C-extension-libraries.md)
