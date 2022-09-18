# TermLayouts.jl

[![](https://img.shields.io/badge/docs-dev-teal.svg)](https://soumitradev.github.io/TermLayouts.jl/dev/) [![Run Tests](https://github.com/soumitradev/TermLayouts.jl/actions/workflows/test.yml/badge.svg)](https://github.com/soumitradev/TermLayouts.jl/actions/workflows/test.yml)

## Description

For quick prototyping, especially data pre-processing, the REPL often is a handy tool. However, the REPL interface as it exists today is too bland and makes working with Images in the REPL significantly more inconvenient. It can be improved for different workloads based on the requirements.

For example, some of the problems with the REPL when working with Images are:

- An external package is needed to display the images in the REPL appropriately
- The external package needs additional maintenance
- The external package achieves the goal of displaying the image in the terminal, but the same function needs to be called over and over again, and since Images can be huge, these images can clog up the REPL, making it harder to work with them
- Images take up significantly more memory than most variables or data structures, so when dealing with large datasets or large images, keeping track of the variables defined is paramount

Furthermore, the REPL also has more general issues that hinder fast and efficient Data Science work:
- The REPL lacks any debugging tools, while the julia-vscode package has achieved this
- The REPL lacks a dedicated logger, which, again, julia-vscode has achieved

Even the ImageInTerminal package has its limitations:
- Older versions (< 1.6) of Julia can only render large images using the default encoder.
- Never versions, however, can use the Sixel encoder to encode large images allowing for a much better viewing experience.

This project will aim to address the above concerns.

## Background

This project is a Google Summer of Code 2022 project for The Julia Language.

The proposal link can be found here: [Proposal PDF](https://summerofcode.withgoogle.com/media/user/e88937082ac5/proposal/tQ7SJDRLSPzdIljs.pdf)
