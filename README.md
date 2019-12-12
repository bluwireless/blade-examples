![BLADE](resources/BLADE.png)

---

# BLADE Example Designs
This repository contains a collection of example designs for getting started with BLADE. Before you start exploring these, make sure you have [BLADE](https://github.com/bluwireless/blade), [DesignFormat](https://github.com/bluwireless/designformat) and [BLADE Templating](https://github.com/bluwireless/blade-templating) on your system so that you can generate the RTL successfully.

## Included Designs
The list of included designs is short at the moment, this will be expanded over time:

 * `design/basic_timer` - A full tutorial on how to build a design with BLADE from scratch, including example code.
 * `designs/counter` - A multi-channel timer demonstrating hierarchy, register blocks, wiring and Verilog templating.

# Getting Started

## System Requirements
You will need to fully setup BLADE, as well as installing some unique dependencies for simulation:

 * [BLADE](https://github.com/bluwireless/blade) - The core of BLADE
 * [DesignFormat](https://github.com/bluwireless/designformat) - Design interchange format (BLADE's output format)
 * [BLADE Templating](https://github.com/bluwireless/blade-templating) - Templating engine based on Mako
 * [Icarus Verilog](http://iverilog.icarus.com) - Opensource Verilog simulator
 * [GTKWave](http://gtkwave.sourceforge.net) - Opensource VCD wave viewer

## Generating and Simulating Designs
For most of the designs contained within this repository, Makefiles are provided to drive the generation and simulation flow. These designs support the following targets:

 * `make generate` - Executes BLADE and BLADE Templating to generate hardware using templates
 * `make run` - Builds the design and runs the simulation using Icarus Verilog
 * `make view` - Opens the VCD trace file using GTKWave
 * `make clean` - Deletes any artefacts created by generation or simulation leaving the source files intact

*NOTE: This excludes the `basic_timer` design - instead you should read the tutorial to see the raw commands for generation and simulation.*