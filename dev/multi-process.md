From Rob Hoelz:

I did some additional testing of ack using multiple workers -
starting with a ondemand forking model, and then moving to a pre-fork
model. The former didn't provide too much of a benefit, and the
latter was somewhat complicated. At first I thought maybe I could
have a shared work queue pipe, but I realized that each child process
would probably buffer inputs, so the work would get divied up oddly.
I then had the thought to maintain a list of available children for
work - children would send a SIGUSR1 to their parent when done, and
the parent would re-register the corresponding child in the
availability list. A good idea in theory, but it turns out that
even though `si_pid` is documented as occurring in `siginfo_t`, it
either isn't available on Linux, or the Perl POSIX module doesn't
pass it through. I ended up opting for a simple list of children
and iterating through them in a round-robin fashion. A possible
improvement could be random selection, perhaps weighted by the sizes
of the files that each child has handled thus far.

The multi-process model didn't show large benefits - although my
first experiment didn't actually perform any work. When I added
experiments to actually test against regexes, that's when I saw
about a 200% speedup running with 8 jobs (8 being the number of
cores in my machine). I tried 16 (figuring one job could be waiting
on I/O while the other used the CPU), but actually saw a slowdown
as a result. This might be different on HDDs, though.

Another big improvement was to use sysread with a 128K buffer (which
is the default cat uses) rather than Perl's diamond operator - this
combined with the multi-process stuff lead to a 400% speedup.
