\name{debug-package}
\alias{debug}
\alias{debug-package}
\docType{package}
\title{How to use the debug package}
\description{
\bold{Update:} as of v1.2.70, I think I may finally have a general-purpose fix for the tcltk bug that has caused display woes for many \code{debug} users. See \bold{Display bugs} below.

\code{debug} is an alternative to \code{trace} and \code{browser}, offering:

\itemize{
\item a visible code window with line-numbered code and highlighted execution point;
\item the ability to set (conditional) breakpoints in advance, at any line number;
\item the opportunity to keep going after errors;
\item multiple debugging windows open at once (when one debuggee calls another, or itself);
\item full debugging of \code{on.exit} code;
\item the ability to move the execution point around without executing intervening statements;
\item direct interpretation of typed-in statements, as if they were in the function itself;
\item debugging of "scripts" (version >= 1.3.11).
}

Even if you don't write functions, or even if you don't write buggy functions, you may find it helpful to run the debugger on functions in \code{package:base} or other packages. Watching what actually happens while a function is executing, can be much more informative than staring at a piece of code or terse documentation.

Debugging your function \code{f} is a two-stage process. First, call \code{mtrace(f)} to store debugging information on \code{f}, and to overwrite \code{f} with a debug-ready version that will call the debugger itself. Second, do whatever you normally do at the command prompt to invoke \code{f}. This is often a direct call to \code{f}, but can be any command that eventually results in \code{f} being invoked. [The third, fourth, etc. stages, in which you actually fix the problem, are not covered here!]

When \code{f} is invoked, a window will appear at the bottom of the screen, showing the code of \code{f} with a highlight on the first numbered line. (There is also an asterisk in the far left hand column of the same row, showing that there's a breakpoint.) The command prompt in R{} will change to "D(...)> ", showing that you are "inside" a function that is being debugged. The debugger is now in "step mode". Anything you type will be evaluated in the frame of the function-- this includes assignments and creation of new variables. If you just type <ENTER>, the highlighted statement in \code{f} will be executed. The result of the statement will be printed in the R{} command window, and the highlight will (probably) move in the \code{f} code window.

To progress through the code of \code{f}, you can keep pressing <ENTER>, but you can also type \code{go()} to put the debugger into "go mode", whereupon it will keep executing code statements without manual intervention. In "go mode", nothing will be printed in the command window (except if there are \code{cat} or \code{print} calls in the function code) until either:

\itemize{
\item the function completes normally, or
\item an error occurs in the function, or
\item there's a user interrupt (e.g. ESCAPE is pressed), or
\item a breakpoint is triggered.
}

In the first case, control is returned to the normal R{} command prompt, just as if the debugger had not been used. In the other cases, the D(...)> prompt will return and the line associated with the error / interrupt / breakpoint will be highlighted in the code window. You are then back in step mode. If there was an error, you can type statement(s) that will cause the error not to happen when the highlighted line executes again, or you can move the highlighted execution point to another line number by calling \code{\link{skip}}. Execution carries on quite normally after errors, just as if the offending statement had been wrapped in a \code{try} call. If your function eventually exits normally (i.e. not via \code{qqq()}, as described next), it will be as if the error never happened (though the error message(s) will be displayed when the R{} command prompt returns).

When in step mode, you can finish debugging and return to the normal R{} command prompt by typing \code{qqq()}. If you type <ESC> while in go mode, you should be returned to step mode, but sometimes you may be dumped back at the R{} command prompt (this is on to-be-fixed list), and sometimes there will be no immediate effect (e.g. if C code is running).

Breakpoints, including conditional breakpoints, are set and cleared by \code{\link{bp}}. Calling \code{go(n)} puts the debugger into go mode, but also sets a temporary breakpoint at line \code{n}, which will be triggered the first time execution reaches line \code{n} but not subsequently.

When the main function code has completed, the debugger moves into any \code{on.exit} code, which is also displayed and line-numbered in the code window. (Even if there are no calls to \code{on.exit}, a numbered NULL statement is placed in the exit code section, so that you can always set a "run-until-return" breakpoint.) If you exit via \code{qqq()}, the exit code will not be executed first; this can lead to subsequent trouble with open connections, screwed-up \code{par} values in graphics, etc.. To make sure the exit code does get executed:

\itemize{
\item use \code{\link{skip}} to move to the start of the exit code;
\item then use \code{go(n)} to run to the final NULL in the exit code;
\item then use \code{qqq()} to finish debugging.
}

When you want to restore \code{f} to its normal non-debugging state (and you are back at the real R{} command prompt), type \code{mtrace(f,FALSE)}. To restore all debuggees, type \code{mtrace.off()}. It is advisable not to \code{save} functions in an \code{\link{mtrace}}d state; to avoid manual untracing and retracing, look up \code{Save} in package \pkg{mvbutils}.

You can debug several functions "at once" (e.g. if \code{f} calls \code{g}, you can \code{\link{mtrace}} both \code{f} and \code{g}, with \code{mtrace(g)} called either inside or outside the debugger), causing several code windows to be open simultaneously. If \code{f} is called again inside \code{f} (either via some statement in \code{f}, or from something you type in step mode), another \code{f} code window will open. The number in the window title is the frame number, and the currently-active frame number is shown in the D(...)> prompt.

For statements typed in at the D(...)> prompt, only the first syntactically-complete R{} expression will be executed; thus, typing \code{a <- 1; a <- 2} will set \code{a} to 1, but typing \code{{ a <- 1; a <- 2}} will set \code{a} to 2.

See section \bold{Special functions} for handling of \code{try}, \code{with}, etc.

See section \bold{Methods} for how to handle S3 methods (easy), reference class methods (pretty easy), and S4 methods (not easy).

For further information, see R-news 3/3.
}
\section{Methods}{
S3 methods work fine with \code{\link{mtrace}}; just do e.g. \code{mtrace( print.classofthing)}. Reference class methods aren't too bad either--- see \code{?mtrace} for details. Unsurprisingly, S4 methods are much more painful to work with. I've only done it once; the following approach worked in R{} 2.12, but probably isn't optimal. Suppose you have figured out that the offending call is something like \code{scrunge( x, y, z)}, where \code{scrunge} is the name of an S4 generic; e.g. you may have tried \code{mtrace( scrunge)}, and found yourself with a debug window containing a 1-line function \code{standardGeneric("scrunge")}. First, use \code{findFunction( "scrunge")} to work out which package contains the definition of \code{scrunge}-- say it's in package \pkg{scrungepack}. Next, you need to work out which specific \code{scrunge} method will be dispatched by \code{scrunge( x, y, z)}. Try this:

\preformatted{
  selectMethod( "scrunge", signature=character())
  # Look for the 'attr(,"target")' line; it might be e.g.
  # attr(,"target")
  #   x    y
  #  "ANY" "ANY"
}

Now you know that it's the \code{x} and \code{y} args that will direct traffic (it could have been just \code{x}, or just \code{z}, or...). So do \code{class(x)} and \code{class(y)} to figure out what the classes are; say they are \code{matrix} and \code{character}. Now do

\preformatted{
  selectMethod( "scrunge", sig=c( "matrix", "character"))
}

Hopefully you'll see another \code{attr(,"target")} line, which will tell you which method to \code{\link{mtrace}}. Suppose it's the same as before (ANY and ANY); then you need to mtrace the \code{ANY#ANY} method. (If only one argument was used for dispatching, there wouldn't be a hash symbol.) The following magic formula will do it:

\preformatted{
  mtrace( 'ANY#ANY', from=environment( scrungepack:::scrunge)$.AllMTable)
}

Then you can proceed as usual. Note that the method that is first dispatched may end up dispatching other methods-- you will have to work out which yourself, and \code{\link{mtrace}} them accordingly. You can \code{\link{mtrace}} various functions in the \pkg{methods} package, e.g. \code{callGeneric}, which might help you track down what's going on. In short: good luck!
}
\section{Special functions}{
Certain system functions with "code" arguments are handled specially in step-mode: currently \code{try}, \code{suppressWarnings}, \code{eval}, \code{evalq}, \code{with}, and \code{within}. In step-mode only, your code argument in these is stepped-into by default if it is more than a simple statement, using a new code window. In go-mode, and in step-mode if the default behaviour has been changed, these functions are handled entirely by R{}. Hence, if you are in go-mode and an error occurs in one of these statements, the debugger will stop at the \code{with} etc. statement, not inside it; but you can then step inside by pressing <ENTER>. The step-into-in-step-mode behaviour can be controlled globally using \code{\link{step.into.sysfuns}}. To avoid step-in at a specific line, you can also just use \code{\link{go}} to proceed to the following statement; this can be much faster than first stepping-in and then calling \code{\link{go}}, because R{} itself handles the evaluation.

To mimic the true behaviour of \code{try}, the debugger should really just return a \code{"try-error"} object if there is an error. However, that is probably not what you want when debugging. Instead, the debugger just behaves as usual with errors, i.e. it breaks into step-mode. If you do then want \code{try} to return the \code{try-error}, just as it would if you weren't debugging, type \code{return( last.try.error())}.

Note that the code window for \code{with}, \code{eval}, etc. contains an on-exit block, just like normal debugger code windows. Its main use is probably to let you set a breakpoint-on-return. However, it seems that you can successfully put \code{on.exit} statements inside your \code{eval} etc. call, whether debugging or not.

\code{with} and \code{within} are S3 generics, and the \pkg{debug} package only knows how to deal with the standard methods: currently \code{with.default}, \code{within.data.frame}, and \code{within.list}. You can debug specific methods manually, e.g. via \code{mtrace( with.myS3class)}.

\code{within} is more complicated than the others, and two extra code windows are currently used: one for the code of \code{within} itself, and one for your statement. The operation of \code{within} itself is not usually very interesting, so the debugger does not pause except at the end of it, unless there is an error. Errors can occur during the updating of your object, which happens after your expression has been evaluated, e.g. from

\preformatted{
  within( data.frame(), bad <- quote( symbols.not.allowed))
}
}
\section{Scripts}{For debugging "scripts" (i.e. qsequences of "live" R{} commands, either in a textfile or in an R{} character vector), see \code{\link{mrun}} and \code{\link{msource}}. Note that \code{\link{mrun}} is mildly useful in its own right, for people who (like me) hate having 100s of different files lying around, and prefer to keep everything as R{} objects in single workspace ".rda" files.
}
\section{Options}{
As of version 1.2.0, output is sent \emph{by default} to \code{stderr()}; this means that you get to see the step-mode output even if the debuggee is redirecting "real" output (e.g. via \code{sink}). If you don't like this (and I believe Tinn-R doesn't), set \code{options( debug.catfile="stdout")}.

Command recall is ON by default, but this means that anything typed while debugging will also be seen in \code{history()} after leaving the debugger. If this is a problem, set \code{options( debug.command.recall=FALSE)}.

There are two adjustable limits on what gets printed out in step mode (otherwise, your screen will often fill with junk, and displaying results may take several minutes). First, printing will be aborted if it takes longer than \code{getOption( "debug.print.time.limit")} seconds, which by default is 0.5 seconds. You might need to increase that, e.g. for displaying big help files in the browser. Also, setting a finite time limit cutoff overrides any other time limits that have been set with \code{setTimeLimit}; this can be prevented by setting \code{options( debug.print.time.limit=Inf)}. Second, by default only objects with \code{object.size} < 8192 bytes will be printed in full; for larger objects, a summary is given instead. You can force printing of any individual object via \code{print}, but you can also increase (or decrease) the threshold to \code{X} bytes, by setting \code{options( threshold.debug.autoprint.size=X)}. The \code{object.size} test isn't foolproof, as some minuscule objects occupy hectares of screen real estate and take ages to print, whereas some big objects print compactly and fast. In my own work, I set the "threshold.debug.autoprint.size" option to \code{Inf} and the time limit usually to 0.5 seconds.

Various TCL/TK-related aspects of the code window can be altered:

\itemize{
\item \code{debug.screen.pos} defaults to "+5-5" for BL corner; try "-5-5" for BR, "-5+5" for TR, "+5+5" for TL.
\item \code{debug.fg} is foreground text colour, defaulting to \code{black}
\item \code{debug.font} defaults to "Courier"; try e.g. ="Courier 24 italic"
\item \code{debug.height} (in lines) defaults to 10
\item \code{debug.width} (in characters) defaults to 120. This is the \emph{window} size; \emph{contents} size is set by...
\item \code{debug.max.line.length} defaults to 256; longer lines are truncated (ie you can't pan to them); not TCL/TK
\item \code{tab.width} defaults to 4, for indenting code lines; not TCL/TK
}

If option \code{debug.wordstar.keys} is TRUE, various somewhat Wordstar-like key-bindings are provided: CTRL-E and CTRL-X to move blue selection up and down, CTRL-D and CTRL-S to scroll right/left, CTRL-W and CTRL-Z to scroll up/down, CTRL-R and CTRL-C to scroll up/down one page, and CTRL-K C to copy the current blue line to the clipboard (since CTRL-C has acquired a different meaning). Now that I've figured out how to add key bindings (sort of), more might appear in future.
}
\section{Display bugs}{
\bold{Update:} in versions >= 1.2.70, try setting \code{options( shakeup.debug.windows=TRUE)} if you have tcltk display woes. This has now worked even on a few previously obstinate Windows machines. Please let me know if this \bold{doesn't} solve it for you.

There have been sporadic and unreproduceable display problems with the TCL/TK window. Sometimes the window frame will appear, but with garbled contents or no contents at all. With RTERM in MS-Windows, a couple of ALT-TABs and mouse clicks to change focus are sometimes necessary. In extremis, the window will eventually sort itself out if you manually minimize, maximize, and restore it-- admittedly an irritation. Although the problem seems less frequent these days, I'm not convinced it is fully solved.

Note: I was getting this problem all the time with R{} 2.13, after not having seen it at all since about R{} 2.8. It now seems OK again after making some random changes to the code; whatever the real problem is, it's probably not permanently fixed.

If you encounter this problem, try setting \code{options(shakeup.debug.windows=TRUE)} (also in \code{.First}). The price paid for setting this option, is that window focus will switch away from R{} to the new code window when the latter is first created, which is mildly irritating. On MS-Windows, I have a fix for that too, but it requires a DLL written in Delphi not C, so I can't CRAN it; let me know if you are desperate.

Apparently the \pkg{RGtk2} package doesn't play nicely with \code{debug}-- the debugging window displays a blank. I haven't checked this out, but would be grateful for advice.
}
\section{Emacs}{
For ESS users: I'm not an Emacs user and so haven't tried ESS with the \pkg{debug} package myself, but a read-through of the ESS documentation suggests that at least one ESS variable may need changing to get the two working optimally, as shown below. Please check the ESS documentation for further details on these points (and see also \code{?mvbutils}). I will update this helpfile when I have more info on what works.

\itemize{
\item The prompt will change when the debugger is running, so you may want to change "inferior-ess-prompt". Prompts will always be of the form D(XXX)> where XXX is a positive integer.
\item Command recall probably won't work inside the debugger (or if it does, it's thanks to ESS rather than to R{}'s own command recall mechanism). It should be disabled by default; if you do get error messages about "history not available", make sure to set \code{options( debug.command.recall=FALSE)} before debugging.
}
}
\seealso{\code{\link{mtrace}}, \code{\link{go}}, \code{\link{skip}}, \code{\link{qqq}}, \code{\link{bp}}, \code{\link{get.retval}}, \code{\link{mtrace.off}}, \code{\link{check.for.tracees}}, \code{\link{step.into.sysfuns}}, \code{\link{last.try.error}}
}
\author{Mark Bravington}
\keyword{debugging
}
