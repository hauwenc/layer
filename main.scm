(declare (uses core options util conv dense pool))

(use getopt-long)

(define prog-name "layer")

(define prog-desc "Neural network inference")

(define commands
  (sort (list (list "dense" "Fully connected layer" weighted-layer-options dense)
              (list "conv"  "2-D convolution layer" conv-layer-options     conv)
              (list "pool"  "2-D pooling layer"     pool-layer-options     pool))
        (lambda (a b) (string< (car a) (car b)))))

(define (print-command-usage command #!optional error)
  (when error (print error))
  (let* ((def (assoc command commands))
         (desc (cadr def))
         (grammar (caddr def)))
    (format #t "Usage: ~A ~A [OPTIONS]\n\n~A.\n\n" prog-name command desc)
    (print "Options:")
    (print (usage grammar))))

(define (print-program-usage #!optional error)
  (when error (begin (print error) (newline)))
  (format #t "Usage: ~A COMMAND [OPTIONS]\n\n~A.\n\n" prog-name prog-desc)
  (print "Commands:")
  (for-each (lambda (c) (print "  " (car c) "\t\t" (cadr c))) commands))

(define (parse-options command args grammar)
  (handle-exceptions
   e
   (begin
     ;; TODO: figure out how to print original error message
     (print-command-usage command
                          (format #f
                                  "Error: ~A - ~A\n"
                                  (get-condition-property e 'exn 'message)
                                  (get-condition-property e 'exn 'arguments)))
     #f)
   (getopt-long args grammar)))

(define (help? arg)
  (member arg (list "-h" "--help")))

(let* ((args (command-line-arguments))
       (command (if (= (length args) 0) #f (car args)))
       (def (assoc command commands)))
  (cond ((not command)                                 ;; No given command
         (print-program-usage))
        ((help? command)                               ;; General usage
         (print-program-usage))
        ((not def)                                     ;; No matching command
         (print-program-usage (format #f "'~A' is not a valid command" command)))
        ((and (> (length args) 1) (help? (cadr args))) ;; Command usage
         (print-command-usage command))
        (else
         (let* ((grammar (caddr def))
                (f (cadddr def))
                (options (parse-options command args grammar)))
           (when options
                 (f (make-options-lookup options)))))))
