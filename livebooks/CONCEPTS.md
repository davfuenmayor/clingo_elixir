# Concept and API index

## [Facts, rules and alternatives](language/01-facts-and-rules.livemd)

- [Introduction](language/01-facts-and-rules.livemd#introduction)

- [Preliminaries: check your setup](language/01-facts-and-rules.livemd#preliminaries-check-your-setup)

- [Facts, rules and shown answers](language/01-facts-and-rules.livemd#facts-rules-and-shown-answers)

- [Classify creatures with rules](language/01-facts-and-rules.livemd#classify-creatures-with-rules)

- [Express alternatives without body disjunction](language/01-facts-and-rules.livemd#express-alternatives-without-body-disjunction)

- [Derive positive consequences](language/01-facts-and-rules.livemd#derive-positive-consequences)

API: `Clingo.solve!`.

## [Negation, recursion and support](language/02-negation-and-recursion.livemd)

- [Introduction](language/02-negation-and-recursion.livemd#introduction)

- [Preliminaries: check your setup](language/02-negation-and-recursion.livemd#preliminaries-check-your-setup)

- [Absence, explicit negation and recursion](language/02-negation-and-recursion.livemd#absence-explicit-negation-and-recursion)

- [Reason with missing evidence](language/02-negation-and-recursion.livemd#reason-with-missing-evidence)

- [Distinguish explicit and default negation](language/02-negation-and-recursion.livemd#distinguish-explicit-and-default-negation)

- [Follow positive cycles](language/02-negation-and-recursion.livemd#follow-positive-cycles)

- [Test default negation](language/02-negation-and-recursion.livemd#test-default-negation)

- [Study mutual absence tests](language/02-negation-and-recursion.livemd#study-mutual-absence-tests)

- [Vary a negative cycle](language/02-negation-and-recursion.livemd#vary-a-negative-cycle)

API: `Clingo.solve!`.

## [Choices, cardinalities and constraints](language/03-choices-and-constraints.livemd)

- [Introduction](language/03-choices-and-constraints.livemd#introduction)

- [Preliminaries: check your setup](language/03-choices-and-constraints.livemd#preliminaries-check-your-setup)

- [Generate candidates, reject violations](language/03-choices-and-constraints.livemd#generate-candidates-reject-violations)

- [Make atoms optional](language/03-choices-and-constraints.livemd#make-atoms-optional)

- [Combine choices with positive recursion](language/03-choices-and-constraints.livemd#combine-choices-with-positive-recursion)

- [Filter candidate models](language/03-choices-and-constraints.livemd#filter-candidate-models)

- [Bound a choice](language/03-choices-and-constraints.livemd#bound-a-choice)

- [Combine bounds and conditions](language/03-choices-and-constraints.livemd#combine-bounds-and-conditions)

- [Generate and filter structured choices](language/03-choices-and-constraints.livemd#generate-and-filter-structured-choices)

- [Choices, consequences and constraints](language/03-choices-and-constraints.livemd#choices-consequences-and-constraints)

API: `Clingo.solve!`.

## [Domains, grounding and arithmetic](language/04-domains-and-grounding.livemd)

- [Introduction](language/04-domains-and-grounding.livemd#introduction)

- [Preliminaries: check your setup](language/04-domains-and-grounding.livemd#preliminaries-check-your-setup)

- [Ground finite domains safely](language/04-domains-and-grounding.livemd#ground-finite-domains-safely)

- [Ground rules over a domain](language/04-domains-and-grounding.livemd#ground-rules-over-a-domain)

- [Compare remaining language constructs](language/04-domains-and-grounding.livemd#compare-remaining-language-constructs)

- [Develop a course-selection model](language/04-domains-and-grounding.livemd#develop-a-course-selection-model)

API: `Clingo.Symbol.number`, `Clingo.solve!`.

## [Aggregates and conditional literals](language/05-aggregates-and-conditionals.livemd)

- [Introduction](language/05-aggregates-and-conditionals.livemd#introduction)

- [Preliminaries: check your setup](language/05-aggregates-and-conditionals.livemd#preliminaries-check-your-setup)

- [Count tuples and express all conditions](language/05-aggregates-and-conditionals.livemd#count-tuples-and-express-all-conditions)

- [Count distinct tuples](language/05-aggregates-and-conditionals.livemd#count-distinct-tuples)

- [Sum weighted tuple sets](language/05-aggregates-and-conditionals.livemd#sum-weighted-tuple-sets)

- [Expand conditional literals](language/05-aggregates-and-conditionals.livemd#expand-conditional-literals)

- [Apply aggregates to course selection](language/05-aggregates-and-conditionals.livemd#apply-aggregates-to-course-selection)

API: `Clingo.solve!`.

## [Optimization and projection](language/06-optimization-and-projection.livemd)

- [Introduction](language/06-optimization-and-projection.livemd#introduction)

- [Preliminaries: check your setup](language/06-optimization-and-projection.livemd#preliminaries-check-your-setup)

- [Optimize costs without mistaking search progress for proof](language/06-optimization-and-projection.livemd#optimize-costs-without-mistaking-search-progress-for-proof)

API: `Clingo.solve!`.

## [Graphs, sets and Boolean clauses](modeling/01-graphs-and-sets.livemd)

- [Introduction](modeling/01-graphs-and-sets.livemd#introduction)

- [Preliminaries: check your setup](modeling/01-graphs-and-sets.livemd#preliminaries-check-your-setup)

- [Reuse generate-and-test on graphs](modeling/01-graphs-and-sets.livemd#reuse-generate-and-test-on-graphs)

- [Choose an exact hitting set](modeling/01-graphs-and-sets.livemd#choose-an-exact-hitting-set)

- [Choose nonadjacent vertices](modeling/01-graphs-and-sets.livemd#choose-nonadjacent-vertices)

- [Cover every graph edge](modeling/01-graphs-and-sets.livemd#cover-every-graph-edge)

- [Reach every vertex from a selected set](modeling/01-graphs-and-sets.livemd#reach-every-vertex-from-a-selected-set)

- [Satisfy a collection of clauses](modeling/01-graphs-and-sets.livemd#satisfy-a-collection-of-clauses)

API: `Clingo.solve!`.

## [Grids and spatial puzzles](modeling/02-grids-and-puzzles.livemd)

- [Introduction](modeling/02-grids-and-puzzles.livemd#introduction)

- [Preliminaries: check your setup](modeling/02-grids-and-puzzles.livemd#preliminaries-check-your-setup)

- [Make row and column constraints explicit](modeling/02-grids-and-puzzles.livemd#make-row-and-column-constraints-explicit)

- [Fill a Latin square](modeling/02-grids-and-puzzles.livemd#fill-a-latin-square)

- [Complete a Sudoku board](modeling/02-grids-and-puzzles.livemd#complete-a-sudoku-board)

- [Illuminate a grid](modeling/02-grids-and-puzzles.livemd#illuminate-a-grid)

- [Route through numbered hints](modeling/02-grids-and-puzzles.livemd#route-through-numbered-hints)

- [Move numbered pieces into regions](modeling/02-grids-and-puzzles.livemd#move-numbered-pieces-into-regions)

API: `Clingo.solve!`.

## [Learning and product configuration](modeling/03-learning-and-configuration.livemd)

- [Introduction](modeling/03-learning-and-configuration.livemd#introduction)

- [Preliminaries: check your setup](modeling/03-learning-and-configuration.livemd#preliminaries-check-your-setup)

- [Search over explanations and compatible products](modeling/03-learning-and-configuration.livemd#search-over-explanations-and-compatible-products)

- [Learn a propositional classifier](modeling/03-learning-and-configuration.livemd#learn-a-propositional-classifier)

- [Learn a binary decision tree](modeling/03-learning-and-configuration.livemd#learn-a-binary-decision-tree)

- [Learn an acyclic rule system](modeling/03-learning-and-configuration.livemd#learn-an-acyclic-rule-system)

- [Read a COOM product description](modeling/03-learning-and-configuration.livemd#read-a-coom-product-description)

- [Understand configuration facts](modeling/03-learning-and-configuration.livemd#understand-configuration-facts)

- [Configure a product from compatible parts](modeling/03-learning-and-configuration.livemd#configure-a-product-from-compatible-parts)

API: `Clingo.solve!`.

## [Actions, state transitions and robots](planning/01-actions-and-robots.livemd)

- [Introduction](planning/01-actions-and-robots.livemd#introduction)

- [Preliminaries: check your setup](planning/01-actions-and-robots.livemd#preliminaries-check-your-setup)

- [Represent change and resource limits](planning/01-actions-and-robots.livemd#represent-change-and-resource-limits)

- [Plan legal disc transfers](planning/01-actions-and-robots.livemd#plan-legal-disc-transfers)

- [Escape a deterministic pursuer](planning/01-actions-and-robots.livemd#escape-a-deterministic-pursuer)

- [Coordinate robots and ordered jobs](planning/01-actions-and-robots.livemd#coordinate-robots-and-ordered-jobs)

API: `Clingo.solve!`.

## [Scheduling, staffing and resources](planning/02-scheduling-and-resources.livemd)

- [Introduction](planning/02-scheduling-and-resources.livemd#introduction)

- [Preliminaries: check your setup](planning/02-scheduling-and-resources.livemd#preliminaries-check-your-setup)

- [Schedule ordered machine operations](planning/02-scheduling-and-resources.livemd#schedule-ordered-machine-operations)

- [Schedule tasks and workers](planning/02-scheduling-and-resources.livemd#schedule-tasks-and-workers)

- [Cover a cyclic staffing schedule](planning/02-scheduling-and-resources.livemd#cover-a-cyclic-staffing-schedule)

- [Schedule with successive time windows](planning/02-scheduling-and-resources.livemd#schedule-with-successive-time-windows)

API: `Clingo.Control.get_const!`, `Clingo.Control.ground!`, `Clingo.Control.load!`, `Clingo.Control.solve!`, `Clingo.solve!`, `Clingo.with_control`.

## [Getting started with clingo_elixir](elixir/01-getting-started.livemd)

- [Introduction](elixir/01-getting-started.livemd#introduction)

- [Preliminaries: check your setup](elixir/01-getting-started.livemd#preliminaries-check-your-setup)

- [Getting Started with clingo_elixir](elixir/01-getting-started.livemd#getting-started-with-clingo_elixir)

API: `Clingo.Control.add!`, `Clingo.Control.assign_external!`, `Clingo.Control.close`, `Clingo.Control.ground!`, `Clingo.Control.new!`, `Clingo.Control.solve!`, `Clingo.Ground.to_string!`, `Clingo.models`, `Clingo.solve!`, `Clingo.with_control`.

## [Inputs, symbols, results and streams](elixir/02-inputs-results-and-streams.livemd)

- [Introduction](elixir/02-inputs-results-and-streams.livemd#introduction)

- [Preliminaries: check your setup](elixir/02-inputs-results-and-streams.livemd#preliminaries-check-your-setup)

- [Supply text, files and grounding functions](elixir/02-inputs-results-and-streams.livemd#supply-text-files-and-grounding-functions)

- [Choose between complete results and lazy samples](elixir/02-inputs-results-and-streams.livemd#choose-between-complete-results-and-lazy-samples)

API: `Clingo.Control.add!`, `Clingo.Control.ground!`, `Clingo.Control.solve!`, `Clingo.Symbol.format!`, `Clingo.Symbol.number`, `Clingo.Symbol.parse!`, `Clingo.models`, `Clingo.solve!`, `Clingo.with_control`.

## [Incremental solving and changing inputs](elixir/03-incremental-solving.livemd)

- [Introduction](elixir/03-incremental-solving.livemd#introduction)

- [Preliminaries: check your setup](elixir/03-incremental-solving.livemd#preliminaries-check-your-setup)

- [Change inputs and ground new parts](elixir/03-incremental-solving.livemd#change-inputs-and-ground-new-parts)

- [Reuse a control between solves](elixir/03-incremental-solving.livemd#reuse-a-control-between-solves)

API: `Clingo.Control.add!`, `Clingo.Control.assign_external!`, `Clingo.Control.ground!`, `Clingo.Control.literal`, `Clingo.Control.release_external!`, `Clingo.Control.solve!`, `Clingo.Symbol.number`, `Clingo.solve!`, `Clingo.with_control`.

## [Inspection, ASPIF and native export](elixir/04-inspection-and-export.livemd)

- [Introduction](elixir/04-inspection-and-export.livemd#introduction)

- [Preliminaries: check your setup](elixir/04-inspection-and-export.livemd#preliminaries-check-your-setup)

- [Inspect atoms and exchange grounded programs](elixir/04-inspection-and-export.livemd#inspect-atoms-and-exchange-grounded-programs)

- [Inspect ASPIF across incremental steps](elixir/04-inspection-and-export.livemd#inspect-aspif-across-incremental-steps)

API: `Clingo.Control.add!`, `Clingo.Control.ground!`, `Clingo.Dimacs.solve!`, `Clingo.Ground.to_string!`, `Clingo.Inspection.symbolic_atoms!`, `Clingo.Symbol.format!`, `Clingo.solve!`, `Clingo.with_control`.

## [Observers, propagators and search agents](extensions/01-observers-and-propagators.livemd)

- [Introduction](extensions/01-observers-and-propagators.livemd#introduction)

- [Preliminaries: check your setup](extensions/01-observers-and-propagators.livemd#preliminaries-check-your-setup)

- [Observe grounding and search without changing answers](extensions/01-observers-and-propagators.livemd#observe-grounding-and-search-without-changing-answers)

- [Observe search and add constraints on demand](extensions/01-observers-and-propagators.livemd#observe-search-and-add-constraints-on-demand)

- [Start a solver-side agent](extensions/01-observers-and-propagators.livemd#start-a-solver-side-agent)

- [Design a Sudoku search agent](extensions/01-observers-and-propagators.livemd#design-a-sudoku-search-agent)

API: `Clingo.Control.add!`, `Clingo.Control.ground!`, `Clingo.Control.load!`, `Clingo.Control.register_observer!`, `Clingo.Control.register_propagator!`, `Clingo.Control.solve!`, `Clingo.View.assignment`, `Clingo.View.check_mode!`, `Clingo.View.decision_level`, `Clingo.solve!`, `Clingo.with_control`.

## [Theory constraints and solver evaluation](extensions/02-theory-constraints.livemd)

- [Introduction](extensions/02-theory-constraints.livemd#introduction)

- [Preliminaries: check your setup](extensions/02-theory-constraints.livemd#preliminaries-check-your-setup)

- [Inspect theory syntax and choose the next extension](extensions/02-theory-constraints.livemd#inspect-theory-syntax-and-choose-the-next-extension)

- [Extend solving with theory constraints](extensions/02-theory-constraints.livemd#extend-solving-with-theory-constraints)

- [Build a restricted integer propagator](extensions/02-theory-constraints.livemd#build-a-restricted-integer-propagator)

- [Evaluate theory-based scheduling](extensions/02-theory-constraints.livemd#evaluate-theory-based-scheduling)

API: `Clingo.Control.add!`, `Clingo.Control.ground!`, `Clingo.Inspection.theory_atoms!`, `Clingo.solve!`, `Clingo.with_control`.

## [Meta-programming and program transformations](extensions/03-meta-programming.livemd)

- [Introduction](extensions/03-meta-programming.livemd#introduction)

- [Preliminaries: check your setup](extensions/03-meta-programming.livemd#preliminaries-check-your-setup)

- [Interpret grounded programs as data](extensions/03-meta-programming.livemd#interpret-grounded-programs-as-data)

- [Build translators and diverse-model interpreters](extensions/03-meta-programming.livemd#build-translators-and-diverse-model-interpreters)

API: `Clingo.Dimacs.solve!`, `Clingo.Ground.to_string!`, `Clingo.solve!`.

## [Preference solving with repeated search](extensions/04-preference-solving.livemd)

- [Introduction](extensions/04-preference-solving.livemd#introduction)

- [Preliminaries: check your setup](extensions/04-preference-solving.livemd#preliminaries-check-your-setup)

- [Implement a small preference engine](extensions/04-preference-solving.livemd#implement-a-small-preference-engine)

API: `Clingo.solve!`, `Clingo.with_control`.
