;;;; Copyright (c) 2016  Spenser Truex
;;;; Permission is hereby granted, free of charge, to any person obtaining a copy of this brainfuck software and associated 
;;;; documentation files (the "Brainfuck Software"), to deal in the Brainfuck Software without restriction, including without
;;;; limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the 
;;;; Brainfuck Software, and to permit persons to whom the Brainfuck Software is furnished to do so, subject to the following 
;;;; conditions:

;;;; The above copyright notice and this permission notice shall be included in all copies or substantial portions of this
;;;;Brainfuck Software.

;;;; THE BRAINFUCK SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
;;;; TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS 
;;;; OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
;;;; OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THIS BRAINFUCK SOFTWARE OR THE USE OR OTHER DEALINGS IN THIS 
;;;; BRAINFUCK SOFTWARE.
(in-package :brain)

;;; All three of the following must be changed together for the desired effect

(define-condition infinite-loop-detected (condition) ())

(defparameter *max-byte* 255)
(defparameter *min-byte* 0)
(defparameter *byte-element-type* '(unsigned-byte 8)
  "Element type used in the tape array. By default an 8 bit unsigned byte is used.")

(defparameter *infinite-looping-allowed* 'nil
  "Turn on or off infinite looping")
(defparameter *loop-limit* 9000
  "Arbitrary limit to detect an infinite loop. May need to be adjusted for long-running programs")
(defvar *current-loop* 0
  "Holds the current number of loops executed. Once it reaches *loop-limit* it will halt the program, unless *infinite-looping-allowed* is T")

(defparameter *tape-size-default* 30000
  "The size of the tape, in bytes, used to store each byte")

(defvar *loop-depth* 0
  "Used to provide an error for #f] and failures to open a loop")

(defvar *output* ""
  "Defaults to an empty string because it is setf'd by other functions")

(defparameter *initial-element* 0
  "initial value for inside the byte array")

