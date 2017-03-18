# Things we can do now that we're using 5.10


      $MATCH
       $&      The string matched by the last successful pattern match (not
               counting any matches hidden within a BLOCK or "eval()" enclosed
               by the current BLOCK).

               The use of this variable anywhere in a program imposes a
               considerable performance penalty on all regular expression
               matches.  To avoid this penalty, you can extract the same
               substring by using "@-".  Starting with Perl 5.10, you can use
               the "/p" match flag and the "${^MATCH}" variable to do the same
               thing for particular match operations.


       ${^MATCH}
               This is similar to $& ($MATCH) except that it does not incur
               the performance penalty associated with that variable, and is
               only guaranteed to return a defined value when the pattern was
               compiled or executed with the "/p" modifier.

               This variable was added in Perl 5.10.

               This variable is read-only and dynamically-scoped.


Will use of `$&` and `${^MATCH}` conflict with each other?

Defined-or: //

state

say
