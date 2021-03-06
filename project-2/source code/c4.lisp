;;;  This is a program which plays a game of Connect Four with a human. 
;;;  To stop the game at any point, press CTRL-C CTRL-C.
;;;*******************************************************************************************

;;;  Global constants initialised here
(defconstant *Dimension* 6)
(defconstant *WIN* 100000)
(defconstant *LOSE* -100000)
(defconstant *PLUS-INFINITY* (* 100 *WIN*))
(defconstant *MINUS-INFINITY* (* 100 *LOSE*))

;;##############################################################################################
;;  This is the function to execute from top-level.  It 
;;  prints the title and calls the Play function.
;;  OPTIONAL INPUTS:  Prune?  T or NIL to turn alpha-beta pruning on (default) or off.
;;                    Depth  A number to indicate maximum tree expansion.  (Default = 3).
;;##############################################################################################
(defun Connect4 ()
  (format t "Connect Four ~% ~%") 
  (format t "Do you want to play first ? (y/n) ~%")
  (let ((My-Turn? (eq 'n (read))) 
   (Root (New-Board))) 
  (format t "Do you want alpha-beta ? (y/n) ~%") 
  (let ((Prune? (eq 'y (read))))   
   (format t "Enter depth of search (1 - 4) : ")
   (let ((Depth (read)) (past-boards (list)))  
    (Play Prune? Depth My-Turn? Root past-boards)))))

;;##############################################################################################
;;  This function alternates calling Human-Move and Computer-Move.
;;  INPUTS:  Prune?   T or NIL for alpha-beta pruning.
;;           Depth
;;           My-Turn  T if Player 2 should move.  NIL if Player 1.
;;           Current-Board  The current board configuration.
;;           past-boards    A list of past board configurations.
;;##############################################################################################
(defun Play (Prune? Depth My-Turn Current-Board past-boards &aux value)
  (cond ((equal Current-Board nil) nil)
    (t
  (Print-Node Current-Board)  
  (cond ((< (setq value (static_eval Current-Board))  *LOSE*)
   (format t "OK smart guy, you won!! (Don't hope to repeat it)~%~%")
   'BYE)
  ((> value *WIN*)
   (format t "OK, I won!! (You know I was designed that way)~%~%")
   'BYE) 
  ((full? Current-Board)
;	 (every #'(lambda (l) (null (first l))) (successors Current-Board (get-color My-Turn)))
(format t "The game ends in a tie!! Enjoyed playing with you.~%~%")
'BYE)
  (t
    (if My-Turn 
      (Play Prune? Depth (not My-Turn) 
       (time (Computer-Move Current-Board Prune? Depth)) past-boards)
      (Play Prune? Depth (not My-Turn) 
        (Human-Move Current-Board past-boards Prune? Depth My-Turn) (push Current-Board past-boards))))))))
;;##############################################################################################
;;  This function generates the color of the token to be dropped into a slot from the boolean
;; variable Turn.
;; INPUT: Turn
;;##############################################################################################
(defun get-color (Turn)
 (if Turn 
   'black 
   'white))

;;##############################################################################################
;;  This function accepts and checks a move by the human competitor.  It returns
;;  the new board configuration after player moves.  
;;  INPUT:  Current-Board
;;          past-boards    A list of past board configurations.
;;          Prune?   T or NIL for alpha-beta pruning.
;;          Depth
;;          My-Turn  T if Player 2 should move.  NIL if Player 1.
;;##############################################################################################
(defun Human-Move (Current-Board past-boards Prune? Depth My-Turn)
  (format t "~%Your turn,  ")
  (let ((Next-Board (Drop-Token Current-Board (Player-Chooses-Slot past-boards Prune? Depth My-Turn) 'white)))
    (cond ((equal 'bye Next-Board) nil)
      ((null Next-Board)
      (format t "~%That slot is full.  Try again.")
      (Human-Move Current-Board))
    (t Next-Board))))

;;##############################################################################################
;;  This function generates the move by the computer.  
;;  Computer-Move analyzes the game tree whose root is Current-Board using MINIMAX searching 
;;  (with the option of alpha-beta pruning).  It will return the new board configuration
;;  after the computer chooses the best move.
;;  INPUT:  Current-Board
;;          Prune?   T or NIL for alpha-beta pruning.
;;          Depth
;;##############################################################################################
(defun Computer-Move (Current-Board Prune Depth)
  (let ((decision (minimax-decision Current-Board Depth Prune)))
    (format t "~%~%~%Number of boards evaluated --> ~A~%~%" (first decision)) 
    (format t "Dropped token in slot ~A~%" (second decision))
    (Drop-Token Current-Board (1- (second decision)) 'black)))

;;##############################################################################################
;;  This function allows a player to choose a slot number that is between 1 and the board 
;; dimension.  It returns the chosen slot number.
;;  Alternately, the player may also type 'u' to undo moves. Moves undone past the first move
;; will lead to the board being reset.
;;  INPUTS: past-boards    A list of past board configurations.
;;          Prune?   T or NIL for alpha-beta pruning.
;;          Depth
;;          My-Turn  T if Player 2 should move.  NIL if Player 1.
;;##############################################################################################
(defun Player-Chooses-Slot (past-boards Prune? Depth My-Turn)
  (format t "~&Choose slot (1..~d) or u to undo moves:  " *Dimension*)
  (let ((Players-Choice (read)))
    (cond ((and (numberp Players-Choice)
      (> Players-Choice 0)
      (<= Players-Choice *Dimension*))
    (1- Players-Choice))
    ((equal Players-Choice 'u) 
      (format t "How many moves would you like to undo?~%")
      (setf num-undo (read))
      (cond ((numberp num-undo)
        (when (< (length past-boards) num-undo)
          (Play Prune? Depth My-Turn (New-Board) (list)))
        (Play Prune? Depth My-Turn (nth (- num-undo 1) past-boards) (nthcdr num-undo past-boards)))
      (t (format t "Invalid choice, please choose again~%")
       (Player-Chooses-Slot past-boards Prune? Depth My-Turn))))
      (t 
        (format t "Invalid choice, please choose again~%")
        (Player-Chooses-Slot past-boards Prune? Depth My-Turn)))))

;;##############################################################################################
;;  This function creates a brand new board 
;;##############################################################################################
(defun New-Board ()
  (make-array (list *Dimension* *Dimension*) :initial-element 'empty))

;;##############################################################################################
;;  This function returns the new board configuration that results when
;;  a token is dropped in a given slot of the current board configuration.
;;  It copies the current configuration into Next-Board, and then modifies
;;  Next-Board based on whose turn it is and how far the token can drop in
;;  the given slot.  If the slot is full, this function returns NIL.
;;  INPUTS:  Current-Board  Current board configuration.
;;           Slot           Number of slot in which token is to be dropped.
;;           color          color of the token to be dropped
;;           Bottom-Row     Number of row that the token is dropping through.
;;##############################################################################################
(defun Drop-Token (Current-Board Slot color)
  (cond ((equal slot 'bye) 'bye)
  (t (if (not (eq (aref Current-Board 0 Slot) 'empty)) 
      nil;; slot is full
      (let ((Next-Board (Copy-of-Board Current-Board)))
        (do ((Bottom-Row 0 (1+ Bottom-Row)))
	  ((or (= Bottom-Row (1- *Dimension*)) ; reached bottom of slot
      (not (eq (aref Current-Board (1+ Bottom-Row) Slot) 'empty)))
					;slot is filled from one row down
          (setf (aref Next-Board Bottom-Row Slot) color)
          Next-Board)))))))

;;##############################################################################################
;; This function returns t if Current-Board is full, otherwise returns nil
;;##############################################################################################
(defun full? (Current-Board)
  (dotimes (i *Dimension* t)
    (when (eq (aref Current-Board 0 i) 'empty)
      (return nil))))

;;##############################################################################################
;;  This function returns a copy of a board.  The copy can be modified 
;;  without affecting the original.
;;##############################################################################################
(defun Copy-Of-Board (Board)
  (let ((newBoard (make-array (list *Dimension* *Dimension*))))
    (dotimes (i *Dimension* newBoard)
      (dotimes (j *Dimension*)
        (setf (aref newBoard i j) (aref Board i j))))))

;;##############################################################################################
;;  This following functions print a node (board) from the game tree.
;;##############################################################################################
(defun Print-Node (Node)
  (Line *Dimension*)
  (dotimes (i *Dimension*)
   (dotimes (j *Dimension*)
     (cond ((eq (aref Node i j) 'black) (format t "|  *  |"))
      ((eq (aref Node i j) 'white) (format t "|  O  |"))
      (t (format t "|     |"))))
   (format t "~%"))
  (Line *Dimension*))

(defun Line (Length)
 (format t "~&")
 (dotimes (i Length)
   (format t "___~A___" (1+ i)))
 (format t "~%"))

;;##############################################################################################
;;  This function generates all the successors of a given board. A single board is constructed
;; as a list of lists. A non-existent successor (suppose a slot is full) is represented by an
;; empty list.  Returns pairs of boards and the slot number in which the token is dropped to
;; to generate that board.
;; INPUT: Board -> current board
;;	  color -> the color of token which is to be dropped to produce successors.
;;##############################################################################################
(defun successors (Board color &optional (Slot 0))
  (if (= Slot  *Dimension*) 
    nil
    (cons (list (Drop-Token Board Slot color) (1+ Slot))
     (successors Board color (1+ Slot)))))