(defparameter *separators* '(#\Newline #\Space #\))
  "#F notation separators. These can be changed to allow whitespace 
comments or to break a right parentheses immediately to the right side")

(defparameter *unread-separators* '(#\))
  "#F notation separators that should be unread for use by other functions")

(defun make-tape-array ()
  "Creates a new tape array"
  (make-array *tape-size-default*
	      :element-type *byte-element-type*
	      :initial-element *initial-element*))
(defvar *tape* (make-tape-array)
  "The tape array used to store each byte")

(defvar *brainfuck* ""
  "Place to store brainfuck code input string globally")

(defun pointer-default ()
  "Get the value to  set the pointer back to."
  (floor (/ *tape-size-default* 2)))

(defvar *pointer* (pointer-default)
  "The pointer location for the tape. Starts at the middle.")

(defvar *code-position* 0
  "Holds the state of the pointer in the brainfuck ccode.")

(defparameter *operators* '((open-loop . #\[) ;Can signal an error, will need to be handled for a userless experience.
			    (close-loop . #\]) ;Also can signal an error
			    (right-shift . #\>)
			    (left-shift . #\<)
			    (print-this-byte . #\.)
			    (read-this-byte . #\,)
			    (incf-byte . #\+)
			    (decf-byte . #\-))
  "The operator's function name and it's character. Nothing is passed to the functions")

(defun reset-globals ()
  (setf *tape* (make-tape-array))
  (setf *brainfuck* "")
  (setf *pointer* (pointer-default))
  (setf *output* "")
  (setf *code-position* 0)
  (setf *current-loop* 0)
  (setf *loop-depth* 0))

(defmacro byte-value ()
  `(aref *tape* *pointer*))

(defmacro crement-if (operation
		      bound
		      bound-next)
  "Increment or decrement a byte"
  `(if (= (byte-value) ,bound)
      (setf (byte-value) ,bound-next)
      (,operation (byte-value))))

(defun open-loop ()
  "Open a brainfuck loop with this function"
  ;; For non-zero the loop will be executed naturally until the ], but for a zero the position must be skipped
  (cond ((and (not *infinite-looping-allowed*)
	      (>= *current-loop* *loop-limit*))
	 (error 'infinite-loop-detected))
	((= 0 (byte-value)) (setf *code-position*
				  (1- (skip-loop *code-position*))))
	(t (progn (incf *current-loop*)
		  (incf *loop-depth*)))))

(defun close-loop ()
  (setf *code-position*
	(1- (goto *code-position*)))
  (decf *loop-depth*))

(defun char->function (char)
  (car (rassoc char *operators*)))

(defun name->char (name)
  (cdr (assoc name *operators*)))

(defun this-code-character ()
  (elt *brainfuck* *code-position*))

(defun one-off-fuck ()
  "Interpret a single brainfuck character and execute it."
  (let ((function (char->function (this-code-character)))) 
    (if function
	(funcall function))))

(defun shorthand-fuck-aux (stream list)
  "Recursive reader macro. A compiler from within Lisp!"
  (let ((char (read-char stream nil nil)))
    (if (or (any-char char *separators*)
	    (null char))
	(progn (when (any-char char *unread-separators*)
		 (unread-char char stream))
	       (char-list->string (nreverse list)))
	(shorthand-fuck-aux stream (push char list)))))

(defun shorthand-fuck (stream char subchar)
  "This is a 'Reader Macro' that provides the #F notation"
  (declare (ignore char subchar))
  (list 'fuck (shorthand-fuck-aux stream nil)))
(set-dispatch-macro-character #\# #\F #'shorthand-fuck)

(defun wrap-pointer ()
  (cond ((= *pointer* *tape-size-default*) (setf *pointer* 0))
	((= *pointer* -1) (setf *pointer* (1- *tape-size-default*)))))

(defun incf-byte ()
  "Increment a byte, and wrap to 0 if 255 is incremented"
  (crement-if incf *max-byte* *min-byte*))

(defun decf-byte ()
  "Decrement a byte, and wrap to 255 if 0 is decremented"
  (crement-if decf *min-byte* *max-byte*))

(defun goto-aux (current-position
		 depth)
  (let ((this (elt *brainfuck* current-position)))
    (if (char= (name->char 'open-loop) this)
	(if (= 1 depth)
	    current-position
	    (if (> depth 1)
		(goto-aux (1- current-position)
			  (1- depth))
		(goto-aux (1- current-position)
			  0)))
	(if (char= (name->char 'close-loop) this)
	    (goto-aux (1- current-position)
		      (1+ depth))
	    (goto-aux (1- current-position)
		      depth)))))

(defun goto (position)
  "Work backwards and find the matching open bracket."
  (goto-aux position 0))

(defun right-shift ()
  "Move to the next byte to the 'right'"
  (incf *pointer*)
  (wrap-pointer))

(defun left-shift ()
  "Move to the next byte to the 'left'"
  (decf *pointer*)
  (wrap-pointer))

(defun print-this-byte ()
  (setf *output* (concatenate 'string
			      *output*
			      (vector (integer->ascii (byte-value))))))

(defun read-this-byte ()
  (setf (byte-value)
	(ascii->integer (read-char))))

(defun skip-loop-aux (position depth)
  (let ((this (char *brainfuck* position)))
    (if (char= (name->char 'open-loop) this)
	(skip-loop-aux (1+ position) (1+ depth))
	(if (char= (name->char 'close-loop) this)
	    (if (= 1 depth)
		(1+ position)
		(skip-loop-aux (1+ position) (1- depth)))
	    (skip-loop-aux (1+ position) depth)))))

(defun skip-loop (position)
  (skip-loop-aux position 0))

(defun fuck (brainfuck-string)
  "Interpret the brainfuck"
  (reset-globals)
  (setf *brainfuck* brainfuck-string)
  ;; Loop over each character in the string
  (loop until (= *code-position* (length *brainfuck*)) 
     do (one-off-fuck)
     do (incf *code-position*))
  *output*)
