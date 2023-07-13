Where You Left Off
==================

Most of the big pieces that it couldn't work without have at least been proven out:
  - Using the pencil to draw gestures as a basic interaction scheme
  - Driving the model constraints with springs (instead of using a more formal
    constraints solver)
  - Implementing the fundamental constraints/quantities with the spring-driven
    system (distance, angle, and rail)

I think it has promise, there's something here. The springs need tuning, it
feels a little loosey-goosey right now, but that's a solvable problem.

The construction ink stuff is pretty fleshed out, it'll probably need some
tweaking as things progress, but it's mostly solid (I think)

The meta ink stuff is very preliminary. Not quite protobage bad, but not even
close to complete. Just the core implementations of the fundamental constraints,
no quality of life things, no general way to relate quantities, things like
that.

The least complete part of this is the user interface. Almost none of the meta
ink even has a way to be created directly by the user, all of the testing has
been with hardcoded models. The pencil gesture idea is cool, but how does it
scale up to all those uses? Would it feel alright to use menus (or mini menus)
for some of this? Lots of open questions here.

Other than that, there's a good amount of cleanup and refactoring to be done,
especially among the physics-type math.

Here's the TODO list as it stands in Trello:
  - Gesture/interface for creating angle quantities
  - Gesture/interface for fixing nodes to a point
  - Way to display angle quantities
  - Gesture/interface for making rail constraints
  - Way to display rail constraints
  - Better way to display distance quantities
  - Some way to display relationships between quantities
  - Delete gestures for constraints
  - Refactor all the math, need a vector type and common operations for all that
  - Tune the springs
  - Spreader rail meta node for repetition

Some other things to consider for the future:
  - Don't forget about the sketch ink idea, a layer where both the user and the
    model can doodle, and the model can get input from (by tracking strokes with
    a node)
  - Zooming, panning, scaling, encapsulating sketches
