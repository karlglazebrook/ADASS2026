;; csubraw.lisp — Common Lisp port of csubraw.py / csubraw.rb.
;;
;; Two stylistic variants in one file, controlled by feature
;; +ADASS-TYPED+ at compile/load time.  When typed, every variable
;; gets a (declare (type ...)) and SBCL inlines the inner loop into
;; tight machine code.  When not typed, the loop runs through generic
;; arithmetic and array-element dispatch — vastly slower.
;;
;; Use as:
;;    sbcl --script csubraw.lisp NRPT NX NY               ; untyped
;;    sbcl --eval '(push :adass-typed *features*)' --script csubraw.lisp NRPT NX NY  ; typed
;;
;; (We control the variant by which entry point is called from Run.py
;; rather than a feature flag — see csubraw-typed.lisp for the typed
;; variant.)

(declaim (optimize (speed 3) (safety 0) (debug 0)))

(defun subr (in-arr nx ny out-arr)
   (dotimes (iy ny)
      (dotimes (ix nx)
         (setf (aref out-arr iy ix)
               (+ (aref in-arr iy ix) ix iy)))))

(defun main ()
   (let* ((args (cdr sb-ext:*posix-argv*))
          (nrpt (if (>= (length args) 1) (parse-integer (nth 0 args)) 1000))
          (nx   (if (>= (length args) 2) (parse-integer (nth 1 args)) 2000))
          (ny   (if (>= (length args) 3) (parse-integer (nth 2 args)) 10))
          (in-arr  (make-array (list ny nx) :element-type 'double-float
                                            :initial-element 0d0))
          (out-arr (make-array (list ny nx) :element-type 'double-float
                                            :initial-element 0d0)))
      (dotimes (iy ny)
         (dotimes (ix nx)
            (setf (aref in-arr iy ix)
                  (coerce (- (+ nx ny) ix iy) 'double-float))))
      (format t "Arrays ~A by ~A count ~A~%" nx ny nrpt)
      (dotimes (r nrpt)
         (subr in-arr nx ny out-arr))
      ;; check
      (block check
         (dotimes (iy ny)
            (dotimes (ix nx)
               (let ((got (aref out-arr iy ix))
                     (want (+ (aref in-arr iy ix) ix iy)))
                  (unless (= got want)
                     (format t "Error: ~A ~A ~A ~A~%"
                             got ix iy (aref in-arr iy ix))
                     (return-from check))))))))

(main)
