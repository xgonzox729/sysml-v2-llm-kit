# Official SysML v2 example index

Source: OMG SysML v2 Release repo, `sysml/src/training` (EPL-2.0). All files parse with the reference implementation.
Each file is small (300–1500 tokens). **Read only the 1–3 files that match your task** — never the whole folder.

| If you are writing… | Read |
|---|---|
| packages, imports, doc/comments, aliases | 01 |
| part defs, attributes, specialization `:>` | 02, 03 |
| subsetting / redefinition `:>>`, multiplicity narrowing | 04, 05 |
| enums | 06 |
| part usages, configurations, items | 07, 08 |
| connections, ports, conjugation `~`, interfaces | 09, 10, 11 |
| binding `bind`, flows `flow` | 12, 13 |
| actions, parameters, succession `then`/`first` | 14, 15 |
| decisions, merges, fork/join, loops | 16, 17 |
| `perform`, terminate, assign, send/accept messages | 18–22 |
| state machines, transitions, entry/do/exit, triggers, `exhibit` | 23–26 |
| occurrences, individuals, time slices/snapshots | 27, 28 |
| expressions, calcs, constraints, `assert` | 29–31 |
| requirements, groups, `satisfy` | 32 |
| analysis cases, trade studies | 33 |
| verification cases, `verify` | 34 |
| use cases, actors, `include` | 35 |
| variability `variation`/`variant` | 36 |
| dependencies, allocation | 37, 38 |
| metadata, filtering, language extension, views | 39–42 |

Also: `sysml-ref/GoldExample_BatteryCharger.sysml` — one validated model combining most constructs (electrical domain).

## Files

