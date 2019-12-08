# Counter
This is a basic example of how to build a hierarchical IP with BLADE, and how you can use registers and interconnects.

## Design Hierarchy
```
Counter
 | - CounterCtrlImp::m_control_0
 | - CounterManagerImp::m_manager_0
 | - CounterCoreWrapImp::m_counter_0
 |    | - CounterCore::core
 | - CounterCoreWrapImp::m_counter_1
 |    | - CounterCore::core
 ...
 | - CounterCoreWrapImp::m_counter_7
      | - CounterCore::core
```

 * `Counter` is the top level of the design - it's define in `yaml_mod/counter.yaml`.
 * `CounterCtrlImp` contains the register bank and AXI4-Lite decoder logic - it's defined in `yaml_mod/counter_ctrl.yaml`, with registers defined in `yaml_reg/counter_reg.yaml`.
 * `CounterManagerImp` is a distribution block for a signal that resets all of the counters to 0 - it's defined in `yaml_mod/counter_manager.yaml`.
 * `CounterCoreWrapImp` wraps an imported Verilog counter core - it's defined in `counter_core_wrap.yaml`.
 * `CounterCore` is a basic timer with start, stop, and load capabilities - it is an imported Verilog IP, with it's implementation in `src_v/counter_core.v`.

## Templated RTL
Blocks like `CounterCtrlImp`, `CounterManagerImp`, and `CounterCoreWrapImp` are marked with an `IMP` option in their YAML declarations - this means that they are leaf nodes that contain implemented logic, as opposed to pure wiring levels. Their implementations are constructed from special templates kept under `imp_src` (e.g. `imp_src/counter_ctrl.v`) - unlike other templates, these are specific to the module being generated.

## Generating and Simulating
Common tasks like generation and simulation are driven by Make rules declared in `Makefile` and the shared Makefiles under `flow` in the root of this repository. The following targets are available:

 * `make generate` - parses the YAML design and generates Verilog into `build/verilog`.
 * `make run` - builds the design and simulates it using Icarus Verilog with waves stored under `build/sim`.
 * `make clean` - deletes all generation and simulation artefacts.
