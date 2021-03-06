# Brainfuck from within Common Lisp
LispFuck is a simple Brainfuck interpreter written in Common Lisp. It has the best brainfuck debugging capabilities currently in existence, and code can be interpreted or compiled. Users may: view the tape contents or individual cell contents, find the final position of execution in the tape, change the length of the byte tape in the REPL, and more.
[![Picture of Emacs REPL](https://raw.githubusercontent.com/equwal/LispFuck/master/pics/repl.png)](https://raw.githubusercontent.com/equwal/LispFuck/master/pics/repl.png)

# Brainfuck
Brainfuck is an esoteric programming language that works on a theoretical byte tape (the Universal Turing Machine). The commands are:
```
> Move to the next byte on the right.
< Move to the next byte on the left.
. Print the current byte using ASCII.
, Read a character of input into this byte.
+ Increment this byte's value by one. If the cell value is 255 then set it to 0.
- Decrease the value of this cell by one. If the cell value is 0 then set it to 255.
[ Start a loop. It will be skipped if the current byte is zero, and if not it will terminate at the
  following "]" when the cell is finally set to zero.
] Delimit the end of a loop. 
Any other character is considered a "comment" meaning it does nothing.
```

These can be combined into a string such as the following "Hello World!" program:
```
> #f++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
"Hello World!
"
```
# How to install:
- Make sure you have a Common Lisp implementation installed. I recommend [Steel Bank Common Lisp](http://www.sbcl.org/).
- [ASDF](https://common-lisp.net/project/asdf/) must be installed. Many Lisps come with it, no installation necessary (including [SBCL](http://www.sbcl.org/)).
- Install this code into your ASDF *load directory*. The default on linux is usually `~/common-lisp/`:
```
me@linux:~$ mkdir common-lisp
me@linux:~$ cd common-lisp
me@linux:~/common-lisp$ git clone https://github.com/equwal/LispBrain.git
```
- Run your favourite Common Lisp implementation and load the :brain package:
```
> (asdf:load-system :brain)
```

If you are unable to find where the ASDF load directory is, you may choose to load the files thusly:
```
> (load "[filepath]/code/packages.lisp")
> (load "[filepath]/code/interpreter.lisp")
> (load "[filepath]/code/brain.asd")
> (asdf:load-system :brain)
```

In Allegro common lisp one must first use `(require :asdf)` before executing any other commands in order to activate the preinstalled ASDF system.
# How to Use:
If everything runs smoothly you will be ready to Brainfuck. If there are issues then please *let it be known*. Now one must choose between the `brain:fuck` and the `#F` notation when using the REPL. The `#F` notation is more concise but does not allow any whitespaces or closing parenthesis in the Brainfuck code, while the `brain:fuck` notation allows any character except for an unescaped literal quote `"`, or an unescaped literal backward slash `\` inside of the Brainfuck code. Below they are both shown:
```
Note: This program prints out an ASCII table using a loop.
> (brain:fuck ".+[.+] Please escape your \" and \\ characters!")
"�	

 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"
```
[![Picture of Emacs brain fuck notation](https://raw.githubusercontent.com/equwal/LispFuck/master/pics/brain-fuck-notation.png)](https://raw.githubusercontent.com/equwal/LispFuck/master/pics/brain-fuck-notation.png)
```
> #f.+[.+] <This is not inside the Brainfuck code, nor is + or -.>[]
"�	

 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"
```
[![Picture of Emacs pound letter F notation](https://raw.githubusercontent.com/equwal/LispFuck/master/pics/pound-f-notation.png)](https://raw.githubusercontent.com/equwal/LispFuck/master/pics/pound-f-notation.png)

Code can be saved in a file and run at the repl with the `(load "filepath")` command, and compiled with the `(compile-file "filepath")` command. [SBCL](http://www.sbcl.org/) will always compile your code for you. I recommend not compiling code unless speed is truly important; compiling can make the debugging capabilities of Common Lisp implementations less usable.

# Debugging Brainfuck

Debugging Brainfuck code can be done using all the normal Common Lisp functions: `step`, `trace`, `time`, etc. The following functions and variables are exported to the user and may be useful for debugging Brainfuck code:
```
brain:fuck                ;Used to execute a Brainfuck string directly.
brain:*tape-size-default* ;Number of cells in the tape. Default: 30,000.
brain:decf-byte           ;The - operator function.
brain:incf-byte           ;The + operator function.
brain:read-this-byte      ;The , operator function.
brain:print-this-byte     ;The . operator function.
brain:right-shift         ;The > operator function.
brain:left-shift          ;The < operator function.
brain:one-off-fuck        ;Function called to loop over each character in the code.
brain:*separators*        ;Characters that terminate #F Brainfuck code. Defaults: #\Space #\) #\Newline.
brain:byte-value          ;Returns the value of the curren byte at the *pointer* position.
brain:*tape*              ;Stores the entire tape.
brain:*pointer*           ;Stores the current position in the byte tape. Useful with byte-value. 
                              Default: Exactly in the middle of the tape (15,000).
```
Note that the variables `*tape*` and `*pointer*` are reset upon executing new Brainfuck code. Once the execution is finished their state is frozen in time and ready to be viewed.

# Examples for Debugging:
Suppose you want to make the tape only 10 bytes long (instead of the default 30000) This way you can easily view the tape contents after execution:
```
> (setf brain:*tape-size-default* 10) ;Sets the tape to only elements 0 to 9
> #f->+ ;Sets cell to 255, shifts right and sets to 1
> brain:*tape* ;Holds the byte tape vector
#(0 0 0 0 0 255 1 0 0 0)
> brain:*pointer*
6
> (byte-value)
1
```
Suppose you want to find information about the execution of `incf-byte` and `decf-byte`:
```
> (trace brain:incf-byte brain:decf-byte)
> (brain:fuck "+-")
;;;; The following text is implementation dependent, and looks exactly like this only on SBCL
  0: (INCF-BYTE)
  0: INCF-BYTE returned 1
  0: (DECF-BYTE)
  0: DECF-BYTE returned 0
""
```

# Brain
- A recently deceased human brain being handled. It jiggles like jello: https://www.youtube.com/watch?v=jHxyP-nUhUY

# Conclusion
All of the colorful pictures of code being executed were taken using Emacs and Slime, and edited with GIMP.

Please sumbit any feedback to me via email.

This software is licensed under the MIT free software license.
====
