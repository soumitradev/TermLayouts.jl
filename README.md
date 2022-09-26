# TermLayouts.jl

[![](https://img.shields.io/badge/docs-dev-teal.svg)](https://soumitradev.github.io/TermLayouts.jl/dev/) [![Run Tests](https://github.com/soumitradev/TermLayouts.jl/actions/workflows/test.yml/badge.svg)](https://github.com/soumitradev/TermLayouts.jl/actions/workflows/test.yml) [![codecov](https://codecov.io/gh/soumitradev/TermLayouts.jl/branch/main/graph/badge.svg?token=LWU3QJ7TW6)](https://codecov.io/gh/soumitradev/TermLayouts.jl)

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

The proposal link can be found here: [Proposal PDF](./proposal.pdf)

## Progress Outline

- [x] Rendering the REPL in a Term.jl `Panel`, and making it interactive, handling keystrokes
- [x] Adding `Panel`s and creating a layout for them
- [x] Making the layout more or less responsive to the terminal size
- [x] Using a config file for the layout
- [x] Documentation for every function, both internal and external, with a Quickstart, using Documenter.jl
- [x] Unit tests for almost every function
- [x] Making the overall REPL Panel asynchronous, and thus extremely smooth and responsive

**What's left to do**
- [ ] Handling cursor movement in the REPL Panel: #5
  - Currently on hold because I couldn't find a way to get the cursor position from a `TTYTerminal`, and even [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) didn't work. One possible fix is to manually keep track of the cursor position using keystrokes, but then there are too many keystrokes and cases to handle
- [ ] Additional Panel types, such as Plots, Image panel, etc.
  - Image panel should probably use: https://github.com/JuliaImages/XTermColors.jl (backend for https://github.com/JuliaImages/ImageInTerminal.jl). Sixel support could also work.
- [ ] Better layout configuration, and keystroke handling for hiding/resizing
  - We discussed about this a bit, and settled on a config file something like `xterm`. We think this would be most appropriate for this project due to its simplicity, and customizability
- [ ] Better testing for some of the more rendering-reliant functions, modularization of the render function
  - See: https://github.com/JuliaTesting/ReferenceTests.jl


## Challenges and Learnings

When I first started working on this project, I had to read through a **lot** of uncommented code from base Julia. This will be an issue because base julia REPL and IO code isn't very well documented, because it isn't that user facing. Not being overwhelmed by reading core julia code was a good skill I learnt, and I notice myself doing this in my other projects too. If I ever have to look into package, or core code to find out why something isn't working, I'm now confident I can find what I want from whatever I see. For any future maintainers, this isn't really necessary because a lot of the groundwork is already done, but it's a really useful general skill to have.

I learn't a lot about how terminals work, and how we can exploit some of the properties of the terminal to do useful things, like draw images, or graphics, or some kind of Panel. Handling keystrokes, redirecting stdout, async updating while maintaing synchronous state, all this taught me a lot about julia's internal workings, and the terminal's internal workings.

Towards the end, I also realized the important utility that tools like Unit testing and documentation provide. The project is now much more maintainable because of it. Getting stuff like GitHub Actions and codecov working in tandem also taught me the importance of CI. I've used CI tools before, and they were useful, but more of an annoyance as a contributor. Now, from a project maintainer perspective, I see the immense value in these tools.

The entire experience of Google Summer of Code taught me the importance of communication. The moment I started to talk to someone about my project, a lot of unclear stuff became much clearer in my head, and the alternative perspectives, advice and experience really helped a lot when I was stuck and had no idea on how to work something out.

I cannot thank my mentors, @johnnychen94, @mortenpi and @fedeclaudi enough. I cannot even put into words the amount of challenges we faced at the beginning of this project. To be honest, at one point I thought it was actually impossible, and I had dug myself a hole. My mentors, with their experience and knowledge of the julia ecosystem always tried their best to help and support me, and helped me out of some of the most mindbending errors or design questions.

This project is probably the most intensive project I have worked on, and that's because of the limited time I got to work on it. I realized how much of my day is consumed by other stuff, so I had to pack most of my work in small, hyper-productive sessions. I apologize if this ever caused my mentors to view me as dormant, inactive, or disinterested, but I tried my best, and always replied on Slack as soon as I could.

One small regret I have is not working on this project as much as I wanted to, because I was trying to manage academics alongside this for most of the pre-GSoC phase, and the concluding phase. My dual degree CGPA requirement for CS was quite high, so I had to make sure I keep that at the top priority. However, due to all the support from my mentors, and their flexibility in how I worked on the project, I recently got my CS Dual Degree, and I'm really really happy about that.

## Link to project
All my work is a standalone Julia package over [here](https://github.com/soumitradev/TermLayouts.jl). Currently, it is not stable enough to be released on the Julia Registry. As it gains some of the features listed above, I believe that it will be a good addition to the Registry.
