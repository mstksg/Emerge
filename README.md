# Description #

**Emerge** is a project exploring emergent behavior in an environment governed by
natural selection and competition.

Organisms float around in a primordial pool, and their characteristics are
determined by an internal gene, which mutates with every succesful (asexual)
reproduction cycle.  However, the interesting part is that not only does the mutatable
gene account for their physical characteristics, but also their internal programming.

What we have are not merely survival of the strongest or fastest, but of the smartest.
Indeed, it is my hope that the only true determination of survival would be
intelligence; their physical characteristics should merely be the specialization of
intelligences.

# Installation #

On Windows, download the zipped binary at http://github.com/mstk/Emerge/downloads ; extract
to a folder and run **emerge.exe**

# The "Eo" #

The basic organism is known as the **Eo**, which comes from "(Hopefully) Emergent Organism".
Eos float around more or less aimlessly around the toroidal pool.  Food is sprinkled
randomly around the pool; Eos need this food to survive.  Their energy drains as they move.

When an Eo reaches a certain energy threshold, it may spontaneously reproduce into two
slightly mutated versions of itself.

## Feelers ##

Every Eo has one input trigger: a **feeler**, poking from their body, of varying length
and thickness (determined by DNA).  When an Eo's feeler pokes into another, it damages the
target; eventually, the target may die, and the attacker will gain all of his energy.

When this feeler is triggered, either by food or another Eo, a signal is sent to the brain
for processing.

## The Brain ##

The logic in each Eo's brain is randomly generated, and the genetic data encoding it is mutatable.
That is, when an Eo is created, the program is just a random string of commands (including a basic
"if-then" control structure).  Every time an Eo reproduces, this program might be randomly mutated,
by adding or removing or changing commands.

Sure, I could write the AI for an Eo that would survive the best; but why not let natural selection
work its course to stumble on it over multiple generations?  What if the "smartest" program possible
can be found...by natural selection alone?

# User Controls #

It's a simulation, but there are some basic controls availible.

### Tracking an Eo/Family Line ###

**Left-click** an Eo to begin tracking it and all of its descendants; when it reproduces, the tracker will
automatically move to one of the descendants.  If the tracked Eo dies, the tracker will move to the
closest remaining descendant of the original tracked family line.

**Keyboard Commands:**

- Pressing **Z** will "move up" the current tracked family line to the parent of the original tracked Eo.
- Pressing **N** will "narrow down" a family line to the most recent common ancestor of the remaining
descendants.
- Pressing **T** will output a report about the currently tracked family line, with a family tree and
other such statistics.
- Pressing **SPACE** will output a report about the currently tracked Eo itself.

### Manipulating Eos ###

**Right-click** an Eo to kill it; **middle-click** an Eo to force it to replicate.  A **right-click** on an
empty spot in the pond will cause a randomly generated Eo to be born.

**Keyboard Commands:**

- Pressing **I** will infuse each Eo with a configurable burst of energy.
- Pressing **M** will cause each Eo to radically mutate in-place.
- Pressing **S** will "sprinkle" a randomly generated Eo somewhere in the pond.
- Pressing **O** will force every Eo to replicate.

### The Pond ###

- Pressing **D** will cause a pond-wide disaster, dealing massive damage to each Eo.
- Pressing **F** will cause all food in the pond at the given time to vanish/go away.
- Pressing **P** will toggle on a *drought*, basically shutting off all food production, and vice-versa.
- Pressing **R** will output a report about the pond itself, the living family line, and other statistics.

### Hall of Fame ###

At any time, pressing **H** will output a *Hall of Fame*, which lists top achievement in miscellaneous
categories for Eos.  Eos are only inducted into the hall upon death.  At program quit, a hall of fame is
also outputted.