- **01. Packages**: `sysml-ref/examples/01. Packages/Comment Example.sysml`; `sysml-ref/examples/01. Packages/Documentation Example.sysml`; `sysml-ref/examples/01. Packages/Package Example.sysml`
- **02. Part Definitions**: `sysml-ref/examples/02. Part Definitions/Part Definition Example.sysml`
- **03. Generalization**: `sysml-ref/examples/03. Generalization/Generalization Example.sysml`
- **04. Subsetting**: `sysml-ref/examples/04. Subsetting/Subsetting Example.sysml`
- **05. Redefinition**: `sysml-ref/examples/05. Redefinition/Redefinition Example.sysml`
- **06. Enumeration Definitions**: `sysml-ref/examples/06. Enumeration Definitions/Enumeration Definitions-1.sysml`; `sysml-ref/examples/06. Enumeration Definitions/Enumeration Definitions-2.sysml`
- **07. Parts**: `sysml-ref/examples/07. Parts/Parts Example-1.sysml`; `sysml-ref/examples/07. Parts/Parts Example-2.sysml`
- **08. Items**: `sysml-ref/examples/08. Items/Items Example.sysml`
- **09. Connections**: `sysml-ref/examples/09. Connections/Connections Example.sysml`
- **10. Ports**: `sysml-ref/examples/10. Ports/Port Conjugation Example.sysml`; `sysml-ref/examples/10. Ports/Port Example.sysml`
- **11. Interfaces**: `sysml-ref/examples/11. Interfaces/Interface Decomposition Example.sysml`; `sysml-ref/examples/11. Interfaces/Interface Example.sysml`
- **12. Binding Connectors**: `sysml-ref/examples/12. Binding Connectors/Binding Connectors Example-1.sysml`; `sysml-ref/examples/12. Binding Connectors/Binding Connectors Example-2.sysml`
- **13. Flows**: `sysml-ref/examples/13. Flows/Flow Definition Example.sysml`; `sysml-ref/examples/13. Flows/Flow Interface Example.sysml`; `sysml-ref/examples/13. Flows/Flow Usage Example.sysml`
- **14. Action Definitions**: `sysml-ref/examples/14. Action Definitions/Action Definition Example.sysml`; `sysml-ref/examples/14. Action Definitions/Action Shorthand Example.sysml`; `sysml-ref/examples/14. Action Definitions/Action Succession Example-1.sysml`; `sysml-ref/examples/14. Action Definitions/Action Succession Example-2.sysml`
- **15. Actions**: `sysml-ref/examples/15. Actions/Action Decomposition.sysml`
- **16. Conditional Succession**: `sysml-ref/examples/16. Conditional Succession/Conditional Succession Example-1.sysml`; `sysml-ref/examples/16. Conditional Succession/Conditional Succession Example-2.sysml`
- **17. Control**: `sysml-ref/examples/17. Control/Camera.sysml`; `sysml-ref/examples/17. Control/Control Structures Example.sysml`; `sysml-ref/examples/17. Control/Decision Example.sysml`; `sysml-ref/examples/17. Control/Fork Join Example.sysml`; `sysml-ref/examples/17. Control/Merge Example.sysml`
- **18. Action Performance**: `sysml-ref/examples/18. Action Performance/Action Performance Example.sysml`
- **19. Terminate Actions**: `sysml-ref/examples/19. Terminate Actions/Terminate Actions Example-1.sysml`; `sysml-ref/examples/19. Terminate Actions/Terminate Actions Example-2.sysml`
- **20. Assignment Actions**: `sysml-ref/examples/20. Assignment Actions/Assignment Example.sysml`
- **21. Asynchronous Messaging**: `sysml-ref/examples/21. Asynchronous Messaging/Messaging Example.sysml`; `sysml-ref/examples/21. Asynchronous Messaging/Messaging with Ports.sysml`
- **22. Opaque Actions**: `sysml-ref/examples/22. Opaque Actions/Opaque Action Example.sysml`
- **23. State Definitions**: `sysml-ref/examples/23. State Definitions/State Definition Example-1.sysml`; `sysml-ref/examples/23. State Definitions/State Definition Example-2.sysml`
- **24. States**: `sysml-ref/examples/24. States/State Actions.sysml`; `sysml-ref/examples/24. States/State Decomposition-1.sysml`; `sysml-ref/examples/24. States/State Decomposition-2.sysml`
- **25. Transitions**: `sysml-ref/examples/25. Transitions/Change and Time Triggers.sysml`; `sysml-ref/examples/25. Transitions/Local Clock Example.sysml`; `sysml-ref/examples/25. Transitions/Transition Actions.sysml`
- **26. State Exhibition**: `sysml-ref/examples/26. State Exhibition/State Exhibition Example.sysml`
- **27. Occurrences**: `sysml-ref/examples/27. Occurrences/Event Occurrence Example.sysml`; `sysml-ref/examples/27. Occurrences/Interaction Example-1.sysml`; `sysml-ref/examples/27. Occurrences/Interaction Example-2.sysml`; `sysml-ref/examples/27. Occurrences/Interaction Realization-1.sysml`; `sysml-ref/examples/27. Occurrences/Interaction Realization-2.sysml`; `sysml-ref/examples/27. Occurrences/Message Payload Example.sysml`; `sysml-ref/examples/27. Occurrences/Time Slice and Snapshot Example.sysml`
- **28. Individuals**: `sysml-ref/examples/28. Individuals/Individuals and Roles-1.sysml`; `sysml-ref/examples/28. Individuals/Individuals and Snapshots Example.sysml`; `sysml-ref/examples/28. Individuals/Individuals and Time Slices.sysml`
- **29. Expressions**: `sysml-ref/examples/29. Expressions/Car Mass Rollup Example 1.sysml`; `sysml-ref/examples/29. Expressions/Car Mass Rollup Example 2.sysml`; `sysml-ref/examples/29. Expressions/MassRollup1.sysml`; `sysml-ref/examples/29. Expressions/MassRollup2.sysml`
- **30. Calculations**: `sysml-ref/examples/30. Calculations/Calculation Definitions.sysml`; `sysml-ref/examples/30. Calculations/Calculation Usages-1.sysml`; `sysml-ref/examples/30. Calculations/Calculation Usages-2.sysml`
- **31. Constraints**: `sysml-ref/examples/31. Constraints/Analytical Constraints.sysml`; `sysml-ref/examples/31. Constraints/Constraint Assertions-1.sysml`; `sysml-ref/examples/31. Constraints/Constraint Assertions-2.sysml`; `sysml-ref/examples/31. Constraints/Constraints Example-1.sysml`; `sysml-ref/examples/31. Constraints/Constraints Example-2.sysml`; `sysml-ref/examples/31. Constraints/Derivation Constraints.sysml`; `sysml-ref/examples/31. Constraints/Time Constraints.sysml`
- **32. Requirements**: `sysml-ref/examples/32. Requirements/Requirement Definitions.sysml`; `sysml-ref/examples/32. Requirements/Requirement Groups.sysml`; `sysml-ref/examples/32. Requirements/Requirement Satisfaction.sysml`; `sysml-ref/examples/32. Requirements/Requirement Usages.sysml`
- **33. Analysis**: `sysml-ref/examples/33. Analysis/Analysis Case Definition Example.sysml`; `sysml-ref/examples/33. Analysis/Analysis Case Usage Example.sysml`; `sysml-ref/examples/33. Analysis/Trade Study Analysis Example.sysml`
- **34. Verification**: `sysml-ref/examples/34. Verification/Verification Case Definition Example.sysml`; `sysml-ref/examples/34. Verification/Verification Case Usage Example.sysml`
- **35. Use Cases**: `sysml-ref/examples/35. Use Cases/Use Case Definition Example.sysml`; `sysml-ref/examples/35. Use Cases/Use Case Usage Example.sysml`
- **36. Variability**: `sysml-ref/examples/36. Variability/Variation Configuration.sysml`; `sysml-ref/examples/36. Variability/Variation Definitions.sysml`; `sysml-ref/examples/36. Variability/Variation Usages.sysml`
- **37. Dependencies**: `sysml-ref/examples/37. Dependencies/Dependency Example.sysml`
- **38. Allocation**: `sysml-ref/examples/38. Allocation/Allocation Definition Example.sysml`; `sysml-ref/examples/38. Allocation/Allocation Usage Example.sysml`
- **39. Metadata**: `sysml-ref/examples/39. Metadata/Metadata Example-1.sysml`; `sysml-ref/examples/39. Metadata/Metadata Example-2.sysml`
- **40. Filtering**: `sysml-ref/examples/40. Filtering/Filtering Example-1.sysml`; `sysml-ref/examples/40. Filtering/Filtering Example-2.sysml`
- **41. Language Extension**: `sysml-ref/examples/41. Language Extension/Model Library Example.sysml`; `sysml-ref/examples/41. Language Extension/Semantic Metadata Example.sysml`; `sysml-ref/examples/41. Language Extension/User Keyword Example.sysml`
- **42. Views**: `sysml-ref/examples/42. Views/Viewpoint Example.sysml`; `sysml-ref/examples/42. Views/Views Example.sysml`
